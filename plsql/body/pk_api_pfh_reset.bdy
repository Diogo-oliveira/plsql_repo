/*-- Last Change Revision: $Rev: 2026724 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_reset IS

    FUNCTION reset_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.RESET_LAB_TESTS';
        IF NOT pk_lab_tests_external_api_db.reset_lab_tests(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_patient      => i_patient,
                                                            i_episode      => i_episode,
                                                            io_transaction => io_transaction,
                                                            o_error        => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'RESET_LAB_TESTS',
                                              o_error);
            RETURN FALSE;
    END reset_lab_tests;

    FUNCTION reset_exams
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN table_number,
        i_episode      IN table_number,
        io_transaction IN OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.RESET_EXAMS';
        IF NOT pk_exams_external_api_db.reset_exams(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    i_episode      => i_episode,
                                                    io_transaction => io_transaction,
                                                    o_error        => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'RESET_EXAMS',
                                              o_error);
            RETURN FALSE;
    END reset_exams;

    FUNCTION reset_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.RESET_PROCEDURES';
        IF NOT pk_procedures_external_api_db.reset_procedures(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => i_patient,
                                                              i_episode => i_episode,
                                                              o_error   => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'RESET_PROCEDURES',
                                              o_error);
            RETURN FALSE;
    END reset_procedures;

    FUNCTION reset_bp
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_BP_EXTERNAL_API_DB.RESET_BP';
        IF NOT pk_bp_external_api_db.reset_bp(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => i_patient,
                                              i_episode => i_episode,
                                              o_error   => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'RESET_BP',
                                              o_error);
            RETURN FALSE;
    END reset_bp;

    FUNCTION reset_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_CARE_PLANS_API_DB.RESET_CARE_PLANS';
        IF NOT pk_care_plans_api_db.reset_care_plans(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     i_episode => i_episode,
                                                     o_error   => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'RESET_CARE_PLANS',
                                              o_error);
            RETURN FALSE;
    END reset_care_plans;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_pfh_reset;
/
