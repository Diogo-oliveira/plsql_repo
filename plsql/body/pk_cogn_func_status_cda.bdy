/*-- Last Change Revision: $Rev: 2026883 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:17 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_cogn_func_status_cda IS

    --Package Info
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;
    g_diagnosis_type_final CONSTANT VARCHAR2(1) := 'D';

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    
    *
    * @return                         Diagnoses list
    *
    * @author                               Joel Lopes
    * @version                              2.6.3
    * @since                                26-12-2013
    **********************************************************************************************/

    FUNCTION get_cog_and_func_cda
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_pat       IN pat_history_diagnosis.id_patient%TYPE,
        i_status    IN table_varchar,
        i_type      IN VARCHAR2,
        i_problem   IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        i_scopeid   IN pat_problem.id_episode%TYPE,
        i_flg_scope IN VARCHAR2,
        i_dt_ini    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE,
        i_dt_end    IN pat_history_diagnosis.dt_pat_history_diagnosis_tstz%TYPE
    ) RETURN pat_cogn_func_table
        PIPELINED IS
        l_entries pat_cogn_func_rec;
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'CALL get_phd';
        -- dbms_output.put_line('ENTREI');
        FOR row_i IN (SELECT a.*
                        FROM (SELECT t.*,
                                     get_is_cog_and_func(g_problem_cognitive_status, t.id) flg_is_cognitive,
                                     get_is_cog_and_func(g_problem_functional_status, t.id) flg_is_functional
                                FROM (SELECT *
                                        FROM TABLE(pk_problems.get_phd(i_lang,
                                                                       i_prof,
                                                                       i_pat,
                                                                       i_status,
                                                                       i_problem,
                                                                       i_scopeid,
                                                                       i_flg_scope,
                                                                       i_dt_ini,
                                                                       i_dt_end)) phd1
                                      UNION ALL
                                      SELECT *
                                        FROM TABLE(pk_problems.get_pp(i_lang    => i_lang,
                                                                      i_prof    => i_prof,
                                                                      i_pat     => i_pat,
                                                                      i_status  => i_status,
                                                                      i_type    => i_type,
                                                                      i_problem => i_problem,
                                                                      i_episode => i_scopeid,
                                                                      i_report  => i_flg_scope,
                                                                      i_dt_ini  => i_dt_ini,
                                                                      i_dt_end  => i_dt_end)) pp2) t
                               WHERE t.flg_source IN (g_problem_type_pmh, g_problem_type_problem, g_problem_type_diag)) a
                       WHERE g_um IN (a.flg_is_cognitive, a.flg_is_functional)
                       ORDER BY a.rank_type, a.dt_order DESC)
        LOOP
            --   dbms_output.put_line('ENTREI NO LOOP');
            l_entries.id                      := row_i.id;
            l_entries.id_problem              := row_i.id_problem;
            l_entries.type                    := row_i.type;
            l_entries.dt_problem2             := row_i.dt_problem2;
            l_entries.dt_problem              := row_i.dt_problem;
            l_entries.dt_problem_to_print     := row_i.dt_problem_to_print;
            l_entries.desc_probl              := row_i.desc_probl;
            l_entries.title                   := row_i.title;
            l_entries.flg_source              := row_i.flg_source;
            l_entries.dt_order                := row_i.dt_order;
            l_entries.flg_status              := row_i.flg_status;
            l_entries.rank_type               := row_i.rank_type;
            l_entries.flg_cancel              := row_i.flg_cancel;
            l_entries.desc_status             := row_i.desc_status;
            l_entries.desc_nature             := row_i.desc_nature;
            l_entries.rank_status             := row_i.rank_status;
            l_entries.rank_nature             := row_i.rank_nature;
            l_entries.flg_nature              := row_i.flg_nature;
            l_entries.title_notes             := row_i.title_notes;
            l_entries.prob_notes              := row_i.prob_notes;
            l_entries.title_canceled          := row_i.title_canceled;
            l_entries.id_prob                 := row_i.id_prob;
            l_entries.viewer_category         := row_i.viewer_category;
            l_entries.viewer_category_desc    := row_i.viewer_category_desc;
            l_entries.viewer_id_prof          := row_i.viewer_id_prof;
            l_entries.viewer_id_epis          := row_i.viewer_id_epis;
            l_entries.viewer_date             := row_i.viewer_date;
            l_entries.registered_by_me        := row_i.registered_by_me;
            l_entries.origin_specialty        := row_i.origin_specialty;
            l_entries.id_origin_specialty     := row_i.id_origin_specialty;
            l_entries.precaution_measures_str := row_i.precaution_measures_str;
            l_entries.id_precaution_measures  := row_i.id_precaution_measures;
            l_entries.header_warning          := row_i.header_warning;
            l_entries.header_warning_str      := row_i.header_warning_str;
            l_entries.resolution_date_str     := row_i.resolution_date_str;
            l_entries.resolution_date         := row_i.resolution_date;
            l_entries.warning_icon            := row_i.warning_icon;
            l_entries.review_info             := row_i.review_info;
            l_entries.id_pat_habit            := row_i.id_pat_habit;
            l_entries.flg_area                := row_i.flg_area;
            l_entries.id_content              := row_i.id_content;
            l_entries.is_cognitive            := row_i.flg_is_cognitive;
            l_entries.is_functional           := row_i.flg_is_functional;
            l_entries.id_terminology_version  := row_i.id_terminology_version;
            l_entries.code_icd                := row_i.code_icd;
            l_entries.dt_problem_serial       := row_i.dt_problem_serial;
            --       dbms_output.put_line('ANTES DO PIPE');
            PIPE ROW(l_entries);
            --            dbms_output.put_line('SAÍ do primeiro LOOP');
        END LOOP;
        --        dbms_output.put_line('SAÍ');
    
        RETURN;
    
        /*   EXCEPTION
        WHEN l_exception THEN
            dbms_output.put_line('ERREI');
            RETURN;*/
    END get_cog_and_func_cda;

    /**********************************************************************************************
    * Check if problem has cognitive or functional
    *
    * @param i_internal_name                cognitive or functional
    * @param i_id_concept                   concept identifier
    *
    * @return                               0 - not cognitive or functional problem 
    *                                       1- is a cognitive or functional problem
    *
    * @author                               Jorge Silva
    * @version                              2.6.3
    * @since                                02-04-2014
    **********************************************************************************************/
    FUNCTION get_is_cog_and_func
    (
        i_internal_name IN concept_type.internal_name%TYPE,
        i_id_concept    IN NUMBER
    ) RETURN NUMBER IS
        count_cog INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO count_cog
          FROM concept_type_rel ctr
          JOIN concept_type ct
            ON ct.id_concept_type = ctr.id_concept_type
           AND ct.internal_name = i_internal_name
         WHERE ctr.id_concept IN
               (SELECT d.id_concept
                  FROM (SELECT cver.id_concept_version,
                               cver.id_concept,
                               cver.id_terminology_version,
                               CAST(pk_api_diagnosis_func.get_diagnosis_parent(cver.id_concept,
                                                                               cver.id_terminology_version) AS NUMBER(24)) id_cv_parent
                          FROM concept_version cver) d
                 WHERE d.id_cv_parent IS NULL
                CONNECT BY PRIOR d.id_cv_parent = d.id_concept_version
                 START WITH d.id_concept_version = i_id_concept)
           AND ctr.flg_main_concept_type = g_main_concept_type_n;
    
        IF count_cog > 0
        THEN
            RETURN count_cog;
        END IF;
    
        RETURN 0;
    
    END get_is_cog_and_func;

END pk_cogn_func_status_cda;
/
