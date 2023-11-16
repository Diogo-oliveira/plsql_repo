/*-- Last Change Revision: $Rev: 2047789 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-10-19 16:28:37 +0100 (qua, 19 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_outp IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    /******************************************************************************************************
    * Create an empty document with a temporary state and returns its ID.
    * The goal is to allow the attachment of images before the save final version of the document.
    *
    * @param   I_LANG    language associated to the professional executing the request
    * @param   I_PROF    professional, institution and software ids
    * @param   I_PATIENT patient id
    * @param   I_EPISODE episode id
    * @param   O_ID_DOC  created documment id
    * @param   O_ERROR   an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Orlando Antunes
    * @version 1.0
    * @since   31-08-2010
    *****************************************************************************************************/
    FUNCTION create_initdoc
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN doc_external.id_patient%TYPE,
        i_episode IN doc_external.id_episode%TYPE,
        i_ext_req IN doc_external.id_external_request%TYPE,
        o_id_doc  OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL TO PK_DOC.CREATE_INITDOC';
        IF NOT pk_doc.create_initdoc(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_patient         => i_patient,
                                     i_episode         => i_episode,
                                     i_ext_req         => NULL,
                                     i_btn             => NULL,
                                     i_id_grupo        => NULL,
                                     i_internal_commit => TRUE,
                                     o_id_doc          => o_id_doc,
                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CREATE_INITDOC',
                                              o_error);
            RETURN FALSE;
    END create_initdoc;

    /******************************************************************************************** 
    *
    * @return BOOLEAN
    *
    * @author Joel Lopes
    * @version 2.6.4.0
    * @since 2014-Jun-02
    ********************************************************************************************/
    FUNCTION get_mapping_problem_cda
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_source_codes         IN table_varchar,
        i_source_coding_scheme IN VARCHAR2,
        i_target_coding_scheme IN VARCHAR2,
        o_target_codes         OUT table_varchar,
        o_target_display_names OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message VARCHAR(1000);
    
        g_id_snomed_area CONSTANT VARCHAR(100) := '2.16.840.1.113883.6.96';
    
        l_target_codes         table_varchar := NEW table_varchar();
        l_target_display_names table_varchar := NEW table_varchar();
    
        l_conc_not_mapped VARCHAR2(100) := 'NOT_MAPPED';
        l_error           VARCHAR2(1000);
    
    BEGIN
    
        o_target_codes         := table_varchar();
        o_target_display_names := table_varchar();
    
        IF i_source_codes.exists(1)
        THEN
            FOR i IN i_source_codes.first .. i_source_codes.last
            LOOP
            
                l_target_codes.extend();
                l_target_display_names.extend();
                l_error := 'VERIFY IF SOURCE CODE RECEIVED WAS PROCESSED';
            
                IF (i_source_codes(i) <> l_conc_not_mapped)
                THEN
                    l_error := 'GET DIAGNOSIS BY CODE_ICD / SNOMED';
                    BEGIN
                        SELECT d.id_diagnosis, pk_translation.get_translation(i_lang, d.code_diagnosis)
                          INTO l_target_codes(i), l_target_display_names(i)
                          FROM diagnosis d
                         WHERE d.id_terminology_version IN
                               (SELECT tv.id_terminology_version
                                  FROM alert_core_data.terminology t
                                  JOIN alert_core_data.terminology_version tv
                                    ON tv.id_terminology = t.id_terminology
                                 WHERE t.hl7_oid = g_id_snomed_area)
                              
                           AND d.code_icd = i_source_codes(i);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_target_codes(i) := l_conc_not_mapped;
                            l_target_display_names(i) := NULL;
                    END;
                
                ELSE
                    l_target_codes(i) := i_source_codes(i);
                    l_target_display_names(i) := NULL;
                END IF;
            END LOOP;
        
            o_target_codes         := l_target_codes;
            o_target_display_names := l_target_display_names;
        
        ELSE
            l_target_codes         := NULL;
            l_target_display_names := NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_owner,
                                              g_package,
                                              'GET_MAPPING_PROBLEM_CDA',
                                              o_error);
            RETURN FALSE;
    END get_mapping_problem_cda;

    /******************************************************************************************** 
    *
    * @return BOOLEAN
    *
    * @author Joel Lopes
    * @version 2.6.4.0
    * @since 2014-Jun-02
    ********************************************************************************************/
    FUNCTION set_problems_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_entries_to_add    IN t_tab_problem_cda,
        i_entries_to_edit   IN t_tab_problem_cda,
        i_entries_to_remove IN t_tab_problem_cda,
        i_cdr_call          IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_record    t_set_problem_cda;
        l_ret       BOOLEAN;
        l_msg       VARCHAR2(1000);
        l_msg_title VARCHAR2(1000);
        l_flg_show  VARCHAR2(1000);
        l_button    VARCHAR2(1000);
        l_type      table_varchar;
        l_ids       table_number;
    
    BEGIN
    
        IF i_entries_to_add.exists(1)
        THEN
            g_error := 'ADD PROBLEMS';
            FOR i IN i_entries_to_add.first .. i_entries_to_add.last
            LOOP
                l_record := i_entries_to_add(i);
                FOR j IN l_record.id_problem.first .. l_record.id_problem.last
                LOOP
                
                    l_ret := pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                                  i_epis                   => i_episode,
                                                                  i_pat                    => i_patient,
                                                                  i_prof                   => i_prof,
                                                                  i_desc_problem           => l_record.desc_probl,
                                                                  i_flg_status             => l_record.flg_status,
                                                                  i_notes                  => l_record.prob_notes,
                                                                  i_prof_cat_type          => pk_prof_utils.get_category(i_lang,
                                                                                                                         i_prof),
                                                                  i_diagnosis              => l_record.id_problem,
                                                                  i_flg_nature             => l_record.flg_nature,
                                                                  i_alert_diag             => table_number(pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => l_record.id_problem(j),
                                                                                                                                                              i_task_type       => pk_problems.get_flg_area_task_type(i_flg_area => l_record.type))),
                                                                  i_precaution_measure     => l_record.id_precaution_measures,
                                                                  i_header_warning         => l_record.header_warning,
                                                                  i_cdr_call               => i_cdr_call,
                                                                  i_flg_area               => table_varchar(l_record.flg_area),
                                                                  i_flg_complications      => NULL,
                                                                  i_flg_cda_reconciliation => pk_alert_constant.g_yes,
                                                                  i_dt_diagnosed           => l_record.dt_problem,
                                                                  i_dt_diagnosed_precision => NULL,
                                                                  i_dt_resolved            => l_record.resolution_date,
                                                                  i_dt_resolved_precision  => NULL,
                                                                  o_msg                    => l_msg,
                                                                  o_msg_title              => l_msg_title,
                                                                  o_flg_show               => l_flg_show,
                                                                  o_button                 => l_button,
                                                                  o_type                   => l_type,
                                                                  o_ids                    => l_ids,
                                                                  o_error                  => o_error);
                END LOOP;
            END LOOP;
        END IF;
    
        IF i_entries_to_edit.exists(1)
        THEN
            g_error := 'EDIT PROBLEMS';
            FOR i IN i_entries_to_edit.first .. i_entries_to_edit.last
            LOOP
                l_record := i_entries_to_edit(i);
                FOR j IN l_record.id_problem.first .. l_record.id_problem.last
                LOOP
                    l_ret := pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                                  i_epis                   => i_episode,
                                                                  i_pat                    => i_patient,
                                                                  i_prof                   => i_prof,
                                                                  i_desc_problem           => l_record.desc_probl,
                                                                  i_flg_status             => l_record.flg_status,
                                                                  i_notes                  => l_record.prob_notes,
                                                                  i_prof_cat_type          => pk_prof_utils.get_category(i_lang,
                                                                                                                         i_prof),
                                                                  i_diagnosis              => l_record.id_problem,
                                                                  i_flg_nature             => l_record.flg_nature,
                                                                  i_alert_diag             => table_number(pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => l_record.id_problem(j),
                                                                                                                                                              i_task_type       => pk_problems.get_flg_area_task_type(i_flg_area => l_record.type))),
                                                                  i_precaution_measure     => l_record.id_precaution_measures,
                                                                  i_header_warning         => l_record.header_warning,
                                                                  i_cdr_call               => i_cdr_call,
                                                                  i_flg_area               => table_varchar(l_record.flg_area),
                                                                  i_flg_complications      => NULL,
                                                                  i_flg_cda_reconciliation => pk_alert_constant.g_yes,
                                                                  i_dt_diagnosed           => l_record.dt_problem,
                                                                  i_dt_diagnosed_precision => NULL,
                                                                  i_dt_resolved            => l_record.resolution_date,
                                                                  i_dt_resolved_precision  => NULL,
                                                                  o_msg                    => l_msg,
                                                                  o_msg_title              => l_msg_title,
                                                                  o_flg_show               => l_flg_show,
                                                                  o_button                 => l_button,
                                                                  o_type                   => l_type,
                                                                  o_ids                    => l_ids,
                                                                  o_error                  => o_error);
                END LOOP;
            END LOOP;
        END IF;
    
        IF i_entries_to_remove.exists(1)
        THEN
            g_error := 'REMOVE PROBLEMS';
            FOR i IN i_entries_to_remove.first .. i_entries_to_remove.last
            LOOP
                l_record := i_entries_to_remove(i);
                l_ret    := pk_problems.cancel_pat_problem(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_pat              => i_patient,
                                                           i_id_episode       => i_episode,
                                                           i_id_problem       => l_record.id_problem_cancel,
                                                           i_type             => 'D',
                                                           i_id_cancel_reason => l_record.id_cancel_reason,
                                                           i_cancel_notes     => l_record.cancel_notes,
                                                           i_prof_cat_type    => NULL,
                                                           o_type             => l_type,
                                                           o_ids              => l_ids,
                                                           o_error            => o_error);
            
            END LOOP;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_PROBLEMS_CDA',
                                              o_error);
            RETURN FALSE;
    END set_problems_cda;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_outp;
/
