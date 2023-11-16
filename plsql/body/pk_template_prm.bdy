/*-- Last Change Revision: $Rev: 1951469 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-05-27 12:49:17 +0100 (qua, 27 mai 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_template_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_TEMPLATE_prm';
    pos_soft        NUMBER := 1;
    -- Private Methods

    FUNCTION
    
     get_context2_search
    (
        i_lang            NUMBER,
        flg_context       VARCHAR,
        i_id_context2_def IN doc_template_context.id_context%TYPE
    ) RETURN NUMBER IS
        o_id2_context_alert NUMBER;
    
        o_error t_error_out;
    BEGIN
    
        IF flg_context = 'I'
        THEN
            o_id2_context_alert := NULL;
        
            -- Other Exams
        ELSIF flg_context = 'E'
        THEN
            o_id2_context_alert := NULL;
            -- Rehabilitation areas
        ELSIF flg_context = 'R'
        THEN
            o_id2_context_alert := NULL;
            -- ICNP
        ELSIF flg_context = 'P'
        THEN
            o_id2_context_alert := NULL;
        ELSE
            o_id2_context_alert := i_id_context2_def;
        
        END IF;
        RETURN o_id2_context_alert;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN 0;
    END get_context2_search;

    FUNCTION
    
     get_context_search
    (
        i_lang           NUMBER,
        flg_context      VARCHAR,
        i_id_context_def IN doc_template_context.id_context%TYPE
    ) RETURN NUMBER IS
        o_id_context_alert NUMBER;
    
        o_error t_error_out;
    BEGIN
    
        IF flg_context = 'I'
        THEN
            SELECT nvl((SELECT ext_interv.id_intervention
                         FROM a_intervention ext_interv
                        INNER JOIN ad_intervention def_interv
                           ON (def_interv.id_content = ext_interv.id_content AND def_interv.flg_status = g_active)
                        WHERE ext_interv.flg_status = g_active
                          AND def_interv.id_intervention = i_id_context_def),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
            -- Other Exams
        ELSIF flg_context = 'E'
        THEN
            SELECT nvl((SELECT ext_e.id_exam
                         FROM a_exam ext_e
                        INNER JOIN ad_exam def_e
                           ON (def_e.id_content = ext_e.id_content AND def_e.flg_available = g_flg_available AND
                              def_e.flg_type = 'E')
                        WHERE ext_e.flg_available = g_flg_available
                          AND ext_e.flg_type = 'E'
                          AND def_e.id_exam = i_id_context_def),
                       0)
              INTO o_id_context_alert
              FROM dual;
            -- Rehabilitation areas
        ELSIF flg_context = 'R'
        THEN
            SELECT nvl((SELECT ext_ra.id_rehab_area
                         FROM a_rehab_area ext_ra
                        INNER JOIN ad_rehab_area def_ra
                           ON (def_ra.id_content = ext_ra.id_content)
                        WHERE def_ra.id_rehab_area = i_id_context_def),
                       0)
              INTO o_id_context_alert
              FROM dual;
            -- ICNP
        ELSIF flg_context = 'P'
        THEN
            SELECT nvl((SELECT ext_ic.id_composition
                         FROM a_icnp_composition ext_ic
                        INNER JOIN ad_icnp_composition def_ic
                           ON (def_ic.id_content = ext_ic.id_content AND def_ic.flg_available = g_flg_available)
                        WHERE ext_ic.flg_available = g_flg_available
                          AND def_ic.id_composition = i_id_context_def),
                       0)
              INTO o_id_context_alert
              FROM dual;
        ELSE
            o_id_context_alert := i_id_context_def;
        
        END IF;
        RETURN o_id_context_alert;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN 0;
    END get_context_search;
    -- content loader method

    FUNCTION set_doc_template_cont_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(2);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        g_func_name := upper('SET_DOC_TEMPLATE_CONT_SEARCH');
    
        INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(a_doc_template_context DOC_TEMPL_CONT_FK_UNI )*/
        INTO a_doc_template_context
            (id_doc_template_context,
             id_doc_template,
             id_profile_template,
             id_context,
             flg_type,
             id_sch_event,
             id_context_2,
             flg_show_previous_values,
             id_institution,
             id_software)
            SELECT seq_doc_template_context.nextval,
                   def_data.id_doc_template,
                   def_data.id_profile_template,
                   def_data.id_context,
                   def_data.flg_type,
                   def_data.id_sch_event,
                   def_data.id_context_2,
                   def_data.flg_show_previous_values,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_doc_template,
                           temp_data.id_profile_template,
                           temp_data.id_context,
                           temp_data.flg_type,
                           temp_data.id_sch_event,
                           temp_data.id_context_2,
                           temp_data.flg_show_previous_values
                      FROM (SELECT ad_dtc.id_doc_template,
                                   ad_dtc.id_profile_template,
                                   decode(ad_dtc.flg_type,
                                          'I',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_i.id_intervention
                                                       FROM a_intervention a_i
                                                      INNER JOIN ad_intervention ad_i
                                                         ON ad_i.id_content = a_i.id_content
                                                        AND ad_i.flg_status = g_active
                                                      WHERE a_i.flg_status = g_active
                                                        AND ad_i.id_intervention = ad_dtc.id_context),
                                                     0),
                                                 nvl((SELECT DISTINCT a_i.id_intervention
                                                       FROM a_intervention a_i
                                                      INNER JOIN ad_intervention ad_i
                                                         ON ad_i.id_content = a_i.id_content
                                                        AND ad_i.flg_status = g_active
                                                      WHERE a_i.flg_status = g_active
                                                        AND ad_i.id_intervention = ad_dtc.id_context
                                                        AND ad_i.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'E',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_e.id_exam
                                                       FROM a_exam a_e
                                                      INNER JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                        AND ad_e.flg_available = g_flg_available
                                                        AND ad_e.flg_type = 'E'
                                                      WHERE a_e.flg_available = g_flg_available
                                                        AND a_e.flg_type = 'E'
                                                        AND ad_e.id_exam = ad_dtc.id_context),
                                                     0),
                                                 nvl((SELECT DISTINCT a_e.id_exam
                                                       FROM a_exam a_e
                                                      INNER JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                        AND ad_e.flg_available = g_flg_available
                                                        AND ad_e.flg_type = 'E'
                                                      WHERE a_e.flg_available = g_flg_available
                                                        AND a_e.flg_type = 'E'
                                                        AND ad_e.id_exam = ad_dtc.id_context
                                                        AND ad_e.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'R',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_ra.id_rehab_area
                                                       FROM a_rehab_area a_ra
                                                      INNER JOIN ad_rehab_area ad_ra
                                                         ON ad_ra.id_content = a_ra.id_content
                                                      WHERE ad_ra.id_rehab_area = ad_dtc.id_context),
                                                     0),
                                                 nvl((SELECT DISTINCT a_ra.id_rehab_area
                                                       FROM a_rehab_area a_ra
                                                      INNER JOIN ad_rehab_area ad_ra
                                                         ON ad_ra.id_content = a_ra.id_content
                                                      WHERE ad_ra.id_rehab_area = ad_dtc.id_context
                                                        AND ad_ra.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'P',
                                          decode(l_cnt_count,
                                                 0,
                                                 decode(ad_dtc.id_context,
                                                        '-1',
                                                        ad_dtc.id_context,
                                                        nvl((SELECT a_ic.id_composition
                                                              FROM a_icnp_composition a_ic
                                                             INNER JOIN ad_icnp_composition ad_ic
                                                                ON ad_ic.id_content = a_ic.id_content
                                                               AND ad_ic.flg_available = g_flg_available
                                                             WHERE a_ic.flg_available = g_flg_available
                                                               AND ad_ic.id_composition = ad_dtc.id_context),
                                                            0)),
                                                 nvl((SELECT a_ic.id_composition
                                                       FROM a_icnp_composition a_ic
                                                      INNER JOIN ad_icnp_composition ad_ic
                                                         ON ad_ic.id_content = a_ic.id_content
                                                        AND ad_ic.flg_available = g_flg_available
                                                      WHERE a_ic.flg_available = g_flg_available
                                                        AND ad_ic.id_composition = ad_dtc.id_context
                                                        AND ad_ic.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'ER',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_e.id_exam
                                                       FROM a_exam a_e
                                                      INNER JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                        AND ad_e.flg_available = g_flg_available
                                                      WHERE a_e.flg_available = g_flg_available
                                                        AND ad_e.id_exam = ad_dtc.id_context),
                                                     0),
                                                 nvl((SELECT DISTINCT a_e.id_exam
                                                       FROM a_exam a_e
                                                      INNER JOIN ad_exam ad_e
                                                         ON ad_e.id_content = a_e.id_content
                                                        AND ad_e.flg_available = g_flg_available
                                                      WHERE a_e.flg_available = g_flg_available
                                                        AND ad_e.id_exam = ad_dtc.id_context
                                                        AND ad_e.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'C',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_c.id_complaint
                                                       FROM complaint a_c
                                                      INNER JOIN ad_complaint ad_c
                                                         ON ad_c.id_content = a_c.id_content
                                                      WHERE a_c.flg_available = g_flg_available
                                                        AND ad_c.id_complaint = ad_dtc.id_context),
                                                     0),
                                                 nvl((SELECT DISTINCT a_c.id_complaint
                                                       FROM complaint a_c
                                                      INNER JOIN ad_complaint ad_c
                                                         ON ad_c.id_content = a_c.id_content
                                                      WHERE a_c.flg_available = g_flg_available
                                                        AND ad_c.id_complaint = ad_dtc.id_context
                                                        AND ad_c.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'D',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND a_da.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT DISTINCT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND to_char(a_da.id_doc_area) IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'SP',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND a_da.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT DISTINCT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND to_char(a_da.id_doc_area) IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'DC',
                                          nvl((SELECT DISTINCT a_da.id_doc_area
                                                FROM doc_area a_da
                                               WHERE a_da.id_doc_area = ad_dtc.id_context
                                                 AND a_da.flg_available = g_flg_available),
                                              0),
                                          'S',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_cs.id_clinical_service
                                                       FROM clinical_service a_cs
                                                       JOIN ad_clinical_service ad_cs
                                                         ON a_cs.id_content = ad_cs.id_content
                                                      WHERE ad_cs.id_clinical_service = ad_dtc.id_context
                                                        AND a_cs.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT DISTINCT a_cs.id_clinical_service
                                                       FROM clinical_service a_cs
                                                       JOIN ad_clinical_service ad_cs
                                                         ON a_cs.id_content = ad_cs.id_content
                                                      WHERE ad_cs.id_clinical_service = ad_dtc.id_context
                                                        AND a_cs.flg_available = g_flg_available
                                                        AND a_cs.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          'DS',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND a_da.flg_available = g_flg_available),
                                                     0),
                                                 nvl((SELECT a_da.id_doc_area
                                                       FROM doc_area a_da
                                                      WHERE a_da.id_doc_area = ad_dtc.id_context
                                                        AND to_char(a_da.id_doc_area) IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     0)),
                                          ad_dtc.id_context) id_context,
                                   ad_dtc.flg_type,
                                   ad_dtc.id_sch_event,
                                   decode(ad_dtc.flg_type,
                                          'DC',
                                          decode(l_cnt_count,
                                                 0,
                                                 nvl((SELECT DISTINCT a_c.id_complaint
                                                       FROM complaint a_c
                                                      INNER JOIN ad_complaint ad_c
                                                         ON ad_c.id_content = a_c.id_content
                                                      WHERE a_c.flg_available = g_flg_available
                                                        AND ad_c.id_complaint = ad_dtc.id_context_2),
                                                     -1),
                                                 nvl((SELECT DISTINCT a_c.id_complaint
                                                       FROM complaint a_c
                                                      INNER JOIN ad_complaint ad_c
                                                         ON ad_c.id_content = a_c.id_content
                                                      WHERE a_c.flg_available = g_flg_available
                                                        AND ad_c.id_complaint = ad_dtc.id_context_2
                                                        AND ad_c.id_content IN
                                                            (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                                     -1)),
                                          'I',
                                          NULL,
                                          'E',
                                          NULL,
                                          'R',
                                          NULL,
                                          'P',
                                          NULL,
                                          'ER',
                                          NULL,
                                          'S',
                                          NULL,
                                          'SP',
                                          0,
                                          'DS',
                                          0,
                                          ad_dtc.id_context_2) id_context_2,
                                   ad_dtc.flg_show_previous_values
                            -- decode FKS to dest_vals
                              FROM ad_doc_template_context ad_dtc
                             WHERE ad_dtc.flg_type = nvl(l_flg_type, ad_dtc.flg_type)
                               AND ad_dtc.id_clinical_service IS NULL
                               AND ad_dtc.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_dtc.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_dtc.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_context != 0
                       AND (temp_data.id_context_2 > -1 OR temp_data.id_context_2 IS NULL)) def_data
             WHERE EXISTS (SELECT 0
                      FROM doc_template a_dt
                     WHERE a_dt.id_doc_template = def_data.id_doc_template
                       AND a_dt.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_doc_template_cont_search;

    FUNCTION del_doc_template_cont_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete doc_template_context';
        g_func_name := upper('del_doc_template_cont_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM a_doc_template_context adtc
             WHERE adtc.id_institution = i_institution
               AND adtc.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM a_doc_template_context adtc
             WHERE adtc.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
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
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_doc_template_cont_search;

    -- frequent loader method
    FUNCTION set_template_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_id_content        IN table_varchar DEFAULT table_varchar(),
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_flg_type  VARCHAR2(2);
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        IF l_cnt.count != 0
        THEN
            l_flg_type  := l_cnt(1);
            l_cnt_count := l_cnt.count - 1;
        END IF;
    
        INSERT /*+ IGNORE_ROW_ON_DUPKEY_INDEX(a_doc_template_context DOC_TEMPL_CONT_FK_UNI )*/
        INTO a_doc_template_context
            (id_doc_template_context,
             id_doc_template,
             id_institution,
             id_software,
             id_profile_template,
             id_dep_clin_serv,
             adw_last_update,
             id_context,
             flg_type,
             id_sch_event,
             id_context_2)
            SELECT seq_doc_template_context.nextval,
                   def_data.id_doc_template,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_profile_template,
                   i_dep_clin_serv_out,
                   SYSDATE,
                   def_data.id_context,
                   def_data.flg_type,
                   def_data.id_sch_event,
                   def_data.id_context_2
              FROM (SELECT ad_dtc.id_doc_template,
                           ad_dtc.id_profile_template,
                           CASE
                                WHEN ad_dtc.flg_type IN ('A') THEN
                                 i_clin_serv_out
                                WHEN ad_dtc.flg_type IN ('DA', 'DS') THEN
                                ------------used to filter by doc-area in case l_cnt_count is not 0------------
                                 decode(l_cnt_count,
                                        0,
                                        nvl((SELECT a_da.id_doc_area
                                              FROM doc_area a_da
                                             WHERE a_da.id_doc_area = ad_dtc.id_context
                                               AND a_da.flg_available = g_flg_available),
                                            0),
                                        nvl((SELECT a_da.id_doc_area
                                              FROM doc_area a_da
                                             WHERE a_da.id_doc_area = ad_dtc.id_context
                                               AND to_char(a_da.id_doc_area)  IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                            0))
                            ----------------------------------------------------------------------------------------------------------------------------------------------
                                WHEN ad_dtc.flg_type IN ('CT') THEN
                                ------------used to filter by complaint in case l_cnt_count is not 0------------
                                 decode(l_cnt_count,
                                        0,
                                        nvl((SELECT a_c.id_complaint
                                              FROM complaint a_c
                                             INNER JOIN ad_complaint ad_c
                                                ON ad_c.id_content = a_c.id_content
                                             WHERE ad_c.flg_available = g_flg_available
                                               AND a_c.id_complaint = ad_dtc.id_context),
                                            0),
                                        nvl((SELECT a_c.id_complaint
                                              FROM complaint a_c
                                             INNER JOIN ad_complaint ad_c
                                                ON ad_c.id_content = a_c.id_content
                                             WHERE a_c.flg_available = g_flg_available
                                               AND ad_c.id_complaint = ad_dtc.id_context
                                               AND ad_c.id_content IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(l_cnt AS table_varchar)) p)),
                                            0))
                            ----------------------------------------------------------------------------------------------------------------------------------------------
                                WHEN ad_dtc.flg_type = 'SD' THEN
                                 NULL
                            END id_context,
                           ad_dtc.flg_type,
                           ad_dtc.id_sch_event,
                           CASE
                                WHEN ad_dtc.flg_type IN ('A', 'SD', 'CT') THEN
                                 ad_dtc.id_context_2
                                WHEN ad_dtc.flg_type IN ('DA', 'DS') THEN
                                 i_clin_serv_out
                            END id_context_2
                      FROM ad_doc_template_context ad_dtc
                     WHERE ad_dtc.flg_type = nvl(l_flg_type, ad_dtc.flg_type)
                       AND ad_dtc.id_software IN
                           (SELECT /*+ dynamic_sampling(p 2)*/
                             column_value
                              FROM TABLE(CAST(i_software AS table_number)) p)
                       AND (ad_dtc.id_clinical_service IN
                           (SELECT /*+ dynamic_sampling(p 2)*/
                              column_value
                               FROM TABLE(CAST(i_clin_serv_in AS table_number)) p))
                       AND ad_dtc.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_mkt AS table_number)) p)
                       AND ad_dtc.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                               column_value
                                                FROM TABLE(CAST(i_vers AS table_varchar)) p)) def_data
             WHERE (def_data.id_context_2 > 0 OR def_data.id_context_2 IS NULL)
               AND (def_data.id_context > 0 OR def_data.id_context IS NULL)
               AND EXISTS (SELECT 0
                      FROM doc_template a_dt
                     WHERE a_dt.id_doc_template = def_data.id_doc_template
                       AND a_dt.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_template_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_template_prm;
/
