/*-- Last Change Revision: $Rev: 1790427 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2017-07-14 16:27:32 +0100 (sex, 14 jul 2017) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_freq_content IS

    /********************************************************************************************
    * Set frequent lab test by complaint
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_compl_lab_test
    (
        i_lang       NUMBER,
        i_operation  VARCHAR,
        i_id_context table_varchar,
        i_id_content table_varchar,
        o_error      OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
        l_analys_samp table_varchar;
    
        aux NUMBER;
    BEGIN
        g_function_name := upper('set_compl_lab_test');
        g_error         := 'begin';
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
                g_error := 'Add';
            
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                
                    SELECT COUNT(*)
                      INTO aux
                      FROM lab_tests_complaint ltc
                     WHERE ltc.id_analysis = l_analys_samp(1)
                       AND ltc.id_complaint = i_id_context(i)
                       AND ltc.id_sample_type = l_analys_samp(2);
                
                    IF aux = 0
                    THEN
                        INSERT INTO lab_tests_complaint
                            (id_analysis, id_complaint, flg_available, id_sample_type)
                        VALUES
                            (l_analys_samp(1), i_id_context(i), g_flg_available, l_analys_samp(2));
                    END IF;
                END LOOP;
            
            ELSIF i_operation = g_operation_r
            THEN
                g_error := 'Remove';
            
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                    DELETE FROM lab_tests_complaint ltc
                     WHERE ltc.id_analysis = l_analys_samp(1)
                       AND ltc.id_sample_type = l_analys_samp(2)
                       AND ltc.id_complaint = i_id_context(i);
                END LOOP;
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove and Add';
                DELETE FROM lab_tests_complaint ltc
                 WHERE ltc.id_complaint = i_id_context(i);
            
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                
                    INSERT INTO lab_tests_complaint
                        (id_analysis, id_complaint, flg_available, id_sample_type)
                    VALUES
                        (l_analys_samp(1), i_id_context(i), g_flg_available, l_analys_samp(2));
                
                END LOOP;
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent img exams   by complaint
     * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_compl_img_exam
    (
        i_lang       NUMBER,
        i_operation  VARCHAR,
        i_id_context table_varchar,
        i_id_content table_varchar,
        o_error      OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_compl_img_exam');
        g_error         := 'begin';
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
                g_error := 'Add';
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT column_value, i_id_context(i), g_flg_available
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_exam = p.column_value
                               AND ec.id_complaint = i_id_context(i));
            
            ELSIF i_operation = g_operation_r
            THEN
                g_error := 'Remove';
                DELETE FROM exam_complaint ec
                 WHERE ec.id_exam IN (SELECT column_value
                                        FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND ec.id_complaint = i_id_context(i);
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove and Add';
                DELETE FROM exam_complaint ec
                 WHERE ec.id_complaint = i_id_context(i)
                   AND EXISTS (SELECT 1
                          FROM exam e
                         WHERE e.id_exam = ec.id_exam
                           AND e.flg_type = 'I');
            
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT column_value, i_id_context(i), g_flg_available
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_exam = p.column_value
                               AND ec.id_complaint = i_id_context(i));
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent other exam by complaint
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_compl_other_exam
    (
        i_lang       NUMBER,
        i_operation  VARCHAR,
        i_id_context table_varchar,
        i_id_content table_varchar,
        o_error      OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_compl_other_exam');
        g_error         := 'begin';
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
                g_error := 'Add';
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT column_value, i_id_context(i), g_flg_available
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_exam = p.column_value
                               AND ec.id_complaint = i_id_context(i));
            
            ELSIF i_operation = g_operation_r
            THEN
                g_error := 'Remove';
                DELETE FROM exam_complaint ec
                 WHERE ec.id_exam IN (SELECT column_value
                                        FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND ec.id_complaint = i_id_context(i);
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove and Add';
                DELETE FROM exam_complaint ec
                 WHERE ec.id_complaint = i_id_context(i)
                   AND EXISTS (SELECT 1
                          FROM exam e
                         WHERE e.id_exam = ec.id_exam
                           AND e.flg_type = 'E');
            
                INSERT INTO exam_complaint
                    (id_exam, id_complaint, flg_available)
                    SELECT column_value, i_id_context(i), g_flg_available
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_complaint ec
                             WHERE ec.id_exam = p.column_value
                               AND ec.id_complaint = i_id_context(i));
            
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent order set by complaint
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_compl_order_set
    (
        i_lang       NUMBER,
        i_operation  VARCHAR,
        i_id_context table_varchar,
        i_id_content table_varchar,
        o_error      OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
        l_os_complaint_link VARCHAR(1) := 'C';
    
    BEGIN
        g_function_name := upper('set_compl_order_set');
        g_error         := 'begin';
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
                g_error := 'Add';
                INSERT INTO order_set_link
                    (id_order_set, id_link, flg_link_type)
                    SELECT column_value, i_id_context(i), l_os_complaint_link
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM order_set_link osl
                             WHERE osl.id_order_set = p.column_value
                               AND osl.flg_link_type = l_os_complaint_link
                               AND osl.id_link = i_id_context(i));
            
            ELSIF i_operation = g_operation_r
            THEN
                g_error := 'Remove';
                DELETE FROM order_set_link osl
                 WHERE osl.id_order_set IN (SELECT column_value
                                              FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND osl.id_link = i_id_context(i)
                   AND osl.flg_link_type = l_os_complaint_link;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove and Add';
                DELETE FROM order_set_link osl
                 WHERE osl.id_link = i_id_context(i)
                   AND osl.flg_link_type = l_os_complaint_link;
            
                INSERT INTO order_set_link
                    (id_order_set, id_link, flg_link_type)
                    SELECT column_value, i_id_context(i), l_os_complaint_link
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM order_set_link osl
                             WHERE osl.id_order_set = p.column_value
                               AND osl.flg_link_type = l_os_complaint_link
                               AND osl.id_link = i_id_context(i));
            
            END IF;
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent imaging exams by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_img_exam
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_img_exam');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv, id_exam, id_dep_clin_serv, flg_type, rank, id_institution, id_software)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_institution,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_exam = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software
                               AND edcs.id_exam_group IS NULL);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam IN (SELECT column_value
                                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software
                   AND edcs.id_exam_group IS NULL;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software
                   AND edcs.id_exam_group IS NULL
                   AND EXISTS (SELECT 1
                          FROM exam e
                         WHERE e.id_exam = edcs.id_exam
                           AND e.flg_type = 'I');
            
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv, id_exam, id_dep_clin_serv, flg_type, rank, id_institution, id_software)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_institution,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_exam = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software
                               AND edcs.id_exam_group IS NULL);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;

    PROCEDURE set_freq_lab_test_group
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_lab_test_group');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO analysis_dep_clin_serv
                    (id_analysis_dep_clin_serv, id_analysis_group, id_dep_clin_serv, rank, id_software)
                    SELECT seq_analysis_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_default_rank,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM analysis_dep_clin_serv adcs
                             WHERE adcs.id_dep_clin_serv = i_id_context(i)
                               AND adcs.id_analysis_group = p.column_value
                               AND adcs.id_software = i_id_software
                               AND adcs.id_analysis IS NULL);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_analysis_group IN
                       (SELECT column_value
                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND adcs.id_dep_clin_serv = i_id_context(i)
                   AND adcs.id_software = i_id_software
                   AND adcs.id_analysis IS NULL;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_dep_clin_serv = i_id_context(i)
                   AND adcs.id_software = i_id_software
                   AND adcs.id_analysis IS NULL;
            
                INSERT INTO analysis_dep_clin_serv
                    (id_analysis_dep_clin_serv, id_analysis_group, id_dep_clin_serv, rank, id_software)
                    SELECT seq_analysis_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_default_rank,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM analysis_dep_clin_serv adcs
                             WHERE adcs.id_dep_clin_serv = i_id_context(i)
                               AND adcs.id_analysis_group = p.column_value
                               AND adcs.id_software = i_id_software
                               AND adcs.id_analysis IS NULL);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent other exams by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_other_exam
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_other_exam');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv, id_exam, id_dep_clin_serv, flg_type, rank, id_institution, id_software)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_institution,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_exam = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software
                               AND edcs.id_exam_group IS NULL);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_exam IN (SELECT column_value
                                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software
                   AND edcs.id_exam_group IS NULL;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM exam_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software
                   AND edcs.id_exam_group IS NULL
                   AND EXISTS (SELECT 1
                          FROM exam e
                         WHERE e.id_exam = edcs.id_exam
                           AND e.flg_type = 'E');
            
                INSERT INTO exam_dep_clin_serv
                    (id_exam_dep_clin_serv, id_exam, id_dep_clin_serv, flg_type, rank, id_institution, id_software)
                    SELECT seq_exam_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_institution,
                           i_id_software
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_exam = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software
                               AND edcs.id_exam_group IS NULL);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent procedures by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_procedures
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_procedures');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     id_software,
                     id_institution)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_software,
                           i_id_institution
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM interv_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_intervention = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM interv_dep_clin_serv edcs
                 WHERE edcs.id_intervention IN
                       (SELECT column_value
                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM interv_dep_clin_serv edcs
                 WHERE edcs.id_dep_clin_serv = i_id_context(i)
                   AND edcs.flg_type = g_freq_var
                   AND edcs.id_software = i_id_software;
            
                INSERT INTO interv_dep_clin_serv
                    (id_interv_dep_clin_serv,
                     id_intervention,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     id_software,
                     id_institution)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_software,
                           i_id_institution
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM interv_dep_clin_serv edcs
                             WHERE edcs.id_dep_clin_serv = i_id_context(i)
                               AND edcs.id_intervention = p.column_value
                               AND edcs.flg_type = g_freq_var
                               AND edcs.id_software = i_id_software);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent diagnosis by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_diagnosis
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_diagnosis');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                FOR z IN 1 .. i_id_content.count
                LOOP
                    IF NOT pk_api_pfh_diagnosis_conf.ins_msi_concept_term(i_institution     => i_id_institution,
                                                                          i_software        => i_id_software,
                                                                          i_concept_version => i_id_content(z),
                                                                          i_concept_term    => NULL,
                                                                          i_dep_clin_serv   => i_id_context(i),
                                                                          i_professional    => 0,
                                                                          i_gender          => NULL,
                                                                          i_age_min         => NULL,
                                                                          i_age_max         => NULL,
                                                                          i_rank            => 0,
                                                                          i_flg_type        => 'M')
                    THEN
                        RAISE l_exception;
                    END IF;
                END LOOP;
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                FOR z IN 1 .. i_id_content.count
                LOOP
                    IF NOT pk_api_pfh_diagnosis_conf.del_msi_concept_term(i_institution     => i_id_institution,
                                                                          i_software        => i_id_software,
                                                                          i_concept_version => i_id_content(z),
                                                                          i_concept_term    => NULL,
                                                                          i_dep_clin_serv   => i_id_context(i),
                                                                          i_professional    => 0,
                                                                          i_flg_type        => 'M',
                                                                          i_flg_delete      => NULL)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END LOOP;
            
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent rehab session type by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_rehab
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_rehab');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO rehab_dep_clin_serv
                    (id_rehab_session_type, id_dep_clin_serv)
                    SELECT column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM rehab_dep_clin_serv rdcs
                             WHERE rdcs.id_dep_clin_serv = i_id_context(i)
                               AND rdcs.id_rehab_session_type = p.column_value);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM rehab_dep_clin_serv rdcs
                 WHERE rdcs.id_rehab_session_type IN
                       (SELECT column_value
                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND rdcs.id_dep_clin_serv = i_id_context(i);
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM rehab_dep_clin_serv rdcs
                 WHERE rdcs.id_dep_clin_serv = i_id_context(i);
            
                INSERT INTO rehab_dep_clin_serv
                    (id_rehab_session_type, id_dep_clin_serv)
                    SELECT column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM rehab_dep_clin_serv rdcs
                             WHERE rdcs.id_dep_clin_serv = i_id_context(i)
                               AND rdcs.id_rehab_session_type = p.column_value);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent body diagram by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_body_diagram
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_body_diagram');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO diag_lay_dep_clin_serv
                    (id_diag_lay_dep_clin_serv,
                     id_diagram_layout,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     id_software,
                     id_institution)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_software,
                           i_id_institution
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM diag_lay_dep_clin_serv dldcs
                             WHERE dldcs.id_dep_clin_serv = i_id_context(i)
                               AND dldcs.id_diagram_layout = p.column_value
                               AND dldcs.flg_type = g_freq_var
                               AND dldcs.id_software = i_id_software
                               AND dldcs.id_institution = i_id_institution);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM diag_lay_dep_clin_serv dldcs
                 WHERE dldcs.id_diagram_layout IN
                       (SELECT column_value
                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND dldcs.id_dep_clin_serv = i_id_context(i)
                   AND dldcs.flg_type = g_freq_var
                   AND dldcs.id_software = i_id_software
                   AND dldcs.id_institution = i_id_institution;
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM diag_lay_dep_clin_serv dldcs
                 WHERE dldcs.id_dep_clin_serv = i_id_context(i)
                   AND dldcs.flg_type = g_freq_var
                   AND dldcs.id_software = i_id_software
                   AND dldcs.id_institution = i_id_institution;
            
                INSERT INTO diag_lay_dep_clin_serv
                    (id_diag_lay_dep_clin_serv,
                     id_diagram_layout,
                     id_dep_clin_serv,
                     flg_type,
                     rank,
                     id_software,
                     id_institution)
                    SELECT seq_interv_dep_clin_serv.nextval,
                           column_value,
                           i_id_context(i),
                           g_freq_var,
                           g_default_rank,
                           i_id_software,
                           i_id_institution
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM diag_lay_dep_clin_serv dldcs
                             WHERE dldcs.id_dep_clin_serv = i_id_context(i)
                               AND dldcs.id_diagram_layout = p.column_value
                               AND dldcs.flg_type = g_freq_var
                               AND dldcs.id_software = i_id_software
                               AND dldcs.id_institution = i_id_institution);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;

    /********************************************************************************************
    * Set frequent exam_cat by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_exam_cat
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_exam_cat');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO exam_cat_dcs
                    (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
                    SELECT seq_exam_cat_dcs.nextval, column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_cat_dcs ecd
                             WHERE ecd.id_dep_clin_serv = i_id_context(i)
                               AND ecd.id_exam_cat = p.column_value);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM exam_cat_dcs ecd
                 WHERE ecd.id_exam_cat IN (SELECT column_value
                                             FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND ecd.id_dep_clin_serv = i_id_context(i);
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM exam_cat_dcs ecd
                 WHERE ecd.id_dep_clin_serv = i_id_context(i);
            
                INSERT INTO exam_cat_dcs
                    (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
                    SELECT seq_exam_cat_dcs.nextval, column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM exam_cat_dcs ecd
                             WHERE ecd.id_dep_clin_serv = i_id_context(i)
                               AND ecd.id_exam_cat = p.column_value);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent lab tests by institution
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_order_set
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_order_set');
    
        IF i_operation = g_operation_a
        THEN
        
            g_error := 'Add';
            INSERT INTO order_set_frequent
                (id_order_set, id_institution, id_software)
                SELECT column_value, i_id_institution, i_id_software
                  FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                 WHERE NOT EXISTS (SELECT 1
                          FROM order_set_frequent osf
                         WHERE osf.id_institution = i_id_institution
                           AND osf.id_software = i_id_software
                           AND osf.id_order_set = p.column_value);
        
        ELSIF i_operation = g_operation_r
        THEN
        
            g_error := 'Remove';
            DELETE FROM order_set_frequent osf
             WHERE osf.id_order_set IN (SELECT column_value
                                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
               AND osf.id_software = i_id_software
               AND osf.id_institution = i_id_institution;
        
        ELSIF i_operation = g_operation_ar
        THEN
            g_error := 'Remove then Add';
            DELETE FROM order_set_frequent osf
             WHERE osf.id_software = i_id_software
               AND osf.id_institution = i_id_institution;
        
            INSERT INTO order_set_frequent
                (id_order_set, id_institution, id_software)
                SELECT column_value, i_id_institution, i_id_software
                  FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                 WHERE NOT EXISTS (SELECT 1
                          FROM order_set_frequent osf
                         WHERE osf.id_institution = i_id_institution
                           AND osf.id_software = i_id_software
                           AND osf.id_order_set = p.column_value);
        END IF;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent sample_text type by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_sample_text
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_sample_text');
    
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
            
                g_error := 'Add';
                INSERT INTO sample_text_freq
                    (id_freq_sample_text, id_sample_text, id_dep_clin_serv)
                    SELECT seq_sample_text_freq.nextval, column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM sample_text_freq stf
                             WHERE stf.id_dep_clin_serv = i_id_context(i)
                               AND stf.id_sample_text = p.column_value);
            
            ELSIF i_operation = g_operation_r
            THEN
            
                g_error := 'Remove';
                DELETE FROM sample_text_freq stf
                 WHERE stf.id_sample_text IN
                       (SELECT column_value
                          FROM TABLE(CAST((i_id_content) AS table_varchar)))
                   AND stf.id_dep_clin_serv = i_id_context(i);
            
            ELSIF i_operation = g_operation_ar
            THEN
                g_error := 'Remove then Add';
                DELETE FROM sample_text_freq stf
                 WHERE stf.id_dep_clin_serv = i_id_context(i);
            
                INSERT INTO sample_text_freq
                    (id_freq_sample_text, id_sample_text, id_dep_clin_serv)
                    SELECT seq_sample_text_freq.nextval, column_value, i_id_context(i)
                      FROM TABLE(CAST((i_id_content) AS table_varchar)) p
                     WHERE NOT EXISTS (SELECT 1
                              FROM sample_text_freq stf
                             WHERE stf.id_dep_clin_serv = i_id_context(i)
                               AND stf.id_sample_text = p.column_value);
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent lab tests by dep clin serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_lab_test
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_analys_samp table_varchar;
        aux           NUMBER;
        l_exception EXCEPTION;
    
    BEGIN
        g_error         := 'begin';
        g_function_name := upper('set_freq_lab_test');
        FOR i IN 1 .. i_id_context.count
        LOOP
        
            IF i_operation = g_operation_a
            THEN
                g_error := 'Add';
            
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                    SELECT COUNT(*)
                      INTO aux
                      FROM analysis_dep_clin_serv adcs
                     WHERE adcs.id_analysis = l_analys_samp(1)
                       AND adcs.id_sample_type = l_analys_samp(2)
                       AND adcs.id_dep_clin_serv = i_id_context(i)
                       AND adcs.id_software = i_id_software
                       AND adcs.id_analysis_group IS NULL;
                
                    IF aux = 0
                    THEN
                        INSERT INTO analysis_dep_clin_serv
                            (id_analysis_dep_clin_serv,
                             id_analysis,
                             id_sample_type,
                             id_dep_clin_serv,
                             rank,
                             id_software,
                             flg_available)
                        VALUES
                            (seq_analysis_dep_clin_serv.nextval,
                             l_analys_samp(1),
                             l_analys_samp(2),
                             i_id_context(i),
                             g_default_rank,
                             i_id_software,
                             g_flg_available);
                        --if it exists and its Y, update to Y, if NOt update to Y
                    
                    END IF;
                END LOOP;
            ELSIF i_operation = g_operation_r
            THEN
                g_error := 'Remove';
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                
                    DELETE FROM analysis_dep_clin_serv adcs
                     WHERE adcs.id_software = i_id_software
                       AND adcs.id_analysis_group IS NULL
                       AND adcs.id_dep_clin_serv = i_id_context(i)
                       AND adcs.id_analysis = l_analys_samp(1)
                       AND adcs.id_sample_type = l_analys_samp(2);
                END LOOP;
            ELSIF i_operation = g_operation_ar
            THEN
            
                g_error := 'Remove then Add';
            
                DELETE FROM analysis_dep_clin_serv adcs
                 WHERE adcs.id_software = i_id_software
                   AND adcs.id_analysis_group IS NULL
                   AND adcs.id_dep_clin_serv = i_id_context(i);
            
                FOR z IN 1 .. i_id_content.count
                LOOP
                    l_analys_samp := pk_utils.str_split_l(i_id_content(z), g_apex_separator);
                
                    INSERT INTO analysis_dep_clin_serv
                        (id_analysis_dep_clin_serv,
                         id_analysis,
                         id_sample_type,
                         id_dep_clin_serv,
                         rank,
                         id_software,
                         flg_available)
                    VALUES
                        (seq_analysis_dep_clin_serv.nextval,
                         l_analys_samp(1),
                         l_analys_samp(2),
                         i_id_context(i),
                         g_default_rank,
                         i_id_software,
                         g_flg_available);
                
                END LOOP;
            END IF;
        
        END LOOP;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END;
    /********************************************************************************************
    * Set frequent content by dep_clin_serv
    * Directs to the type of content its necessary to configure most freq
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_dcs
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_flg_content    VARCHAR,
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
    
        l_exception EXCEPTION;
    BEGIN
        g_function_name := upper('set_freq_dcs');
    
        IF i_flg_content = g_flg_img_exam_condition
        THEN
            g_error := 'set_freq_img_exam';
        
            set_freq_img_exam(i_lang,
                              i_id_institution,
                              i_id_software,
                              i_operation,
                              i_id_context,
                              i_id_content,
                              o_error);
        ELSIF i_flg_content = g_flg_other_exam_condition
        THEN
            g_error := 'set_freq_other_exam';
            set_freq_other_exam(i_lang,
                                i_id_institution,
                                i_id_software,
                                i_operation,
                                i_id_context,
                                i_id_content,
                                o_error);
        
        ELSIF i_flg_content = g_flg_lab_test_condition
        THEN
            g_error := 'set_freq_lab_test';
            set_freq_lab_test(i_lang,
                              i_id_institution,
                              i_id_software,
                              i_operation,
                              i_id_context,
                              i_id_content,
                              o_error);
        ELSIF i_flg_content = g_flg_lab_group_condition
        THEN
            g_error := 'set_freq_lab_test_group';
            set_freq_lab_test_group(i_lang,
                                    i_id_institution,
                                    i_id_software,
                                    i_operation,
                                    i_id_context,
                                    i_id_content,
                                    o_error);
        ELSIF i_flg_content = g_flg_procedures_condition
        THEN
            g_error := 'set_freq_procedures';
            set_freq_procedures(i_lang,
                                i_id_institution,
                                i_id_software,
                                i_operation,
                                i_id_context,
                                i_id_content,
                                o_error);
        ELSIF i_flg_content = g_flg_exam_cat_condition
        THEN
            g_error := 'set_freq_exam_cat';
            set_freq_exam_cat(i_lang,
                              i_id_institution,
                              i_id_software,
                              i_operation,
                              i_id_context,
                              i_id_content,
                              o_error);
        ELSIF i_flg_content = g_flg_body_diagrams_condition
        THEN
            g_error := 'set_freq_body_diagram';
            set_freq_body_diagram(i_lang,
                                  i_id_institution,
                                  i_id_software,
                                  i_operation,
                                  i_id_context,
                                  i_id_content,
                                  o_error);
        ELSIF i_flg_content = g_flg_rehab_condition
        THEN
            g_error := 'set_freq_rehab';
            set_freq_rehab(i_lang, i_id_institution, i_id_software, i_operation, i_id_context, i_id_content, o_error);
        
        ELSIF i_flg_content = g_flg_diag_condition
        THEN
            g_error := 'set_freq_diagnosis';
            set_freq_diagnosis(i_lang,
                               i_id_institution,
                               i_id_software,
                               i_operation,
                               i_id_context,
                               i_id_content,
                               o_error);
        ELSIF i_flg_content = g_flg_sample_text_condition
        THEN
            g_error := 'set_freq_sample_text';
            set_freq_sample_text(i_lang,
                                 i_id_institution,
                                 i_id_software,
                                 i_operation,
                                 i_id_context,
                                 i_id_content,
                                 o_error);
        
        ELSIF i_flg_content = g_flg_order_sets_condition
        THEN
            g_error := 'set_freq_order_set';
            set_freq_order_set(i_lang,
                               i_id_institution,
                               i_id_software,
                               i_operation,
                               i_id_context,
                               i_id_content,
                               o_error);
        
        END IF;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;
    /********************************************************************************************
    * Set frequent content by complaint
    * Directs to the type of content its necessary to configure most freq
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq_complaint
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'N',
        i_flg_content    VARCHAR,
        i_id_context     table_varchar,
        i_id_content     table_varchar,
        o_error          OUT t_error_out
    ) IS
        l_exception EXCEPTION;
    
    BEGIN
        g_function_name := upper('set_freq_complaint');
    
        IF i_flg_content = g_flg_img_exam_condition
        THEN
        
            g_error := 'set_compl_img_exam';
        
            set_compl_img_exam(i_lang, i_operation, i_id_context, i_id_content, o_error);
        ELSIF i_flg_content = g_flg_other_exam_condition
        THEN
            g_error := 'set_compl_other_exam';
            set_compl_other_exam(i_lang, i_operation, i_id_context, i_id_content, o_error);
        ELSIF i_flg_content = g_flg_lab_test_condition
        THEN
            g_error := 'set_compl_lab_test';
            set_compl_lab_test(i_lang, i_operation, i_id_context, i_id_content, o_error);
        
        ELSIF i_flg_content = g_flg_order_sets_condition
        THEN
            g_error := 'set_compl_order_set';
        
            set_compl_order_set(i_lang, i_operation, i_id_context, i_id_content, o_error);
        END IF;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END;

    /********************************************************************************************
    * Set frequent content
    * Directs to a most frequent by complaint or most frequent by dep_clin_serv
    * @author                        JM
    * @version                       2.6.4.2.5
    * @since                         2015/11/25
    ********************************************************************************************/

    PROCEDURE set_freq
    (
        i_lang           VARCHAR,
        i_id_institution VARCHAR,
        i_id_software    VARCHAR,
        i_operation      VARCHAR DEFAULT 'A',
        i_flg_context    VARCHAR,
        i_flg_content    VARCHAR,
        i_id_context     table_varchar,
        i_id_content     table_varchar
    ) IS
    
        l_error t_error_out;
        l_exception EXCEPTION;
    BEGIN
    
        g_function_name := upper('set_freq');
    
        IF i_flg_context = g_dcs
        THEN
        
            g_error := 'set_freq_dcs';
            set_freq_dcs(i_lang,
                         i_id_institution,
                         i_id_software,
                         i_operation,
                         i_flg_content,
                         i_id_context,
                         i_id_content,
                         l_error);
        ELSIF i_flg_context = g_compl
        THEN
        
            g_error := 'set_freq_complaint';
            set_freq_complaint(i_lang,
                               i_id_institution,
                               i_id_software,
                               i_operation,
                               i_flg_content,
                               i_id_context,
                               i_id_content,
                               l_error);
        
        END IF;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_function_name,
                                              l_error);
            pk_alert_exceptions.reset_error_state;
    END set_freq;

    /********************************************************************************************
    * Get   structure available in the institution and  software
    *
    *
    * @author                        JM
    * @version                       2.6.4.4
    * @since                         2014/07/24
    ********************************************************************************************/

    FUNCTION get_inst_structure
    (
        i_lang        IN language.id_language%TYPE,
        i_institution institution.id_institution%TYPE,
        i_software    software.id_software%TYPE
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
    BEGIN
    
        SELECT t_rec_apex_manyfields(res_data.desc_dept,
                                     res_data.id_dept,
                                     res_data.desc_department,
                                     res_data.id_department,
                                     res_data.desc_clinical_service,
                                     res_data.id_clinical_service,
                                     res_data.id_content) BULK COLLECT
          INTO l_tbl_res
          FROM (SELECT pk_translation.get_translation(i_lang, dpt.code_dept) desc_dept,
                       dpt.id_dept,
                       pk_translation.get_translation(i_lang, d.code_department) desc_department,
                       d.id_department,
                       pk_translation.get_translation(i_lang, a.code_clinical_service) desc_clinical_service,
                       a.id_clinical_service,
                       a.id_content
                  FROM clinical_service a
                 INNER JOIN dep_clin_serv c
                    ON c.id_clinical_service = a.id_clinical_service
                 INNER JOIN department d
                    ON d.id_department = c.id_department
                 INNER JOIN software_dept sd
                    ON sd.id_dept = d.id_dept
                 INNER JOIN dept dpt
                    ON dpt.id_dept = d.id_dept
                 WHERE d.id_institution = i_institution
                   AND (sd.id_software = i_software OR i_software IS NULL)) res_data;
        RETURN l_tbl_res;
    
    END get_inst_structure;
    /********************************************************************************************
    * Get display of searchable content available in a specific institution
    * and software
    *
    * @author                        JM
    * @version                       2.6.4.4
    * @since                         2014/07/24
    ********************************************************************************************/

    FUNCTION get_searchable_content
    (
        i_lang        IN language.id_language%TYPE,
        i_institution institution.id_institution%TYPE,
        i_software    software.id_software%TYPE,
        i_context     VARCHAR,
        i_flg_context VARCHAR,
        i_flg_content VARCHAR
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_context table_varchar;
    
        l_context_clinical_service VARCHAR(1) := 'D';
        l_context_complaint        VARCHAR(1) := 'D';
    
        l_flg_img_exam_condition      VARCHAR(1) := 'I';
        l_flg_other_exam_condition    VARCHAR(1) := 'O';
        l_flg_lab_test_condition      VARCHAR(1) := 'A';
        l_flg_procedures_condition    VARCHAR(1) := 'P';
        l_flg_sr_procedures_condition VARCHAR(2) := 'SP';
        l_flg_exam_cat_condition      VARCHAR(2) := 'EC';
        l_flg_body_diagrams_condition VARCHAR(2) := 'BD';
        l_flg_rehab_condition         VARCHAR(1) := 'R';
        l_flg_sample_text_condition   VARCHAR(2) := 'ST';
        l_flg_order_sets_condition    VARCHAR(2) := 'OS';
        l_flg_lab_group_condition     VARCHAR(2) := 'AG';
    
        l_diag_def      VARCHAR(1) := 'D';
        l_diag_search   VARCHAR(1) := 'P';
        l_flg_freq      VARCHAR(1) := 'M';
        l_software_oris NUMBER := 2;
    
        l_flg_img_exam   VARCHAR(1) := 'I';
        l_flg_other_exam VARCHAR(1) := 'E';
    
        l_flg_diag_condition VARCHAR(1) := 'D';
    
        l_flg_search VARCHAR(1) := 'P';
        o_diag_res   t_coll_diagnosis_config;
    
        l_diag_task        NUMBER := 63;
        l_menus_one        NUMBER := -1;
        l_zero             NUMBER := 0;
        l_order_set_temp   VARCHAR(1) := 'T';
        l_order_set_finish VARCHAR(1) := 'F';
        l_room_tube        VARCHAR(1) := 'T';
    BEGIN
        SELECT column_value BULK COLLECT
          INTO l_context
          FROM TABLE(CAST((pk_utils.str_split_l(i_context, ':')) AS table_varchar)) p;
    
        IF i_flg_content = l_flg_img_exam_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                           e.id_exam id_alert,
                           e.id_content id_content,
                           NULL item1,
                           NULL item2,
                           NULL item3,
                           NULL item4
                      FROM exam e, exam_dep_clin_serv edcs, exam_room er
                     INNER JOIN room r
                        ON r.id_room = er.id_room
                     INNER JOIN department d
                        ON d.id_department = r.id_department
                     WHERE edcs.id_institution = i_institution
                       AND edcs.id_software = i_software
                       AND e.flg_type = l_flg_img_exam
                       AND e.id_exam = edcs.id_exam
                       AND edcs.flg_type = l_flg_search
                       AND e.flg_available = g_flg_available
                       AND er.id_exam = e.id_exam
                       AND d.id_institution = edcs.id_institution
                       AND r.flg_available = g_flg_available
                       AND d.flg_available = g_flg_available
                       AND er.flg_available = g_flg_available
                     GROUP BY e.code_exam, e.id_exam, e.id_content) res_data;
            RETURN l_tbl_res;
        ELSIF i_flg_content = l_flg_sample_text_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.desc_context,
                                         res_data.id_context,
                                         res_data.id_dep_clin_serv,
                                         res_data.id_content_context) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                           cs.id_clinical_service AS id_context,
                           dcs.id_dep_clin_serv,
                           cs.id_content AS id_content_context,
                           stt.intern_name_sample_text_type || ' - ' ||
                           pk_translation.get_translation(i_lang, st.code_title_sample_text) AS desc_content,
                           st.id_sample_text id_alert,
                           st.id_content id_content
                      FROM sample_text_freq stf
                     INNER JOIN sample_text st
                        ON st.id_sample_text = stf.id_sample_text
                     INNER JOIN sample_text_type stt
                        ON stt.id_sample_text_type = st.id_sample_text_type
                     INNER JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = stf.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                     INNER JOIN department d
                        ON d.id_department = dcs.id_department
                     WHERE dcs.flg_available = g_flg_available
                       AND cs.flg_available = g_flg_available
                       AND d.flg_available = g_flg_available
                       AND d.id_institution = i_institution
                       AND stt.id_software IN (i_software, 0)
                       AND stt.flg_available = g_flg_available
                       AND st.flg_available = g_flg_available) res_data;
            RETURN l_tbl_res;
        ELSIF i_flg_content = l_flg_rehab_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.desc_context,
                                         res_data.id_context,
                                         res_data.id_dep_clin_serv,
                                         res_data.id_content_context) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                           cs.id_clinical_service AS id_context,
                           dcs.id_dep_clin_serv,
                           cs.id_content AS id_content_context,
                           pk_translation.get_translation(i_lang, rst.code_rehab_session_type) AS desc_content,
                           rst.id_rehab_session_type id_alert,
                           rst.id_content id_content
                    
                      FROM rehab_dep_clin_serv rdcs
                     INNER JOIN rehab_session_type rst
                        ON rdcs.id_rehab_session_type = rst.id_rehab_session_type
                     INNER JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = rdcs.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                     INNER JOIN department d
                        ON d.id_department = dcs.id_department
                     WHERE dcs.flg_available = g_flg_available
                       AND cs.flg_available = g_flg_available
                       AND d.flg_available = g_flg_available
                          
                       AND d.id_institution = i_institution
                    
                    ) res_data;
            RETURN l_tbl_res;
        ELSIF i_flg_content = l_flg_exam_cat_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.desc_context,
                                         res_data.id_context,
                                         res_data.id_dep_clin_serv,
                                         res_data.id_content_context) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                           cs.id_clinical_service AS id_context,
                           dcs.id_dep_clin_serv,
                           cs.id_content AS id_content_context,
                           pk_translation.get_translation(i_lang, ec.code_exam_cat) AS desc_content,
                           ec.id_exam_cat id_alert,
                           ec.id_content id_content
                    
                      FROM exam_cat_dcs ecd
                     INNER JOIN exam_cat ec
                        ON ec.id_exam_cat = ecd.id_exam_cat
                     INNER JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                    
                     INNER JOIN department d
                        ON d.id_department = dcs.id_department
                     WHERE dcs.flg_available = g_flg_available
                       AND cs.flg_available = g_flg_available
                       AND d.flg_available = g_flg_available
                          
                       AND d.id_institution = i_institution
                       AND ec.flg_available = g_flg_available
                    
                    ) res_data;
        
            RETURN l_tbl_res;
        ELSIF i_flg_content = l_flg_body_diagrams_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.desc_context,
                                         res_data.id_context,
                                         res_data.id_dep_clin_serv,
                                         res_data.id_content_context) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                           cs.id_clinical_service AS id_context,
                           dcs.id_dep_clin_serv,
                           cs.id_content AS id_content_context,
                           pk_translation.get_translation(i_lang, dl.code_diagram_layout) AS desc_content,
                           dl.id_diagram_layout id_alert,
                           NULL id_content
                    
                      FROM diag_lay_dep_clin_serv dldcs
                     INNER JOIN diagram_layout dl
                        ON dl.id_diagram_layout = dldcs.id_diagram_layout
                     INNER JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = dldcs.id_dep_clin_serv
                     INNER JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                     WHERE dldcs.id_institution = i_institution
                       AND dldcs.id_software = i_software
                       AND dl.flg_available = g_flg_available
                       AND dldcs.flg_type IN (l_diag_def, l_diag_search)
                       AND dldcs.id_dep_clin_serv IN (SELECT column_value
                                                        FROM TABLE(l_context))
                    
                    ) res_data;
            RETURN l_tbl_res;
        
        ELSIF i_flg_content = l_flg_other_exam_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                           e.id_exam id_alert,
                           e.id_content id_content,
                           NULL item1,
                           NULL item2,
                           NULL item3,
                           NULL item4
                      FROM exam e, exam_dep_clin_serv edcs
                     WHERE e.flg_available = g_flg_available
                       AND edcs.id_institution = i_institution
                       AND edcs.id_software = i_software
                       AND e.flg_type = l_flg_other_exam
                       AND e.id_exam = edcs.id_exam
                       AND edcs.flg_type = l_flg_search) res_data;
            RETURN l_tbl_res;
        
        ELSIF i_flg_content = l_flg_diag_condition
        THEN
        
            o_diag_res := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                  i_prof                     => profissional(l_zero,
                                                                                                             i_institution,
                                                                                                             i_software),
                                                                  i_patient                  => l_menus_one,
                                                                  i_terminologies_task_types => table_number(l_diag_task),
                                                                  i_term_task_type           => l_diag_task,
                                                                  i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                  i_text_search              => NULL,
                                                                  i_include_other_diagnosis  => pk_alert_constant.g_no,
                                                                  i_synonym_list_enable      => g_flg_available,
                                                                  i_synonym_search_enable    => g_flg_available,
                                                                  i_row_limit                => NULL);
        
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT desc_diagnosis     desc_content,
                           id_diagnosis       id_alert,
                           code_icd           id_content,
                           id_alert_diagnosis item1,
                           flg_terminology    item2,
                           NULL               item3,
                           NULL               item4
                      FROM TABLE(o_diag_res)) res_data;
            RETURN l_tbl_res;
        
        ELSIF i_flg_content = l_flg_procedures_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, i.code_intervention) AS desc_content,
                           i.id_intervention id_alert,
                           i.id_content id_content,
                           NULL item1,
                           NULL item2,
                           NULL item3,
                           NULL item4
                      FROM intervention i, interv_dep_clin_serv idcs
                     WHERE i.flg_status = g_active
                       AND i.id_intervention = idcs.id_intervention
                       AND idcs.id_institution = i_institution
                       AND idcs.id_software = i_software
                       AND idcs.flg_type = l_flg_search) res_data;
            RETURN l_tbl_res;
        ELSIF i_flg_content = l_flg_lab_test_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, a.code_analysis) || '-' ||
                           pk_translation.get_translation(i_lang, st.code_sample_type) AS desc_content,
                           ast.id_analysis || '-' || ast.id_sample_type id_alert,
                           ast.id_content id_content,
                           NULL item1,
                           NULL item2,
                           NULL item3,
                           NULL item4
                      FROM analysis_sample_type ast
                     INNER JOIN analysis a
                        ON a.id_analysis = ast.id_analysis
                     INNER JOIN sample_type st
                        ON st.id_sample_type = ast.id_sample_type
                     WHERE st.flg_available = g_flg_available
                       AND a.flg_available = g_flg_available
                       AND ast.flg_available = g_flg_available
                       AND EXISTS
                     (SELECT 1
                              FROM analysis_instit_soft ais
                             INNER JOIN analysis_param p
                                ON ais.id_institution = p.id_institution
                               AND ais.id_software = p.id_software
                               AND ais.id_analysis = p.id_analysis
                               AND ais.id_sample_type = p.id_sample_type
                             INNER JOIN analysis_parameter app
                                ON app.id_analysis_parameter = p.id_analysis_parameter
                             INNER JOIN exam_cat ec
                                ON ec.id_exam_cat = ais.id_exam_cat
                             WHERE ais.id_analysis = ast.id_analysis
                               AND ais.id_sample_type = ast.id_sample_type
                               AND app.flg_available = g_flg_available
                               AND ec.flg_available = g_flg_available
                               AND ais.id_institution = i_institution
                               AND ais.id_software = i_software
                               AND ais.flg_available = g_flg_available
                               AND p.flg_available = g_flg_available
                               AND ais.flg_type = l_flg_search
                               AND EXISTS (SELECT 1
                                      FROM analysis_instit_recipient air
                                     WHERE air.id_analysis_instit_soft = ais.id_analysis_instit_soft)
                               AND EXISTS (SELECT 1
                                      FROM analysis_room ar
                                     INNER JOIN room r
                                        ON r.id_room = ar.id_room
                                     WHERE ar.id_analysis = ais.id_analysis
                                       AND r.flg_available = g_flg_available
                                       AND ar.flg_type = l_room_tube
                                       AND ar.flg_default = g_flg_available
                                       AND ar.id_institution = ais.id_institution
                                       AND ar.id_sample_type = ais.id_sample_type
                                       AND ar.flg_available = g_flg_available
                                       AND r.id_department IN
                                           (SELECT d.id_department
                                              FROM department d
                                             WHERE d.id_institution = ais.id_institution
                                               AND d.flg_available = g_flg_available)))) res_data;
            RETURN l_tbl_res;
        
        ELSIF i_flg_content = l_flg_lab_group_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT pk_translation.get_translation(i_lang, ag.code_analysis_group) AS desc_content,
                           ag.id_analysis_group id_alert,
                           ag.id_content id_content,
                           NULL item1,
                           NULL item2,
                           NULL item3,
                           NULL item4
                      FROM analysis_group ag
                     WHERE ag.flg_available = g_flg_available
                       AND EXISTS (SELECT 1
                              FROM analysis_instit_soft ais
                             INNER JOIN analysis_agp agp
                                ON agp.id_analysis_group = ais.id_analysis_group
                             INNER JOIN analysis_sample_type a
                                ON a.id_analysis = agp.id_analysis
                             WHERE ag.id_analysis_group = ais.id_analysis_group
                               AND ais.id_institution = i_institution
                               AND ais.id_software = i_software
                               AND ais.flg_available = g_flg_available
                               AND ais.flg_type = l_flg_search)) res_data;
            RETURN l_tbl_res;
        
        ELSIF i_flg_content = l_flg_order_sets_condition
        THEN
            SELECT t_rec_apex_manyfields(res_data.desc_content,
                                         res_data.id_alert,
                                         res_data.id_content,
                                         res_data.item1,
                                         res_data.item2,
                                         res_data.item3,
                                         res_data.item4) BULK COLLECT
              INTO l_tbl_res
              FROM (SELECT os.title        AS desc_content,
                           os.id_order_set id_alert,
                           os.id_content   id_content,
                           NULL            item1,
                           NULL            item2,
                           NULL            item3,
                           NULL            item4
                      FROM order_set os
                     WHERE os.flg_status IN (l_order_set_temp, l_order_set_finish)
                       AND os.id_institution = i_institution) res_data;
        
            RETURN l_tbl_res;
        END IF;
    
    END get_searchable_content;
    /********************************************************************************************
    * Get display of most freq content available in a specific institution
    * , software and dep_clin_serv
    *
    * @author                        JM
    * @version                       2.6.4.4
    * @since                         2014/07/24
    ********************************************************************************************/

    FUNCTION get_most_freq_content
    (
        i_lang        IN language.id_language%TYPE,
        i_institution institution.id_institution%TYPE,
        i_software    software.id_software%TYPE,
        i_context     VARCHAR,
        i_flg_context VARCHAR,
        i_flg_content VARCHAR
    ) RETURN t_tbl_apex_manyfields IS
        l_tbl_res t_tbl_apex_manyfields := t_tbl_apex_manyfields();
        l_context table_varchar;
    
        l_context_clinical_service VARCHAR(1) := 'D';
        l_context_complaint        VARCHAR(1) := 'C';
        l_os_complaint_link        VARCHAR(1) := 'C';
    
        l_flg_img_exam                VARCHAR(1) := 'I';
        l_flg_other_exam              VARCHAR(1) := 'E';
        l_flg_img_exam_condition      VARCHAR(1) := 'I';
        l_flg_other_exam_condition    VARCHAR(1) := 'O';
        l_flg_lab_test_condition      VARCHAR(1) := 'A';
        l_flg_procedures_condition    VARCHAR(1) := 'P';
        l_flg_sr_procedures_condition VARCHAR(2) := 'SP';
        l_flg_exam_cat_condition      VARCHAR(2) := 'EC';
        l_flg_body_diagrams_condition VARCHAR(2) := 'BD';
        l_flg_rehab_condition         VARCHAR(1) := 'R';
        l_flg_sample_text_condition   VARCHAR(2) := 'ST';
        l_flg_order_sets_condition    VARCHAR(2) := 'OS';
    
        l_flg_lab_group_condition VARCHAR(2) := 'AG';
        l_flg_diag_condition      VARCHAR(1) := 'D';
    
        l_flg_freq   VARCHAR(1) := 'M';
        l_flg_search VARCHAR(1) := 'P';
    
        l_order_set_temp   VARCHAR(1) := 'T';
        l_order_set_finish VARCHAR(1) := 'F';
        l_software_oris    NUMBER := 2;
        l_room_tube        VARCHAR(1) := 'T';
    BEGIN
    
        SELECT column_value BULK COLLECT
          INTO l_context
          FROM TABLE(CAST((pk_utils.str_split_l(i_context, ':')) AS table_varchar)) p;
    
        IF i_flg_context = l_context_clinical_service
        THEN
        
            IF i_flg_content = l_flg_img_exam_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                                cs.id_clinical_service AS id_context,
                                dcs.id_dep_clin_serv,
                                cs.id_content AS id_content_context,
                                pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                                e.id_exam id_alert,
                                e.id_content id_content
                         
                           FROM exam_dep_clin_serv edcs
                          INNER JOIN exam e
                             ON e.id_exam = edcs.id_exam
                          INNER JOIN dep_clin_serv dcs
                             ON dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                          INNER JOIN clinical_service cs
                             ON cs.id_clinical_service = dcs.id_clinical_service
                          WHERE /* edcs.id_institution = i_institution
                                                                                      and*/
                          edcs.id_software = i_software
                       AND e.flg_type = l_flg_img_exam
                       AND edcs.id_dep_clin_serv IN (SELECT column_value
                                                      FROM TABLE(l_context))
                       AND e.flg_available = g_flg_available
                       AND edcs.flg_type = l_flg_freq
                         /*   AND EXISTS
                         (select 1
                                  from exam_dep_clin_serv edcs1
                                 where edcs1.id_exam = edcs.id_exam
                                   and edcs1.id_institution = edcs.id_institution
                                   and edcs1.id_software = edcs.id_software
                                   and edcs1.flg_type = l_flg_search)*/
                         ) res_data;
                RETURN l_tbl_res;
            ELSIF i_flg_content = l_flg_other_exam_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                                cs.id_clinical_service AS id_context,
                                dcs.id_dep_clin_serv,
                                cs.id_content AS id_content_context,
                                pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                                e.id_exam id_alert,
                                e.id_content id_content
                         
                           FROM exam_dep_clin_serv edcs
                          INNER JOIN exam e
                             ON e.id_exam = edcs.id_exam
                          INNER JOIN dep_clin_serv dcs
                             ON dcs.id_dep_clin_serv = edcs.id_dep_clin_serv
                          INNER JOIN clinical_service cs
                             ON cs.id_clinical_service = dcs.id_clinical_service
                          WHERE /*edcs.id_institution = i_institution
                                                                                      and */
                          edcs.id_software = i_software
                       AND e.flg_type = l_flg_other_exam
                       AND edcs.id_dep_clin_serv IN (SELECT column_value
                                                      FROM TABLE(l_context))
                       AND e.flg_available = g_flg_available
                       AND edcs.flg_type = l_flg_freq
                         /*     AND EXISTS
                         (select 1
                                  from exam_dep_clin_serv edcs1
                                 where edcs1.id_exam = edcs.id_exam
                                   and edcs1.id_institution = edcs.id_institution
                                   and edcs1.id_software = edcs.id_software
                                   and edcs1.flg_type = l_flg_search)*/
                         ) res_data;
                RETURN l_tbl_res;
            ELSIF i_flg_content = l_flg_procedures_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, i.code_intervention) AS desc_content,
                               i.id_intervention id_alert,
                               i.id_content id_content
                          FROM interv_dep_clin_serv idcs
                         INNER JOIN intervention i
                            ON i.id_intervention = idcs.id_intervention
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = idcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE idcs.id_software = i_software
                           AND idcs.id_dep_clin_serv IN (SELECT column_value
                                                           FROM TABLE(l_context))
                           AND i.flg_status = g_active
                           AND idcs.flg_type = l_flg_freq
                           AND EXISTS (SELECT 1
                                  FROM interv_dep_clin_serv idcs1
                                 WHERE idcs1.id_intervention = idcs.id_intervention
                                   AND idcs1.id_institution = i_institution
                                   AND idcs1.id_software = idcs.id_software
                                   AND idcs1.flg_type = l_flg_search)) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_sample_text_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               stt.intern_name_sample_text_type || ' - ' ||
                               pk_translation.get_translation(i_lang, st.code_title_sample_text) AS desc_content,
                               st.id_sample_text id_alert,
                               st.id_content id_content
                          FROM sample_text_freq stf
                         INNER JOIN sample_text st
                            ON st.id_sample_text = stf.id_sample_text
                         INNER JOIN sample_text_type stt
                            ON stt.id_sample_text_type = st.id_sample_text_type
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = stf.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE stf.id_dep_clin_serv IN (SELECT column_value
                                                          FROM TABLE(l_context))
                           AND stt.id_software IN (i_software, 0)
                           AND stt.flg_available = g_flg_available
                              
                           AND st.flg_available = g_flg_available) res_data;
                RETURN l_tbl_res;
            ELSIF i_flg_content = l_flg_body_diagrams_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, dl.code_diagram_layout) AS desc_content,
                               dl.id_diagram_layout id_alert,
                               NULL id_content
                        
                          FROM diag_lay_dep_clin_serv dldcs
                         INNER JOIN diagram_layout dl
                            ON dl.id_diagram_layout = dldcs.id_diagram_layout
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = dldcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE dldcs.id_institution = i_institution
                           AND dldcs.id_software = i_software
                           AND dl.flg_available = g_flg_available
                           AND dldcs.flg_type = l_flg_freq
                           AND dldcs.id_dep_clin_serv IN (SELECT column_value
                                                            FROM TABLE(l_context))
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_order_sets_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.item1,
                                             res_data.item2,
                                             res_data.item3,
                                             res_data.item4
                                             
                                             ) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT NULL            item1,
                               NULL            item2,
                               NULL            item3,
                               NULL            item4,
                               os.title        AS desc_content,
                               os.id_order_set id_alert,
                               os.id_content   id_content
                        
                          FROM order_set_frequent osf
                         INNER JOIN order_set os
                            ON os.id_order_set = osf.id_order_set
                         WHERE osf.id_software = i_software
                           AND os.flg_status IN (l_order_set_temp, l_order_set_finish)
                           AND osf.id_institution = i_institution
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_exam_cat_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, ec.code_exam_cat) AS desc_content,
                               ec.id_exam_cat id_alert,
                               ec.id_content id_content
                        
                          FROM exam_cat_dcs ecd
                         INNER JOIN exam_cat ec
                            ON ec.id_exam_cat = ecd.id_exam_cat
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = ecd.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE ec.flg_available = g_flg_available
                           AND ecd.id_dep_clin_serv IN (SELECT column_value
                                                          FROM TABLE(l_context))
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_rehab_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, rst.code_rehab_session_type) AS desc_content,
                               rst.id_rehab_session_type id_alert,
                               rst.id_content id_content
                        
                          FROM rehab_dep_clin_serv rdcs
                         INNER JOIN rehab_session_type rst
                            ON rdcs.id_rehab_session_type = rst.id_rehab_session_type
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = rdcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE rdcs.id_dep_clin_serv IN (SELECT column_value
                                                           FROM TABLE(l_context))
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_lab_test_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, a.code_analysis) || '-' ||
                               pk_translation.get_translation(i_lang, st.code_sample_type) AS desc_content,
                               ast.id_analysis || '-' || ast.id_sample_type id_alert,
                               ast.id_content id_content
                        
                          FROM analysis_dep_clin_serv adcs
                         INNER JOIN analysis_sample_type ast
                            ON ast.id_analysis = adcs.id_analysis
                           AND ast.id_sample_type = adcs.id_sample_type
                         INNER JOIN analysis a
                            ON a.id_analysis = ast.id_analysis
                         INNER JOIN sample_type st
                            ON st.id_sample_type = ast.id_sample_type
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE ast.flg_available = g_flg_available
                           AND adcs.flg_available = g_flg_available
                           AND a.flg_available = g_flg_available
                           AND st.flg_available = g_flg_available
                           AND dcs.flg_available = g_flg_available
                           AND cs.flg_available = g_flg_available
                           AND adcs.id_dep_clin_serv IN (SELECT column_value
                                                           FROM TABLE(l_context))
                           AND EXISTS
                         (SELECT 1
                                  FROM analysis_instit_soft ais
                                 INNER JOIN analysis_param p
                                    ON ais.id_institution = p.id_institution
                                   AND ais.id_software = p.id_software
                                   AND ais.id_analysis = p.id_analysis
                                   AND ais.id_sample_type = p.id_sample_type
                                 INNER JOIN analysis_parameter app
                                    ON app.id_analysis_parameter = p.id_analysis_parameter
                                 INNER JOIN exam_cat ec
                                    ON ec.id_exam_cat = ais.id_exam_cat
                                 WHERE ais.id_analysis = ast.id_analysis
                                   AND ais.id_sample_type = ast.id_sample_type
                                   AND app.flg_available = g_flg_available
                                   AND ec.flg_available = g_flg_available
                                   AND ais.id_institution = i_institution
                                   AND ais.id_software = i_software
                                   AND ais.flg_available = g_flg_available
                                   AND p.flg_available = g_flg_available
                                   AND ais.flg_type = l_flg_search
                                   AND EXISTS (SELECT 1
                                          FROM analysis_instit_recipient air
                                         WHERE air.id_analysis_instit_soft = ais.id_analysis_instit_soft)
                                   AND EXISTS (SELECT 1
                                          FROM analysis_room ar
                                         INNER JOIN room r
                                            ON r.id_room = ar.id_room
                                         WHERE ar.id_analysis = ais.id_analysis
                                           AND r.flg_available = g_flg_available
                                           AND ar.flg_type = l_room_tube
                                           AND ar.flg_default = g_flg_available
                                           AND ar.id_institution = ais.id_institution
                                           AND ar.id_sample_type = ais.id_sample_type
                                           AND ar.flg_available = g_flg_available
                                           AND r.id_department IN
                                               (SELECT d.id_department
                                                  FROM department d
                                                 WHERE d.id_institution = ais.id_institution
                                                   AND d.flg_available = g_flg_available)))
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_lab_group_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) AS desc_context,
                               cs.id_clinical_service AS id_context,
                               dcs.id_dep_clin_serv,
                               cs.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, ag.code_analysis_group) AS desc_content,
                               ag.id_analysis_group id_alert,
                               ag.id_content id_content
                        
                          FROM analysis_dep_clin_serv adcs
                         INNER JOIN analysis_group ag
                            ON ag.id_analysis_group = adcs.id_analysis_group
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = adcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE adcs.flg_available = g_flg_available
                           AND dcs.flg_available = g_flg_available
                           AND ag.flg_available = g_flg_available
                           AND cs.flg_available = g_flg_available
                           AND adcs.id_dep_clin_serv IN (SELECT column_value
                                                           FROM TABLE(l_context))
                           AND EXISTS (SELECT 1
                                  FROM analysis_agp agp
                                 INNER JOIN analysis_sample_type ast
                                    ON ast.id_analysis = agp.id_analysis
                                   AND ast.id_sample_type = agp.id_sample_type
                                 INNER JOIN analysis a
                                    ON a.id_analysis = ast.id_analysis
                                 INNER JOIN sample_type st
                                    ON st.id_sample_type = ast.id_sample_type
                                 WHERE agp.id_analysis_group = ag.id_analysis_group
                                   AND a.flg_available = g_flg_available
                                   AND ast.flg_available = g_flg_available
                                   AND st.flg_available = g_flg_available
                                
                                )
                           AND EXISTS (SELECT 1
                                  FROM analysis_instit_soft ais
                                 WHERE ais.id_analysis_group = ag.id_analysis_group
                                   AND ais.id_institution = i_institution
                                   AND ais.id_software = i_software
                                   AND ais.flg_available = g_flg_available
                                   AND ais.flg_type = l_flg_search)
                        
                        ) res_data;
                RETURN l_tbl_res;
            
            END IF;
        ELSIF i_flg_context = l_context_complaint
        THEN
        
            IF i_flg_content = l_flg_lab_test_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, c.code_complaint) AS desc_context,
                               c.id_complaint AS id_context,
                               NULL id_dep_clin_serv,
                               c.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, a.code_analysis) || '-' ||
                               pk_translation.get_translation(i_lang, st.code_sample_type) AS desc_content,
                               ast.id_analysis || '-' || ast.id_sample_type id_alert,
                               ast.id_content id_content
                        
                          FROM lab_tests_complaint ltc
                         INNER JOIN analysis_sample_type ast
                            ON ast.id_analysis = ltc.id_analysis
                           AND ast.id_sample_type = ltc.id_sample_type
                         INNER JOIN analysis a
                            ON a.id_analysis = ast.id_analysis
                         INNER JOIN sample_type st
                            ON st.id_sample_type = ast.id_sample_type
                         INNER JOIN complaint c
                            ON c.id_complaint = ltc.id_complaint
                         WHERE ast.flg_available = g_flg_available
                           AND ltc.flg_available = g_flg_available
                           AND a.flg_available = g_flg_available
                           AND st.flg_available = g_flg_available
                           AND c.flg_available = g_flg_available
                           AND ltc.id_complaint IN (SELECT column_value
                                                      FROM TABLE(l_context))
                           AND EXISTS
                         (SELECT 1
                                  FROM analysis_instit_soft ais
                                 INNER JOIN analysis_param p
                                    ON ais.id_institution = p.id_institution
                                   AND ais.id_software = p.id_software
                                   AND ais.id_analysis = p.id_analysis
                                   AND ais.id_sample_type = p.id_sample_type
                                 INNER JOIN analysis_parameter app
                                    ON app.id_analysis_parameter = p.id_analysis_parameter
                                 INNER JOIN exam_cat ec
                                    ON ec.id_exam_cat = ais.id_exam_cat
                                 WHERE ais.id_analysis = ast.id_analysis
                                   AND ais.id_sample_type = ast.id_sample_type
                                   AND app.flg_available = g_flg_available
                                   AND ec.flg_available = g_flg_available
                                   AND ais.id_institution = i_institution
                                   AND ais.id_software = i_software
                                   AND ais.flg_available = g_flg_available
                                   AND p.flg_available = g_flg_available
                                   AND ais.flg_type = l_flg_search
                                   AND EXISTS (SELECT 1
                                          FROM analysis_instit_recipient air
                                         WHERE air.id_analysis_instit_soft = ais.id_analysis_instit_soft)
                                   AND EXISTS (SELECT 1
                                          FROM analysis_room ar
                                         INNER JOIN room r
                                            ON r.id_room = ar.id_room
                                         WHERE ar.id_analysis = ais.id_analysis
                                           AND r.flg_available = g_flg_available
                                           AND ar.flg_type = l_room_tube
                                           AND ar.flg_default = g_flg_available
                                           AND ar.id_institution = ais.id_institution
                                           AND ar.id_sample_type = ais.id_sample_type
                                           AND ar.flg_available = g_flg_available
                                           AND r.id_department IN
                                               (SELECT d.id_department
                                                  FROM department d
                                                 WHERE d.id_institution = ais.id_institution
                                                   AND d.flg_available = g_flg_available)))
                        
                        ) res_data;
                RETURN l_tbl_res;
            ELSIF i_flg_content = l_flg_order_sets_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, c.code_complaint) AS desc_context,
                               c.id_complaint AS id_context,
                               NULL id_dep_clin_serv,
                               c.id_content AS id_content_context,
                               os.title AS desc_content,
                               os.id_order_set id_alert,
                               os.id_content id_content
                          FROM order_set_link osl
                         INNER JOIN order_set os
                            ON os.id_order_set = os.id_order_set
                         INNER JOIN complaint c
                            ON c.id_complaint = osl.id_link
                         WHERE os.flg_status IN (l_order_set_finish, l_order_set_temp)
                           AND osl.flg_link_type = l_os_complaint_link
                           AND c.id_complaint IN (SELECT column_value
                                                    FROM TABLE(l_context))
                           AND os.id_institution = i_institution) res_data;
                RETURN l_tbl_res;
            
            ELSIF i_flg_content = l_flg_img_exam_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, c.code_complaint) AS desc_context,
                               c.id_complaint AS id_context,
                               NULL id_dep_clin_serv,
                               c.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                               e.id_exam id_alert,
                               e.id_content id_content
                        
                          FROM exam_complaint ec
                         INNER JOIN exam e
                            ON e.id_exam = ec.id_exam
                         INNER JOIN complaint c
                            ON c.id_complaint = ec.id_complaint
                         WHERE e.flg_type = l_flg_img_exam
                           AND ec.flg_available = g_flg_available
                           AND ec.id_complaint IN (SELECT column_value
                                                     FROM TABLE(l_context))
                           AND e.flg_available = g_flg_available
                           AND EXISTS (SELECT 1
                                  FROM exam_dep_clin_serv edcs
                                 WHERE edcs.id_exam = e.id_exam
                                   AND edcs.id_institution = i_institution
                                   AND edcs.id_software = i_software
                                   AND edcs.flg_type = l_flg_search)) res_data;
                RETURN l_tbl_res;
            ELSIF i_flg_content = l_flg_other_exam_condition
            THEN
                SELECT t_rec_apex_manyfields(res_data.desc_content,
                                             res_data.id_alert,
                                             res_data.id_content,
                                             res_data.desc_context,
                                             res_data.id_context,
                                             res_data.id_dep_clin_serv,
                                             res_data.id_content_context) BULK COLLECT
                  INTO l_tbl_res
                  FROM (SELECT pk_translation.get_translation(i_lang, c.code_complaint) AS desc_context,
                               c.id_complaint AS id_context,
                               NULL id_dep_clin_serv,
                               c.id_content AS id_content_context,
                               pk_translation.get_translation(i_lang, e.code_exam) AS desc_content,
                               e.id_exam id_alert,
                               e.id_content id_content
                        
                          FROM exam_complaint ec
                         INNER JOIN exam e
                            ON e.id_exam = ec.id_exam
                         INNER JOIN complaint c
                            ON c.id_complaint = ec.id_complaint
                         WHERE e.flg_type = l_flg_other_exam
                           AND ec.flg_available = g_flg_available
                           AND ec.id_complaint IN (SELECT column_value
                                                     FROM TABLE(l_context))
                           AND e.flg_available = g_flg_available
                           AND EXISTS (SELECT 1
                                  FROM exam_dep_clin_serv edcs
                                 WHERE edcs.id_exam = e.id_exam
                                   AND edcs.id_institution = i_institution
                                   AND edcs.id_software = i_software
                                   AND edcs.flg_type = l_flg_search)) res_data;
                RETURN l_tbl_res;
            END IF;
        END IF;
    
    END get_most_freq_content;
BEGIN
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_freq_content;
/
