/*-- Last Change Revision: $Rev: 2026810 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_barcode IS

    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);
    my_exception EXCEPTION;

    g_barcode_valid_len CONSTANT PLS_INTEGER := 12;
    g_barcode_lpad_char CONSTANT VARCHAR2(1) := '0';

    g_barcode_message     CONSTANT VARCHAR2(40 CHAR) := 'MEDICATION_BARCODE_';
    g_result_needs_reason CONSTANT VARCHAR2(1 CHAR) := 'R';

    e_null_column_value EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_null_column_value, -1400);
    --
    e_existing_fky_reference EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_existing_fky_reference, -2266);
    --
    e_check_constraint_failure EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_check_constraint_failure, -2290);
    --
    e_no_parent_key EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_parent_key, -2291);
    --
    e_child_record_found EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_child_record_found, -2292);
    --
    e_forall_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_forall_error, -24381);
    --
    -- Defined for backward compatibilty.
    e_integ_constraint_failure EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_integ_constraint_failure, -2291);

    -- Private utilities
    PROCEDURE get_constraint_info
    (
        owner_out OUT all_constraints.owner%TYPE,
        name_out  OUT all_constraints.constraint_name%TYPE
    ) IS
        l_errm  VARCHAR2(2000) := dbms_utility.format_error_stack;
        dotloc  PLS_INTEGER;
        leftloc PLS_INTEGER;
    BEGIN
        dotloc    := instr(l_errm, '.');
        leftloc   := instr(l_errm, '(');
        owner_out := substr(l_errm, leftloc + 1, dotloc - leftloc - 1);
        name_out  := substr(l_errm, dotloc + 1, instr(l_errm, ')') - dotloc - 1);
    END get_constraint_info;

    /**********************************************************************************************
    * Validates if given code exists in given institution 
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_barcode                the barcode to validate
    * @param o_exists                 boolean with the existence of the barcode in the given institution
    * @param o_error                  Error message
    *
    * @author                         Nelson Canastro
    * @version                        1.0 
    * @since                          2010/05/25
    **********************************************************************************************/
    FUNCTION check_exists_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_barcode IN episode.barcode%TYPE,
        o_exists  OUT BOOLEAN,
        o_patient OUT patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_type      epis_type.id_epis_type%TYPE;
        l_id_epis_type_tech epis_type.id_epis_type%TYPE;
    
        -- barcode considering episode.barcode
        CURSOR c_epis_barcode IS
            SELECT 'X', decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech, epis.id_patient -- show technician episode when it returns more than one episode
              FROM episode epis
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
               AND epis.barcode = i_barcode
             ORDER BY epis_type_tech DESC, epis.dt_begin_tstz DESC;
    
        -- barcode considering the national health number 
        CURSOR c_epis_health_number IS
            SELECT 'X', decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech, epis.id_patient
              FROM (SELECT psa.id_patient,
                           row_number() over(ORDER BY decode(psa.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM pat_soc_attributes psa
                     WHERE psa.national_health_number = i_barcode
                       AND psa.id_institution IN (0, i_prof.institution)) t
              JOIN episode epis
                ON epis.id_patient = t.id_patient
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
             ORDER BY t.line_number, epis_type_tech DESC, epis.dt_begin_tstz DESC;
    
        -- barcode considering the clinical record
        CURSOR c_epis_clin_record IS
            SELECT 'X', decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech, epis.id_patient
              FROM (SELECT cr.id_patient
                      FROM clin_record cr
                     WHERE cr.num_clin_record = i_barcode
                       AND cr.id_institution = i_prof.institution
                       AND cr.flg_status = pk_alert_constant.g_active) t
              JOIN episode epis
                ON epis.id_patient = t.id_patient
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
             ORDER BY epis_type_tech DESC, epis.dt_begin_tstz DESC;
        --
        l_val_external_barcode sys_config.value%TYPE;
        -- Dummy variable to allow for cursor opening
        l_char    VARCHAR2(1);
        l_num     NUMBER;
        l_patient patient.id_patient%TYPE;
    BEGIN
    
        g_error := 'GET ID_EPIS_TYPE';
        -- PFH
        IF i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                               pk_alert_constant.g_soft_oris,
                               pk_alert_constant.g_soft_primary_care,
                               pk_alert_constant.g_soft_edis,
                               pk_alert_constant.g_soft_inpatient,
                               pk_alert_constant.g_soft_private_practice,
                               pk_alert_constant.g_soft_triage,
                               pk_alert_constant.g_soft_ubu)
        THEN
            l_id_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        
            IF l_id_epis_type IS NULL
            THEN
                g_error := 'EPIS_TYPE CONFIGURATION MISSING!';
                RAISE g_exception;
            END IF;
        
        ELSE
            -- techicians
            l_id_epis_type_tech := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        END IF;
    
        g_error                := 'GET CONFIGURATION';
        l_val_external_barcode := pk_sysconfig.get_config(i_code_cf => g_cfg_external_barcode, i_prof => i_prof);
    
        IF l_val_external_barcode = g_ext_bar_na
           OR l_val_external_barcode IS NULL
        THEN
            g_error := 'OPEN C_EPIS_BARCODE';
            OPEN c_epis_barcode;
            FETCH c_epis_barcode
                INTO l_char, l_num, o_patient;
            CLOSE c_epis_barcode;
        ELSIF l_val_external_barcode = g_ext_bar_cr
        THEN
            g_error := 'OPEN C_EPIS_CLIN_RECORD';
            OPEN c_epis_clin_record;
            FETCH c_epis_clin_record
                INTO l_char, l_num, o_patient;
            CLOSE c_epis_clin_record;
        ELSIF l_val_external_barcode = g_ext_bar_nhs
        THEN
            g_error := 'OPEN C_EPIS_HEALTH_NUMBER';
            OPEN c_epis_health_number;
            FETCH c_epis_health_number
                INTO l_char, l_num, o_patient;
            CLOSE c_epis_health_number;
        END IF;
    
        -- Assigns the return variable   
        IF l_char IS NOT NULL
        THEN
            o_exists := TRUE;
        ELSE
            o_exists := FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXISTS_BARCODE',
                                              o_error);
            RETURN FALSE;
    END check_exists_barcode;

    FUNCTION generate_barcode_checkdigit
    (
        i_lang    IN language.id_language%TYPE,
        i_barcode IN VARCHAR2,
        o_barcode OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Gerar código de barras  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_BARCODE - 
                  Saida:   O_BARCODE - código de barras  
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/05/12 
          NOTAS: 
        *********************************************************************************/
        l_barcode VARCHAR2(30);
        l_digit   NUMBER(3);
        l_odd     NUMBER(3) := 0;
        l_even    NUMBER(3) := 0;
        l_last    NUMBER(3);
        l_check   NUMBER(3);
    BEGIN
        g_error   := 'GET L_BARCODE';
        l_barcode := lpad(i_barcode, g_barcode_valid_len, g_barcode_lpad_char);
    
        g_error := 'VALIDATE LENGTH';
        IF length(l_barcode) != g_barcode_valid_len
        THEN
            g_error := pk_message.get_message(i_lang, 'BARCODE_M001');
            RETURN FALSE;
        END IF;
    
        g_error := 'GET L_ODD';
        l_digit := 1;
        WHILE (l_digit < 13)
        LOOP
            l_odd   := l_odd + to_number(substr(l_barcode, l_digit, 1));
            l_digit := l_digit + 2;
        END LOOP;
    
        g_error := 'GET L_EVEN';
        l_digit := 2;
        WHILE (l_digit < 13)
        LOOP
            l_even  := l_even + to_number(substr(l_barcode, l_digit, 1));
            l_digit := l_digit + 2;
        END LOOP;
        l_even := l_even * 3;
    
        g_error := 'GET L_LAST';
        l_last  := MOD(l_odd + l_even, 10);
    
        g_error := 'GET L_CHECK';
        SELECT decode(l_last, 1, 9, 2, 8, 3, 7, 4, 6, 5, 5, 6, 4, 7, 3, 8, 2, 9, 1, 0)
          INTO l_check
          FROM dual;
    
        g_error   := 'GET O_BARCODE';
        o_barcode := i_barcode || to_char(l_check);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GENERATE_BARCODE_CHECKDIGIT',
                                                     o_error);
    END generate_barcode_checkdigit;

    FUNCTION generate_barcode
    (
        i_lang         IN language.id_language%TYPE,
        i_barcode_type IN VARCHAR2,
        i_institution  IN NUMBER,
        i_software     IN NUMBER,
        o_barcode      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Gerar código de barras  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_BARCODE_TYPE - destino do cód barras: 
                              H - colheitas; E - requisição de exame; 
                              P - doente 
                     I_INSTITUTION - instituição onde está o prof. 
                     I_SOFTWARE - aplicação alert 
                  Saida:   O_BARCODE - código de barras  
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/05/12 
          NOTAS: 
        *********************************************************************************/
        l_aux              VARCHAR2(200);
        l_get_sequence_sql VARCHAR2(200);
        l_nextval          NUMBER;
        l_barcode_type     sys_config.value%TYPE;
        l_barcode          VARCHAR2(30);
        l_error            t_error_out;
        l_prof             profissional;
    BEGIN
        l_aux   := 'BARCODE_' || i_barcode_type;
        l_prof  := profissional(NULL, i_institution, i_software);
        g_error := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
        IF NOT pk_sysconfig.get_config(l_aux, l_prof, l_barcode_type)
        THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_BARCODE.GENERATE_BARCODE / ' ||
                       g_error;
            RAISE g_exception_user;
        END IF;
    
        g_error := 'VALIDATE L_BARCODE_TYPE';
        IF l_barcode_type IS NULL
        THEN
            g_error := pk_message.get_message(i_lang, 'BARCODE_M002');
            RAISE g_exception_user;
        END IF;
    
        g_error            := 'GET L_GET_SEQUENCE_SQL';
        l_get_sequence_sql := 'SELECT SEQ_BARCODE_' || i_barcode_type || '.NEXTVAL FROM DUAL';
        EXECUTE IMMEDIATE l_get_sequence_sql
            INTO l_nextval;
    
        g_error   := 'GET L_BARCODE';
        l_barcode := lpad(l_barcode_type, 2, g_barcode_lpad_char) || lpad(l_nextval, 10, g_barcode_lpad_char);
    
        g_error := 'CALL TO GENERATE_BARCODE_CHECKDIGIT';
        IF NOT generate_barcode_checkdigit(i_lang    => i_lang,
                                           i_barcode => l_barcode,
                                           o_barcode => o_barcode,
                                           o_error   => l_error)
        THEN
        
            o_error := l_error;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_user THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GENERATE_BARCODE',
                                                     g_action_type_user,
                                                     o_error);
        WHEN g_exception THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GENERATE_BARCODE',
                                                     o_error);
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GENERATE_BARCODE',
                                                     o_error);
    END generate_barcode;

    /**********************************************************************************************
    * Listar o episódio clinico associado ao código de barras pesquisado
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_barcode                Código de barras a pesquisar                   
    * @param o_result                 devolve o episódio clinico associado ao código de barras ou a mensagem de erro 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/26
    **********************************************************************************************/
    FUNCTION get_grid_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_barcode IN episode.barcode%TYPE,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_type      epis_type.id_epis_type%TYPE;
        l_id_epis_type_tech epis_type.id_epis_type%TYPE;
    
        -- barcode considering episode.barcode
        CURSOR c_epis_barcode IS
            SELECT epis.id_episode,
                   epis.id_patient,
                   decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech -- show technician episode when it returns more than one episode
              FROM episode epis
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
               AND epis.barcode = i_barcode
             ORDER BY epis_type_tech DESC, epis.dt_begin_tstz DESC;
    
        -- barcode considering the national health number 
        CURSOR c_epis_health_number IS
            SELECT epis.id_episode,
                   epis.id_patient,
                   decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech
              FROM (SELECT psa.id_patient,
                           row_number() over(ORDER BY decode(psa.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM pat_soc_attributes psa
                     WHERE psa.national_health_number = i_barcode
                       AND psa.id_institution IN (0, i_prof.institution)) t
              JOIN episode epis
                ON epis.id_patient = t.id_patient
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
             ORDER BY t.line_number, epis_type_tech DESC, epis.dt_begin_tstz DESC;
    
        -- barcode considering the clinical record
        CURSOR c_epis_clin_record IS
            SELECT epis.id_episode,
                   epis.id_patient,
                   decode(epis.id_epis_type, l_id_epis_type_tech, 1, 0) epis_type_tech
              FROM (SELECT cr.id_patient
                      FROM clin_record cr
                     WHERE cr.num_clin_record = i_barcode
                       AND cr.id_institution = i_prof.institution
                       AND cr.flg_status = pk_alert_constant.g_active) t
              JOIN episode epis
                ON epis.id_patient = t.id_patient
             WHERE epis.id_epis_type = nvl(l_id_epis_type, epis.id_epis_type)
               AND epis.id_institution = i_prof.institution
             ORDER BY epis_type_tech DESC, epis.dt_begin_tstz DESC;
    
        l_id_episode episode.id_episode%TYPE;
        l_id_patient episode.id_patient%TYPE;
        l_num        NUMBER;
        --
        l_val_external_barcode sys_config.value%TYPE;
    
    BEGIN
        g_error := 'GET ID_EPIS_TYPE';
        -- PFH
        IF i_prof.software IN (pk_alert_constant.g_soft_outpatient,
                               pk_alert_constant.g_soft_oris,
                               pk_alert_constant.g_soft_primary_care,
                               pk_alert_constant.g_soft_edis,
                               pk_alert_constant.g_soft_inpatient,
                               pk_alert_constant.g_soft_private_practice,
                               pk_alert_constant.g_soft_triage,
                               pk_alert_constant.g_soft_ubu)
        THEN
            l_id_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        
            IF l_id_epis_type IS NULL
            THEN
                g_error := 'EPIS_TYPE CONFIGURATION MISSING!';
                RAISE g_exception;
            END IF;
        
        ELSE
            -- techicians
            l_id_epis_type_tech := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        END IF;
    
        g_error                := 'GET CONFIGURATION';
        l_val_external_barcode := pk_sysconfig.get_config(i_code_cf => g_cfg_external_barcode, i_prof => i_prof);
    
        IF l_val_external_barcode = g_ext_bar_na
           OR l_val_external_barcode IS NULL
        THEN
            g_error := 'OPEN C_EPIS_BARCODE';
            OPEN c_epis_barcode;
            FETCH c_epis_barcode
                INTO l_id_episode, l_id_patient, l_num;
            CLOSE c_epis_barcode;
        ELSIF l_val_external_barcode = g_ext_bar_cr
        THEN
            g_error := 'OPEN C_EPIS_CLIN_RECORD';
            OPEN c_epis_clin_record;
            FETCH c_epis_clin_record
                INTO l_id_episode, l_id_patient, l_num;
            CLOSE c_epis_clin_record;
        ELSIF l_val_external_barcode = g_ext_bar_nhs
        THEN
            g_error := 'OPEN C_EPIS_HEALTH_NUMBER';
            OPEN c_epis_health_number;
            FETCH c_epis_health_number
                INTO l_id_episode, l_id_patient, l_num;
            CLOSE c_epis_health_number;
        END IF;
        --
        IF l_id_episode IS NULL
        THEN
            g_error := 'GET CURSOR O_RESULT(1)';
            OPEN o_result FOR
                SELECT NULL id_episode, NULL id_patient, title
                  FROM (SELECT 01 myrank, pk_message.get_message(i_lang, 'EDIS_GRID_M002') title
                          FROM dual
                        UNION ALL
                        SELECT 02 myrank, pk_message.get_message(i_lang, 'EDIS_GRID_T046') title
                          FROM dual) xsql
                 ORDER BY myrank DESC;
        
        ELSE
            g_error := 'GET CURSOR O_RESULT(2)';
            OPEN o_result FOR
                SELECT l_id_episode id_episode, l_id_patient id_patient, NULL title
                  FROM dual;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     'PK_BARCODE',
                                                     'GET_GRID_BARCODE',
                                                     o_error);
    END get_grid_barcode;

    /**********************************************************************************************
    * Retorna o código de barras da instituição 
    * 
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_institution            instituição                  
    * @param o_institution_barcode    devolve o código de barras da instituição 
    * @param o_error                  Error message
    *
    * @author                         Rui Duarte
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/
    FUNCTION get_institution_barcode
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_institution         IN institution.id_institution%TYPE,
        o_institution_barcode OUT institution.barcode%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_barcode IS
            SELECT i.value
              FROM instit_ext_sys i
             WHERE i.id_institution = i_institution
               AND i.id_external_sys = 5;
    BEGIN
        g_error := 'OPEN C_BARCODE';
        OPEN c_barcode;
        FETCH c_barcode
            INTO o_institution_barcode;
        CLOSE c_barcode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_GRID_BARCODE',
                                                     o_error);
    END get_institution_barcode;

    FUNCTION validate_patient_barcode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_barcode    IN VARCHAR2,
        o_summary    OUT VARCHAR2,
        o_result     OUT VARCHAR2,
        o_patient    OUT patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        my_exception EXCEPTION;
        l_patient_barcode episode.barcode%TYPE;
        l_exists          BOOLEAN;
    BEGIN
    
        IF NOT check_exists_barcode(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_barcode => i_barcode,
                                    o_exists  => l_exists,
                                    o_patient => o_patient,
                                    o_error   => o_error)
        THEN
            RAISE my_exception;
        END IF;
    
        IF l_exists
        THEN
        
            SELECT get_pat_barcode(i_lang, i_prof, i_id_episode, cr.id_patient, epis.barcode, cr.num_clin_record)
              INTO l_patient_barcode
              FROM episode epis
              JOIN clin_record cr
                ON cr.id_patient = epis.id_patient
             WHERE epis.id_episode = i_id_episode
               AND cr.id_institution = i_prof.institution
               AND cr.flg_status = pk_alert_constant.g_active;
        
            IF nvl(length(i_barcode), 0) > 0
               AND l_patient_barcode = i_barcode
            THEN
                o_summary := pk_message.get_message(i_lang, g_barcode_message || 'M002');
                o_result  := pk_alert_constant.g_yes;
                RETURN TRUE;
            ELSE
                o_summary := pk_message.get_message(i_lang, g_barcode_message || 'M003');
                o_result  := pk_alert_constant.g_no;
                RETURN TRUE;
            END IF;
        ELSE
            o_summary := pk_message.get_message(i_lang, g_barcode_message || 'M006');
            o_result  := g_result_needs_reason;
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_PATIENT_BARCODE',
                                              o_error    => o_error);
            RETURN FALSE;
    END validate_patient_barcode;

    /********************************************************************************************
    * Gets patient barcode
    *
    * @param i_lang          language id
    * @param i_prof          professional, software and institution ids
    * @param i_episode       episode id                  
    *
    * @return                Patient barcode 
    * 
    * @raises                PL/SQL generic errors "OTHERS"
    *
    * @author                Alexandre Santos
    * @version               v1.0 
    * @since                 2010/09/20
    *********************************************************************************************/
    FUNCTION get_pat_barcode
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_patient              IN patient.id_patient%TYPE DEFAULT NULL,
        i_barcode              IN episode.barcode%TYPE DEFAULT NULL,
        i_num_clin_record      IN clin_record.num_clin_record%TYPE DEFAULT NULL,
        i_val_external_barcode IN sys_config.value%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_val_external_barcode sys_config.value%TYPE;
        l_id_pat               patient.id_patient%TYPE;
        l_ret                  VARCHAR2(100);
        --
        l_error t_error_out;
    
    BEGIN
        g_error := 'GET CFG EXTERNAL BARCODE';
        IF i_val_external_barcode IS NULL
        THEN
            l_val_external_barcode := pk_sysconfig.get_config(i_code_cf => g_cfg_external_barcode, i_prof => i_prof);
        ELSE
            l_val_external_barcode := i_val_external_barcode;
        END IF;
    
        g_error := 'GET BARCODE - ' || l_val_external_barcode;
        IF l_val_external_barcode = g_ext_bar_na
           OR l_val_external_barcode IS NULL
        THEN
            l_ret := i_barcode;
        ELSIF l_val_external_barcode = g_ext_bar_cr
        THEN
            l_ret := i_num_clin_record;
        ELSIF l_val_external_barcode = g_ext_bar_nhs
        THEN
            SELECT t.national_health_number
              INTO l_ret
              FROM (SELECT psa.national_health_number,
                           row_number() over(ORDER BY decode(psa.id_episode, i_episode, 1, 2), decode(psa.id_institution, i_prof.institution, 1, 2)) line_number
                      FROM pat_soc_attributes psa
                     WHERE psa.id_patient = i_patient
                       AND nvl(psa.id_episode, -1) IN (-1, i_episode)
                       AND psa.id_institution IN (0, i_prof.institution)) t
             WHERE t.line_number = 1;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BARCODE',
                                              'GET_PAT_BARCODE',
                                              l_error);
            RETURN '';
    END get_pat_barcode;

    --***********************************************
    FUNCTION get_barcode_cfg_base
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_code_cf IN VARCHAR2
    ) RETURN t_tbl_barcode_type_cfg IS
        tbl_row t_tbl_barcode_type_cfg;
    BEGIN
    
        tbl_row := pk_tech_utils.get_barcode_cfg_base(i_lang => i_lang, i_prof => i_prof, i_code_cf => i_code_cf);
    
        RETURN tbl_row;
    
    END get_barcode_cfg_base;

    --***********************************************
    FUNCTION get_barcode_cfg
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_code_cf IN VARCHAR2
    ) RETURN v_barcode_type_cfg%ROWTYPE IS
        l_row v_barcode_type_cfg%ROWTYPE;
    BEGIN
    
        l_row := pk_tech_utils.get_barcode_cfg(i_lang => i_lang, i_prof => i_prof, i_code_cf => i_code_cf);
    
        RETURN l_row;
    
    END get_barcode_cfg;

BEGIN
    g_epis_active := 'A';
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
