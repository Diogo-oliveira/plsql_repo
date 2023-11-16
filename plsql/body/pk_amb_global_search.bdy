/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_amb_global_search IS

    --Package Info
    g_package_owner VARCHAR2(30 CHAR);
    --g_package_name  VARCHAR2(30 CHAR);

    g_error        VARCHAR2(4000);
    g_package_name VARCHAR2(32);

    /************************************************************************************************************
    * Get consult info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/
    FUNCTION get_tbl_col_info_rec_cons_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN consult_req%ROWTYPE
    ) RETURN t_trl_trs_result IS
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec_cons_req';
    
    BEGIN
        l_trl_trs_result.id_episode      := i_rowtype.id_episode;
        l_trl_trs_result.id_patient      := i_rowtype.id_patient;
        l_trl_trs_result.id_professional := i_rowtype.id_prof_req;
        l_trl_trs_result.dt_record       := i_rowtype.dt_consult_req_tstz;
        l_trl_trs_result.id_task_type    := NULL;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec_cons_req');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END;

    /************************************************************************************************************
    * Get consult prof info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/11/22
    ***********************************************************************************************************/

    FUNCTION get_tbl_col_inf_cons_req_prof
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN consult_req_prof%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT cr.id_episode, cr.id_patient, cr.id_prof_req, cr.dt_consult_req_tstz
              FROM consult_req cr
             WHERE cr.id_consult_req = i_rowtype.id_consult_req;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_inf_cons_req_prof';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_inf_cons_req_prof');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END;

    /************************************************************************************************************
    * Get consult info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of episode, patient, professional and date record
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/
    FUNCTION get_tbl_col_info_rec_diet_req
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diet_req%ROWTYPE
    ) RETURN t_trl_trs_result IS
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec_diet_req';
    
    BEGIN
        l_trl_trs_result.id_episode      := i_rowtype.id_episode;
        l_trl_trs_result.id_patient      := i_rowtype.id_patient;
        l_trl_trs_result.id_professional := i_rowtype.id_professional;
        l_trl_trs_result.dt_record       := i_rowtype.dt_creation;
        l_trl_trs_result.id_task_type    := NULL;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec_diet_req');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END;

    /************************************************************************************************************
    * Get diet type description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/03
    ***********************************************************************************************************/

    PROCEDURE get_tbl_col_codes_diet_req
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diet_req%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_record VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_DIET_TYPE.' ||
                                            i_rowtype.id_epis_diet_req;
    
        l_id_task_type NUMBER;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_codes_diet_req';
    
    BEGIN
    
        o_code_list := table_varchar(l_code_record);
    
        o_desc_list := table_varchar(pk_translation.get_translation(i_lang,
                                                                    'DIET_TYPE.CODE_DIET_TYPE.' ||
                                                                    i_rowtype.id_diet_type));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package_name,
                                  sub_object_name => '');
        
    END get_tbl_col_codes_diet_req;

    /************************************************************************************************************
    * Get consult prof info: episode, patient, professional and date record
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_rowtype       table rowtype
    *
    * @return                Info of diet, patient, professional and date record
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/

    FUNCTION get_tbl_col_info_diet_det
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN epis_diet_det%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT dr.id_episode, dr.id_patient, dr.id_professional, dr.dt_creation
              FROM epis_diet_req dr
             WHERE dr.id_epis_diet_req = i_rowtype.id_epis_diet_req;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_diet_det';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_diet_det');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END;

    /************************************************************************************************************
    * Get diet type description 
    * Used for global search.
    *
    * @param i_owner         table owner
    * @param i_table         table name
    * @param i_lang          language identifier
    * @param i_rowtype       table rowtype
    * @param o_code_list     code list
    * @param o_desc_list     description list
    *
    * @return                List of code and description
    *
    * @author                Joel Lopes
    * @version               2.6.3
    * @since                 2013/12/04
    ***********************************************************************************************************/

    PROCEDURE get_tbl_col_codes_diet_det
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN epis_diet_det%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_record VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_DIET.' ||
                                            i_rowtype.id_epis_diet_det;
    
        l_id_task_type NUMBER;
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_codes_diet_det';
    
    BEGIN
    
        o_code_list := table_varchar(l_code_record);
    
        o_desc_list := table_varchar(pk_translation.get_translation(i_lang, 'DIET.CODE_DIET.' || i_rowtype.id_diet));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package_name,
                                  sub_object_name => '');
        
    END get_tbl_col_codes_diet_det;

    /**
    * Get task description.
    * Used for the global search.
    *
    * @param i_owner         Table owner
    * @param i_table         table
    * @param i_rowtype       rowtype    
    *
    * @return               episode and patient
    *
    * @author                         Joel Lopes
    * @version                        2.6.3.8.5.1
    * @since                          27/11/2013
    */

    FUNCTION get_tbl_col_info_rec_problems
    (
        i_owner   IN VARCHAR2,
        i_table   IN VARCHAR2,
        i_rowtype IN pat_history_diagnosis%ROWTYPE
    ) RETURN t_trl_trs_result IS
        CURSOR c_cur IS
        --Exemplo de um cursor, adaptar a cada tabela
            SELECT i_rowtype.id_episode,
                   i_rowtype.id_patient,
                   i_rowtype.id_professional,
                   i_rowtype.dt_pat_history_diagnosis_tstz,
                   CASE
                       WHEN i_rowtype.flg_area = 'P' THEN
                        60
                       WHEN i_rowtype.flg_area = 'H'
                            AND i_rowtype.flg_type = 'M' THEN
                        62
                       WHEN i_rowtype.flg_area = 'H'
                            AND i_rowtype.flg_type = 'S' THEN
                        61
                       WHEN i_rowtype.flg_area = 'H'
                            AND i_rowtype.flg_type = 'A' THEN
                        64
                   END
            
              FROM dual;
    
        l_trl_trs_result t_trl_trs_result := t_trl_trs_result(NULL, NULL, NULL, NULL, NULL);
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_rec_problems';
    
    BEGIN
        OPEN c_cur;
        FETCH c_cur
            INTO l_trl_trs_result.id_episode,
                 l_trl_trs_result.id_patient,
                 l_trl_trs_result.id_professional,
                 l_trl_trs_result.dt_record,
                 l_trl_trs_result.id_task_type;
        CLOSE c_cur;
    
        pk_alertlog.log_error(text        => l_trl_trs_result.id_episode || ' - ' || l_trl_trs_result.id_patient,
                              object_name => 'get_tbl_col_info_rec_problems');
    
        RETURN l_trl_trs_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => k_function_name,
                                  sub_object_name => '');
        
            RETURN NULL;
    END get_tbl_col_info_rec_problems;

    /**
    * Get task description.
    * Used for the global search.
    *
    * @param i_owner         Table owner
    * @param i_table         table
    * @param i_rowtype       rowtype    
    *
    * @return               episode and patient
    *
    * @author                         Joel Lopes
    * @version                        2.6.3.8.5.1
    * @since                          27/11/2013
    */

    PROCEDURE get_tbl_col_info_codes_prob
    (
        i_owner     IN VARCHAR2,
        i_table     IN VARCHAR2,
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_rowtype   IN pat_history_diagnosis%ROWTYPE,
        o_code_list OUT table_varchar,
        o_desc_list OUT table_varchar
    ) IS
        l_code_record VARCHAR2(100 CHAR) := '' || i_owner || '.' || i_table || '.ID_DIAGNOSIS.' ||
                                            i_rowtype.id_pat_history_diagnosis;
    
        l_desc VARCHAR2(400 CHAR);
    
        l_id_task_type NUMBER;
    
        l_code_list table_varchar := table_varchar();
        l_desc_list table_varchar := table_varchar();
    
        k_function_name CONSTANT VARCHAR2(0100 CHAR) := 'get_tbl_col_info_codes_prob';
    
    BEGIN
    
        IF i_rowtype.id_diagnosis IS NOT NULL
        THEN
        
            SELECT (CASE
                        WHEN i_rowtype.flg_area = 'P' THEN
                         60
                        WHEN i_rowtype.flg_area = 'H'
                             AND i_rowtype.flg_type = 'M' THEN
                         62
                        WHEN i_rowtype.flg_area = 'H'
                             AND i_rowtype.flg_type = 'S' THEN
                         61
                        WHEN i_rowtype.flg_area = 'H'
                             AND i_rowtype.flg_type = 'A' THEN
                         64
                    END)
              INTO l_id_task_type
              FROM dual;
        
            SELECT decode(i_rowtype.desc_pat_history_diagnosis,
                          NULL,
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_id_task_type       => l_id_task_type,
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9),
                          decode(i_rowtype.id_alert_diagnosis,
                                 NULL,
                                 i_rowtype.desc_pat_history_diagnosis,
                                 i_rowtype.desc_pat_history_diagnosis || ' - ' ||
                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                            i_id_diagnosis       => d.id_diagnosis,
                                                            i_id_task_type       => l_id_task_type,
                                                            i_code               => d.code_icd,
                                                            i_flg_other          => d.flg_other,
                                                            i_flg_std_diag       => ad.flg_icd9)))
              INTO l_desc
              FROM diagnosis d
              LEFT JOIN alert_diagnosis ad
                ON ad.id_diagnosis = d.id_diagnosis
               AND ad.id_alert_diagnosis =
                   nvl(i_rowtype.id_alert_diagnosis,
                       pk_api_pfh_diagnosis_in.get_diag_preferred_term_id(i_concept_version => d.id_diagnosis,
                                                                          i_task_type       => l_id_task_type))
             WHERE d.id_diagnosis = i_rowtype.id_diagnosis;
        
            l_code_list := table_varchar(l_code_record);
        
            l_desc_list := table_varchar(l_desc);
        
        END IF;
    
        o_code_list := l_code_list;
    
        o_desc_list := l_desc_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => k_function_name || ':' || '-' || SQLERRM,
                                  object_name     => g_package_name,
                                  sub_object_name => '');
        
    END get_tbl_col_info_codes_prob;

END pk_amb_global_search;
/
