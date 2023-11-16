/*-- Last Change Revision: $Rev: 1976409 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-01-15 12:20:58 +0000 (sex, 15 jan 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_ref_ext IS

    /* CAN'T TOUCH THIS */
    g_error VARCHAR2(1000 CHAR);

    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    /**
    * Checks if session is active and returns session data: URL, EXT_CODE and NUM_ORDER
    *
    * @param   i_lang            Language identifier    
    * @param   i_session_id      Session identifier   
    * @param   o_ref_url         Session URL
    * @param   o_ext_code        External code institution
    * @param   o_num_order       Professional num order   
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-04-2010
    */
    FUNCTION get_session_data
    (
        i_lang       IN language.id_language%TYPE,
        i_session_id IN ref_ext_session.id_session%TYPE,
        o_ref_url    OUT ref_ext_session.ref_url%TYPE,
        o_ext_code   OUT institution.ext_code%TYPE,
        o_num_order  OUT professional.num_order%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_session(x_id_session IN ref_ext_session.id_session%TYPE) IS
            SELECT s.ref_url, s.ext_code, s.num_order
              FROM ref_ext_session s
             WHERE s.id_session = x_id_session
               AND s.flg_active = pk_ref_constant.g_yes;
    BEGIN
    
        g_error := 'Init get_session_data / ID_SESSION=' || i_session_id;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_session(i_session_id);
        FETCH c_session
            INTO o_ref_url, o_ext_code, o_num_order;
        g_found := c_session%FOUND;
        CLOSE c_session;
    
        IF NOT g_found
        THEN
            g_error := 'Invalid session. ID_SESSION=' || i_session_id || ' EXT_CODE=' || o_ext_code || ' NUM_ORDER=' ||
                       o_num_order;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_SESSION_DATA',
                                              o_error    => o_error);
            IF c_session%ISOPEN
            THEN
                CLOSE c_session;
            END IF;
            RETURN FALSE;
    END get_session_data;

    /**
    * Returns institution identifier
    *
    * @param   i_lang            Language identifier
    * @param   i_ext_code        External code institution
    * @param   o_id_inst         Institution identifier in Alert
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-04-2010
    */
    FUNCTION get_inst
    (
        i_lang     IN language.id_language%TYPE,
        i_ext_code IN institution.ext_code%TYPE,
        o_id_inst  OUT institution.id_institution%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_inst(x_id_inst institution.ext_code%TYPE) IS
            SELECT i.id_institution
              FROM institution i
             WHERE i.ext_code = x_id_inst
               AND i.flg_available = pk_ref_constant.g_yes;
    BEGIN
    
        g_error := 'Init get_prof_inst / EXT_CODE=' || i_ext_code;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_inst(i_ext_code);
        FETCH c_inst
            INTO o_id_inst;
        g_found := c_inst%FOUND;
        CLOSE c_inst;
    
        IF NOT g_found
        THEN
            g_error := 'Institution ' || i_ext_code || ' not found.';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INST',
                                              o_error    => o_error);
            IF c_inst%ISOPEN
            THEN
                CLOSE c_inst;
            END IF;
            RETURN FALSE;
    END get_inst;

    /**
    * Returns professional and institution identifiers
    *
    * @param   i_lang            Language identifier
    * @param   i_ext_code        External code institution
    * @param   i_num_order       Professional num order    
    * @param   o_id_prof         Professional identifier in Alert
    * @param   o_id_inst         Institution identifier in Alert
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-04-2010
    */
    FUNCTION get_prof_inst
    (
        i_lang      IN language.id_language%TYPE,
        i_ext_code  IN institution.ext_code%TYPE,
        i_num_order IN professional.num_order%TYPE,
        o_id_prof   OUT professional.id_professional%TYPE,
        o_user      OUT ab_user_info.login%TYPE,
        o_id_inst   OUT institution.id_institution%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_prof
        (
            x_i institution.ext_code%TYPE,
            x_p professional.num_order%TYPE
        ) IS
            SELECT p.id_professional, i.id_institution, u.login
              FROM professional p
              JOIN prof_institution pi
                ON (p.id_professional = pi.id_professional)
              JOIN institution i
                ON (i.id_institution = pi.id_institution)
              JOIN ab_user_info u
                ON (p.id_professional = u.id_ab_user_info)
             WHERE p.num_order = x_p
               AND p.flg_state = pk_ref_constant.g_active
               AND i.ext_code = x_i
               AND i.flg_available = pk_ref_constant.g_yes
               AND pi.flg_state = pk_ref_constant.g_active
               AND pi.dt_end_tstz IS NULL;
    BEGIN
    
        g_error := 'Init get_prof_inst / EXT_CODE=' || i_ext_code || ' NUM_ORDER=' || i_num_order;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_prof(i_ext_code, i_num_order);
        FETCH c_prof
            INTO o_id_prof, o_id_inst, o_user;
        g_found := c_prof%FOUND;
        CLOSE c_prof;
    
        IF NOT g_found
        THEN
            g_error := 'User ' || i_num_order || ' not found in institution ' || i_ext_code;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PROF_INST',
                                              o_error    => o_error);
            IF c_prof%ISOPEN
            THEN
                CLOSE c_prof;
            END IF;
            RETURN FALSE;
    END get_prof_inst;

    /**
    * Gets patient identifier in Alert (if exists) 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional id, institution and software    
    * @param   i_patient_data    Temporary patient data
    * @param   o_sns             Patient SNS
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   05-05-2010
    */
    FUNCTION get_patient_sns
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient_data IN ref_ext_xml_data.patient_data%TYPE,
        o_sns          OUT pat_health_plan.num_health_plan%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_hplan      health_plan.id_health_plan%TYPE;

        l_sns_doc_type  doc_type.id_doc_type%TYPE;
    BEGIN
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init get_patient_sns';
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error        := 'Call pk_sysconfig.get_config';
        l_id_hplan     := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
        l_sns_doc_type := to_number(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_sc_sns_doc_type,
                                                            i_prof    => i_prof));
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- searching in /Patient/HealthPlans
        g_error := 'searching in /Patient/HealthPlans/CODE=' || l_id_hplan;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT num_hp
              INTO o_sns
              FROM (SELECT extractvalue(VALUE(pat_hplan), '/HealthPlans/Code') id_hp,
                           extractvalue(VALUE(pat_hplan), '/HealthPlans/Number') num_hp
                      FROM TABLE(xmlsequence(extract(xmltype(i_patient_data), '/Patient/HealthPlans'))) pat_hplan)
             WHERE id_hp = l_id_hplan;
        EXCEPTION
            WHEN no_data_found THEN
                -- no sns defined, trying documents element
                NULL;
        END;
    
        IF o_sns IS NULL
        THEN
            -- searching in /Patient/Identification/DOCUMENTATION
            g_error := 'searching in /Patient/Identification/Documents/Type=' || l_sns_doc_type;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT doc_num
                  INTO o_sns
                  FROM (SELECT extractvalue(VALUE(pat_hplan), '/Documents/Type') doc_type,
                               extractvalue(VALUE(pat_hplan), '/Documents/Number') doc_num
                          FROM TABLE(xmlsequence(extract(xmltype(i_patient_data), '/Patient/Identification/Documents'))) pat_hplan)
                 WHERE doc_type = l_sns_doc_type;
            EXCEPTION
                WHEN no_data_found THEN
                    -- no sns defined for this patient
                    NULL;
            END;
        END IF;
    
        g_error := 'SNS=' || o_sns;
        pk_alertlog.log_debug(g_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PATIENT_SNS',
                                                     o_error    => o_error);
    END get_patient_sns;

    /**
    * Gets patient identifier in Alert (if exists) 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional id, institution and software
    * @param   i_referral_data   Referral temporary data. If is a referral update, gets patient identifier from this parameter.
    * @param   i_sns             SNS number. Gets patient identifier from this parameter only if is a referral creation.
    * @param   o_id_patient      Patient identifier
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-04-2010
    */
    FUNCTION get_patient_id
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_referral_data IN ref_ext_xml_data.referral_data%TYPE,
        i_sns           IN pat_health_plan.num_health_plan%TYPE,
        o_id_patient    OUT patient.id_patient%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_hplan        health_plan.id_health_plan%TYPE;
        l_sc_multi_instit VARCHAR2(1 CHAR);
        l_num_sns_tab     table_number;
    
        CURSOR c_pat_hplan_multi
        (
            x_id_hplan  IN pat_health_plan.id_health_plan%TYPE,
            x_num_hplan IN pat_health_plan.num_health_plan%TYPE
        ) IS
            SELECT id_patient
              FROM pat_health_plan php
             WHERE php.id_health_plan = x_id_hplan
               AND php.flg_status = pk_ref_constant.g_active
               AND php.num_health_plan = x_num_hplan
               AND php.id_institution = 0;
    
        CURSOR c_pat_hplan
        (
            x_id_hplan  IN pat_health_plan.id_health_plan%TYPE,
            x_num_hplan IN pat_health_plan.num_health_plan%TYPE,
            x_id_inst   IN pat_health_plan.id_institution%TYPE
        ) IS
            SELECT id_patient
              FROM pat_health_plan php
             WHERE php.id_health_plan = x_id_hplan
               AND php.flg_status = pk_ref_constant.g_active
               AND php.num_health_plan = x_num_hplan
               AND php.id_institution = x_id_inst;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init get_patient_id / SNS=' || i_sns;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error    := 'Call pk_sysconfig.get_config';
        l_id_hplan := pk_ref_utils.get_default_health_plan(i_prof => i_prof);
    
        l_sc_multi_instit := pk_sysconfig.get_config(pk_ref_constant.g_sc_multi_institution, i_prof);
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- checking if is a referral creation or update
        g_error := 'Check ReferralID';
        pk_alertlog.log_debug(g_error);
    
        BEGIN
            SELECT p1.id_patient
              INTO o_id_patient
              FROM (SELECT extractvalue(VALUE(referral_data), '/Referral/ReferralID') id_referral
                      FROM TABLE(xmlsequence(extract(xmltype(i_referral_data), '/Referral'))) referral_data) t
              JOIN p1_external_request p1
                ON (p1.id_external_request = t.id_referral);
        EXCEPTION
            WHEN no_data_found THEN
                o_id_patient := NULL;
        END;
    
        IF o_id_patient IS NULL
        THEN
        
            -- getting patient from sns number
        
            -- getting sns number
            g_error := 'MULTI_INSITTUTION=' || l_sc_multi_instit;
            pk_alertlog.log_debug(g_error);
        
            IF l_sc_multi_instit = pk_ref_constant.g_yes
            THEN
            
                g_error := 'OPEN c_pat_hplan_multi(' || l_id_hplan || ',' || i_sns || ')';
                pk_alertlog.log_debug(g_error);
            
                OPEN c_pat_hplan_multi(l_id_hplan, i_sns);
                FETCH c_pat_hplan_multi BULK COLLECT
                    INTO l_num_sns_tab;
                CLOSE c_pat_hplan_multi;
            
                g_error := 'l_num_sns_tab.COUNT=' || l_num_sns_tab.count;
                pk_alertlog.log_debug(g_error);
            
            ELSIF l_sc_multi_instit = pk_ref_constant.g_no
            THEN
            
                g_error := 'OPEN c_pat_hplan(' || l_id_hplan || ',' || i_sns || ',' || i_prof.id || ')';
                pk_alertlog.log_debug(g_error);
            
                OPEN c_pat_hplan(l_id_hplan, i_sns, i_prof.id);
                FETCH c_pat_hplan BULK COLLECT
                    INTO l_num_sns_tab;
                CLOSE c_pat_hplan;
            
                g_error := 'l_num_sns_tab.COUNT=' || l_num_sns_tab.count;
                pk_alertlog.log_debug(g_error);
            END IF;
        
            IF l_num_sns_tab.count != 1
            THEN
            
                -- too many patients with the same sns number... 
                -- return null
                o_id_patient := NULL;
            
                g_error := 'ID_PATIENT NOT FOUND / SNS=' || i_sns || ' ID_INSTITUION=' || i_prof.id;
                pk_alertlog.log_debug(g_error);
            
            ELSE
                -- patient found in Alert DB
                g_error := 'ID_PATIENT=' || l_num_sns_tab(1);
                pk_alertlog.log_debug(g_error);
            
                o_id_patient := l_num_sns_tab(1);
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_PATIENT_ID',
                                                     o_error    => o_error);
    END get_patient_id;

    /**
    * Gets workflow identifier according to external system origin
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_id_ext_sys      External system identifier
    * @param   o_id_workflow     Workflow identifier    
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   20-04-2010
    */
    FUNCTION get_id_workflow
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ext_sys  IN external_sys.id_external_sys%TYPE,
        o_id_workflow OUT wf_workflow.id_workflow%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ext_sys_fertis external_sys.id_external_sys%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
    
        g_error := 'Init get_id_workflow / ID_EXT_SYS=' || i_id_ext_sys;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error          := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_ext_sys_fertis;
        l_ext_sys_fertis := to_number(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ext_sys_fertis,
                                                              i_prof    => i_prof));
    
        ----------------------
        -- FUNC
        ----------------------      
        g_error := 'CASE ' || i_id_ext_sys || ' / FERTIS=' || l_ext_sys_fertis;
        pk_alertlog.log_debug(g_error);
        CASE i_id_ext_sys
            WHEN l_ext_sys_fertis THEN
                o_id_workflow := pk_ref_constant.g_wf_fertis;
            ELSE
                o_id_workflow := NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ID_WORKFLOW',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_workflow;

    /**
    * Returns Referral software identifier
    *
    * @param   i_lang           Language associated to the professional executing the request                  
    * @param   i_id_prof        Professional identifier 
    * @param   i_id_inst        Institution identifier
    *
    * @RETURN  Software identifier
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION get_ref_software
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        i_id_inst IN institution.id_institution%TYPE
    ) RETURN software.id_software%TYPE IS
        l_id_soft software.id_software%TYPE;
    BEGIN
    
        -- gets software identifier
        g_error := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_sc_software_p1 ||
                   ' ID_PROFESSIONAL=' || i_id_prof || ' ID_INSTITUTION=' || i_id_inst;
        pk_alertlog.log_debug(g_error);
    
        l_id_soft := pk_sysconfig.get_config(pk_ref_constant.g_sc_software_p1, profissional(i_id_prof, i_id_inst, 0));
    
        RETURN l_id_soft;
    
    END get_ref_software;

    /**
    * Checks if codes of diagnostics and problems are valid 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_diag_type       Allowable diagnosis type   
    * @param   i_ref_temp        Referral temporary data
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   05-05-2010
    */
    FUNCTION check_diag_codes
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diag_type IN table_varchar,
        i_ref_temp  IN ref_ext_xml_data.referral_data%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_icd_tab  table_varchar;
        l_id_tab        table_number;
        l_diag_type_tab table_varchar;
    
        -- checking if table_number has nulls
        FUNCTION get_nulls(i_table IN table_number) RETURN VARCHAR2 IS
            l_result VARCHAR2(1 CHAR);
        BEGIN
        
            g_error := 'Init get_nulls / TABLE.COUNT=' || i_table.count;
            pk_alertlog.log_debug(g_error);
        
            l_result := pk_ref_constant.g_no;
        
            FOR i IN 1 .. i_table.count
            LOOP
                IF i_table(i) IS NULL
                THEN
                    l_result := pk_ref_constant.g_yes;
                END IF;
            END LOOP;
        
            RETURN l_result;
        END get_nulls;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init check_diag_codes / i_diag_type=' || pk_utils.to_string(i_diag_type);
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- FUNC
        ----------------------
    
        ---------------
        -- checking diagnosis type (must be included in i_diag_type for problems and diagnosis)
        g_error := 'Checking diagnosis type';
        SELECT extractvalue(VALUE(referral_data), 'DiagnosisInformation/Codification') d_codification
          BULK COLLECT
          INTO l_diag_type_tab
          FROM TABLE(xmlsequence(extract(xmltype(i_ref_temp), '/Referral/ClinicalInformation/DiagnosisInformation'))) referral_data
         WHERE extractvalue(VALUE(referral_data), 'DiagnosisInformation/Codification') NOT IN
               (SELECT column_value
                  FROM TABLE(CAST(i_diag_type AS table_varchar)));
    
        IF l_diag_type_tab.count > 0
        THEN
            g_error := 'Invalid diagnosis type / VALID diagnosis type=' || pk_utils.to_string(i_diag_type) ||
                       ' Referral diagnosis type=' || pk_utils.to_string(l_diag_type_tab);
            RAISE g_exception;
        END IF;
    
        ---------------
        -- checking code icds
        g_error         := 'reset';
        l_id_tab        := NULL;
        l_code_icd_tab  := NULL;
        l_diag_type_tab := NULL;
    
        g_error := 'Checking diagnosis code_icd';
        pk_alertlog.log_debug(g_error);
    
        SELECT DISTINCT d.id_diagnosis, t_ref.d_code, t_ref.d_codification
          BULK COLLECT
          INTO l_id_tab, l_code_icd_tab, l_diag_type_tab
          FROM (SELECT extractvalue(VALUE(referral_data), 'DiagnosisInformation/Codification') d_codification, -- ICD9, ICD10, ICPC2...
                       extractvalue(VALUE(referral_data), 'DiagnosisInformation/Code') d_code
                  FROM TABLE(xmlsequence(extract(xmltype(i_ref_temp),
                                                 '/Referral/ClinicalInformation/DiagnosisInformation'))) referral_data) t_ref
          LEFT JOIN diagnosis_content d
            ON (d.flg_type = t_ref.d_codification AND d.code_icd = t_ref.d_code);
    
        g_error := 'DIAGNOSIS IDs=' || pk_utils.to_string(l_id_tab) || ' CODEs=' || pk_utils.to_string(l_code_icd_tab) ||
                   ' DIAG_TYPE=' || pk_utils.to_string(l_diag_type_tab);
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Call get_nulls / ID.COUNT=' || l_id_tab.count || ' CODE_ICD.COUNT=' || l_code_icd_tab.count;
        IF get_nulls(i_table => l_id_tab) = pk_ref_constant.g_yes
        THEN
            -- some problems do not match
            g_error := 'Inexistent Diagnosis / CODEs=' || pk_utils.to_string(l_code_icd_tab) || ' TYPEs=' ||
                       pk_utils.to_string(l_diag_type_tab);
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CHECK_DIAG_CODES',
                                              o_error    => o_error);
            RETURN FALSE;
    END check_diag_codes;

    /* 
    * Fills in the referral rowtype with old and new data 
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_pat_temp        Patient temp data imported by external system
    * @param   i_ref_temp        Referral temp data imported by external system
    * @param   o_ref_old_row     Referral data in alert database
    * @param   o_ref_new_row     Referral new data imported by external system
    * @param   o_error           An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   04-05-2010
    */
    FUNCTION fill_referral_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat_temp    IN ref_ext_xml_data.patient_data%TYPE,
        i_ref_temp    IN ref_ext_xml_data.referral_data%TYPE,
        o_ref_old_row OUT p1_external_request%ROWTYPE,
        o_ref_new_row OUT p1_external_request%ROWTYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- returns dest institutions available for this speciality (using view v_ref_network)
        -- IF x_inst_ext_code is specified than returns only id_institution of x_inst_ext_code
        CURSOR c_spec_inst_fertis
        (
            x_spec          IN p1_speciality.id_speciality%TYPE,
            x_inst_ext_code IN institution.ext_code%TYPE,
            x_id_inst_dest  IN institution.id_institution%TYPE,
            x_id_ext_sys    IN external_sys.id_external_sys%TYPE,
            x_id_dcs        IN p1_spec_dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
        -- external workflow
            SELECT v.id_institution, v.id_dep_clin_serv
              FROM v_ref_network v
             WHERE v.flg_type = pk_ref_constant.g_p1_type_c
               AND v.id_inst_orig = i_prof.institution
               AND v.id_speciality = x_spec
               AND v.id_external_sys IN (nvl(x_id_ext_sys, 0), 0)
                  --AND v.flg_default_dcs = pk_ref_constant.g_yes -- needed to issue the referral
               AND (x_inst_ext_code IS NULL OR v.ext_code = x_inst_ext_code) -- IF x_inst_ext_code is NOT NULL returns this institution
               AND (x_id_inst_dest IS NULL OR v.id_institution = x_id_inst_dest)
               AND ((x_id_dcs IS NULL) OR (v.id_dep_clin_serv = x_id_dcs AND v.flg_visible_orig = pk_ref_constant.g_yes OR
                   v.flg_default_dcs = pk_ref_constant.g_yes))
            UNION ALL
            -- internal workflow
            SELECT vi.id_institution, vi.id_dep_clin_serv
              FROM v_ref_internal_fertis vi
             WHERE vi.flg_type = pk_ref_constant.g_p1_type_c
               AND vi.id_inst_orig = i_prof.institution
               AND vi.id_speciality = x_spec
               AND vi.id_external_sys IN (nvl(x_id_ext_sys, 0), 0)
                  --AND vi.flg_default_dcs = pk_ref_constant.g_yes -- needed to issue the referral
               AND (x_inst_ext_code IS NULL OR vi.ext_code = x_inst_ext_code) -- IF x_inst_ext_code is NOT NULL returns this institution
               AND (x_id_inst_dest IS NULL OR vi.id_institution = x_id_inst_dest)
               AND ((x_id_dcs IS NULL) OR (vi.id_dep_clin_serv = x_id_dcs));
    
        CURSOR c_spec_inst
        (
            x_spec          IN p1_speciality.id_speciality%TYPE,
            x_inst_ext_code IN institution.ext_code%TYPE,
            x_id_inst_dest  IN institution.id_institution%TYPE,
            x_id_ext_sys    IN external_sys.id_external_sys%TYPE,
            x_flg_avail     IN p1_spec_dep_clin_serv.flg_availability%TYPE,
            x_id_dcs        IN p1_spec_dep_clin_serv.id_dep_clin_serv%TYPE
        ) IS
        -- external workflow       
            SELECT v.id_institution, v.id_dep_clin_serv
              FROM v_ref_network v
             WHERE v.flg_type = pk_ref_constant.g_p1_type_c
               AND v.id_inst_orig = i_prof.institution
               AND v.id_speciality = x_spec
               AND v.id_external_sys IN (nvl(x_id_ext_sys, 0), 0)
                  --AND v.flg_default_dcs = pk_ref_constant.g_yes -- needed to issue the referral
               AND (x_inst_ext_code IS NULL OR v.ext_code = x_inst_ext_code) -- IF x_inst_ext_code is NOT NULL returns this institution
               AND (x_id_inst_dest IS NULL OR v.id_institution = x_id_inst_dest)
               AND x_flg_avail = pk_ref_constant.g_flg_availability_e -- use this view for external referrals
               AND ((x_id_dcs IS NULL) OR (v.id_dep_clin_serv = x_id_dcs AND v.flg_visible_orig = pk_ref_constant.g_yes OR
                   v.flg_default_dcs = pk_ref_constant.g_yes))
            UNION ALL
            -- at hospital entrance workflow
            SELECT vp.id_institution, vp.id_dep_clin_serv
              FROM v_ref_hosp_entrance vp
             WHERE vp.flg_type = pk_ref_constant.g_p1_type_c
               AND vp.id_institution = i_prof.institution
               AND vp.id_speciality = x_spec
               AND vp.id_external_sys IN (nvl(x_id_ext_sys, 0), 0)
                  --AND vp.flg_default_dcs = pk_ref_constant.g_yes -- needed to issue the referral
               AND (x_inst_ext_code IS NULL OR vp.ext_code = x_inst_ext_code) -- IF x_inst_ext_code is NOT NULL returns this institution
               AND (x_id_inst_dest IS NULL OR vp.id_institution = x_id_inst_dest)
               AND x_flg_avail = pk_ref_constant.g_flg_availability_p -- use this view for hosp entrance referrals
               AND ((x_id_dcs IS NULL) OR
                   (vp.id_dep_clin_serv = x_id_dcs AND vp.flg_visible_orig = pk_ref_constant.g_yes OR
                   vp.flg_default_dcs = pk_ref_constant.g_yes));
    
        l_ext_code_dest    ref_ext_session.ext_code%TYPE;
        l_sns              pat_health_plan.num_health_plan%TYPE;
        l_flg_availability p1_spec_dep_clin_serv.flg_availability%TYPE;
    BEGIN
    
        g_error := 'Init fill_referral_data';
        pk_alertlog.log_debug(g_error);
    
        --------------------
        -- getting referral new data (imported by external system)
        g_error := 'Getting referral new data';
        SELECT t_ref.id_referral,
               t_ref.id_external_sys,
               t_ref.id_speciality,
               t_ref.ext_code,
               t_ref.flg_priority,
               t_ref.flg_home,
               t_ref.id_dep_clin_serv
          INTO o_ref_new_row.id_external_request,
               o_ref_new_row.id_external_sys,
               o_ref_new_row.id_speciality,
               l_ext_code_dest,
               o_ref_new_row.flg_priority,
               o_ref_new_row.flg_home,
               o_ref_new_row.id_dep_clin_serv
          FROM (SELECT extractvalue(VALUE(referral_data), '/Referral/ReferralID') id_referral,
                       extractvalue(VALUE(referral_data), '/Referral/ExternalSystemID') id_external_sys,
                       extractvalue(VALUE(referral_data), '/Referral/Speciality/Code') id_speciality,
                       extractvalue(VALUE(referral_data), '/Referral/DestinationInstitution/Code') ext_code,
                       extractvalue(VALUE(referral_data), '/Referral/UrgencyLevel') flg_priority,
                       extractvalue(VALUE(referral_data), '/Referral/Home') flg_home,
                       extractvalue(VALUE(referral_data), '/Referral/ClinServ/Code') id_dep_clin_serv -- not filled yet
                  FROM TABLE(xmlsequence(extract(xmltype(i_ref_temp), '/Referral'))) referral_data) t_ref;
    
        g_error := '-------------- ReferralID=' || o_ref_new_row.id_external_request;
    
        -- getting patient sns
        g_error  := 'Call get_patient_sns / ID_REF=' || o_ref_new_row.id_external_request;
        g_retval := get_patient_sns(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient_data => i_pat_temp,
                                    o_sns          => l_sns,
                                    o_error        => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- getting patient id
        g_error  := 'Call get_patient_id / SNS=' || l_sns || ' ID_REF=' || o_ref_new_row.id_external_request;
        g_retval := get_patient_id(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_referral_data => i_ref_temp,
                                   i_sns           => l_sns,
                                   o_id_patient    => o_ref_new_row.id_patient,
                                   o_error         => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        --------------------
        -- getting workflow id
        g_error  := 'Call get_id_workflow / ID_EXT_SYS=' || o_ref_new_row.id_external_sys;
        g_retval := get_id_workflow(i_lang        => i_lang,
                                    i_prof        => i_prof,
                                    i_id_ext_sys  => o_ref_new_row.id_external_sys,
                                    o_id_workflow => o_ref_new_row.id_workflow,
                                    o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        g_error            := 'Call pk_api_ref_ws.get_flg_availability / WF=' || o_ref_new_row.id_workflow ||
                              ' ID_INST_ORIG=' || o_ref_new_row.id_inst_orig || ' ID_INST_DEST=' ||
                              o_ref_new_row.id_inst_dest || ' ID_EXT_SYS=' || o_ref_new_row.id_external_sys ||
                              ' ID_EXTERNAL_REQUEST=' || o_ref_new_row.id_external_request;
        l_flg_availability := pk_api_ref_ws.get_flg_availability(i_id_workflow  => o_ref_new_row.id_workflow,
                                                                 i_id_inst_orig => o_ref_new_row.id_inst_orig,
                                                                 i_id_inst_dest => o_ref_new_row.id_inst_dest);
    
        -- get old data from p1_external_request if is an update
        IF o_ref_new_row.id_external_request IS NOT NULL
        THEN
        
            --------------------
            -- updating referral...
        
            -- getting old data                
            g_error  := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || o_ref_new_row.id_external_request;
            g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_id_ref => o_ref_new_row.id_external_request,
                                                           o_rec    => o_ref_old_row,
                                                           o_error  => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            -- referral data
            g_error                                := 'Updating referral / setting referral data / ID_REF=' ||
                                                      o_ref_new_row.id_external_request;
            o_ref_new_row.dt_status_tstz           := o_ref_old_row.dt_status_tstz;
            o_ref_new_row.id_prof_requested        := o_ref_old_row.id_prof_requested;
            o_ref_new_row.flg_status               := o_ref_old_row.flg_status;
            o_ref_new_row.id_schedule              := o_ref_old_row.id_schedule;
            o_ref_new_row.num_req                  := o_ref_old_row.num_req;
            o_ref_new_row.flg_digital_doc          := o_ref_old_row.flg_digital_doc;
            o_ref_new_row.flg_mail                 := o_ref_old_row.flg_mail;
            o_ref_new_row.flg_paper_doc            := o_ref_old_row.flg_paper_doc;
            o_ref_new_row.id_inst_orig             := o_ref_old_row.id_inst_orig;
            o_ref_new_row.req_type                 := o_ref_old_row.req_type;
            o_ref_new_row.num_req                  := o_ref_old_row.num_req;
            o_ref_new_row.decision_urg_level       := o_ref_old_row.decision_urg_level;
            o_ref_new_row.id_prof_status           := o_ref_old_row.id_prof_status;
            o_ref_new_row.flg_import               := o_ref_old_row.flg_import;
            o_ref_new_row.dt_last_interaction_tstz := o_ref_old_row.dt_last_interaction_tstz;
            o_ref_new_row.dt_requested             := o_ref_old_row.dt_requested;
            o_ref_new_row.flg_interface            := o_ref_old_row.flg_interface;
            o_ref_new_row.id_episode               := o_ref_old_row.id_episode;
            o_ref_new_row.flg_forward_dcs          := o_ref_old_row.flg_forward_dcs;
            o_ref_new_row.id_prof_redirected       := o_ref_old_row.id_prof_redirected;
            o_ref_new_row.ext_reference            := o_ref_old_row.ext_reference;
            o_ref_new_row.id_external_sys          := o_ref_old_row.id_external_sys;
        
            IF o_ref_new_row.id_dep_clin_serv IS NULL
            THEN
                o_ref_new_row.id_dep_clin_serv := o_ref_old_row.id_dep_clin_serv;
            END IF;
        
            -- todo: check if this behaviour is valid for all external systems (is valid for FERTIS)
            -- id_inst_dest cannot be changed
        
            IF l_ext_code_dest IS NOT NULL
            THEN
            
                -- check if this ext_code is the same
                g_error  := 'Call get_inst / EXT_CODE=' || l_ext_code_dest;
                g_retval := get_inst(i_lang     => i_lang,
                                     i_ext_code => l_ext_code_dest,
                                     o_id_inst  => o_ref_new_row.id_inst_dest,
                                     o_error    => o_error);
            
                IF NOT g_retval
                THEN
                    RAISE g_exception_np;
                END IF;
            
                IF o_ref_new_row.id_inst_dest != o_ref_old_row.id_inst_dest
                THEN
                
                    g_error := 'ID_INST_DEST not valid / ID_INST_DEST=' || o_ref_new_row.id_inst_dest || ' EXT_CODE=' ||
                               l_ext_code_dest;
                    RAISE g_exception;
                
                END IF;
            
            ELSE
                g_error                    := 'o_ref_new_row.id_inst_dest=' || o_ref_new_row.id_inst_dest ||
                                              ' o_ref_old_row.id_inst_dest=' || o_ref_old_row.id_inst_dest;
                o_ref_new_row.id_inst_dest := o_ref_old_row.id_inst_dest;
            END IF;
        
            --------------------
            -- getting instituion dest
            -- returns the institution defined when referral was created
        
            IF o_ref_new_row.id_workflow = pk_ref_constant.g_wf_fertis
            THEN
                -- FERTIS is different because of internal FERTIS workflow            
                g_error := 'OPEN 1 c_spec_inst_fertis (' || o_ref_new_row.id_speciality || ', NULL, ' ||
                           o_ref_new_row.id_inst_dest || ',' || o_ref_new_row.id_external_sys || ');';
                OPEN c_spec_inst_fertis(o_ref_new_row.id_speciality,
                                        NULL,
                                        o_ref_new_row.id_inst_dest,
                                        o_ref_new_row.id_external_sys,
                                        o_ref_new_row.id_dep_clin_serv);
            
                FETCH c_spec_inst_fertis
                    INTO o_ref_new_row.id_inst_dest, o_ref_new_row.id_dep_clin_serv; -- in case dep_clin_serv is null, gets the default
                g_found := c_spec_inst_fertis%FOUND;
                CLOSE c_spec_inst_fertis;
            
            ELSE
                -- other workflows
                g_error := 'OPEN 1 c_spec_inst (' || o_ref_new_row.id_speciality || ', NULL, ' ||
                           o_ref_new_row.id_inst_dest || ',' || o_ref_new_row.id_external_sys || ',' ||
                           l_flg_availability || ');';
                OPEN c_spec_inst(o_ref_new_row.id_speciality,
                                 NULL,
                                 o_ref_new_row.id_inst_dest,
                                 o_ref_new_row.id_external_sys,
                                 l_flg_availability,
                                 o_ref_new_row.id_dep_clin_serv);
                FETCH c_spec_inst
                    INTO o_ref_new_row.id_inst_dest, o_ref_new_row.id_dep_clin_serv; -- in case dep_clin_serv is null, gets the default
                g_found := c_spec_inst%FOUND;
                CLOSE c_spec_inst;
            
            END IF;
        
            IF NOT g_found
            THEN
                -- do not show any institution... return error
                g_error := 'ID_INST_DEST not available / ID_SPEC=' || o_ref_new_row.id_speciality || ' EXT_CODE=' ||
                           l_ext_code_dest || ' ID_EXTERNAL_SYS=' || o_ref_new_row.id_external_sys ||
                           ' FLG_AVAILABILITY=' || l_flg_availability || ' ID_DEP_CLIN_SERV=' ||
                           o_ref_new_row.id_dep_clin_serv || ' ID_WF=' || o_ref_new_row.id_workflow || ' ID_INST_DEST=' ||
                           o_ref_new_row.id_inst_dest;
                RAISE g_exception;
            END IF;
        
        ELSE
        
            --------------------
            -- creating referral...
        
            IF l_ext_code_dest IS NULL
            THEN
                -- dest institution cannot be null... return error
                g_error := 'ID_INST_DEST cannot be null';
                RAISE g_exception;
            END IF;
        
            -- referral data
            g_error                                := 'Creating referral / setting referral data';
            o_ref_new_row.dt_status_tstz           := g_sysdate_tstz;
            o_ref_new_row.id_prof_requested        := i_prof.id;
            o_ref_new_row.flg_status               := pk_ref_constant.g_p1_status_o;
            o_ref_new_row.id_inst_orig             := i_prof.institution;
            o_ref_new_row.dt_last_interaction_tstz := g_sysdate_tstz;
        
            --------------------
            -- getting instituion dest
            -- Is there any available institution for this speciality? 
            -- trying l_ext_code_dest... if is an invalid instituion (for referral), show all dest institutions available
            IF o_ref_new_row.id_workflow = pk_ref_constant.g_wf_fertis
            THEN
                -- FERTIS is different because of internal FERTIS workflow            
                g_error := 'OPEN 2 c_spec_inst_fertis (' || o_ref_new_row.id_speciality || ',' || l_ext_code_dest ||
                           ', NULL,' || o_ref_new_row.id_external_sys || ');';
                OPEN c_spec_inst_fertis(o_ref_new_row.id_speciality,
                                        l_ext_code_dest,
                                        NULL,
                                        o_ref_new_row.id_external_sys,
                                        o_ref_new_row.id_dep_clin_serv);
            
                FETCH c_spec_inst_fertis
                    INTO o_ref_new_row.id_inst_dest, o_ref_new_row.id_dep_clin_serv; -- in case dep_clin_serv is null, gets the default
                g_found := c_spec_inst_fertis%FOUND;
                CLOSE c_spec_inst_fertis;
            
            ELSE
                -- other workflows
                g_error := 'OPEN 2 c_spec_inst (' || o_ref_new_row.id_speciality || ',' || l_ext_code_dest || ', NULL,' ||
                           o_ref_new_row.id_external_sys || ',' || l_flg_availability || ');';
                OPEN c_spec_inst(o_ref_new_row.id_speciality,
                                 l_ext_code_dest,
                                 NULL,
                                 o_ref_new_row.id_external_sys,
                                 l_flg_availability,
                                 o_ref_new_row.id_dep_clin_serv);
                FETCH c_spec_inst
                    INTO o_ref_new_row.id_inst_dest, o_ref_new_row.id_dep_clin_serv; -- in case dep_clin_serv is null, gets the default
                g_found := c_spec_inst%FOUND;
                CLOSE c_spec_inst;
            
            END IF;
        
            IF NOT g_found
            THEN
            
                -- do not show any institution... return error
                g_error := 'ID_INST_DEST not available / ID_SPEC=' || o_ref_new_row.id_speciality || ' EXT_CODE=' ||
                           l_ext_code_dest || ' ID_EXTERNAL_SYS=' || o_ref_new_row.id_external_sys ||
                           ' FLG_AVAILABILITY=' || l_flg_availability || ' ID_DEP_CLIN_SERV=' ||
                           o_ref_new_row.id_dep_clin_serv || ' ID_WF=' || o_ref_new_row.id_workflow || ' ID_INST_DEST=' ||
                           o_ref_new_row.id_inst_dest;
                RAISE g_exception;
            END IF;
        
        END IF;
    
        g_error                := 'FLG_TYPE=C';
        o_ref_new_row.flg_type := pk_ref_constant.g_p1_type_c;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'FILL_REFERRAL_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END fill_referral_data;

    /**
    * Converts year, month and day sting into normalized date string
    *
    * @param   y year
    * @param   m month
    * @param   d day   
    *
    * @RETURN  date string, NULL in case of error
    * @author  Joao Sa
    * @version 1.0
    * @since   14-12-2007
    */
    FUNCTION get_date_str
    (
        y VARCHAR2,
        m VARCHAR2,
        d VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        -- JB 14/10/2009
        g_error := 'Init get_date_str / y=' || y || ' m=' || m || ' d=' || d;
        pk_alertlog.log_debug(g_error);
    
        IF y IS NULL
           OR m IS NULL
           OR d IS NULL
        THEN
            RETURN NULL;
        ELSE
            g_error := 'Return';
            RETURN to_char(y) || lpad(to_char(m), 2, '0') || lpad(to_char(d), 2, '0') || '000000';
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_date_str;

    /**
    * Transform history data into a string    
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_text            Text
    * @param   i_code_desc       Code description
    * @param   i_notes           Notes
    * @param   i_dt_begin        Begin date
    * @param   i_dt_end          End date
    * @param   i_parent          Parent    
    *
    * @RETURN  VARCHAR2 String
    * @author  Ana Monteiro
    * @version 2.5
    * @since   21-04-2010
    */
    FUNCTION history_list_to_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_notes     IN VARCHAR2,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_parent    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text     VARCHAR2(1000 CHAR);
        l_text_aux VARCHAR2(200 CHAR);
        l_dt_aux   VARCHAR2(50 CHAR);
    BEGIN
    
        g_error := 'Init history_list_to_text / DT_BEGIN=' || i_dt_begin || ' DT_END=' || i_dt_end;
        pk_alertlog.log_debug(g_error);
        g_error := 'TEXT=' || i_text;
        pk_alertlog.log_debug(g_error);
        g_error := 'CODE_DESC=' || i_code_desc;
        pk_alertlog.log_debug(g_error);
        g_error := 'NOTES=' || i_notes;
        pk_alertlog.log_debug(g_error);
        g_error := 'PARENT=' || i_parent;
        pk_alertlog.log_debug(g_error);
    
        l_text := i_text;
    
        g_error := 'TEXT 1';
        IF l_text IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text || chr(10) || chr(10)), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'TEXT 2';
                l_text  := l_text || chr(10) || chr(10);
            END IF;
        END IF;
    
        g_error := 'PARENT 1';
        IF i_parent IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(chr(10) || i_parent), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'PARENT 2';
                l_text  := l_text || i_parent || ': ';
            END IF;
        END IF;
    
        g_error := 'CODE_DESC 1';
        IF to_number(nvl(length(l_text), 0) + nvl(length(i_code_desc), 0)) <= pk_ref_constant.g_max_text_field_size
        THEN
            g_error := 'CODE_DESC 2';
            l_text  := l_text || i_code_desc;
        END IF;
    
        g_error := 'DT_BEGIN 1';
        IF i_dt_begin IS NOT NULL
        THEN
            g_error  := 'DT_BEGIN 2';
            l_dt_aux := pk_date_utils.dt_chr_tsz(i_lang,
                                                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL),
                                                 i_prof);
        
            g_error    := 'Call pk_message.get_message / P1_AUTO_COMPLETE_T001';
            l_text_aux := '; ' || pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => 'P1_AUTO_COMPLETE_T001');
        
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'DT_BEGIN 3';
                l_text  := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        g_error := 'DT_END 1';
        IF i_dt_end IS NOT NULL
        THEN
        
            g_error  := 'DT_END 2';
            l_dt_aux := pk_date_utils.dt_chr_tsz(i_lang,
                                                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL),
                                                 i_prof);
        
            g_error    := 'Call pk_message.get_message / P1_AUTO_COMPLETE_T002';
            l_text_aux := '; ' || pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => 'P1_AUTO_COMPLETE_T002');
        
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'DT_END 3';
                l_text  := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        g_error := 'NOTES 1';
        IF i_notes IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + nvl(length(chr(10) || i_notes), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'NOTES 2';
                l_text  := l_text || chr(10) || i_notes;
            END IF;
        END IF;
    
        g_error := 'Return';
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END history_list_to_text;

    /**
    * Transform diagnostic tests data into a string   
    *
    * @param   i_lang            Language identifier
    * @param   i_prof            Professional, institution and software ids
    * @param   i_text            Text
    * @param   i_code_desc       Code description
    * @param   i_result          Result tests
    * @param   i_dt              Tests date    
    *
    * @RETURN  VARCHAR2 String
    * @author  Ana Monteiro
    * @version 2.5
    * @since   21-04-2010
    */
    FUNCTION exam_list_to_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_text      IN VARCHAR2,
        i_code_desc IN VARCHAR2,
        i_result    IN VARCHAR2,
        i_dt        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_text     VARCHAR2(1000 CHAR);
        l_text_aux VARCHAR2(200 CHAR);
        l_dt_aux   VARCHAR2(50 CHAR);
    BEGIN
    
        g_error := 'Init exam_list_to_text / DT=' || i_dt;
        pk_alertlog.log_debug(g_error);
        g_error := 'TEXT=' || i_text;
        pk_alertlog.log_debug(g_error);
        g_error := 'CODE_DESC=' || i_code_desc;
        pk_alertlog.log_debug(g_error);
        g_error := 'RESULT=' || i_result;
        pk_alertlog.log_debug(g_error);
    
        l_text := i_text;
    
        g_error := 'TEXT 1';
        IF l_text IS NOT NULL
        THEN
            IF to_number(nvl(length(l_text), 0) + length(chr(10) || chr(10))) <= pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'TEXT 2';
                l_text  := l_text || chr(10) || chr(10);
            END IF;
        END IF;
    
        g_error := 'CODE 1';
        IF (to_number(nvl(length(l_text), 0) + nvl(length(i_code_desc), 0))) <= pk_ref_constant.g_max_text_field_size
        THEN
            g_error := 'CODE 2';
            l_text  := l_text || i_code_desc;
        END IF;
    
        g_error := 'RESULT 1';
        IF i_result IS NOT NULL
        THEN
            g_error    := 'Call pk_message.get_message / P1_AUTO_COMPLETE_T003';
            l_text_aux := '; ' || pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => 'P1_AUTO_COMPLETE_T003');
        
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || i_result), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'RESULT 2';
                l_text  := l_text || l_text_aux || i_result;
            END IF;
        END IF;
    
        g_error := 'DT 1';
        IF i_dt IS NOT NULL
        THEN
        
            g_error  := 'DT 2';
            l_dt_aux := pk_date_utils.dt_chr_tsz(i_lang,
                                                 pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                 i_prof);
        
            g_error    := 'Call pk_message.get_message  / P1_AUTO_COMPLETE_T004';
            l_text_aux := '; ' || pk_message.get_message(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_code_mess => 'P1_AUTO_COMPLETE_T004');
        
            IF to_number(nvl(length(l_text), 0) + nvl(length(l_text_aux || l_dt_aux), 0)) <=
               pk_ref_constant.g_max_text_field_size
            THEN
                g_error := 'DT 3';
                l_text  := l_text || l_text_aux || l_dt_aux;
            END IF;
        END IF;
    
        g_error := 'Return';
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' / ' || SQLERRM;
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END exam_list_to_text;

    /**
    * Returns patient data from temporary table REF_EXT_XML_DATA.
    * This data is stored on XML format. 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_id_session     Session identifier
    * @param   o_data           Patient data
    * @param   o_health_plan    Patient health plans
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-04-2010
    */
    FUNCTION get_patient_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_session  IN ref_ext_session.id_session%TYPE,
        o_data        OUT pk_types.cursor_type,
        o_health_plan OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient_temp_data  ref_ext_xml_data.patient_data%TYPE;
        l_referral_temp_data ref_ext_xml_data.referral_data%TYPE;
        l_ref_url            ref_ext_session.ref_url%TYPE;
        l_ext_code           ref_ext_session.ext_code%TYPE;
        l_num_order          ref_ext_session.num_order%TYPE;
        l_id_patient         patient.id_patient%TYPE;
        l_sns                pat_health_plan.num_health_plan%TYPE;
        l_doc_type_id        doc_type.id_doc_type%TYPE;
    
        CURSOR c_ext(x_id_session IN ref_ext_xml_data.id_session%TYPE) IS
            SELECT xml.patient_data, xml.referral_data
              FROM ref_ext_xml_data xml
             WHERE xml.id_session = x_id_session
             ORDER BY dt_inserted DESC; -- if there is another session (outdated), returns the latest one    
    BEGIN
    
        g_error := 'Init get_patient_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Call pk_sysconfig.get_config (' || pk_ref_constant.g_sc_bi_doc_type || ')';
        pk_alertlog.log_debug(g_error);
        l_doc_type_id := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_sc_bi_doc_type, i_prof => i_prof);
    
        -- checks if session is active and returns session data
        g_error := 'Call get_session_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_session_data(i_lang       => i_lang,
                                     i_session_id => i_id_session,
                                     o_ref_url    => l_ref_url,
                                     o_ext_code   => l_ext_code,
                                     o_num_order  => l_num_order,
                                     o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- getting patient temporary data
        g_error := 'OPEN c_ext / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        OPEN c_ext(i_id_session);
        FETCH c_ext
            INTO l_patient_temp_data, l_referral_temp_data;
        g_found := c_ext%FOUND;
        CLOSE c_ext;
    
        IF NOT g_found
        THEN
            g_error := 'Patient Data not found';
            RAISE g_exception;
        END IF;
    
        IF l_patient_temp_data IS NULL
        THEN
            g_error := 'Patient Data IS NULL';
            RAISE g_exception;
        END IF;
    
        -- getting patient sns
        g_error := 'Call get_patient_sns';
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_patient_sns(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient_data => l_patient_temp_data,
                                    o_sns          => l_sns,
                                    o_error        => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- getting patient id
        g_error := 'Call get_patient_id / SNS=' || l_sns;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_patient_id(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_referral_data => l_referral_temp_data,
                                   i_sns           => l_sns,
                                   o_id_patient    => l_id_patient,
                                   o_error         => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        -- getting patient data    
        g_error := 'OPEN o_data';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT l_id_patient id_patient,
                   pat.name,
                   pat.gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', pat.gender, i_lang) gender_desc,
                   get_date_str(pat.birth_date_year, pat.birth_date_month, pat.birth_date_day) dt_birth,
                   decode(pat.isencao, -1, NULL, pat.isencao) isencao,
                   pk_translation.get_translation(i_lang, 'ISENCAO.CODE_ISENCAO.' || pat.isencao) isencao_desc,
                   decode(pat.recm, -1, NULL, pat.recm) recm,
                   pk_translation.get_translation(i_lang, 'RECM.CODE_RECM.' || pat.recm) recm_desc,
                   pat.num_main_contact num_main_contact,
                   pat.address address,
                   pat.zip_code zip_code,
                   pat.location location,
                   pat.district district,
                   c_add.id_country country_address,
                   pk_translation.get_translation(i_lang, c_add.code_country) country_address_desc,
                   c_nat.id_country country_nation,
                   pk_translation.get_translation(i_lang, c_nat.code_country) country_nation_desc,
                   c_bplace.id_country country_bplace,
                   pk_translation.get_translation(i_lang, c_bplace.code_country) country_bplace_desc,
                   pat.marital_status marital_status,
                   pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', pat.marital_status, i_lang) marital_status_desc,
                   pat.scholarship scholarship,
                   pk_translation.get_translation(i_lang, 'SCHOLARSHIP.CODE_SCHOLARSHIP.' || pat.scholarship) scholarship_desc,
                   pat.occupation occupation,
                   pk_translation.get_translation(i_lang, 'OCCUPATION.CODE_OCCUPATION.' || pat.occupation) occupation_desc, -- ACM, 2010-05-25: ALERT-100182
                   pat.job_status job_status,
                   pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', pat.job_status, i_lang) job_status_desc,
                   pat.father_name,
                   pat.mother_name,
                   pat.sns_number,
                   pat.num_doc_number -- BI
              FROM (SELECT extractvalue(VALUE(patient_data), '/Patient/Identification/Name') name,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/Gender') gender,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/BirthDate/Year') birth_date_year,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/BirthDate/Month') birth_date_month,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/BirthDate/Day') birth_date_day,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/Nationality') alpha2_country_nation,
                           extractvalue(VALUE(patient_data), '/Patient/Benefits/Exemption/ExemptionID') isencao,
                           extractvalue(VALUE(patient_data), '/Patient/Benefits/Recm/RecmID') recm,
                           extractvalue(VALUE(patient_data), '/Patient/Address/Address') address,
                           extractvalue(VALUE(patient_data), '/Patient/Address/Location') location,
                           extractvalue(VALUE(patient_data), '/Patient/Address/ZipCode') zip_code,
                           extractvalue(VALUE(patient_data), '/Patient/Address/District') district,
                           extractvalue(VALUE(patient_data), '/Patient/Address/AddressCountry') alpha2_country_address,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/BirthPlace/Country') alpha2_country_bplace,
                           -- num_main_contact
                           (SELECT t.phone_num
                              FROM (SELECT extractvalue(VALUE(phone), '/Phone/Type') phone_type,
                                           extractvalue(VALUE(phone), '/Phone/Number') phone_num
                                      FROM TABLE(xmlsequence(extract(xmltype(l_patient_temp_data),
                                                                     '/Patient/Contacts/Phone'))) phone) t
                             WHERE phone_type = pk_ref_constant.g_pat_phone_type_main) num_main_contact,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/MaritalStatus') marital_status,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/ProfessionSituation/Scholarship') scholarship,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/ProfessionSituation/Profession') occupation,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/ProfessionSituation/Situation') job_status,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/Membership/FatherName') father_name,
                           extractvalue(VALUE(patient_data), '/Patient/Identification/Membership/MotherName') mother_name,
                           l_sns sns_number,
                           -- BI                          
                           (SELECT t2.doc_num
                              FROM (SELECT extractvalue(VALUE(doc), '/Documents/Type') doc_type,
                                           extractvalue(VALUE(doc), '/Documents/Number') doc_num
                                      FROM TABLE(xmlsequence(extract(xmltype(l_patient_temp_data),
                                                                     '/Patient/Identification/Documents'))) doc) t2
                             WHERE doc_type = l_doc_type_id) num_doc_number
                      FROM TABLE(xmlsequence(extract(xmltype(l_patient_temp_data), '/Patient'))) patient_data) pat
              LEFT JOIN country c_add
                ON (pat.alpha2_country_address = c_add.alpha2_code AND c_add.flg_available = pk_ref_constant.g_yes)
              LEFT JOIN country c_nat
                ON (pat.alpha2_country_nation = c_nat.alpha2_code AND c_nat.flg_available = pk_ref_constant.g_yes)
              LEFT JOIN country c_bplace
                ON (pat.alpha2_country_bplace = c_bplace.alpha2_code AND c_bplace.flg_available = pk_ref_constant.g_yes);
    
        g_error := 'OPEN o_health_plan';
        pk_alertlog.log_debug(g_error);
        OPEN o_health_plan FOR
            SELECT extractvalue(VALUE(pat_hplan), '/HealthPlans/Code') health_plan_code,
                   extractvalue(VALUE(pat_hplan), '/HealthPlans/Number') num_health_plan
              FROM TABLE(xmlsequence(extract(xmltype(l_patient_temp_data), '/Patient/HealthPlans'))) pat_hplan;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            IF c_ext%ISOPEN
            THEN
                CLOSE c_ext;
            END IF;
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_health_plan);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PATIENT_DATA',
                                              o_error    => o_error);
            IF c_ext%ISOPEN
            THEN
                CLOSE c_ext;
            END IF;
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_health_plan);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_patient_data;

    /**
    * Returns referral data (must be synchronized with function PK_REF_CORE.get_referral) 
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional, institution and software ids
    * @param   i_id_session                   Session identifier
    * @param   o_detail                       Referral general data
    * @param   o_text                         Referral detail data
    * @param   o_problem                      Patient problems to be addressed
    * @param   o_diagnosis                    Referral diagnosis
    * @param   o_mcdt                         Referral MCDT details
    * @param   o_needs                        Referral additional needs: Sent to registrar
    * @param   o_info                         Referral additional needs: Additional information    
    * @param   o_notes_status                 Referral tracking status    
    * @param   o_notes_status_det             Referral tracking status details
    * @param   o_answer                       Referral answer   
    * @param   o_can_cancel                   Flag indicating if referral can be canceled by the professional
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   20-04-2010
    */
    FUNCTION get_referral_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_session       IN ref_ext_session.id_session%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_text             OUT pk_types.cursor_type,
        o_problem          OUT pk_types.cursor_type,
        o_diagnosis        OUT pk_types.cursor_type,
        o_mcdt             OUT pk_types.cursor_type,
        o_needs            OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_notes_status     OUT pk_types.cursor_type,
        o_notes_status_det OUT pk_types.cursor_type,
        o_answer           OUT pk_types.cursor_type,
        o_can_cancel       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_inst(x_id_inst IN institution.id_institution%TYPE) IS
            SELECT abbreviation, code_institution
              FROM institution i
             WHERE i.id_institution = x_id_inst;
    
        CURSOR c_ref(x_id_session IN ref_ext_xml_data.id_session%TYPE) IS
            SELECT xml.referral_data, xml.patient_data
              FROM ref_ext_xml_data xml
             WHERE xml.id_session = x_id_session
             ORDER BY dt_inserted DESC; -- if there is another session (outdated), returns the latest one            
    
        l_referral_temp_data ref_ext_xml_data.referral_data%TYPE;
        l_patient_temp_data  ref_ext_xml_data.patient_data%TYPE;
        l_ref_old_data       p1_external_request%ROWTYPE;
        l_ref_new_data       p1_external_request%ROWTYPE;
    
        l_prof_name professional.name%TYPE;
        l_prof_spec VARCHAR2(500 CHAR);
    
        l_ref_url   ref_ext_session.ref_url%TYPE;
        l_ext_code  ref_ext_session.ext_code%TYPE;
        l_num_order ref_ext_session.num_order%TYPE;
    
        -- status info
        l_my_data            t_rec_prof_data; -- professional data
        l_status_icon        VARCHAR2(500 CHAR);
        l_wf_status_info     table_varchar;
        l_status_info_row    t_rec_wf_status_info := t_rec_wf_status_info();
        l_wf_transition_info table_varchar;
        l_id_cat             category.id_category%TYPE;
    
        -- referral data
        l_id_clinical_service  dep_clin_serv.id_clinical_service%TYPE;
        l_id_department        dep_clin_serv.id_department%TYPE;
        l_sc_other_institution sys_config.desc_sys_config%TYPE;
        l_inst_abbrev          institution.abbreviation%TYPE;
        l_inst_code            institution.code_institution%TYPE;
        l_dt_schedule          schedule.dt_begin_tstz%TYPE;
        l_dt_probl_begin_flash VARCHAR2(10 CHAR);
        l_dt_probl_begin_str   VARCHAR2(100 CHAR);
    
        l_diag_type     diagnosis.flg_type%TYPE;
        l_diag_type_tab table_varchar;
    
        -- sys_messages
        l_code_msg_arr     table_varchar;
        l_desc_message_ibt pk_ref_constant.ibt_varchar_varchar;
    
    BEGIN
        ----------------------
        -- INIT
        ----------------------
        g_error := 'Init get_referral_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- CONFIG
        ----------------------
        g_error := 'Call pk_sysconfig.get_config (' || pk_ref_constant.g_sc_other_institution || ')';
        pk_alertlog.log_debug(g_error);
        l_sc_other_institution := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_sc_other_institution,
                                                          i_prof    => i_prof);
    
        g_error     := 'Call pk_sysconfig.get_config (' || pk_ref_constant.g_ref_inst_diag_list || ')';
        l_diag_type := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_inst_diag_list, i_prof => i_prof);
    
        --for now there is only one diagnostic allowable (configured in SYS_CONFIG)
        g_error         := 'diag allowable';
        l_diag_type_tab := table_varchar(l_diag_type);
    
        ------------------------------------
        -- getting sys_messages
        ------------------------------------    
        g_error        := 'Fill l_code_msg_arr';
        l_code_msg_arr := table_varchar(pk_ref_constant.g_sm_doctor_req_t018,
                                        pk_ref_constant.g_sm_doctor_req_t019,
                                        pk_ref_constant.g_sm_doctor_req_t020,
                                        pk_ref_constant.g_sm_doctor_req_t021,
                                        pk_ref_constant.g_sm_doctor_req_t038,
                                        pk_ref_constant.g_sm_doctor_req_t039,
                                        pk_ref_constant.g_sm_doctor_req_t041,
                                        pk_ref_constant.g_sm_doctor_req_t042,
                                        pk_ref_constant.g_sm_doctor_req_t045,
                                        pk_ref_constant.g_sm_doctor_req_t046,
                                        pk_ref_constant.g_sm_doctor_req_t055);
    
        g_error := 'Call pk_ref_utils.get_message_ibt / l_code_msg_arr.COUNT=' || l_code_msg_arr.count;
        pk_alertlog.log_debug(g_error);
        g_retval := pk_ref_utils.get_message_ibt(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_code_msg_arr  => l_code_msg_arr,
                                                 io_desc_msg_ibt => l_desc_message_ibt,
                                                 o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------            
    
        --------------------
        -- checks if session is active and returns session data
        g_error  := 'Call get_session_data / ID_SESSION=' || i_id_session;
        g_retval := get_session_data(i_lang       => i_lang,
                                     i_session_id => i_id_session,
                                     o_ref_url    => l_ref_url,
                                     o_ext_code   => l_ext_code,
                                     o_num_order  => l_num_order,
                                     o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------------
        -- getting professional name and signature
        g_error     := 'Get prof name';
        l_prof_name := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                        i_prof    => i_prof, -- current professional
                                                        i_prof_id => i_prof.id -- professional inserting/updating referral
                                                        );
    
        g_error     := 'Get prof spec';
        l_prof_spec := pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_prof_id   => i_prof.id, -- professional inserting/updating referral
                                                        i_prof_inst => i_prof.institution);
    
        g_error  := 'Call pk_prof_utils.get_id_category / ID_PROF=' || i_prof.id;
        l_id_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        --------------------
        -- getting referral temporary data
        g_error := 'OPEN c_ref / ID_SESSION=' || i_id_session;
        OPEN c_ref(i_id_session);
        FETCH c_ref
            INTO l_referral_temp_data, l_patient_temp_data;
        g_found := c_ref%FOUND;
        CLOSE c_ref;
    
        IF NOT g_found
        THEN
            g_error := 'Referral data not found';
            RAISE g_exception;
        END IF;
    
        IF l_referral_temp_data IS NULL
        THEN
            g_error := 'Referral data IS NULL';
            RAISE g_exception;
        END IF;
    
        --------------------
        -- getting referral new data (imported by external system) and old data (present in alert db)
        g_error  := 'Call fill_referral_data / ID_SESSION=' || i_id_session;
        g_retval := fill_referral_data(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_pat_temp    => l_patient_temp_data,
                                       i_ref_temp    => l_referral_temp_data,
                                       o_ref_old_row => l_ref_old_data,
                                       o_ref_new_row => l_ref_new_data,
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------------
        -- getting remaining referral new data
    
        -- getting oldest problem begin date
        g_error := 'Getting problem begin date / ID_SESSION=' || i_id_session;
        BEGIN
            SELECT --dt_problem_begin, 
             year_begin, month_begin, day_begin
              INTO --l_ref_new_data.dt_probl_begin_tstz, -- ALERT-194568
                   l_ref_new_data.year_begin,
                   l_ref_new_data.month_begin,
                   l_ref_new_data.day_begin
              FROM (SELECT --pk_date_utils.get_string_tstz(i_lang,
                    --                              i_prof,
                    --                              get_date_str(t_ref.prob_year, t_ref.prob_month, t_ref.prob_day),
                    --                              NULL) dt_problem_begin,
                     to_number(t_ref.prob_year) year_begin,
                     to_number(t_ref.prob_month) month_begin,
                     to_number(t_ref.prob_day) day_begin
                      FROM (SELECT extractvalue(VALUE(referral_data), 'DiagnosisInformation/Type') diag_type,
                                   extractvalue(VALUE(referral_data), 'DiagnosisInformation/BeginDate/Year') prob_year,
                                   extractvalue(VALUE(referral_data), 'DiagnosisInformation/BeginDate/Month') prob_month,
                                   extractvalue(VALUE(referral_data), 'DiagnosisInformation/BeginDate/Day') prob_day
                              FROM TABLE(xmlsequence(extract(xmltype(l_referral_temp_data),
                                                             '/Referral/ClinicalInformation/DiagnosisInformation'))) referral_data) t_ref
                     WHERE diag_type = pk_ref_constant.g_exr_diag_type_p -- Problems only
                     ORDER BY year_begin, month_begin, day_begin)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- get old data from p1_external_request if is an update
        IF l_ref_new_data.id_external_request IS NOT NULL
        THEN
        
            --------------------
            -- updating referral...
        
            -- data will be set only when is an update
            g_error := 'Updating referral ID=' || l_ref_new_data.id_external_request;
            BEGIN
                g_error := 'SELECT dep_clin_serv=' || l_ref_new_data.id_dep_clin_serv;
                pk_alertlog.log_debug(g_error);
            
                SELECT dcs.id_clinical_service, dcs.id_department
                  INTO l_id_clinical_service, l_id_department
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_dep_clin_serv = l_ref_new_data.id_dep_clin_serv;
            
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := g_error || ' / NOT FOUND';
                    pk_alertlog.log_warn(g_error);
            END;
        
            -- getting DT_SCHEDULE (if any)
            g_error  := 'Call pk_ref_utils.get_ref_schedule_date / ID_REF=' || l_ref_new_data.id_external_request;
            g_retval := pk_ref_utils.get_ref_schedule_date(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_id_ref      => l_ref_new_data.id_external_request,
                                                           o_dt_schedule => l_dt_schedule,
                                                           o_error       => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
        ELSE
        
            --------------------
            -- creating referral...
        
            -- nothing to be done
            g_error := 'Creating new referral';
            pk_alertlog.log_debug(g_error);
        
        END IF;
    
        --------------------
        -- getting instituion dest info
        IF l_ref_new_data.id_inst_dest IS NOT NULL
        THEN
        
            g_error := 'ID_INST_DEST=' || l_ref_new_data.id_inst_dest;
            OPEN c_inst(l_ref_new_data.id_inst_dest);
            FETCH c_inst
                INTO l_inst_abbrev, l_inst_code;
            CLOSE c_inst;
        
        ELSE
            g_error       := 'ID_INST_DEST=NULL';
            l_inst_abbrev := NULL;
            l_inst_code   := NULL;
        END IF;
    
        --------------------
        -- getting status info
    
        -- getting professional data
        g_error  := 'Calling pk_ref_core.get_prof_data / ID_PROF=' || i_prof.id;
        g_retval := pk_ref_core.get_prof_data(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_dcs       => NULL,
                                              o_prof_data => l_my_data,
                                              o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        -- getting status info from workflow framework
        g_error          := 'Calling pk_ref_core.init_param_tab / ID_REF=' || l_ref_new_data.id_external_request;
        l_wf_status_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_ext_req            => l_ref_new_data.id_external_request,
                                                       i_id_patient         => l_ref_new_data.id_patient,
                                                       i_id_inst_orig       => l_ref_new_data.id_inst_orig,
                                                       i_id_inst_dest       => l_ref_new_data.id_inst_dest,
                                                       i_id_dep_clin_serv   => l_ref_new_data.id_dep_clin_serv,
                                                       i_id_speciality      => l_ref_new_data.id_speciality,
                                                       i_flg_type           => l_ref_new_data.flg_type,
                                                       i_decision_urg_level => l_ref_new_data.decision_urg_level,
                                                       i_id_prof_requested  => l_ref_new_data.id_prof_requested,
                                                       i_id_prof_redirected => l_ref_new_data.id_prof_redirected,
                                                       i_id_prof_status     => l_ref_new_data.id_prof_status,
                                                       i_external_sys       => l_ref_new_data.id_external_sys,
                                                       i_location           => pk_ref_constant.g_location_detail,
                                                       i_flg_status         => l_ref_new_data.flg_status);
    
        g_error  := 'Calling pk_workflow.get_status_info / WF=' || l_ref_new_data.id_workflow || ' FLG_STATUS=' ||
                    l_ref_new_data.flg_status || ' ID_CAT=' || l_id_cat || ' ID_PROFILE_TEMPLATE=' ||
                    l_my_data.id_profile_template || ' ID_FUNCTIONALITY=' || l_my_data.id_functionality;
        g_retval := pk_workflow.get_status_info(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_workflow         => l_ref_new_data.id_workflow,
                                                i_id_status           => pk_ref_status.convert_status_n(i_status => l_ref_new_data.flg_status),
                                                i_id_category         => l_id_cat,
                                                i_id_profile_template => l_my_data.id_profile_template,
                                                i_id_functionality    => l_my_data.id_functionality,
                                                i_param               => l_wf_status_info,
                                                o_status_info         => l_status_info_row,
                                                o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'STATUS_ICON=' || l_status_icon;
        pk_alertlog.log_debug(g_error);
    
        IF l_status_info_row.icon IS NOT NULL
        THEN
            l_status_icon := lpad(l_status_info_row.rank, 6, '0') || l_status_info_row.icon;
        END IF;
    
        --------------------
        -- checking if referral can be canceled
        g_error              := 'Calling pk_ref_core.init_param_tab / ID_REF=' || l_ref_new_data.id_external_request;
        l_wf_transition_info := pk_ref_core.init_param_tab(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_ext_req            => l_ref_new_data.id_external_request,
                                                           i_id_patient         => l_ref_new_data.id_patient,
                                                           i_id_inst_orig       => l_ref_new_data.id_inst_orig,
                                                           i_id_inst_dest       => l_ref_new_data.id_inst_dest,
                                                           i_id_dep_clin_serv   => l_ref_new_data.id_dep_clin_serv,
                                                           i_id_speciality      => l_ref_new_data.id_speciality,
                                                           i_flg_type           => l_ref_new_data.flg_type,
                                                           i_decision_urg_level => l_ref_new_data.decision_urg_level,
                                                           i_id_prof_requested  => l_ref_new_data.id_prof_requested,
                                                           i_id_prof_redirected => l_ref_new_data.id_prof_redirected,
                                                           i_id_prof_status     => l_ref_new_data.id_prof_status,
                                                           i_external_sys       => l_ref_new_data.id_external_sys,
                                                           i_flg_status         => l_ref_new_data.flg_status);
    
        g_error  := 'Calling pk_workflow.check_transition / FLG_STATUS_BEGIN=' || l_ref_new_data.flg_status ||
                    ' FLG_STATUS_END=' || pk_ref_constant.g_p1_status_c;
        g_retval := pk_workflow.check_transition(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_workflow         => l_ref_new_data.id_workflow,
                                                 i_id_status_begin     => pk_ref_status.convert_status_n(i_status => l_ref_new_data.flg_status),
                                                 i_id_status_end       => pk_ref_status.convert_status_n(pk_ref_constant.g_p1_status_c),
                                                 i_id_workflow_action  => pk_ref_constant.get_action_id(pk_ref_constant.g_ref_action_c),
                                                 i_id_category         => l_id_cat,
                                                 i_id_profile_template => l_my_data.id_profile_template,
                                                 i_id_functionality    => l_my_data.id_functionality,
                                                 i_param               => l_wf_transition_info,
                                                 o_flg_available       => o_can_cancel,
                                                 o_error               => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception;
        END IF;
    
        g_error                := 'Call pk_ref_utils.parse_dt_str_flash / ID_REF=' ||
                                  l_ref_new_data.id_external_request || ' YEAR_BEGIN=' || l_ref_new_data.year_begin ||
                                  ' MONTH_BEGIN=' || l_ref_new_data.month_begin || ' DAY_BEGIN=' ||
                                  l_ref_new_data.day_begin;
        l_dt_probl_begin_flash := pk_ref_utils.parse_dt_str_flash(i_lang  => i_lang,
                                                                  i_prof  => i_prof,
                                                                  i_year  => l_ref_new_data.year_begin,
                                                                  i_month => l_ref_new_data.month_begin,
                                                                  i_day   => l_ref_new_data.day_begin);
    
        l_dt_probl_begin_str := pk_ref_utils.parse_dt_str_app(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_year  => l_ref_new_data.year_begin,
                                                              i_month => l_ref_new_data.month_begin,
                                                              i_day   => l_ref_new_data.day_begin);
    
        --------------------
        -- open o_detail
        g_error := 'open o_detail / ID_REF=' || l_ref_new_data.id_external_request;
        OPEN o_detail FOR
            SELECT l_ref_new_data.id_external_request id_external_request,
                   l_ref_new_data.id_external_request id_p1,
                   l_ref_new_data.flg_type            flg_type, -- Referrals originated in external systems are always of type consultation (for now...)
                   l_ref_new_data.num_req             num_req,
                   l_ref_new_data.id_workflow         id_workflow,
                   -- dt_p1 computed with old referral data
                   nvl2(l_ref_old_data.id_external_request,
                        pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                           pk_ref_utils.get_ref_detail_date(i_lang,
                                                                                            l_ref_old_data.id_external_request,
                                                                                            l_ref_old_data.flg_status,
                                                                                            l_ref_old_data.id_workflow),
                                                           i_prof),
                        NULL) dt_p1,
                   l_status_icon status_icon,
                   l_ref_new_data.flg_status flg_status,
                   l_status_info_row.color status_colors,
                   l_status_info_row.desc_status desc_status,
                   -- priority_icon
                   nvl2(pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_PRIORITY', l_ref_new_data.flg_priority),
                        lpad(pk_sysdomain.get_rank(i_lang,
                                                   'P1_EXTERNAL_REQUEST.FLG_PRIORITY',
                                                   l_ref_new_data.flg_priority),
                             6,
                             '0') ||
                        pk_sysdomain.get_img(i_lang, 'P1_EXTERNAL_REQUEST.FLG_PRIORITY', l_ref_new_data.flg_priority),
                        NULL) priority_icon,
                   pk_date_utils.get_elapsed_tsz(i_lang, l_ref_new_data.dt_status_tstz, g_sysdate_tstz) dt_elapsed,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_ref_new_data.id_prof_requested) prof_name_request,
                   pk_ref_utils.get_prof_spec_signature(i_lang,
                                                        i_prof,
                                                        l_ref_new_data.id_prof_requested,
                                                        l_ref_new_data.id_inst_orig) prof_spec_request,
                   pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_PRIORITY', l_ref_new_data.flg_priority, i_lang) priority_desc, -- ALERT-273753
                   l_ref_new_data.id_dep_clin_serv id_dep_clin_serv,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_clinical_service_code || l_id_clinical_service) desc_clinical_service,
                   l_id_department id_department,
                   pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || l_id_department) desc_department,
                   -------- specs and subspecs
                   l_ref_new_data.id_speciality id_speciality,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_p1_speciality_code || l_ref_new_data.id_speciality) spec_name,
                   pk_translation.get_translation(i_lang,
                                                  pk_ref_constant.g_clinical_service_code || l_id_clinical_service) sub_spec_name, -- clinical service
                   l_ref_new_data.id_dep_clin_serv id_sub_speciality,
                   --------
                   -- orig institution
                   l_ref_new_data.id_inst_orig id_inst_orig,
                   -- dest institution 
                   l_ref_new_data.id_inst_dest id_institution,
                   decode(l_ref_new_data.id_inst_dest, l_sc_other_institution, NULL, l_inst_abbrev) inst_abbrev,
                   pk_ref_core.get_inst_name(i_lang,
                                             i_prof,
                                             l_ref_new_data.flg_status,
                                             l_ref_new_data.id_inst_dest,
                                             l_inst_code,
                                             l_inst_abbrev) inst_name,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_id_clinical_service) dep_name,
                   -- dt_schedule                   
                   pk_date_utils.dt_chr_tsz(i_lang, l_dt_schedule, i_prof) dt_schedule,
                   -- problem begin date
                   decode(l_my_data.id_category,
                          pk_ref_constant.g_cat_id_med,
                          l_dt_probl_begin_str, -- ALERT-194568
                          NULL) dt_probl_begin,
                   decode(l_my_data.id_category,
                          pk_ref_constant.g_cat_id_med,
                          l_dt_probl_begin_flash, -- ALERT-194568
                          NULL) dt_probl_begin_ts,
                   l_ref_new_data.flg_priority flg_priority,
                   l_ref_new_data.flg_home flg_home,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, l_ref_new_data.id_prof_redirected) prof_redirected,
                   pk_date_utils.date_send_tsz(i_lang, l_ref_new_data.dt_last_interaction_tstz, i_prof) dt_last_interaction,
                   l_ref_new_data.id_external_sys id_external_sys
              FROM dual;
    
        --------------------
        -- open o_text    
        g_error := 'open o_text / ID_REF=' || l_ref_new_data.id_external_request;
        OPEN o_text FOR
            SELECT decode(detail_type,
                          pk_ref_constant.g_detail_type_jstf,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t038),
                          pk_ref_constant.g_detail_type_sntm,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018),
                          pk_ref_constant.g_detail_type_evlt,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018),
                          pk_ref_constant.g_detail_type_hstr,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t019),
                          pk_ref_constant.g_detail_type_hstf,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t019),
                          pk_ref_constant.g_detail_type_obje,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t055),
                          pk_ref_constant.g_detail_type_cmpe,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t020),
                          NULL) label_group,
                   decode(detail_type,
                          pk_ref_constant.g_detail_type_jstf,
                          NULL,
                          pk_ref_constant.g_detail_type_sntm,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t041),
                          pk_ref_constant.g_detail_type_evlt,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t042),
                          pk_ref_constant.g_detail_type_hstr,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t045),
                          pk_ref_constant.g_detail_type_hstf,
                          l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t046),
                          pk_ref_constant.g_detail_type_obje,
                          NULL,
                          pk_ref_constant.g_detail_type_cmpe,
                          NULL,
                          NULL) label,
                   NULL id,
                   NULL id_parent,
                   NULL id_req,
                   pk_sysdomain.get_domain(pk_ref_constant.g_p1_detail_type, detail_type, i_lang) title,
                   detail_desc text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                   l_prof_name prof_name,
                   l_prof_spec prof_spec,
                   detail_type flg_type,
                   pk_ref_constant.g_active flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home,
                   NULL id_group
              FROM (SELECT extractvalue(VALUE(referral_data), '/ClinicalNotes/Type') detail_type,
                           extractvalue(VALUE(referral_data), '/ClinicalNotes/Information') detail_desc
                      FROM TABLE(xmlsequence(extract(xmltype(l_referral_temp_data),
                                                     '/Referral/ClinicalInformation/ClinicalNotes'))) referral_data)
             WHERE detail_type IN (pk_ref_constant.g_detail_type_jstf,
                                   pk_ref_constant.g_detail_type_sntm,
                                   pk_ref_constant.g_detail_type_evlt,
                                   pk_ref_constant.g_detail_type_hstr,
                                   pk_ref_constant.g_detail_type_hstf,
                                   pk_ref_constant.g_detail_type_obje,
                                   pk_ref_constant.g_detail_type_cmpe);
    
        --------------------
        -- open o_problem            
        g_error := 'open o_problem / ID_REF=' || l_ref_new_data.id_external_request;
        OPEN o_problem FOR
            SELECT l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t018) label_group,
                   l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t039) label,
                   id_diagnosis id,
                   id_diagnosis_parent id_parent,
                   NULL id_req,
                   pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => NULL,
                                              i_id_diagnosis       => id_diagnosis,
                                              i_code               => code_icd,
                                              i_flg_other          => flg_other,
                                              i_flg_std_diag       => pk_ref_constant.g_yes) title, --problem description                   
                   NULL text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                   l_prof_name prof_name,
                   l_prof_spec prof_spec,
                   pk_ref_constant.g_exr_diag_type_p flg_type,
                   pk_ref_constant.g_active flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home
              FROM (SELECT d.id_diagnosis, d.id_diagnosis_parent, d.code_icd, d.flg_other
                      FROM (SELECT extractvalue(VALUE(referral_data), '/DiagnosisInformation/Code') diag_code_id,
                                   extractvalue(VALUE(referral_data), '/DiagnosisInformation/Type') diag_type
                              FROM TABLE(xmlsequence(extract(xmltype(l_referral_temp_data),
                                                             '/Referral/ClinicalInformation/DiagnosisInformation'))) referral_data) t
                      JOIN diagnosis d
                        ON d.code_icd = t.diag_code_id
                     WHERE diag_type = pk_ref_constant.g_exr_diag_type_p -- problems only
                       AND d.flg_type IN (SELECT column_value
                                            FROM TABLE(CAST(l_diag_type_tab AS table_varchar))));
    
        --------------------
        -- open o_diagnosis             
        g_error := 'open o_diagnosis / ID_REF=' || l_ref_new_data.id_external_request;
        OPEN o_diagnosis FOR
            SELECT l_desc_message_ibt(pk_ref_constant.g_sm_doctor_req_t021) label_group,
                   NULL label,
                   id_diagnosis id,
                   id_diagnosis_parent id_parent,
                   NULL id_req,
                   pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_id_alert_diagnosis => NULL,
                                              i_id_diagnosis       => id_diagnosis,
                                              i_code               => code_icd,
                                              i_flg_other          => flg_other,
                                              i_flg_std_diag       => pk_ref_constant.g_yes) title, -- diagnosis description 
                   NULL text,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) dt_insert,
                   l_prof_name prof_name,
                   l_prof_spec prof_spec,
                   pk_ref_constant.g_exr_diag_type_d flg_type,
                   pk_ref_constant.g_active flg_status,
                   NULL id_institution,
                   NULL flg_priority,
                   NULL flg_home
              FROM (SELECT d.id_diagnosis, d.id_diagnosis_parent, d.code_icd, d.flg_other
                      FROM (SELECT extractvalue(VALUE(referral_data), '/DiagnosisInformation/Code') diag_code_id,
                                   extractvalue(VALUE(referral_data), '/DiagnosisInformation/Type') diag_type
                              FROM TABLE(xmlsequence(extract(xmltype(l_referral_temp_data),
                                                             '/Referral/ClinicalInformation/DiagnosisInformation'))) referral_data) t
                      JOIN diagnosis d
                        ON d.code_icd = t.diag_code_id
                     WHERE diag_type = pk_ref_constant.g_exr_diag_type_d -- diagnosis only
                       AND d.flg_type IN (SELECT column_value
                                            FROM TABLE(CAST(l_diag_type_tab AS table_varchar))));
    
        pk_types.open_my_cursor(o_mcdt);
        pk_types.open_my_cursor(o_needs);
        pk_types.open_my_cursor(o_info);
        pk_types.open_my_cursor(o_notes_status);
        pk_types.open_my_cursor(o_notes_status_det);
        pk_types.open_my_cursor(o_answer);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_REFERRAL_DATA',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_mcdt);
            pk_types.open_my_cursor(o_needs);
            pk_types.open_my_cursor(o_info);
            pk_types.open_my_cursor(o_notes_status);
            pk_types.open_my_cursor(o_notes_status_det);
            pk_types.open_my_cursor(o_answer);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END get_referral_data;

    /**
    * Validates if the session is valid. Returns professional data.
    *
    * @param   i_id_session    Session identifier
    * @param   o_professional  Professional identifier
    * @param   o_user          Professional login
    * @param   o_language      Professional language identifier
    * @param   o_institution   Institution identifier
    * @param   o_software      Software identifier
    * @param   o_error         Error
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   13-07-2010
    */
    FUNCTION validate_session
    (
        i_id_session   IN VARCHAR2,
        o_professional OUT professional.id_professional%TYPE,
        o_user         OUT ab_user_info.login%TYPE,
        o_language     OUT language.id_language%TYPE,
        o_institution  OUT institution.id_institution%TYPE,
        o_software     OUT software.id_software%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_url   ref_ext_session.ref_url%TYPE;
        l_ext_code  institution.ext_code%TYPE;
        l_num_order professional.num_order%TYPE;
    
        -- exceptions
        l_e_invalid_session EXCEPTION;
        l_e_user_not_found  EXCEPTION;
    BEGIN
    
        g_error := 'Init validate_session / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        o_language := pk_ref_constant.g_lang_pt;
    
        --------------------
        -- checks if session is active and returns session data
        g_error := 'Call get_session_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_session_data(i_lang       => o_language,
                                     i_session_id => i_id_session,
                                     o_ref_url    => l_ref_url,
                                     o_ext_code   => l_ext_code,
                                     o_num_order  => l_num_order,
                                     o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE l_e_invalid_session;
        END IF;
    
        -- mapping IDs
        g_error := 'Call get_prof_inst / NUM_ORDER=' || l_num_order || ' EXT_CODE=' || l_ext_code;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_prof_inst(i_lang      => o_language,
                                  i_ext_code  => l_ext_code,
                                  i_num_order => l_num_order,
                                  o_id_prof   => o_professional,
                                  o_user      => o_user,
                                  o_id_inst   => o_institution,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE l_e_user_not_found;
        END IF;
    
        -- gets software identifier
        g_error := 'Call get_ref_software / ID_PROFESSIONAL=' || o_professional || ' ID_INSTITUTION=' || o_institution;
        pk_alertlog.log_debug(g_error);
    
        o_software := get_ref_software(i_lang => o_language, i_id_prof => o_professional, i_id_inst => o_institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_e_invalid_session THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(1000 CHAR) := pk_message.get_message(o_language,
                                                                              pk_ref_constant.g_sm_doctor_cs_t080) || ' ' ||
                                                       pk_message.get_message(o_language,
                                                                              pk_ref_constant.g_sm_doctor_cs_t081);
            BEGIN
                l_error_in.set_all(o_language,
                                   l_error_message,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package,
                                   'VALIDATE_SESSION',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        WHEN l_e_user_not_found THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(1000 CHAR) := pk_message.get_message(o_language,
                                                                              pk_ref_constant.g_sm_doctor_cs_t080) || ' ' ||
                                                       pk_message.get_message(o_language,
                                                                              pk_ref_constant.g_sm_doctor_cs_t082);
            BEGIN
                l_error_in.set_all(o_language,
                                   l_error_message,
                                   l_error_message,
                                   g_error,
                                   g_owner,
                                   g_package,
                                   'VALIDATE_SESSION',
                                   l_error_message,
                                   pk_ref_constant.g_err_flg_action_u);
                g_retval := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => o_language,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'VALIDATE_SESSION',
                                                     o_error    => o_error);
    END validate_session;

    ------------------------------------------------------------------------------
    -- Input data
    ------------------------------------------------------------------------------

    /**
    * Generate session id randomly
    *
    * @RETURN  VARCHAR2 session identifier
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-04-2010
    */
    FUNCTION get_gen_session_id RETURN VARCHAR2 IS
    BEGIN
        RETURN(dbms_random.string('A', 30));
    END get_gen_session_id;

    /**
    * Validates if user is active
    *
    * @param   i_lang           Language associated to the professional executing the request                  
    * @param   i_ext_code       Intitution external code 
    * @param   i_num_order      Professional order number
    * @param   i_pass           Confidence data
    * @param   o_id_prof        Professional identifier in Alert
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION validate_user
    (
        i_lang      IN language.id_language%TYPE,
        i_ext_code  IN institution.ext_code%TYPE,
        i_num_order IN professional.num_order%TYPE,
        i_pass      IN VARCHAR2,
        o_id_prof   OUT professional.id_professional%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_inst institution.id_institution%TYPE;
        l_id_soft software.id_software%TYPE;
        l_pass    sys_config.desc_sys_config%TYPE;
        l_user    ab_user_info.login%TYPE;
    BEGIN
    
        g_error := 'Init validate_user / EXT_CODE=' || i_ext_code || ' NUM_ORDER=' || i_num_order || ' PASS=' || i_pass;
        pk_alertlog.log_debug(g_error);
    
        -- get professional and institution data
        g_error := 'Call get_prof_inst / NUM_ORDER=' || i_num_order || ' EXT_CODE=' || i_ext_code;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_prof_inst(i_lang      => i_lang,
                                  i_ext_code  => i_ext_code,
                                  i_num_order => i_num_order,
                                  o_id_prof   => o_id_prof,
                                  o_user      => l_user,
                                  o_id_inst   => l_id_inst,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- gets software identifier
        g_error := 'Call get_ref_software / ID_PROFESSIONAL=' || o_id_prof || ' ID_INSTITUTION=' || l_id_inst;
        pk_alertlog.log_debug(g_error);
    
        l_id_soft := get_ref_software(i_lang => i_lang, i_id_prof => o_id_prof, i_id_inst => l_id_inst);
    
        IF l_id_soft IS NULL
        THEN
            g_error := 'Parameter SOFTWARE_ID_P1 not found';
            RAISE g_exception;
        END IF;
    
        -- gets password auto login   
        g_error := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_p1_auto_login_pass ||
                   ' ID_PROFESSIONAL=' || o_id_prof || ' ID_INSTITUTION=' || l_id_inst;
        pk_alertlog.log_debug(g_error);
    
        l_pass := pk_sysconfig.get_config(pk_ref_constant.g_p1_auto_login_pass,
                                          profissional(o_id_prof, l_id_inst, l_id_soft));
    
        IF l_pass IS NULL
        THEN
            g_error := 'Parameter ' || pk_ref_constant.g_p1_auto_login_pass || ' not found';
            RAISE g_exception;
        END IF;
    
        -- comparing passwords
        g_error := 'Comparing passwords';
        pk_alertlog.log_debug(g_error);
    
        IF l_pass = i_pass
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'Invalid user. The password is incorrec: ' || i_pass;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'VALIDATE_USER',
                                                     o_error    => o_error);
    END validate_user;

    /**
    * Creates a new session identifier
    * Used by interfaces
    *
    * @param   i_lang           Language associated to the professional executing the request                  
    * @param   i_pass           Confidence data
    * @param   i_num_order      Professional order number
    * @param   i_ext_code       Intitution external code
    * @param   o_session_id     Session identifier        
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION get_session_id
    (
        i_lang       IN language.id_language%TYPE,
        i_pass       IN VARCHAR2,
        i_num_order  IN professional.num_order%TYPE,
        i_ext_code   IN institution.ext_code%TYPE,
        o_session_id OUT ref_ext_session.id_session%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_session IS
            SELECT ROWID rid, id_session
              FROM ref_ext_session s
             WHERE s.num_order = i_num_order
               AND s.ext_code = i_ext_code
               AND s.flg_active = pk_ref_constant.g_yes;
    
        l_rowid      UROWID;
        l_id_session ref_ext_session.id_session%TYPE;
        l_id_prof    professional.id_professional%TYPE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init get_session_id / PASS=' || i_pass || ' NUM_ORDER=' || i_num_order || ' EXT_CODE=' ||
                   i_ext_code;
        pk_alertlog.log_debug(g_error);
    
        g_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- VAL
        ----------------------        
        IF i_pass IS NULL
           OR i_num_order IS NULL
           OR i_ext_code IS NULL
        THEN
            g_error := 'Invalid parameters / PASS=' || i_pass || ' NUM_ORDER=' || i_num_order || ' EXT_CODE=' ||
                       i_ext_code;
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- FUNC
        ----------------------    
    
        -- checks if user is valid
        g_error  := 'Call validate_user / NUM_ORDER=' || i_num_order || ' EXT_CODE=' || i_ext_code || ' PASS=' ||
                    i_pass;
        g_retval := validate_user(i_lang      => i_lang,
                                  i_ext_code  => i_ext_code,
                                  i_num_order => i_num_order,
                                  i_pass      => i_pass,
                                  o_id_prof   => l_id_prof,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- checks if there is any active session id for the professional and institution
        g_error      := 'OPEN c_session / PASS=' || i_pass || ' NUM_ORDER=' || i_num_order || ' EXT_CODE=' ||
                        i_ext_code;
        l_rowid      := NULL;
        l_id_session := NULL;
    
        OPEN c_session;
        FETCH c_session
            INTO l_rowid, l_id_session;
        g_found := c_session%FOUND;
        CLOSE c_session;
    
        IF g_found
        THEN
            -- inactivate session
            g_error := 'UPDATE ref_ext_session FLG_ACTIVE=' || pk_ref_constant.g_no || ' ID_SESSION=' || l_id_session ||
                       ' ROWID=' || l_rowid;
            UPDATE ref_ext_session
               SET flg_active = pk_ref_constant.g_no
             WHERE ROWID = l_rowid;
        END IF;
    
        -- generating session identifier
        g_error      := 'get_gen_session_id';
        o_session_id := get_gen_session_id();
    
        g_error := g_error || ' / ID_SESSION=' || o_session_id;
        IF o_session_id IS NULL
        THEN
            g_error := 'Invalid session id / id_session IS NULL';
            RAISE g_exception;
        ELSE
            g_error := 'INSERT INTO ref_ext_session / ID_SESSION=' || o_session_id || ' FLG_ACTIVE=' ||
                       pk_ref_constant.g_yes || ' NUM_ORDER=' || i_num_order || ' EXT_CODE=' || i_ext_code ||
                       ' ID_PROFESSIONAL=' || l_id_prof || ' DT_SESSION tstz=' || g_sysdate_tstz;
            BEGIN
                INSERT INTO ref_ext_session
                    (id_session, dt_session, ref_url, flg_active, num_order, ext_code, id_professional, dt_inserted)
                VALUES
                    (o_session_id,
                     g_sysdate_tstz,
                     NULL,
                     pk_ref_constant.g_yes,
                     i_num_order,
                     i_ext_code,
                     l_id_prof,
                     g_sysdate_tstz);
            EXCEPTION
                WHEN OTHERS THEN
                    g_error := 'EXCEPTION ' || SQLERRM;
                    pk_alertlog.log_error(g_error);
            END;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            IF c_session%ISOPEN
            THEN
                CLOSE c_session;
            END IF;
            RETURN FALSE;
        WHEN OTHERS THEN
            IF c_session%ISOPEN
            THEN
                CLOSE c_session;
            END IF;
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_owner,
                                                     i_package  => g_package,
                                                     i_function => 'GET_SESSION_ID',
                                                     o_error    => o_error);
    END get_session_id;

    /**
    * Saves patient and referral temporary data
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_patient_data   Patient temporary data (xml format)
    * @param   i_referral_data  Referral temporary data (xml format)
    * @param   o_ref_url        Temporary URL
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   29-04-2010
    */
    FUNCTION set_temp_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_session    IN ref_ext_xml_data.id_session%TYPE,
        i_patient_data  IN ref_ext_xml_data.patient_data%TYPE,
        i_referral_data IN ref_ext_xml_data.referral_data%TYPE,
        o_ref_url       OUT ref_ext_session.ref_url%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_auto_login_url sys_config.value%TYPE;
        l_diag_type      diagnosis.flg_type%TYPE;
        l_diag_type_tab  table_varchar;
    
        l_user         ab_user_info.login%TYPE;
        l_prof         profissional;
        l_ext_code     institution.ext_code%TYPE;
        l_num_order    professional.num_order%TYPE;
        l_flg_valid    VARCHAR2(1 CHAR);
        l_ref_old_data p1_external_request%ROWTYPE;
        l_ref_new_data p1_external_request%ROWTYPE;
    
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    
        l_exists PLS_INTEGER;
    
        PROCEDURE create_ref_ext_xml
        (
            x_id_session    IN ref_ext_xml_data.id_session%TYPE,
            x_patient_data  IN ref_ext_xml_data.patient_data%TYPE,
            x_referral_data IN ref_ext_xml_data.referral_data%TYPE,
            x_professional  IN ref_ext_xml_data.id_professional%TYPE,
            x_dt_inserted   IN ref_ext_xml_data.dt_inserted%TYPE
        ) IS
            PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
        
            -- inserting patient and referral temporary data    
            g_error := 'INSERT INTO ref_ext_xml_data / ID_SESSION=' || i_id_session || ' ID_PROFESSIONAL=' || l_prof.id;
            pk_alertlog.log_debug(g_error);
        
            INSERT INTO ref_ext_xml_data
                (id_session, patient_data, referral_data, id_professional, dt_inserted)
            VALUES
                (x_id_session, x_patient_data, x_referral_data, x_professional, x_dt_inserted);
        
            COMMIT;
        
        END create_ref_ext_xml;
    
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init set_temp_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
        l_prof := profissional(NULL, NULL, NULL);
    
        ----------------------------
        -- LOG
        ----------------------------
        g_error := 'PATIENT_XML';
        pk_alertlog.log_debug(g_error);
    
        pk_ref_utils.log_clob(i_clob => i_patient_data);
    
        g_error := 'REFERRAL_XML';
        pk_alertlog.log_debug(g_error);
    
        pk_ref_utils.log_clob(i_clob => i_referral_data);
        ----------------------------
    
        g_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- FUNC
        ----------------------  
    
        --------------------
        -- validating parameters
        IF i_id_session IS NULL
           OR i_patient_data IS NULL
           OR i_referral_data IS NULL
        THEN
        
            g_error      := 'set_temp_data / ID_SESSION=' || i_id_session;
            l_error_code := pk_ref_constant.g_ref_error_1005;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
        
            RAISE g_exception;
        END IF;
    
        --------------------
        -- checks if session is active and returns session data
        g_error := 'Call get_session_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_session_data(i_lang       => i_lang,
                                     i_session_id => i_id_session,
                                     o_ref_url    => o_ref_url,
                                     o_ext_code   => l_ext_code,
                                     o_num_order  => l_num_order,
                                     o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- mapping IDs
        g_error := 'Call get_prof_inst / NUM_ORDER=' || l_num_order || ' EXT_CODE=' || l_ext_code;
        pk_alertlog.log_debug(g_error);
    
        g_retval := get_prof_inst(i_lang      => i_lang,
                                  i_ext_code  => l_ext_code,
                                  i_num_order => l_num_order,
                                  o_id_prof   => l_prof.id,
                                  o_user      => l_user,
                                  o_id_inst   => l_prof.institution,
                                  o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        -- gets software identifier
        g_error := 'Call get_ref_software / ID_PROFESSIONAL=' || l_prof.id || ' ID_INSTITUTION=' || l_prof.institution;
        pk_alertlog.log_debug(g_error);
    
        l_prof.software := get_ref_software(i_lang => i_lang, i_id_prof => l_prof.id, i_id_inst => l_prof.institution);
    
        IF l_prof.software IS NULL
        THEN
            g_error := 'Parameter SOFTWARE_ID_P1 not found';
            RAISE g_exception;
        END IF;
    
        --------------------
        -- inserting patient and referral temporary data
        g_error := 'Call create_ref_ext_xml / ID_SESSION=' || i_id_session;
        create_ref_ext_xml(x_id_session    => i_id_session,
                           x_patient_data  => i_patient_data,
                           x_referral_data => i_referral_data,
                           x_professional  => l_prof.id,
                           x_dt_inserted   => g_sysdate_tstz);
    
        --------------------
        -- validating XML
    
        -- checking if i_patient_data has value PATIENT
        g_error := 'Checking patient element';
        pk_alertlog.log_debug(g_error);
        l_exists := NULL;
    
        SELECT existsnode(VALUE(patient_data), 'Patient')
          INTO l_exists
          FROM TABLE(xmlsequence(extract(xmltype(i_patient_data), '/Patient'))) patient_data;
    
        IF l_exists = 0
        THEN
            g_error      := 'Invalid PATIENT xml';
            l_error_code := pk_ref_constant.g_ref_error_1005;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
        
            RAISE g_exception;
        END IF;
    
        -- checking if i_patient_data has value REFERRAL
        g_error := 'Checking patient element';
        pk_alertlog.log_debug(g_error);
        l_exists := NULL;
    
        SELECT existsnode(VALUE(referral_data), 'Referral')
          INTO l_exists
          FROM TABLE(xmlsequence(extract(xmltype(i_referral_data), '/Referral'))) referral_data;
    
        IF l_exists = 0
        THEN
            g_error      := 'Invalid REFERRAL xml';
            l_error_code := pk_ref_constant.g_ref_error_1005;
            l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
        
            RAISE g_exception;
        END IF;
    
        ----------------------
        -- CONFIG
        ----------------------
        -- this configs can only be loaded after l_prof is defined
        g_error          := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' || pk_ref_constant.g_sc_auto_login_url ||
                            ' PROFISSIONAL(' || pk_utils.to_string(l_prof) || ')';
        l_auto_login_url := pk_sysconfig.get_config(pk_ref_constant.g_sc_auto_login_url, l_prof);
    
        IF l_auto_login_url IS NULL
        THEN
            g_error := 'Parameter ' || pk_ref_constant.g_sc_auto_login_url || ' not found';
            RAISE g_exception;
        END IF;
    
        g_error := 'URL=' || l_auto_login_url;
        --pk_alertlog.log_debug(g_error);
    
        l_diag_type := pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_inst_diag_list, i_prof => l_prof);
    
        --for now there is only one diagnostic allowable (configured in SYS_CONFIG)
        g_error         := 'diag allowable';
        l_diag_type_tab := table_varchar(l_diag_type);
    
        --------------------
        -- validating diagnosis codes               
        g_error := 'Call check_diag_codes / ' || pk_utils.to_string(l_diag_type_tab);
        pk_alertlog.log_debug(g_error);
    
        g_retval := check_diag_codes(i_lang      => i_lang,
                                     i_prof      => l_prof,
                                     i_diag_type => l_diag_type_tab,
                                     i_ref_temp  => i_referral_data,
                                     o_error     => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        --------------------
        -- getting referral new data (imported by external system) and old data (present in alert db)
        g_error := 'Call fill_referral_data / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_retval := fill_referral_data(i_lang        => i_lang,
                                       i_prof        => l_prof,
                                       i_pat_temp    => i_patient_data,
                                       i_ref_temp    => i_referral_data,
                                       o_ref_old_row => l_ref_old_data,
                                       o_ref_new_row => l_ref_new_data,
                                       o_error       => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        IF l_ref_new_data.id_external_request IS NOT NULL
        THEN
        
            --------------------
            -- validating some data to check if we are updating the correct referral
            g_error  := 'Call check_referral_update / OLD_ID_PATIENT=' || l_ref_old_data.id_patient ||
                        ' OLD_ID_SPECIALITY=' || l_ref_old_data.id_speciality || ' OLD_ID_INST_DEST=' ||
                        l_ref_old_data.id_inst_dest || ' NEW_ID_PATIENT=' || l_ref_new_data.id_patient ||
                        ' NEW_ID_SPECIALITY=' || l_ref_new_data.id_speciality || ' NEW_ID_INST_DEST=' ||
                        l_ref_new_data.id_inst_dest || ' i_old_flg_status=' || l_ref_old_data.flg_status;
            g_retval := pk_api_ref_ws.check_referral_update(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_id_ref          => l_ref_old_data.id_external_request,
                                                            i_old_flg_type    => l_ref_old_data.flg_type,
                                                            i_old_id_workflow => l_ref_old_data.id_workflow,
                                                            i_old_id_pat      => l_ref_old_data.id_patient,
                                                            i_old_inst_dest   => l_ref_old_data.id_inst_dest,
                                                            i_old_id_spec     => l_ref_old_data.id_speciality,
                                                            i_old_id_dcs      => l_ref_old_data.id_dep_clin_serv,
                                                            i_old_id_ext_sys  => l_ref_old_data.id_external_sys,
                                                            i_old_flg_status  => l_ref_old_data.flg_status,
                                                            i_new_flg_type    => l_ref_new_data.flg_type,
                                                            i_new_id_workflow => l_ref_new_data.id_workflow,
                                                            i_new_id_pat      => l_ref_new_data.id_patient,
                                                            i_new_inst_dest   => l_ref_new_data.id_inst_dest,
                                                            i_new_id_spec     => l_ref_new_data.id_speciality,
                                                            i_new_id_dcs      => l_ref_new_data.id_dep_clin_serv,
                                                            i_new_id_ext_sys  => l_ref_new_data.id_external_sys,
                                                            o_flg_valid       => l_flg_valid,
                                                            o_error           => o_error);
        
            IF NOT g_retval
            THEN
                RAISE g_exception_np;
            END IF;
        
            IF l_flg_valid = pk_ref_constant.g_no
            THEN
                g_error := 'Referral ' || l_ref_new_data.id_external_request ||
                           ' not valid to be updated / OLD_ID_PATIENT=' || l_ref_old_data.id_patient ||
                           ' OLD_ID_SPECIALITY=' || l_ref_old_data.id_speciality || ' OLD_ID_INST_DEST=' ||
                           l_ref_old_data.id_inst_dest || ' OLD_EXTENRAL_SYS=' || l_ref_old_data.id_external_sys ||
                           ' NEW_ID_PATIENT=' || l_ref_new_data.id_patient || ' NEW_ID_SPECIALITY=' ||
                           l_ref_new_data.id_speciality || ' NEW_ID_INST_DEST=' || l_ref_new_data.id_inst_dest ||
                           ' NEW_EXTENRAL_SYS=' || l_ref_new_data.id_external_sys;
            
                l_error_code := pk_ref_constant.g_ref_error_1007;
                l_error_desc := pk_ref_core.get_ref_error_desc(i_lang => i_lang, i_id_ref_error => l_error_code);
            
                RAISE g_exception;
            END IF;
        
        END IF;
    
        --------------------
        -- generates URL for this session
        IF o_ref_url IS NOT NULL
        THEN
            g_error := 'URL IS NOT NULL / ID_SESSION=' || i_id_session || ' URL=' || o_ref_url || ' EXT_CODE=' ||
                       l_ext_code || ' NUM_ORDER=' || l_num_order;
            pk_alertlog.log_warn(g_error);
        END IF;
    
        -- replacing variables
        g_error   := 'replace';
        o_ref_url := REPLACE(l_auto_login_url, '@1', i_id_session);
        o_ref_url := REPLACE(o_ref_url, '@2', pk_ref_constant.g_provider_referral);
    
        -- updating URL and ID_REFERRAL in REF_EXT_SESSION
        g_error := 'UPDATE ref_ext_session / ID_SESSION=' || i_id_session || ' ID_REF=' ||
                   l_ref_new_data.id_external_request || ' REF_URL=' || o_ref_url;
        --pk_alertlog.log_debug(g_error);
    
        UPDATE ref_ext_session s
           SET s.ref_url             = o_ref_url,
               s.id_external_request = nvl(l_ref_new_data.id_external_request, id_external_request)
         WHERE id_session = i_id_session;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_TEMP_DATA',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
                pk_alert_exceptions.reset_error_state();
            END;
            RETURN FALSE;
    END set_temp_data;

    /**
    * Checks if referral original institution is private or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    Flag indicating if this institution is private or not
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-07-2010
    */
    FUNCTION check_priv_orig_inst
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_ext(x_id_session IN ref_ext_xml_data.id_session%TYPE) IS
            SELECT xml.referral_data, s.id_external_request
              FROM ref_ext_xml_data xml
              JOIN ref_ext_session s
                ON s.id_session = xml.id_session
             WHERE xml.id_session = x_id_session
             ORDER BY xml.dt_inserted DESC; -- if there is another session (outdated), returns the latest one
    
        l_id_inst_orig  institution.id_institution%TYPE;
        l_referral_data ref_ext_xml_data.referral_data%TYPE;
        l_id_ref        p1_external_request.id_external_request%TYPE;
        l_ref_row       p1_external_request%ROWTYPE;
    
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init check_priv_orig_inst / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN c_ext(' || i_id_session || ')';
        OPEN c_ext(i_id_session);
        FETCH c_ext
            INTO l_referral_data, l_id_ref;
        CLOSE c_ext;
    
        IF l_id_ref IS NULL
           AND l_referral_data IS NOT NULL
        THEN
            -- getting ID_EXTERNAL_REQUEST
            SELECT extractvalue(VALUE(referral_data), '/Referral/ReferralID') id_referral
              INTO l_id_ref
              FROM TABLE(xmlsequence(extract(xmltype(l_referral_data), '/Referral'))) referral_data;
        END IF;
    
        IF l_id_ref IS NULL
        THEN
        
            -- considering i_prof.institution
            g_error := 'i_prof.institution=' || i_prof.institution;
            pk_alertlog.log_debug(g_error);
        
            l_id_inst_orig := i_prof.institution;
        
        ELSE
            -- considering p1_external_request.id_inst_orig
            g_error := 'Call pk_p1_external_request.get_ref_row / ID_REF=' || l_id_ref;
            pk_alertlog.log_debug(g_error);
        
            g_retval := pk_p1_external_request.get_ref_row(i_lang   => i_lang,
                                                           i_prof   => i_prof,
                                                           i_id_ref => l_id_ref,
                                                           o_rec    => l_ref_row,
                                                           o_error  => o_error);
        
            IF NOT g_retval
            THEN
                g_error := 'ERROR: ' || g_error;
                RAISE g_exception_np;
            END IF;
        
            l_id_inst_orig := l_ref_row.id_inst_orig;
        END IF;
    
        -- checking this institution
        g_error := 'Call pk_ref_core.check_private_inst / ID_INST=' || l_id_inst_orig;
        pk_alertlog.log_debug(g_error);
    
        g_retval := pk_ref_core.check_private_inst(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_id_inst    => l_id_inst_orig,
                                                   o_flg_result => o_flg_result,
                                                   o_error      => o_error);
    
        IF NOT g_retval
        THEN
            g_error := 'ERROR: ' || g_error;
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'CHECK_PRIV_ORIG_INST',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END check_priv_orig_inst;

    /**
    * Checks if referral is being updated, or not
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_id_session    Session identifier that is related to referral temporary data    
    * @param   o_flg_result    {*} Y - referral is being updated {*} N - referral is being created
    * @param   o_error         An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   19-07-2010
    */
    FUNCTION check_ref_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_session.id_session%TYPE,
        o_flg_result OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ext(x_id_session IN ref_ext_xml_data.id_session%TYPE) IS
            SELECT xml.referral_data, s.id_external_request
              FROM ref_ext_xml_data xml
              JOIN ref_ext_session s
                ON s.id_session = xml.id_session
             WHERE xml.id_session = x_id_session
             ORDER BY xml.dt_inserted DESC; -- if there is another session (outdated), returns the latest one
    
        l_referral_data ref_ext_xml_data.referral_data%TYPE;
        l_id_ref        p1_external_request.id_external_request%TYPE;
    
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init check_ref_update / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'OPEN c_ext(' || i_id_session || ')';
        OPEN c_ext(i_id_session);
        FETCH c_ext
            INTO l_referral_data, l_id_ref;
        CLOSE c_ext;
    
        g_error := 'IF';
        IF l_referral_data IS NOT NULL
        THEN
            -- getting ID_EXTERNAL_REQUEST
            g_error := 'getting ID_EXTERNAL_REQUEST';
            pk_alertlog.log_debug(g_error);
        
            SELECT extractvalue(VALUE(referral_data), '/Referral/ReferralID') id_referral
              INTO l_id_ref
              FROM TABLE(xmlsequence(extract(xmltype(l_referral_data), '/Referral'))) referral_data;
        END IF;
    
        g_error := 'id_ref=' || l_id_ref;
        pk_alertlog.log_debug(g_error);
    
        IF l_id_ref IS NULL
        THEN
            -- referral creation
            o_flg_result := pk_ref_constant.g_no;
        ELSE
            o_flg_result := pk_ref_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'CHECK_REF_UPDATE',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END check_ref_update;

    /**
    * This functions updates session table after the referral has been created and notifies INTER-ALERT that the referral was updated
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been created
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   18-05-2010
    */
    FUNCTION set_ref_created
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init set_ref_created / ID_SESSION=' || i_id_session || ' ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- FUNC
        ----------------------   
    
        g_error := 'UPDATE ref_ext_session / ID_REFERRAL=' || i_id_ref || ' ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        UPDATE ref_ext_session s
           SET s.id_external_request = i_id_ref, s.flg_active = pk_ref_constant.g_no
         WHERE s.id_session = i_id_session;
    
        -- INTER-ALERT
        g_error := '---- CREATE CONFIRMATION / ID_SESSION=' || i_id_session || ' ID_REF=' || i_id_ref ||
                   ' INSTITUTION=' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        pk_ia_event_referral.referral_create_confirmation(i_id_session     => i_id_session,
                                                          i_id_institution => i_prof.institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_CREATED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_created;

    /**
    * This functions notifies INTER-ALERT that the referral was updated
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   15-07-2010
    */
    FUNCTION set_ref_updated
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_code ref_error.id_ref_error%TYPE;
        l_error_desc pk_translation.t_desc_translation;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init set_ref_updated / ID_SESSION=' || i_id_session || ' ID_REF=' || i_id_ref;
        pk_alertlog.log_debug(g_error);
    
        ----------------------
        -- FUNC
        ----------------------   
        g_error := 'UPDATE ref_ext_session / ID_REFERRAL=' || i_id_ref || ' ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
    
        UPDATE ref_ext_session s
           SET s.id_external_request = i_id_ref, s.flg_active = pk_ref_constant.g_no
         WHERE s.id_session = i_id_session;
    
        -- INTER-ALERT
        g_error := '---- UPDATE CONFIRMATION / ID_SESSION=' || i_id_session || ' ID_REF=' || i_id_ref ||
                   ' INSTITUTION=' || i_prof.institution;
        pk_alertlog.log_debug(g_error);
        pk_ia_event_referral.referral_update_confirmation(i_id_session     => i_id_session,
                                                          i_id_institution => i_prof.institution);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SET_REF_UPDATED',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END set_ref_updated;

    /**
    * This is called by flash, to ping session identifier
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_session     Session identifier 
    * @param   i_id_ref         Referral identifier that has been updated
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if its a valid user, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   23-11-2010
    */
    FUNCTION session_ping
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_session IN ref_ext_xml_data.id_session%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_code   ref_error.id_ref_error%TYPE;
        l_error_desc   pk_translation.t_desc_translation;
        l_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------    
        g_error := 'Init session_ping / ID_SESSION=' || i_id_session;
        pk_alertlog.log_debug(g_error);
        l_sysdate_tstz := current_timestamp;
    
        ----------------------
        -- FUNC
        ----------------------
        -- this session is still alive, reset dt_session
        g_error := 'UPDATE ref_ext_session SET dt_session=' || l_sysdate_tstz || ' WHERE id_session=' || i_id_session;
        pk_alertlog.log_debug(g_error);
        UPDATE ref_ext_session
           SET dt_session = l_sysdate_tstz
         WHERE id_session = i_id_session;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_flg_action VARCHAR2(1 CHAR);
            BEGIN
                IF l_error_code IS NOT NULL
                THEN
                    l_flg_action := pk_ref_constant.g_err_flg_action_u; -- user defined error
                ELSE
                    l_error_code := SQLCODE;
                    l_error_desc := SQLERRM;
                    l_flg_action := pk_ref_constant.g_err_flg_action_s; -- system error
                END IF;
                pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                  i_sqlcode     => l_error_code,
                                                  i_sqlerrm     => l_error_desc,
                                                  i_message     => g_error,
                                                  i_owner       => g_owner,
                                                  i_package     => g_package,
                                                  i_function    => 'SESSION_PING',
                                                  i_action_type => l_flg_action,
                                                  i_action_msg  => NULL,
                                                  o_error       => o_error);
            END;
            RETURN FALSE;
    END session_ping;

    ------------------------------------------------------------------------------
    -- Job procedures (bulk operations)
    ------------------------------------------------------------------------------

    /**
    * Gets expire date based on i_date
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_date           Session creation date    
    *
    * @RETURN  Session expire date
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-07-2010
    */
    FUNCTION get_dt_expire
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN ref_ext_session.dt_session%TYPE
    ) RETURN ref_ext_session.dt_session%TYPE IS
        l_ref_ext_session_timout PLS_INTEGER;
        l_result                 ref_ext_session.dt_session%TYPE;
    BEGIN
    
        g_error := 'Init get_dt_expire / i_date=' ||
                   pk_date_utils.to_char_insttimezone(i_prof, i_date, pk_ref_constant.g_format_date);
        pk_alertlog.log_debug(g_error);
    
        -- getting number minutes for session timeout
        g_error                  := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' ||
                                    pk_ref_constant.g_ref_ext_session_timout;
        l_ref_ext_session_timout := to_number(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_ext_session_timout,
                                                                      i_prof    => i_prof));
    
        g_error  := 'Getting o_dt_expire / TIMEOUT=' || l_ref_ext_session_timout;
        l_result := pk_date_utils.add_to_ltstz(i_date, l_ref_ext_session_timout, pk_ref_constant.g_minute);
    
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN NULL;
    END get_dt_expire;

    /**
    * Cleans inactive sessions have existed for some time
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-05-2010
    */
    PROCEDURE clean_ref_session(i_lang IN language.id_language%TYPE) IS
        l_error                t_error_out;
        l_prof                 profissional;
        l_ref_ext_session_hist PLS_INTEGER;
        l_dt_limit             TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_id_session           ref_ext_session.id_session%TYPE;
        l_count                NUMBER;
        l_num_commit           PLS_INTEGER;
    
        CURSOR c_session(x_dt_limit IN TIMESTAMP WITH LOCAL TIME ZONE) IS
            SELECT id_session
              FROM ref_ext_session s
             WHERE s.flg_active = pk_ref_constant.g_no
               AND s.dt_inserted < x_dt_limit;
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'Init clean_ref_session / ID_LANG=' || i_lang;
        g_sysdate_tstz := current_timestamp;
        l_num_commit   := 100;
    
        g_error := 'Call pk_ref_interface.set_prof_interface';
        l_prof  := pk_ref_interface.set_prof_interface(profissional(NULL, 0, pk_ref_constant.g_id_soft_referral));
    
        ----------------------
        -- CONFIG
        ----------------------
    
        -- getting number of months from which the sessions will be deleted
        g_error                := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' ||
                                  pk_ref_constant.g_ref_ext_session_hist;
        l_ref_ext_session_hist := to_number(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_ext_session_hist,
                                                                    i_prof    => l_prof));
    
        ----------------------
        -- FUNC
        ----------------------
    
        -- getting limit date
        g_error    := 'Getting date limit / MONTHS=' || l_ref_ext_session_hist;
        l_dt_limit := add_months(g_sysdate_tstz, -l_ref_ext_session_hist);
        l_count    := 0;
    
        g_error := 'OPEN c_session(' || l_dt_limit || ')';
        OPEN c_session(l_dt_limit);
        LOOP
        
            g_error := 'FETCH c_session';
            FETCH c_session
                INTO l_id_session;
            EXIT WHEN c_session%NOTFOUND;
        
            l_count := l_count + 1;
        
            BEGIN
                -- ref_ext_xml_data
                g_error := 'DELETE FROM ref_ext_xml_data WHERE ID_SESSION=' || l_id_session;
                DELETE FROM ref_ext_xml_data
                 WHERE id_session = l_id_session;
            
                -- ref_ext_session
                g_error := 'DELETE FROM ref_ext_session WHERE ID_SESSION=' || l_id_session;
                DELETE FROM ref_ext_session
                 WHERE id_session = l_id_session;
            
                -- commit/rollback
                g_error := 'MOD(' || l_count || ',' || l_num_commit || ')';
                IF MOD(l_count, l_num_commit) = 0
                THEN
                    ------------------------
                    COMMIT;
                    ------------------------
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    -- undo all changes to this point... continues with other sessions
                    ------------------------
                    pk_utils.undo_changes;
                    ------------------------
            END;
        
            -- reset vars
            l_id_session := NULL;
        
        END LOOP;
        CLOSE c_session;
    
        ------------------------
        COMMIT;
        ------------------------
    
    EXCEPTION
        WHEN OTHERS THEN
            ------------------------
            pk_utils.undo_changes;
            ------------------------
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'CLEAN_REF_SESSION',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
    END clean_ref_session;

    /**
    * Sets sessions status to inactive
    *
    * @param   i_lang             Language
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   14-05-2010
    */
    PROCEDURE inactive_ref_session(i_lang IN language.id_language%TYPE) IS
        l_error                  t_error_out;
        l_prof                   profissional;
        l_ref_ext_session_timout PLS_INTEGER;
        l_count                  NUMBER;
        l_id_session             ref_ext_session.id_session%TYPE;
        l_dt_limit               TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_dt_session             ref_ext_session.dt_session%TYPE;
    
        CURSOR c_session(x_dt_limit IN TIMESTAMP WITH LOCAL TIME ZONE) IS
            SELECT id_session, dt_session
              FROM ref_ext_session s
             WHERE s.flg_active = pk_ref_constant.g_yes
               AND s.dt_session < x_dt_limit;
    
    BEGIN
    
        ----------------------
        -- INIT
        ----------------------
        g_error        := 'Init inactive_ref_session / ID_LANG=' || i_lang;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'Call pk_ref_interface.set_prof_interface';
        l_prof  := pk_ref_interface.set_prof_interface(profissional(NULL, 0, pk_ref_constant.g_id_soft_referral));
    
        ----------------------
        -- CONFIG
        ----------------------
    
        -- getting number minutes for session timeout
        g_error                  := 'Call pk_sysconfig.get_config / ID_SYS_CONFIG=' ||
                                    pk_ref_constant.g_ref_ext_session_timout;
        l_ref_ext_session_timout := to_number(pk_sysconfig.get_config(i_code_cf => pk_ref_constant.g_ref_ext_session_timout,
                                                                      i_prof    => l_prof));
    
        ----------------------
        -- FUNC
        ----------------------
    
        g_error    := 'Getting date limit / TIMEOUT=' || l_ref_ext_session_timout;
        l_dt_limit := g_sysdate_tstz - (l_ref_ext_session_timout / (24 * 60));
    
        l_count := 0;
        g_error := 'OPEN c_session / l_dt_limit=' || l_dt_limit;
        OPEN c_session(l_dt_limit);
        LOOP
        
            g_error := 'FETCH c_session';
            FETCH c_session
                INTO l_id_session, l_dt_session;
            EXIT WHEN c_session%NOTFOUND;
        
            l_count := l_count + 1;
        
            g_error := 'ID_SESSION=' || l_id_session || ' DT_SESSION char=' ||
                       pk_date_utils.date_char_tsz(i_lang, l_dt_session, l_prof.institution, l_prof.software) ||
                       ' DT_SESSION tstz=' || l_dt_session || ' DT_LIMIT char=' ||
                       pk_date_utils.date_char_tsz(i_lang, l_dt_limit, l_prof.institution, l_prof.software) ||
                       ' DT_LIMIT tstz=' || l_dt_limit;
            BEGIN
            
                -- ref_ext_session
                g_error := 'UPDATE ref_ext_session SET FLG_ACTIVE=' || pk_ref_constant.g_no || ' WHERE ID_SESSION=' ||
                           l_id_session || ' / DT_SESSION char=' ||
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_date_utils.get_string_tstz(i_lang, l_prof, l_dt_session, NULL),
                                                    l_prof) || ' DT_SESSION tstz=' || l_dt_session;
                UPDATE ref_ext_session s
                   SET s.flg_active = pk_ref_constant.g_no
                 WHERE s.id_session = l_id_session
                   AND s.flg_active = pk_ref_constant.g_yes;
            
                -- commit/rollback
                g_error := 'COMMIT';
                ------------------------
                COMMIT;
                ------------------------                
            
            EXCEPTION
                WHEN OTHERS THEN
                    -- undo all changes to this point... continues with other sessions
                    ------------------------
                    pk_utils.undo_changes;
                    ------------------------
            END;
        
            -- reset vars
            l_id_session := NULL;
        
        END LOOP;
        CLOSE c_session;
    
        ------------------------
        COMMIT;
        ------------------------
    
    EXCEPTION
        WHEN OTHERS THEN
            ------------------------
            pk_utils.undo_changes;
            ------------------------
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'INACTIVE_REF_SESSION',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state();
    END inactive_ref_session;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_api_ref_ext;
/
