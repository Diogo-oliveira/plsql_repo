/*-- Last Change Revision: $Rev: 1909626 $*/
/*-- Last Change by: $Author: helder.moreira $*/
/*-- Date of last change: $Date: 2019-07-25 11:40:30 +0100 (qui, 25 jul 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_guideline_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_guideline_prm';

    g_cfg_done t_low_char;
    pos_soft   NUMBER := 1;

    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;

    g_func_name t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_guideline_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_guideline_search');
        INSERT INTO guideline
            (id_guideline,
             id_institution,
             guideline_desc,
             flg_status,
             context_title,
             context_adaptation,
             context_type_media,
             context_editor,
             id_guideline_ebm,
             context_edition_site,
             context_edition,
             dt_context_edition,
             context_access,
             id_context_language,
             context_subtitle,
             id_context_associated_language,
             adw_last_update,
             id_software,
             flg_type_recommendation,
             context_desc,
             id_content)
            SELECT seq_guideline.nextval,
                   def_data.id_institution,
                   def_data.guideline_desc,
                   def_data.flg_status,
                   def_data.context_title,
                   def_data.context_adaptation,
                   def_data.context_type_media,
                   def_data.context_editor,
                   def_data.id_guideline_ebm,
                   def_data.context_edition_site,
                   def_data.context_edition,
                   def_data.dt_context_edition,
                   def_data.context_access,
                   def_data.id_context_language,
                   def_data.context_subtitle,
                   def_data.id_context_associated_language,
                   SYSDATE,
                   def_data.id_software,
                   def_data.flg_type_recommendation,
                   def_data.context_desc,
                   def_data.id_content
              FROM (SELECT temp_data.id_guideline,
                           temp_data.id_institution,
                           temp_data.guideline_desc,
                           temp_data.flg_status,
                           temp_data.context_title,
                           temp_data.context_adaptation,
                           temp_data.context_type_media,
                           temp_data.context_editor,
                           temp_data.id_guideline_ebm,
                           temp_data.context_edition_site,
                           temp_data.context_edition,
                           temp_data.dt_context_edition,
                           temp_data.context_access,
                           temp_data.id_context_language,
                           temp_data.context_subtitle,
                           temp_data.id_context_associated_language,
                           temp_data.adw_last_update,
                           temp_data.id_software,
                           temp_data.flg_type_recommendation,
                           temp_data.context_desc,
                           temp_data.id_content,
                           row_number() over(PARTITION BY temp_data.id_content ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT NULL                                   id_guideline,
                                   i_institution                          id_institution,
                                   src_tbl.guideline_desc,
                                   src_tbl.flg_status,
                                   src_tbl.context_title,
                                   src_tbl.context_adaptation,
                                   src_tbl.context_type_media,
                                   src_tbl.context_editor,
                                   src_tbl.id_guideline_ebm,
                                   src_tbl.context_edition_site,
                                   src_tbl.context_edition,
                                   src_tbl.dt_context_edition,
                                   src_tbl.context_access,
                                   src_tbl.id_context_language,
                                   src_tbl.context_subtitle,
                                   src_tbl.id_context_associated_language,
                                   NULL                                   adw_last_update,
                                   src_tbl.flg_type_recommendation,
                                   src_tbl.context_desc,
                                   src_tbl.id_content,
                                   src_tbl.id_software,
                                   gmv.id_market,
                                   gmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline src_tbl
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = src_tbl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND EXISTS (SELECT 0
                                      FROM alert_default.guideline_task_link gtl
                                     WHERE gtl.id_guideline = src_tbl.id_guideline)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline dest_tbl
                     WHERE dest_tbl.id_content = def_data.id_content
                       AND dest_tbl.id_institution = def_data.id_institution);
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
    END set_guideline_search;

    FUNCTION del_guideline_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline';
        g_func_name := upper('del_guideline_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            UPDATE guideline g
               SET g.flg_status = 'D'
             WHERE g.id_professional IS NULL
               AND g.id_institution = i_institution
			   AND g.flg_status != 'D'
               AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                      column_value
                                       FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            UPDATE guideline g
               SET g.flg_status = 'D'
             WHERE g.id_professional IS NULL
               AND g.id_institution = i_institution
			   AND g.flg_status != 'D';
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_search;

    FUNCTION set_inst_guideline_link
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_var_s VARCHAR2(1) := pk_guidelines.g_guide_link_spec;
        l_var_e VARCHAR2(1) := pk_guidelines.g_guide_link_envi;
        l_var_t VARCHAR2(1) := pk_guidelines.g_guide_link_type;
        l_var_h VARCHAR2(1) := pk_guidelines.g_guide_link_pathol;
        l_var_p VARCHAR2(1) := pk_guidelines.g_guide_link_prof;
        --l_var_d VARCHAR2(1) := pk_guidelines.g_guide_link_edit_prof;
        l_var_c VARCHAR2(1) := pk_guidelines.g_guide_link_chief_complaint;
    
    BEGIN
        g_func_name := 'GET_INST_GUIDELINE_LINK ';
    
        g_error := 'OPEN C_GUIDELINE_LINK CURSOR';
    
        INSERT INTO guideline_link
            (id_guideline_link, id_guideline, id_link, link_type)
            SELECT seq_guideline_link.nextval, def_data.id_guideline, def_data.id_link, def_data.link_type
              FROM (SELECT temp_data.id_guideline,
                           temp_data.id_link,
                           temp_data.link_type,
                           row_number() over(PARTITION BY temp_data.id_guideline, temp_data.id_link, temp_data.link_type ORDER BY temp_data.id_guideline) records_count
                      FROM (SELECT nvl((SELECT g1.id_guideline
                                         FROM guideline g1
                                        WHERE g1.id_content = g.id_content
                                          AND g1.id_content IS NOT NULL
                                          AND g1.id_institution = i_institution
                                          AND rownum = 1),
                                       0) id_guideline,
                                   CASE
                                    
                                    --> by Speciality (PFH)
                                        WHEN gl.link_type = l_var_s
                                             AND i_software(pos_soft) != 3 THEN
                                         nvl((SELECT s.id_speciality
                                               FROM speciality s
                                              WHERE s.id_content = (SELECT sd.id_content
                                                                      FROM alert_default.speciality sd
                                                                     WHERE sd.id_speciality = gl.id_link)
                                                AND s.id_content IS NOT NULL
                                                AND rownum = 1),
                                             0)
                                    
                                        WHEN gl.link_type IN (l_var_t, l_var_p, l_var_c) THEN
                                         gl.id_link
                                        ELSE
                                         0
                                    END id_link,
                                   gl.link_type
                              FROM alert_default.guideline_link gl
                              JOIN alert_default.guideline g
                                ON (g.id_guideline = gl.id_guideline)
                              JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = gl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND gl.link_type IN (l_var_t, l_var_p, l_var_c, l_var_s)
                            
                            UNION ALL
                            SELECT nvl((SELECT g1.id_guideline
                                         FROM guideline g1
                                        WHERE g1.id_content = g.id_content
                                          AND g1.id_content IS NOT NULL
                                          AND g1.id_institution = i_institution
                                          AND rownum = 1),
                                       0) id_guideline,
                                   gl.id_link,
                                   gl.link_type
                              FROM alert_default.guideline_link gl
                              JOIN alert_default.guideline g
                                ON (g.id_guideline = gl.id_guideline)
                              JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = gl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND EXISTS (SELECT 0
                                      FROM diagnosis_content d
                                     WHERE d.id_software IN
                                           (SELECT /* +opt_estimate(p rows = 10) */
                                             column_value
                                              FROM TABLE(CAST(i_software AS table_number)) p)
                                       AND d.flg_type_dep_clin = pk_diagnosis.g_diag_pesq
                                       AND d.id_institution = i_institution
                                       AND d.id_diagnosis = gl.id_link)
                               AND gl.link_type = l_var_h
                            
                            UNION ALL
                            
                            SELECT nvl((SELECT g.id_guideline
                                         FROM guideline g
                                        WHERE g.id_content = g.id_content
                                          AND g.id_content IS NOT NULL
                                          AND g.id_institution = i_institution
                                          AND rownum = 1),
                                       0) id_guideline,
                                   t.id_dept id_link,
                                   gl.link_type
                              FROM software_dept sd
                              JOIN dept t
                                ON (sd.id_dept = t.id_dept), alert_default.guideline_link gl
                            
                              JOIN alert_default.guideline g
                                ON (g.id_guideline = gl.id_guideline)
                              JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = gl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND sd.id_software IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_software AS table_number)) p)
                               AND t.id_institution = i_institution
                               AND t.flg_available = g_flg_available
                               AND gl.link_type = l_var_e
                            
                            UNION ALL
                            SELECT nvl((SELECT g.id_guideline
                                         FROM guideline g
                                        INNER JOIN alert_default.guideline f
                                           ON (f.id_content = g.id_content)
                                        WHERE id_institution = i_institution
                                          AND g.id_content IS NOT NULL
                                          AND f.id_guideline = gl.id_guideline),
                                       0) id_guideline,
                                   css.column_value id_link,
                                   gl.link_type
                              FROM alert_default.guideline_link gl
                              JOIN TABLE(CAST(pk_backoffice_default.check_clinical_service_parent(i_lang, gl.id_link) AS table_number)) css
                                ON (1 = 1)
                             WHERE gl.link_type = l_var_s
                               AND i_software(pos_soft) = 3
                               AND EXISTS
                             (SELECT 0
                                      FROM alert_default.guideline_mrk_vrs gmv
                                     WHERE gmv.id_guideline = gl.id_guideline
                                       AND gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p))) temp_data) def_data
             WHERE def_data.id_guideline > 0
               AND def_data.id_link > 0
               AND def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_link gl
                     WHERE gl.id_guideline = def_data.id_guideline
                       AND gl.id_link = def_data.id_link
                       AND gl.link_type = def_data.link_type);
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_inst_guideline_link;

    FUNCTION del_inst_guideline_link
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_link';
        g_func_name := upper('del_inst_guideline_link');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_link gl
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gl.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_link gl
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gl.id_guideline
                       AND g.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_inst_guideline_link;

    FUNCTION set_guideline_task_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --> Tasks Types
        l_var_analysis NUMBER := pk_guidelines.g_task_analysis; -- Analises := 1;
        l_var_appoint  NUMBER := pk_guidelines.g_task_appoint; -- Consultas := 2;
        l_var_img      NUMBER := pk_guidelines.g_task_img; -- Imagem: exam := 4;
        l_var_enfint   NUMBER := pk_guidelines.g_task_enfint; -- Intervenções de enfermagem := 6;
        --l_var_drug           NUMBER := pk_guidelines.g_task_drug; -- Medicação : drug / tabelas infarmed := 7;
        l_var_otherexam NUMBER := pk_guidelines.g_task_otherexam; -- Outros exames : exam := 8;
        l_var_spec      NUMBER := pk_guidelines.g_task_spec; -- Pareceres : speciality := 9;
        --l_var_drug_ext       NUMBER := pk_guidelines.g_task_drug_ext; -- Medicação exterior := 11;
        l_var_proc           NUMBER := pk_guidelines.g_task_proc; -- Procedimentos := 12;
        l_var_monitorization NUMBER := pk_guidelines.g_task_monitorization; -- monitorizacoes := 14;
        l_var_pat_educ       NUMBER := pk_guidelines.g_task_patient_education;
    
        l_exam_img   exam.flg_type%TYPE := pk_exam_constant.g_type_img;
        l_exam_other exam.flg_type%TYPE := pk_exam_constant.g_type_exm;
    
    BEGIN
    
        g_func_name := 'set_guideline_task_link_search ';
    
        g_error := 'OPEN C_GUIDELINE_TASK CURSOR';
    
        INSERT INTO guideline_task_link
            (id_guideline_task_link,
             id_guideline,
             task_type,
             task_notes,
             id_task_attach,
             task_codification,
             id_task_link)
            SELECT seq_guideline_task_link.nextval,
                   result_data.id_guideline,
                   result_data.task_type,
                   result_data.task_notes,
                   result_data.id_task_attach,
                   result_data.task_codification,
                   result_data.task_link
              FROM (SELECT def_data.id_guideline,
                           def_data.task_type,
                           def_data.task_notes,
                           def_data.id_task_attach,
                           def_data.task_codification,
                           def_data.task_link,
                           row_number() over(PARTITION BY def_data.id_guideline, def_data.task_link, def_data.task_type, def_data.id_task_attach, def_data.task_codification ORDER BY def_data.id_software DESC, def_data.id_market DESC, decode(def_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT general_vals.id_guideline,
                                   general_vals.task_type,
                                   general_vals.task_notes,
                                   general_vals.id_task_attach,
                                   general_vals.task_codification,
                                   CASE
                                    --> PAT EDUCATION
                                        WHEN general_vals.task_type = l_var_pat_educ THEN
                                         nvl((SELECT DISTINCT ntt.id_nurse_tea_topic
                                               FROM nurse_tea_topic ntt
                                              WHERE ntt.flg_available = g_flg_available
                                                AND ntt.id_nurse_tea_topic = general_vals.id_task_link
                                                AND rownum = 1),
                                             0)
                                        WHEN general_vals.task_type = l_var_analysis
                                             AND general_vals.task_codification IS NULL THEN
                                         nvl((SELECT a.id_analysis
                                               FROM analysis a
                                              WHERE id_content = (
                                                                  
                                                                  SELECT DISTINCT a.id_content
                                                                    FROM alert_default.analysis a
                                                                    JOIN alert_default.analysis_mrk_vrs amv
                                                                      ON (amv.id_analysis = a.id_analysis)
                                                                    JOIN alert_default.analysis_instit_soft ais
                                                                      ON (ais.id_analysis = a.id_analysis AND
                                                                         ais.flg_available = g_flg_available AND
                                                                         ais.flg_type = pk_alert_constant.g_analysis_request)
                                                                   WHERE a.flg_available = g_flg_available
                                                                     AND a.id_analysis = general_vals.id_task_link
                                                                     AND amv.id_market IN
                                                                         (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                           column_value
                                                                            FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                                     AND amv.version IN
                                                                         (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                           column_value
                                                                            FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                                     AND ais.id_software IN
                                                                         (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                           column_value
                                                                            FROM TABLE(CAST(i_software AS table_number)) p))
                                                AND a.id_content IS NOT NULL
                                                AND a.flg_available = g_flg_available
                                                AND rownum = 1),
                                             0)
                                        WHEN general_vals.task_type = l_var_appoint
                                             AND general_vals.id_task_link = -1 THEN
                                         -1
                                        WHEN general_vals.task_type = l_var_enfint THEN
                                        
                                         nvl((SELECT ic.id_composition
                                               FROM icnp_composition ic
                                               JOIN alert_default.icnp_composition i
                                                 ON (ic.id_content = i.id_content)
                                               JOIN alert_default.icnp_compo_cs ad_ic
                                                 ON (ad_ic.id_composition = i.id_composition)
                                               JOIN alert_default.clinical_service cs
                                                 ON (cs.id_clinical_service = ad_ic.id_clinical_service AND
                                                    cs.flg_available = g_flg_available)
                                              WHERE i.flg_available = g_flg_available
                                                AND i.flg_type = 'A'
                                                AND i.id_composition = general_vals.id_task_link
                                                AND ad_ic.id_market IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                AND ad_ic.version IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                AND ad_ic.id_software IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_software AS table_number)) p)
                                                AND ic.flg_available = g_flg_available
                                                AND ic.flg_type = 'A'
                                                AND rownum = 1),
                                             0)
                                    
                                        WHEN general_vals.task_type = l_var_spec THEN
                                         nvl((SELECT sp.id_speciality
                                               FROM speciality sp
                                              WHERE sp.id_content =
                                                    (SELECT sp1.id_content
                                                       FROM alert_default.speciality sp1
                                                      WHERE sp1.id_speciality = general_vals.id_task_link
                                                        AND sp1.flg_available = g_flg_available)
                                                AND sp.id_content IS NOT NULL
                                                AND sp.flg_available = g_flg_available
                                                AND rownum = 1),
                                             0)
                                    
                                        WHEN general_vals.task_type = l_var_monitorization THEN --moniterizations
                                        
                                         nvl((SELECT vs.id_vital_sign
                                               FROM vital_sign vs
                                               JOIN alert_default.vs_soft_inst vsi
                                                 ON (vsi.id_vital_sign = vs.id_vital_sign AND vsi.flg_view = 'V2')
                                              WHERE vs.flg_available = g_flg_available
                                                AND vs.id_vital_sign = general_vals.id_task_link
                                                AND vsi.id_market IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                AND vsi.version IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                AND vsi.id_software IN
                                                    (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_software AS table_number)) p)),
                                             0)
                                        ELSE
                                         0
                                    END task_link,
                                   general_vals.id_software,
                                   general_vals.id_market,
                                   general_vals.version
                              FROM (SELECT nvl((SELECT g1.id_guideline
                                                 FROM guideline g1
                                                WHERE g1.id_content = g.id_content
                                                  AND g1.id_content IS NOT NULL
                                                  AND g1.id_institution = i_institution
                                                  AND rownum = 1),
                                               0) id_guideline,
                                           
                                           gtl.id_task_link,
                                           gtl.task_type,
                                           gtl.task_notes,
                                           gtl.id_task_attach,
                                           gtl.task_codification,
                                           NULL                  id_software,
                                           gmv.id_market,
                                           gmv.version
                                      FROM alert_default.guideline_task_link gtl
                                      JOIN alert_default.guideline g
                                        ON (g.id_guideline = gtl.id_guideline)
                                      JOIN alert_default.guideline_mrk_vrs gmv
                                        ON (gmv.id_guideline = gtl.id_guideline)
                                     WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)) general_vals
                             WHERE id_guideline > 0
                            
                            -->analysis
                            UNION ALL
                            SELECT analysis_vals.id_guideline,
                                   analysis_vals.task_type,
                                   analysis_vals.task_notes,
                                   analysis_vals.id_task_attach,
                                   analysis_vals.task_codification,
                                   
                                   nvl((SELECT ac.id_analysis_codification
                                         FROM analysis_codification ac
                                         JOIN codification t
                                           ON (ac.id_codification = t.id_codification)
                                         JOIN alert_default.codification b
                                           ON (t.id_content = b.id_content)
                                         JOIN alert_default.analysis_codification ac1
                                           ON ac1.id_codification = b.id_codification
                                         JOIN alert_default.analysis an
                                           ON (ac1.id_analysis = an.id_analysis)
                                        WHERE an.id_content = analysis_vals.id_content
                                          AND an.flg_available = g_flg_available
                                          AND ac.id_analysis = analysis_vals.analysis
                                          AND ac1.flg_available = g_flg_available
                                          AND t.flg_available = g_flg_available
                                          AND ac.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0) task_link,
                                   analysis_vals.id_software,
                                   analysis_vals.id_market,
                                   analysis_vals.version
                              FROM (SELECT nvl((SELECT g1.id_guideline
                                                 FROM guideline g1
                                                WHERE g1.id_content = g.id_content
                                                  AND g1.id_content IS NOT NULL
                                                  AND g1.id_institution = i_institution
                                                  AND rownum = 1),
                                               0) id_guideline,
                                           
                                           nvl((SELECT a1.id_analysis
                                                 FROM analysis a1
                                                WHERE a1.id_content = a.id_content
                                                  AND a1.id_content IS NOT NULL
                                                  AND a1.flg_available = g_flg_available
                                                  AND rownum = 1),
                                               0) analysis,
                                           gtl.task_type,
                                           gtl.task_notes,
                                           gtl.id_task_attach,
                                           gtl.task_codification,
                                           a.id_content id_content,
                                           ais.id_software,
                                           gmv.id_market,
                                           gmv.version
                                      FROM alert_default.guideline_task_link gtl
                                      JOIN alert_default.guideline g
                                        ON (g.id_guideline = gtl.id_guideline)
                                      JOIN alert_default.guideline_mrk_vrs gmv
                                        ON (gmv.id_guideline = gtl.id_guideline)
                                      JOIN alert_default.analysis a
                                        ON (a.id_analysis = gtl.id_task_link)
                                      JOIN alert_default.analysis_mrk_vrs amv
                                        ON (amv.id_analysis = a.id_analysis)
                                      JOIN alert_default.analysis_instit_soft ais
                                        ON (ais.id_analysis = a.id_analysis AND ais.flg_available = g_flg_available AND
                                           ais.flg_type = pk_alert_constant.g_analysis_request)
                                     WHERE a.flg_available = g_flg_available
                                          
                                       AND amv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND amv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                       AND ais.id_software IN
                                           (SELECT /*+ opt_estimate(p rows = 10)*/
                                             column_value
                                              FROM TABLE(CAST(i_software AS table_number)) p)
                                       AND gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                       AND gtl.task_type = l_var_analysis
                                       AND gtl.task_codification IS NOT NULL) analysis_vals
                             WHERE analysis_vals.analysis > 0
                               AND analysis_vals.id_guideline > 0
                            
                            UNION ALL
                            SELECT appointment_vals.id_guideline,
                                   appointment_vals.task_type,
                                   appointment_vals.task_notes,
                                   appointment_vals.id_task_attach,
                                   appointment_vals.task_codification,
                                   
                                   nvl((SELECT dcs.id_dep_clin_serv
                                         FROM dep_clin_serv dcs
                                         JOIN department d
                                           ON (d.id_department = dcs.id_department AND d.flg_available = g_flg_available AND
                                              d.id_software IN
                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_software AS table_number)) p) AND
                                              d.id_institution = i_institution)
                                         JOIN dept dp
                                           ON (dp.id_dept = d.id_dept AND dp.id_institution = i_institution)
                                         JOIN clinical_service cs
                                           ON (cs.id_clinical_service = dcs.id_clinical_service AND
                                              cs.flg_available = g_flg_available)
                                        WHERE dcs.flg_available = g_flg_available
                                          AND cs.id_clinical_service = appointment_vals.clinical_service
                                          AND rownum = 1),
                                       0) task_link,
                                   appointment_vals.id_software,
                                   appointment_vals.id_market,
                                   appointment_vals.version
                            
                              FROM (SELECT nvl((SELECT g1.id_guideline
                                                 FROM guideline g1
                                                WHERE g1.id_content = g.id_content
                                                  AND g1.id_content IS NOT NULL
                                                  AND g1.id_institution = i_institution
                                                  AND rownum = 1),
                                               0) id_guideline,
                                           
                                           nvl((SELECT cs.id_clinical_service
                                                 FROM clinical_service cs
                                                WHERE cs.id_content = cs.id_content
                                                  AND cs.id_content IS NOT NULL
                                                  AND cs.flg_available = g_flg_available
                                                  AND rownum = 1),
                                               0) clinical_service,
                                           
                                           gtl.task_type,
                                           gtl.task_notes,
                                           gtl.id_task_attach,
                                           gtl.task_codification,
                                           cs.id_content,
                                           NULL                  id_software,
                                           gmv.id_market,
                                           gmv.version
                                      FROM alert_default.guideline_task_link gtl
                                      JOIN alert_default.guideline g
                                        ON (g.id_guideline = gtl.id_guideline)
                                      JOIN alert_default.guideline_mrk_vrs gmv
                                        ON (gmv.id_guideline = gtl.id_guideline), alert_default.clinical_service cs
                                     WHERE cs.flg_available = g_flg_available
                                       AND cs.id_clinical_service IN
                                           (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                             column_value
                                              FROM TABLE(CAST(pk_backoffice_default.check_clinical_service_parent(i_lang,
                                                                                                                  gtl.id_task_link) AS
                                                              table_number)) p)
                                          
                                       AND gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                       AND gtl.task_type = l_var_appoint
                                          
                                       AND gtl.id_task_link != -1) appointment_vals
                             WHERE appointment_vals.clinical_service > 0
                               AND id_guideline > 0
                            
                            -->img_exam
                            UNION ALL (SELECT img_exam_vals.id_guideline,
                                             img_exam_vals.task_type,
                                             img_exam_vals.task_notes,
                                             img_exam_vals.id_task_attach,
                                             
                                             decode(img_exam_vals.task_codification,
                                                    NULL,
                                                    to_number(NULL),
                                                    nvl((SELECT ec.id_exam_codification
                                                          FROM exam_codification ec
                                                          JOIN codification t
                                                            ON (ec.id_codification = t.id_codification)
                                                          JOIN alert_default.codification b
                                                            ON (t.id_content = b.id_content)
                                                          JOIN alert_default.exam_codification ec1
                                                            ON ec1.id_codification = b.id_codification
                                                          JOIN alert_default.exam e
                                                            ON (ec1.id_exam = e.id_exam)
                                                        
                                                         WHERE e.id_content = img_exam_vals.exam_id_content
                                                           AND e.flg_type = l_exam_img
                                                           AND e.flg_available = g_flg_available
                                                           AND ec1.flg_available = g_flg_available
                                                           AND t.flg_available = g_flg_available
                                                           AND ec.id_exam = img_exam_vals.task_link
                                                           AND ec.flg_available = g_flg_available
                                                           AND rownum = 1),
                                                        0)) task_codification,
                                             img_exam_vals.task_link,
                                             img_exam_vals.id_software,
                                             img_exam_vals.id_market,
                                             img_exam_vals.version
                                        FROM (SELECT temp_vals.id_guideline,
                                                     temp_vals.task_type,
                                                     temp_vals.task_notes,
                                                     temp_vals.id_task_attach,
                                                     temp_vals.task_codification,
                                                     temp_vals.exam_id_content,
                                                     
                                                     nvl((SELECT e.id_exam
                                                           FROM exam e
                                                          WHERE e.id_content = exam_id_content
                                                            AND e.id_content IS NOT NULL
                                                            AND e.flg_available = g_flg_available
                                                            AND e.flg_type = l_exam_img
                                                            AND rownum = 1),
                                                         0) task_link,
                                                     temp_vals.id_software,
                                                     temp_vals.id_market,
                                                     temp_vals.version
                                                FROM (SELECT nvl((SELECT g1.id_guideline
                                                                   FROM guideline g1
                                                                  WHERE g1.id_content = g.id_content
                                                                    AND g1.id_content IS NOT NULL
                                                                    AND g1.id_institution = i_institution
                                                                    AND rownum = 1),
                                                                 0) id_guideline,
                                                             
                                                             nvl((SELECT e.id_content
                                                                   FROM alert_default.exam e
                                                                   JOIN alert_default.exam_mrk_vrs emv
                                                                     ON (emv.id_exam = e.id_exam)
                                                                   JOIN alert_default.exam_clin_serv ecs
                                                                     ON (ecs.id_exam = e.id_exam AND
                                                                        ecs.flg_type = pk_exam_constant.g_exam_can_req)
                                                                  WHERE e.flg_available = g_flg_available
                                                                    AND e.id_exam = gtl.id_task_link
                                                                    AND e.flg_type = l_exam_img
                                                                    AND emv.id_market IN
                                                                        (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                          column_value
                                                                           FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                                    AND emv.version IN
                                                                        (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                          column_value
                                                                           FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                                    AND ecs.id_software IN
                                                                        (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                          column_value
                                                                           FROM TABLE(CAST(i_software AS table_number)) p)),
                                                                 0) exam_id_content,
                                                             gtl.task_type,
                                                             gtl.task_notes,
                                                             gtl.id_task_attach,
                                                             gtl.task_codification,
                                                             NULL id_software,
                                                             gmv.id_market,
                                                             gmv.version
                                                      
                                                        FROM alert_default.guideline_task_link gtl
                                                        JOIN alert_default.guideline g
                                                          ON (g.id_guideline = gtl.id_guideline)
                                                        JOIN alert_default.guideline_mrk_vrs gmv
                                                          ON (gmv.id_guideline = gtl.id_guideline)
                                                            
                                                         AND gmv.id_market IN
                                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                                               column_value
                                                                FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                         AND gmv.version IN
                                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                                               column_value
                                                                FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                         AND gtl.task_type = l_var_img) temp_vals) img_exam_vals)
                            
                            UNION ALL
                            -->other_exams
                            SELECT o_exams_vals.id_guideline,
                                   o_exams_vals.task_type,
                                   o_exams_vals.task_notes,
                                   o_exams_vals.id_task_attach,
                                   
                                   decode(o_exams_vals.task_codification,
                                          NULL,
                                          to_number(NULL),
                                          nvl((SELECT ec.id_exam_codification
                                                FROM exam_codification ec
                                                JOIN codification t
                                                  ON (ec.id_codification = t.id_codification)
                                                JOIN alert_default.codification b
                                                  ON (t.id_content = b.id_content)
                                                JOIN alert_default.exam_codification ec1
                                                  ON ec1.id_codification = b.id_codification
                                                JOIN alert_default.exam e
                                                  ON (ec1.id_exam = e.id_exam)
                                              
                                               WHERE e.id_content = o_exams_vals.exam_id_content
                                                 AND e.flg_type = l_exam_other
                                                 AND e.flg_available = g_flg_available
                                                 AND ec1.flg_available = g_flg_available
                                                 AND t.flg_available = g_flg_available
                                                 AND ec.id_exam = o_exams_vals.task_link
                                                 AND ec.flg_available = g_flg_available
                                                 AND rownum = 1),
                                              0)) task_codification,
                                   
                                   o_exams_vals.task_link,
                                   o_exams_vals.id_software,
                                   o_exams_vals.id_market,
                                   o_exams_vals.version
                              FROM (SELECT temp_vals.id_guideline,
                                           temp_vals.task_type,
                                           temp_vals.task_notes,
                                           temp_vals.id_task_attach,
                                           temp_vals.task_codification,
                                           temp_vals.exam_id_content,
                                           
                                           nvl((SELECT e.id_exam
                                                 FROM exam e
                                                WHERE e.id_content = exam_id_content
                                                  AND e.id_content IS NOT NULL
                                                  AND e.flg_available = g_flg_available
                                                  AND e.flg_type = l_exam_other
                                                  AND rownum = 1),
                                               0) task_link,
                                           temp_vals.id_software,
                                           temp_vals.id_market,
                                           temp_vals.version
                                    
                                      FROM (SELECT nvl((SELECT g1.id_guideline
                                                         FROM guideline g1
                                                        WHERE g1.id_content = g.id_content
                                                          AND g1.id_content IS NOT NULL
                                                          AND g1.id_institution = i_institution
                                                          AND rownum = 1),
                                                       0) id_guideline,
                                                   
                                                   nvl((SELECT e.id_content
                                                         FROM alert_default.exam e
                                                         JOIN alert_default.exam_mrk_vrs emv
                                                           ON (emv.id_exam = e.id_exam)
                                                         JOIN alert_default.exam_clin_serv ecs
                                                           ON (ecs.id_exam = e.id_exam AND
                                                              ecs.flg_type = pk_exam_constant.g_exam_can_req)
                                                        WHERE e.flg_available = g_flg_available
                                                          AND e.id_exam = gtl.id_task_link
                                                          AND e.flg_type = l_exam_other
                                                          AND emv.id_market IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                          AND emv.version IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                          AND ecs.id_software IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_software AS table_number)) p)),
                                                       0) exam_id_content,
                                                   gtl.task_type,
                                                   gtl.task_notes,
                                                   gtl.id_task_attach,
                                                   gtl.task_codification,
                                                   NULL id_software,
                                                   gmv.id_market,
                                                   gmv.version
                                            
                                              FROM alert_default.guideline_task_link gtl
                                              JOIN alert_default.guideline g
                                                ON (g.id_guideline = gtl.id_guideline)
                                              JOIN alert_default.guideline_mrk_vrs gmv
                                                ON (gmv.id_guideline = gtl.id_guideline)
                                                  
                                               AND gmv.id_market IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                                               AND gmv.version IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                               AND gtl.task_type = l_var_otherexam
                                               AND gtl.task_codification IS NOT NULL) temp_vals) o_exams_vals
                            UNION ALL
                            
                            --> PROCEDURES
                            SELECT procedures_vals.id_guideline,
                                   procedures_vals.task_type,
                                   procedures_vals.task_notes,
                                   procedures_vals.id_task_attach,
                                   
                                   decode(procedures_vals.task_codification,
                                          NULL,
                                          to_number(NULL),
                                          nvl((SELECT ec.id_exam_codification
                                                FROM exam_codification ec
                                                JOIN codification t
                                                  ON (ec.id_codification = t.id_codification)
                                                JOIN alert_default.codification b
                                                  ON (t.id_content = b.id_content)
                                                JOIN alert_default.exam_codification ec1
                                                  ON ec1.id_codification = b.id_codification
                                                JOIN alert_default.exam e
                                                  ON (ec1.id_exam = e.id_exam)
                                              
                                               WHERE e.id_content = procedures_vals.proc_id_content
                                                 AND e.flg_type = 'E'
                                                 AND e.flg_available = g_flg_available
                                                 AND ec1.flg_available = g_flg_available
                                                 AND t.flg_available = g_flg_available
                                                 AND ec.id_exam = procedures_vals.task_link
                                                 AND ec.flg_available = g_flg_available
                                                 AND rownum = 1),
                                              0)) task_codification,
                                   
                                   procedures_vals.task_link,
                                   procedures_vals.id_software,
                                   procedures_vals.id_market,
                                   procedures_vals.version
                              FROM (SELECT temp_vals.id_guideline,
                                           temp_vals.task_type,
                                           temp_vals.task_notes,
                                           temp_vals.id_task_attach,
                                           temp_vals.task_codification,
                                           temp_vals.proc_id_content,
                                           
                                           nvl((SELECT i.id_intervention
                                                 FROM intervention i
                                                WHERE i.id_content = proc_id_content
                                                  AND i.id_content IS NOT NULL
                                                  AND i.flg_status = g_active
                                                  AND rownum = 1),
                                               0) task_link,
                                           temp_vals.id_software,
                                           temp_vals.id_market,
                                           temp_vals.version
                                      FROM (SELECT nvl((SELECT g1.id_guideline
                                                         FROM guideline g1
                                                        WHERE g1.id_content = g.id_content
                                                          AND g1.id_content IS NOT NULL
                                                          AND g1.id_institution = i_institution
                                                          AND rownum = 1),
                                                       0) id_guideline,
                                                   
                                                   nvl((SELECT DISTINCT i.id_content
                                                         FROM alert_default.intervention i
                                                         JOIN alert_default.interv_mrk_vrs imv
                                                           ON (imv.id_intervention = i.id_intervention)
                                                         JOIN alert_default.interv_clin_serv ics
                                                           ON (i.id_intervention = i.id_intervention AND
                                                              ics.flg_type = pk_alert_constant.g_interv_can_req)
                                                        WHERE i.flg_status = pk_alert_constant.g_active
                                                          AND i.id_intervention = gtl.id_task_link
                                                          AND imv.id_market IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_mkt AS table_number)) p)
                                                          AND imv.version IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                                          AND ics.id_software IN
                                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                                column_value
                                                                 FROM TABLE(CAST(i_software AS table_number)) p)),
                                                       0) proc_id_content,
                                                   gtl.task_type,
                                                   gtl.task_notes,
                                                   gtl.id_task_attach,
                                                   gtl.task_codification,
                                                   NULL id_software,
                                                   gmv.id_market,
                                                   gmv.version
                                            
                                              FROM alert_default.guideline_task_link gtl
                                              JOIN alert_default.guideline g
                                                ON (g.id_guideline = gtl.id_guideline)
                                              JOIN alert_default.guideline_mrk_vrs gmv
                                                ON (gmv.id_guideline = gtl.id_guideline)
                                                  
                                               AND gmv.id_market IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                                               AND gmv.version IN
                                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                               AND gtl.task_type = l_var_proc
                                               AND gtl.task_codification IS NOT NULL) temp_vals) procedures_vals
                             WHERE procedures_vals.proc_id_content > 0
                               AND procedures_vals.id_guideline > 0
                            
                            ) def_data) result_data
            
             WHERE result_data.records_count = 1
               AND result_data.task_link != 0
               AND (result_data.task_codification > 0 OR result_data.task_codification IS NULL)
               AND NOT EXISTS
             (SELECT 0
                      FROM guideline_task_link gtl
                     WHERE gtl.id_guideline = result_data.id_guideline
                       AND gtl.id_task_link = result_data.task_link
                       AND gtl.task_type = result_data.task_type
                       AND (gtl.id_task_attach = result_data.id_task_attach OR
                           (gtl.id_task_attach IS NULL AND result_data.id_task_attach IS NULL))
                       AND (gtl.task_codification = result_data.task_codification OR
                           (gtl.task_codification IS NULL AND result_data.task_codification IS NULL)));
    
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_guideline_task_link_search;

    FUNCTION del_guideline_task_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_task_link';
        g_func_name := upper('del_guideline_task_link_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_task_link gtl
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gtl.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_task_link gtl
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gtl.id_guideline
                       AND g.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_task_link_search;

    FUNCTION set_guideline_ctxt_img_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_guideline_ctxt_img_search');
        INSERT INTO guideline_context_image
            (id_guideline_context_image, id_guideline, file_name, img_desc, dt_img, img, img_thumbnail, flg_status)
            SELECT seq_guideline_context_image.nextval,
                   def_data.id_guideline,
                   def_data.file_name,
                   def_data.img_desc,
                   def_data.dt_img,
                   def_data.img,
                   def_data.img_thumbnail,
                   def_data.flg_status
              FROM (SELECT temp_data.id_guideline,
                           temp_data.file_name,
                           temp_data.img_desc,
                           temp_data.dt_img,
                           temp_data.img,
                           temp_data.img_thumbnail,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.id_guideline, temp_data.file_name, temp_data.img_desc, temp_data.dt_img, temp_data.flg_status ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_g.id_guideline
                                         FROM guideline ext_g
                                        INNER JOIN alert_default.guideline int_g
                                           ON (int_g.id_content = ext_g.id_content)
                                        WHERE ext_g.id_institution = i_institution
                                          AND int_g.id_guideline = src_tbl.id_guideline),
                                       0) id_guideline,
                                   src_tbl.file_name,
                                   src_tbl.img_desc,
                                   src_tbl.dt_img,
                                   src_tbl.img,
                                   src_tbl.img_thumbnail,
                                   src_tbl.flg_status,
                                   gmv.id_market,
                                   gmv.version
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline_context_image src_tbl
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = src_tbl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_guideline != 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_context_image dest_tbl
                     WHERE dest_tbl.id_guideline = def_data.id_guideline
                       AND dest_tbl.file_name = def_data.file_name
                       AND dest_tbl.img_desc = def_data.img_desc
                       AND dest_tbl.dt_img = def_data.dt_img
                       AND dbms_lob.compare(dest_tbl.img, def_data.img) > 0
                       AND dbms_lob.compare(dest_tbl.img_thumbnail, def_data.img_thumbnail) > 0
                       AND dest_tbl.flg_status = def_data.flg_status);
    
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
    END set_guideline_ctxt_img_search;

    FUNCTION del_guideline_ctxt_img_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_context_image';
        g_func_name := upper('del_guideline_ctxt_img_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_context_image gci
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gci.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_context_image gci
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gci.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_ctxt_img_search;

    FUNCTION set_guideline_ctxt_auth_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_guideline_ctxt_auth_search');
        INSERT INTO guideline_context_author
            (id_guideline_context_author, id_guideline, first_name, last_name, title)
            SELECT seq_guideline_context_author.nextval,
                   def_data.id_guideline,
                   def_data.first_name,
                   def_data.last_name,
                   def_data.title
              FROM (SELECT temp_data.id_guideline,
                           temp_data.first_name,
                           temp_data.last_name,
                           temp_data.title,
                           row_number() over(PARTITION BY temp_data.id_guideline, temp_data.first_name, temp_data.last_name, temp_data.title ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_g.id_guideline
                                         FROM guideline ext_g
                                        INNER JOIN alert_default.guideline int_g
                                           ON (int_g.id_content = ext_g.id_content)
                                        WHERE ext_g.id_institution = i_institution
                                          AND int_g.id_guideline = src_tbl.id_guideline),
                                       0) id_guideline,
                                   src_tbl.first_name,
                                   src_tbl.last_name,
                                   src_tbl.title,
                                   gmv.id_market,
                                   gmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline_context_author src_tbl
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = src_tbl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_guideline != 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_context_author dest_tbl
                     WHERE dest_tbl.id_guideline = def_data.id_guideline
                       AND dest_tbl.first_name = def_data.first_name
                       AND dest_tbl.last_name = def_data.last_name
                       AND dest_tbl.title = def_data.title);
    
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
    END set_guideline_ctxt_auth_search;

    FUNCTION del_guideline_ctxt_auth_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_context_author';
        g_func_name := upper('del_guideline_ctxt_auth_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_context_author gca
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gca.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_context_author gca
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gca.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_ctxt_auth_search;

    FUNCTION set_guideline_criteria_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_guideline_criteria_search');
        INSERT INTO guideline_criteria
            (id_guideline_criteria,
             id_guideline,
             criteria_type,
             gender,
             min_age,
             max_age,
             min_weight,
             max_weight,
             id_weight_unit_measure,
             min_height,
             max_height,
             id_height_unit_measure,
             imc_min,
             imc_max,
             id_blood_pressure_unit_measure,
             min_blood_pressure_s,
             max_blood_pressure_s,
             min_blood_pressure_d,
             max_blood_pressure_d)
            SELECT seq_guideline_criteria.nextval,
                   def_data.id_guideline,
                   def_data.criteria_type,
                   def_data.gender,
                   def_data.min_age,
                   def_data.max_age,
                   def_data.min_weight,
                   def_data.max_weight,
                   def_data.id_weight_unit_measure,
                   def_data.min_height,
                   def_data.max_height,
                   def_data.id_height_unit_measure,
                   def_data.imc_min,
                   def_data.imc_max,
                   def_data.id_blood_pressure_unit_measure,
                   def_data.min_blood_pressure_s,
                   def_data.max_blood_pressure_s,
                   def_data.min_blood_pressure_d,
                   def_data.max_blood_pressure_d
              FROM (SELECT temp_data.id_guideline,
                           temp_data.criteria_type,
                           temp_data.gender,
                           temp_data.min_age,
                           temp_data.max_age,
                           temp_data.min_weight,
                           temp_data.max_weight,
                           temp_data.id_weight_unit_measure,
                           temp_data.min_height,
                           temp_data.max_height,
                           temp_data.id_height_unit_measure,
                           temp_data.imc_min,
                           temp_data.imc_max,
                           temp_data.id_blood_pressure_unit_measure,
                           temp_data.min_blood_pressure_s,
                           temp_data.max_blood_pressure_s,
                           temp_data.min_blood_pressure_d,
                           temp_data.max_blood_pressure_d,
                           row_number() over(PARTITION BY temp_data.id_guideline, temp_data.criteria_type ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_g.id_guideline
                                         FROM guideline ext_g
                                        INNER JOIN alert_default.guideline int_g
                                           ON (int_g.id_content = ext_g.id_content)
                                        WHERE ext_g.id_institution = i_institution
                                          AND int_g.id_guideline = src_tbl.id_guideline),
                                       0) id_guideline,
                                   src_tbl.criteria_type,
                                   src_tbl.gender,
                                   src_tbl.min_age,
                                   src_tbl.max_age,
                                   src_tbl.min_weight,
                                   src_tbl.max_weight,
                                   src_tbl.id_weight_unit_measure,
                                   src_tbl.min_height,
                                   src_tbl.max_height,
                                   src_tbl.id_height_unit_measure,
                                   src_tbl.imc_min,
                                   src_tbl.imc_max,
                                   src_tbl.id_blood_pressure_unit_measure,
                                   src_tbl.min_blood_pressure_s,
                                   src_tbl.max_blood_pressure_s,
                                   src_tbl.min_blood_pressure_d,
                                   src_tbl.max_blood_pressure_d,
                                   gmv.id_market,
                                   gmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline_criteria src_tbl
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = src_tbl.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_guideline != 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_criteria dest_tbl
                     WHERE dest_tbl.id_guideline = def_data.id_guideline
                       AND dest_tbl.criteria_type = def_data.criteria_type);
    
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
    END set_guideline_criteria_search;

    FUNCTION del_guideline_criteria_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_criteria';
        g_func_name := upper('del_guideline_criteria_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_criteria gc
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gc.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_criteria gc
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gc.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_criteria_search;

    FUNCTION set_guideline_crit_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_func_name := upper('set_guideline_crit_link_search ');
    
        g_error := 'OPEN C_GUIDELINE_CRITERIA_LINK CURSOR';
    
        INSERT INTO guideline_criteria_link
            (id_guideline_criteria_link, id_guideline_criteria, id_link_other_criteria_type, id_link_other_criteria)
            SELECT seq_guideline_criteria_link.nextval,
                   result_data.id_guideline_criteria,
                   result_data.id_link_other_criteria_type,
                   result_data.id_link_other_criteria
              FROM (SELECT def_data.id_guideline_criteria,
                           def_data.id_link_other_criteria_type,
                           def_data.id_link_other_criteria,
                           row_number() over(PARTITION BY def_data.id_guideline_criteria, def_data.id_link_other_criteria_type, def_data.id_link_other_criteria ORDER BY def_data.id_market DESC, decode(def_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT
                            
                             CASE
                              -->allergy
                                  WHEN temp_data.id_link_other_criteria_type = 1 THEN
                                   nvl((SELECT a.id_allergy
                                         FROM allergy a
                                         JOIN allergy_inst_soft ais
                                           ON (ais.id_allergy = a.id_allergy AND ais.id_institution = i_institution AND
                                              ais.id_software = i_software(pos_soft))
                                        WHERE a.id_allergy = temp_data.id_link_other_criteria
                                          AND a.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0)
                              -->analysis
                                  WHEN temp_data.id_link_other_criteria_type = 2 THEN
                                   nvl((SELECT a.id_analysis
                                         FROM analysis a
                                         JOIN analysis_instit_soft ais
                                           ON (ais.id_analysis = a.id_analysis AND ais.id_institution = i_institution AND
                                              ais.id_software = i_software(pos_soft) AND
                                              ais.flg_available = g_flg_available)
                                         JOIN analysis_param ap
                                           ON (ap.id_analysis = a.id_analysis AND ap.flg_available = g_flg_available)
                                         JOIN alert_default.analysis a2
                                           ON a.id_content = a2.id_content
                                       
                                        WHERE a2.id_analysis = temp_data.id_link_other_criteria
                                          AND a2.flg_available = g_flg_available
                                          AND a.id_content IS NOT NULL
                                          AND a.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0)
                              --> Diagnosis
                                  WHEN temp_data.id_link_other_criteria_type = 3 THEN
                                  
                                   nvl((SELECT d.id_diagnosis
                                         FROM diagnosis d
                                         JOIN diagnosis_dep_clin_serv ddcs
                                           ON (ddcs.id_diagnosis = d.id_diagnosis AND ddcs.id_institution = i_institution AND
                                              ddcs.flg_type = 'P' AND ddcs.id_software = i_software(pos_soft))
                                        WHERE d.id_diagnosis = temp_data.id_link_other_criteria
                                          AND d.flg_available = g_flg_available
                                          AND rownum = 1),
                                       0)
                              
                              --> Image Exams
                                  WHEN temp_data.id_link_other_criteria_type = 4 THEN
                                   nvl((SELECT e.id_exam
                                         FROM exam e
                                         JOIN exam_dep_clin_serv edcs
                                           ON (edcs.id_exam = e.id_exam AND edcs.id_institution = i_institution AND
                                              edcs.id_software = i_software(pos_soft) AND
                                              edcs.flg_type = pk_exam_constant.g_exam_can_req)
                                         JOIN alert_default.exam e2
                                           ON (e.id_content = e2.id_content)
                                       
                                        WHERE e2.id_exam = temp_data.id_link_other_criteria
                                          AND e2.flg_available = g_flg_available
                                          AND e.id_content IS NOT NULL
                                          AND e.flg_available = g_flg_available
                                          AND e.flg_type = pk_exam_constant.g_type_img
                                          AND rownum = 1),
                                       0)
                              --> Other Exams
                                  WHEN temp_data.id_link_other_criteria_type = 6 THEN
                                   nvl((SELECT e.id_exam
                                         FROM exam e
                                         JOIN exam_dep_clin_serv edcs
                                           ON (edcs.id_exam = e.id_exam AND edcs.id_institution = i_institution AND
                                              edcs.id_software = i_software(pos_soft) AND
                                              edcs.flg_type = pk_exam_constant.g_exam_can_req)
                                         JOIN alert_default.exam e2
                                           ON (e.id_content = e2.id_content)
                                       
                                        WHERE e2.id_exam = temp_data.id_link_other_criteria
                                          AND e2.flg_available = g_flg_available
                                          AND e.id_content IS NOT NULL
                                          AND e.flg_available = g_flg_available
                                          AND e.flg_type = pk_exam_constant.g_type_exm
                                          AND rownum = 1),
                                       0)
                              --> ICNP Diagnosis
                                  WHEN temp_data.id_link_other_criteria_type = 7 THEN
                                   nvl((SELECT ic.id_composition
                                         FROM icnp_composition ic
                                         JOIN icnp_predefined_action ipa
                                           ON (ipa.id_composition_parent = ic.id_composition AND
                                              ipa.id_institution = i_institution AND ipa.flg_available = g_flg_available)
                                         JOIN alert_default.icnp_composition ic2
                                           ON (ic.id_content = ic2.id_content)
                                         JOIN alert_default.icnp_predefined_action ipa2
                                           ON (ipa2.id_composition_parent = ic2.id_composition AND
                                              ipa2.flg_available = g_flg_available)
                                        WHERE ic2.id_composition = temp_data.id_link_other_criteria
                                          AND ic2.flg_available = g_flg_available
                                          AND ipa2.version IN
                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                column_value
                                                 FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                          AND ipa2.id_market IN
                                              (SELECT /*+ opt_estimate(p rows = 10)*/
                                                column_value
                                                 FROM TABLE(CAST(i_mkt AS table_number)) p)
                                          AND ic.id_content IS NOT NULL
                                          AND ic.flg_available = g_flg_available
                                          AND ic.flg_type = 'D'
                                          AND rownum = 1),
                                       0)
                                  ELSE
                                   0
                              END id_link_other_criteria,
                             gc.id_guideline_criteria,
                             temp_data.id_link_other_criteria_type,
                             temp_data.id_market,
                             temp_data.version
                            
                              FROM (SELECT nvl((SELECT g1.id_guideline
                                                 FROM guideline g1
                                                WHERE g1.id_content = g.id_content
                                                  AND g1.id_content IS NOT NULL
                                                  AND g1.id_institution = i_institution
                                                  AND rownum = 1),
                                               0) id_guideline,
                                           
                                           gcl.id_guideline_criteria,
                                           gcl.id_link_other_criteria,
                                           gcl.id_link_other_criteria_type,
                                           gc.criteria_type                ad_ct,
                                           gmv.id_market,
                                           gmv.version
                                    
                                      FROM alert_default.guideline_criteria_link gcl
                                      JOIN alert_default.guideline_criteria gc
                                        ON (gc.id_guideline_criteria = gcl.id_guideline_criteria)
                                      JOIN guideline_criteria_type gct
                                        ON (gct.id_guideline_criteria_type = gcl.id_link_other_criteria_type)
                                      JOIN alert_default.guideline g
                                        ON (g.id_guideline = gc.id_guideline)
                                      JOIN alert_default.guideline_mrk_vrs gmv
                                        ON (gmv.id_guideline = gc.id_guideline)
                                     WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                              column_value
                                                               FROM TABLE(CAST(i_mkt AS table_number)) p)
                                       AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                            column_value
                                                             FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                              JOIN guideline g1
                                ON (g1.id_guideline = temp_data.id_guideline)
                              JOIN guideline_criteria gc
                                ON (g1.id_guideline = gc.id_guideline)
                              JOIN alert_default.guideline g2
                                ON (g2.id_content = g1.id_content)
                              JOIN alert_default.guideline_criteria gc2
                                ON (gc2.id_guideline = g2.id_guideline AND gc2.criteria_type = gc.criteria_type)
                             WHERE gc.id_guideline_criteria IS NOT NULL
                               AND temp_data.id_guideline > 0
                               AND gc.criteria_type = temp_data.ad_ct) def_data) result_data
             WHERE result_data.records_count = 1
               AND result_data.id_link_other_criteria > 0
               AND NOT EXISTS (SELECT 0
                      FROM guideline_criteria_link gcl
                     WHERE gcl.id_guideline_criteria = result_data.id_guideline_criteria
                       AND gcl.id_link_other_criteria_type = result_data.id_link_other_criteria_type
                       AND gcl.id_link_other_criteria = result_data.id_link_other_criteria);
    
        o_result_tbl := SQL%ROWCOUNT;
        IF o_result_tbl > 0
        THEN
            g_cfg_done := 'TRUE';
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
            RETURN FALSE;
    END set_guideline_crit_link_search;

    FUNCTION del_guideline_crit_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_criteria';
        g_func_name := upper('del_guideline_crit_link_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_criteria_link gcl
             WHERE EXISTS (SELECT 1
                      FROM guideline_criteria gc
                     WHERE gc.id_guideline_criteria = gcl.id_guideline_criteria
                       AND EXISTS (SELECT 1
                              FROM guideline g
                             WHERE g.id_guideline = gc.id_guideline
                               AND g.id_professional IS NULL
                               AND g.id_institution = i_institution
                               AND g.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)));
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_criteria_link gcl
             WHERE EXISTS (SELECT 1
                      FROM guideline_criteria gc
                     WHERE gc.id_guideline_criteria = gcl.id_guideline_criteria
                       AND EXISTS (SELECT 1
                              FROM guideline g
                             WHERE g.id_guideline = gc.id_guideline
                               AND g.id_professional IS NULL
                               AND g.id_institution = i_institution));
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_crit_link_search;

    FUNCTION set_guide_adv_input_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_var_t VARCHAR2(1) := pk_guidelines.g_adv_input_type_tasks;
        l_var_c VARCHAR2(1) := pk_guidelines.g_adv_input_type_criterias;
    BEGIN
        g_func_name := upper('set_guide_adv_input_search');
        INSERT INTO guideline_adv_input_value
            (id_guideline_adv_input_value,
             id_adv_input_link,
             flg_type,
             id_advanced_input,
             id_advanced_input_field,
             id_advanced_input_field_det,
             value_type,
             nvalue,
             dvalue,
             vvalue,
             value_desc,
             criteria_value_type)
            SELECT seq_guideline_adv_input_value.nextval,
                   def_data.id_adv_input_link,
                   def_data.flg_type,
                   def_data.id_advanced_input,
                   def_data.id_advanced_input_field,
                   def_data.id_advanced_input_field_det,
                   def_data.value_type,
                   def_data.nvalue,
                   def_data.dvalue,
                   def_data.vvalue,
                   def_data.value_desc,
                   def_data.criteria_value_type
              FROM (SELECT temp_data.id_adv_input_link,
                           temp_data.flg_type,
                           temp_data.id_advanced_input,
                           temp_data.id_advanced_input_field,
                           temp_data.id_advanced_input_field_det,
                           temp_data.value_type,
                           temp_data.nvalue,
                           temp_data.dvalue,
                           temp_data.vvalue,
                           temp_data.value_desc,
                           temp_data.criteria_value_type,
                           row_number() over(PARTITION BY temp_data.id_adv_input_link, temp_data.flg_type, temp_data.id_advanced_input, temp_data.id_advanced_input_field, temp_data.id_advanced_input_field_det ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT ext_gc.id_guideline_criteria
                                         FROM guideline_criteria ext_gc
                                        INNER JOIN guideline ext_g
                                           ON (ext_g.id_guideline = ext_gc.id_guideline AND
                                              ext_g.id_institution = i_institution)
                                        INNER JOIN alert_default.guideline int_g
                                           ON (int_g.id_content = ext_g.id_content)
                                        WHERE int_g.id_guideline = gc.id_guideline
                                          AND ext_gc.criteria_type = gc.criteria_type),
                                       0) id_adv_input_link,
                                   src_tbl.flg_type,
                                   src_tbl.id_advanced_input,
                                   src_tbl.id_advanced_input_field,
                                   src_tbl.id_advanced_input_field_det,
                                   src_tbl.value_type,
                                   src_tbl.nvalue,
                                   src_tbl.dvalue,
                                   src_tbl.vvalue,
                                   src_tbl.value_desc,
                                   src_tbl.criteria_value_type,
                                   gmv.id_market,
                                   gmv.version
                              FROM alert_default.guideline_adv_input_value src_tbl
                             INNER JOIN alert_default.guideline_criteria gc
                                ON (gc.id_guideline_criteria = src_tbl.id_adv_input_link)
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = gc.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND src_tbl.flg_type = l_var_c
                            UNION ALL
                            SELECT src_tbl.id_adv_input_link, --get_id_adv_input_link proper id
                                   src_tbl.flg_type,
                                   src_tbl.id_advanced_input,
                                   src_tbl.id_advanced_input_field,
                                   src_tbl.id_advanced_input_field_det,
                                   src_tbl.value_type,
                                   src_tbl.nvalue,
                                   src_tbl.dvalue,
                                   src_tbl.vvalue,
                                   src_tbl.value_desc,
                                   src_tbl.criteria_value_type,
                                   gmv.id_market,
                                   gmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline_adv_input_value src_tbl
                             INNER JOIN alert_default.guideline_task_link gt
                                ON (gt.id_guideline_task_link = src_tbl.id_adv_input_link)
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = gt.id_guideline)
                             WHERE gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND src_tbl.flg_type = l_var_t) temp_data
                     WHERE temp_data.id_adv_input_link > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_adv_input_value dest_tbl
                     WHERE dest_tbl.id_adv_input_link = def_data.id_adv_input_link
                       AND dest_tbl.flg_type = def_data.flg_type
                       AND dest_tbl.id_advanced_input = def_data.id_advanced_input
                       AND dest_tbl.id_advanced_input_field = def_data.id_advanced_input_field
                       AND (dest_tbl.id_advanced_input_field_det = def_data.id_advanced_input_field_det OR
                           dest_tbl.id_advanced_input_field_det IS NULL));
    
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
    END set_guide_adv_input_search;
    FUNCTION set_guideline_frequent_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_guideline_frequent_search');
        INSERT INTO guideline_frequent
            (id_guideline_frequent, rank, id_guideline, id_institution, id_software)
            SELECT def_data.id_guideline_frequent,
                   def_data.rank,
                   def_data.id_guideline,
                   def_data.id_institution,
                   def_data.id_software
              FROM (SELECT ((SELECT nvl(MAX(gf.id_guideline_frequent), 0)
                               FROM guideline_frequent gf) + rownum) id_guideline_frequent,
                           rank,
                           temp_data.id_guideline,
                           i_institution id_institution,
                           i_software(pos_soft) id_software,
                           row_number() over(PARTITION BY temp_data.id_guideline ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT rank,
                                   nvl((SELECT ext_g.id_guideline
                                         FROM guideline ext_g
                                        INNER JOIN alert_default.guideline int_g
                                           ON (int_g.id_content = ext_g.id_content)
                                        WHERE ext_g.id_institution = i_institution
                                          AND int_g.id_guideline = src_tbl.id_guideline),
                                       0) id_guideline,
                                   src_tbl.id_software,
                                   gmv.id_market,
                                   gmv.version
                            
                            -- decode FKS to dest_vals
                              FROM alert_default.guideline_frequent src_tbl
                             INNER JOIN alert_default.guideline_mrk_vrs gmv
                                ON (gmv.id_guideline = src_tbl.id_guideline)
                             WHERE src_tbl.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND gmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND gmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_guideline > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM guideline_frequent dest_tbl
                     WHERE dest_tbl.id_guideline = def_data.id_guideline
                       AND dest_tbl.id_software = def_data.id_software
                       AND dest_tbl.id_institution = def_data.id_institution);
    
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
    END set_guideline_frequent_search;
    -- frequent loader method

    FUNCTION del_guideline_frequent_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete guideline_frequent';
        g_func_name := upper('del_guideline_frequent_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM guideline_frequent gf
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gf.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution
                       AND g.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                               FROM TABLE(CAST(i_software AS table_number)) p))
               AND gf.id_institution = i_institution
               AND gf.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM guideline_frequent gf
             WHERE EXISTS (SELECT 1
                      FROM guideline g
                     WHERE g.id_guideline = gf.id_guideline
                       AND g.id_professional IS NULL
                       AND g.id_institution = i_institution)
               AND gf.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            alert.pk_alert_exceptions.process_error(i_lang,
                                                    SQLCODE,
                                                    SQLERRM,
                                                    g_error,
                                                    g_package_owner,
                                                    g_package_name,
                                                    g_func_name,
                                                    o_error);
            alert.pk_utils.undo_changes;
            alert.pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END del_guideline_frequent_search;

    -- global vars
    PROCEDURE reset_cfg_done IS
    BEGIN
        g_cfg_done := 'FALSE';
    END reset_cfg_done;

    FUNCTION get_cfg_done RETURN VARCHAR2 IS
    BEGIN
        RETURN g_cfg_done;
    END get_cfg_done;
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

    g_cfg_done := 'FALSE';
END pk_guideline_prm;
/
