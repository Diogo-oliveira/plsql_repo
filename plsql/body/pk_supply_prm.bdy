/*-- Last Change Revision: $Rev: 1985453 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-04-09 14:30:59 +0100 (sex, 09 abr 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_supply_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_SUPPLY_prm';
    pos_soft        NUMBER := 1;
    --  g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_supplies_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('supplies.code_supplies.');
    
    BEGIN
    
        g_func_name := upper('load_supplies_def');
    
        INSERT INTO supplies
            (id_supplies, code_supplies, flg_available, id_content)
            SELECT seq_supplies.nextval, l_code_translation || seq_supplies.currval, g_flg_available, id_content
              FROM (SELECT ad_s.id_supplies, ad_s.id_content
                      FROM ad_supplies ad_s
                     WHERE ad_s.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM supplies a_s
                             WHERE a_s.id_content = ad_s.id_content
                               AND a_s.flg_available = g_flg_available)) def_data;
    
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
        
    END load_supplies_def;

    FUNCTION load_supply_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('SUPPLY.CODE_SUPPLY.');
    
    BEGIN
    
        g_func_name := upper('LOAD_SUPPLY_DEF');
    
        INSERT INTO supply
            (id_supply, id_content, code_supply, id_supply_type, flg_type, standard_code)
            SELECT seq_supply.nextval,
                   id_content,
                   l_code_translation || seq_supply.currval,
                   id_supply_type,
                   flg_type,
                   standard_code
              FROM (SELECT a_s.id_content,
                           nvl((SELECT a_st.id_supply_type
                                 FROM supply_type a_st
                                 JOIN ad_supply_type ad_st
                                   ON ad_st.id_content = a_st.id_content
                                WHERE ad_st.id_supply_type = a_s.id_supply_type
                                  AND ad_st.flg_available = g_flg_available
                                  AND a_st.flg_available = g_flg_available),
                               0) id_supply_type,
                           a_s.flg_type,
                           a_s.standard_code
                      FROM ad_supply a_s
                     WHERE a_s.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM supply a_s1
                             WHERE a_s1.id_content = a_s.id_content
                               AND a_s1.flg_available = g_flg_available)) def_data
             WHERE def_data.id_supply_type > 0;
    
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
        
    END load_supply_def;

    FUNCTION load_supply_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('supply_type.code_supply_type.');
        l_level_array      table_number := table_number();
    
    BEGIN
    
        SELECT DISTINCT LEVEL
          BULK COLLECT
          INTO l_level_array
          FROM ad_supply_type st
         WHERE st.flg_available = g_flg_available
         START WITH st.id_parent IS NULL
        CONNECT BY PRIOR st.id_supply_type = st.id_parent
         ORDER BY LEVEL ASC;
    
        g_func_name := upper('load_supply_type_def');
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO supply_type
                (id_supply_type, id_content, code_supply_type, id_parent, flg_available)
                SELECT seq_supply_type.nextval,
                       id_content,
                       l_code_translation || seq_supply_type.currval,
                       id_parent,
                       g_flg_available
                  FROM (SELECT ad_st.id_content,
                               decode(ad_st.id_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT a_st.id_supply_type
                                            FROM supply_type a_st
                                            JOIN ad_supply_type ad_st1
                                              ON a_st.id_content = ad_st1.id_content
                                           WHERE ad_st1.id_supply_type = ad_st.id_parent
                                             AND a_st.flg_available = g_flg_available
                                             AND ad_st1.flg_available = g_flg_available),
                                          0)) id_parent,
                               LEVEL lvl
                          FROM ad_supply_type ad_st
                         WHERE ad_st.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                                  FROM supply_type a_st1
                                 WHERE a_st1.id_content = ad_st.id_content
                                   AND a_st1.flg_available = g_flg_available)
                         START WITH ad_st.id_parent IS NULL
                        CONNECT BY PRIOR ad_st.id_supply_type = ad_st.id_parent) def_data
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND (def_data.id_parent > 0 OR def_data.id_parent IS NULL);
    
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
        
    END load_supply_type_def;

    /**
    * Get id context per flag context
    *
    * @param i_lang                      Prefered language ID
    * @param i_flg_context_def      Flag context alert default
    * @param i_id_context_def       ID context alert default
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID
    *
    *
    * @return                       id_context
    *
    * @updateauthor            Adriana Salgueiro
    * @updateversion           v2.8.1.0
    * @updated                    2019/02/06
    */

    FUNCTION get_supply_context
    (
        i_lang            IN NUMBER,
        i_flg_context_def IN supply_context.flg_context%TYPE,
        i_id_context_def  IN supply_context.id_context%TYPE,
        i_id_institution  IN NUMBER,
        i_id_software     IN NUMBER
    ) RETURN VARCHAR IS
    
        o_id_context_alert supply_context.id_context%TYPE;
        o_error            t_error_out;
        l_medication_ctx CONSTANT VARCHAR2(1) := 'M';
        l_interv_ctx     CONSTANT VARCHAR2(1) := 'P';
        l_mfr_ctx        CONSTANT VARCHAR2(1) := 'F';
        l_icnp_ctx       CONSTANT VARCHAR2(1) := 'I';
        l_labtest_ctx    CONSTANT VARCHAR2(1) := 'A';
        l_imageexm_ctx   CONSTANT VARCHAR2(1) := 'E';
        l_otherexm_ctx   CONSTANT VARCHAR2(1) := 'O';
        l_srinterv_ctx   CONSTANT VARCHAR2(1) := 'S';
    
    BEGIN
    
        g_func_name := upper('get_supply_context');
    
        IF (i_flg_context_def = l_interv_ctx OR i_flg_context_def = l_mfr_ctx)
        THEN
            -- compare procedures
            SELECT nvl((SELECT a_i.id_intervention
                         FROM intervention a_i
                        INNER JOIN ad_intervention ad_i
                           ON ad_i.id_content = a_i.id_content
                          AND ad_i.flg_status = 'A'
                        WHERE a_i.flg_status = 'A'
                          AND ad_i.id_intervention = i_id_context_def
                          AND EXISTS (SELECT 0
                                 FROM interv_dep_clin_serv a_idcs
                                WHERE a_idcs.id_institution = i_id_institution
                                  AND a_idcs.id_software = i_id_software
                                  AND a_idcs.id_intervention = a_i.id_intervention)),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSIF (i_flg_context_def = l_icnp_ctx)
        THEN
            -- compare nursing procedures
            SELECT nvl((SELECT a_ic.id_composition
                         FROM icnp_composition a_ic
                        INNER JOIN ad_icnp_composition ad_ic
                           ON ad_ic.id_content = a_ic.id_content
                          AND ad_ic.flg_available = g_flg_available
                        WHERE a_ic.flg_available = g_flg_available
                          AND ad_ic.id_composition = i_id_context_def),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSIF (i_flg_context_def = l_labtest_ctx)
        THEN
            -- compare lab tests
            SELECT nvl((SELECT a_a.id_analysis
                         FROM analysis a_a
                        INNER JOIN ad_analysis ad_a
                           ON ad_a.id_content = a_a.id_content
                          AND ad_a.flg_available = g_flg_available
                        WHERE a_a.flg_available = g_flg_available
                          AND ad_a.id_analysis = i_id_context_def
                          AND EXISTS (SELECT 0
                                 FROM analysis_instit_soft a_ais
                                WHERE a_ais.id_institution = i_id_institution
                                  AND a_ais.id_software = i_id_software
                                  AND a_ais.id_analysis = a_a.id_analysis
                                  AND a_ais.flg_available = g_flg_available)),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSIF (i_flg_context_def = l_imageexm_ctx OR i_flg_context_def = l_otherexm_ctx)
        THEN
            -- compare exams
            SELECT nvl((SELECT a_e.id_exam
                         FROM exam a_e
                        INNER JOIN ad_exam ad_e
                           ON ad_e.id_content = a_e.id_content
                          AND ad_e.flg_available = g_flg_available
                        WHERE a_e.flg_available = g_flg_available
                          AND ad_e.id_exam = i_id_context_def
                          AND EXISTS (SELECT 0
                                 FROM exam_dep_clin_serv a_edcs
                                WHERE a_edcs.id_institution = i_id_institution
                                  AND a_edcs.id_software = i_id_software
                                  AND a_edcs.id_exam = a_e.id_exam)),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSIF (i_flg_context_def = l_srinterv_ctx)
        THEN
            -- compare surgical interventions
            SELECT nvl((SELECT a_i.id_intervention
                         FROM intervention a_i
                        INNER JOIN ad_intervention ad_i
                           ON ad_i.id_content = a_i.id_content
                          AND ad_i.flg_status = 'A'
                        WHERE a_i.flg_status = 'A'
                          AND ad_i.id_intervention = i_id_context_def
                          AND EXISTS (SELECT 0
                                 FROM interv_dep_clin_serv a_idcs
                                WHERE a_idcs.id_institution = i_id_institution
                                  AND a_idcs.id_software = i_id_software
                                  AND a_idcs.id_intervention = a_i.id_intervention
                                  AND rownum = 1)),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSIF (i_flg_context_def = l_medication_ctx)
        THEN
            SELECT nvl((SELECT DISTINCT ad_sc.id_context
                         FROM ad_supply_context ad_sc
                        INNER JOIN apm_product apm_p
                           ON apm_p.id_product = ad_sc.id_product
                          AND apm_p.id_product_supplier = ad_sc.id_product_supplier
                        WHERE ad_sc.id_context = i_id_context_def
                          AND apm_p.flg_available = g_flg_available),
                       0)
              INTO o_id_context_alert
              FROM dual;
        
        ELSE
            o_id_context_alert := NULL;
        
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
            NULL;
            RETURN 0;
        
    END get_supply_context;

    /**
    * Set association between supplies and interventions/medication/icnp/labtests/exams
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution       Institution ID
    * @param i_mkt                     market id
    * @param i_vers                     version of content
    * @param i_id_software          Software ID
    * @param o_result_tbl            Number of records inserted
    * @param o_error                   Error
    *
    *
    * @return                       true or false on success or error
    *
    * @updateauthor            Adriana Salgueiro
    * @updateversion           v2.8.1.0
    * @updated                    2019/02/06
    */

    FUNCTION set_supply_context_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_supply_context_search');
    
        INSERT INTO supply_context
            (id_supply_context,
             id_supply,
             quantity,
             id_unit_measure,
             id_context,
             flg_context,
             id_institution,
             id_software)
            SELECT seq_supply_context.nextval,
                   def_data.id_supply,
                   def_data.quantity,
                   def_data.id_unit_measure,
                   def_data.id_context,
                   def_data.flg_context,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_supply,
                           temp_data.quantity,
                           temp_data.id_unit_measure,
                           temp_data.id_context,
                           temp_data.flg_context,
                           row_number() over(PARTITION BY temp_data.id_supply, temp_data.id_context, temp_data.flg_context ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_s.id_supply
                                                FROM supply a_s
                                                JOIN ad_supply ad_s
                                                  ON a_s.id_content = ad_s.id_content
                                               WHERE ad_s.id_supply = ad_sc.id_supply
                                                 AND a_s.flg_available = g_flg_available
                                                 AND ad_s.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_s.id_supply
                                                FROM supply a_s
                                                JOIN ad_supply ad_s
                                                  ON a_s.id_content = ad_s.id_content
                                               WHERE ad_s.id_supply = ad_sc.id_supply
                                                 AND a_s.flg_available = g_flg_available
                                                 AND ad_s.flg_available = g_flg_available
                                                 AND a_s.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_supply,
                                   ad_sc.quantity,
                                   nvl2(ad_sc.id_unit_measure,
                                        nvl((SELECT a_um.id_unit_measure
                                              FROM unit_measure a_um
                                             WHERE a_um.id_unit_measure = ad_sc.id_unit_measure
                                               AND a_um.flg_available = g_flg_available),
                                            '0'),
                                        NULL) id_unit_measure,
                                   pk_supply_prm.get_supply_context(i_lang,
                                                                    ad_sc.flg_context,
                                                                    ad_sc.id_context,
                                                                    i_institution,
                                                                    i_software(pos_soft)) id_context,
                                   ad_sc.flg_context,
                                   ad_sc.id_software,
                                   ad_smv.id_market,
                                   ad_smv.version
                            -- decode FKS to dest_vals
                              FROM ad_supply_context ad_sc
                             INNER JOIN ad_supply_mrk_vrs ad_smv
                                ON ad_sc.id_supply = ad_smv.id_supply
                             WHERE ad_sc.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_smv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_smv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_supply > 0
               AND (def_data.id_context != '0' OR def_data.id_context IS NULL)
               AND (def_data.id_unit_measure > 0 OR def_data.id_unit_measure IS NULL)
               AND NOT EXISTS (SELECT 0
                      FROM supply_context a_sc
                     WHERE a_sc.id_institution = i_institution
                       AND a_sc.id_software = i_software(pos_soft)
                       AND a_sc.id_supply = def_data.id_supply
                       AND a_sc.id_context = def_data.id_context
                       AND a_sc.flg_context = def_data.flg_context);
    
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
        
    END set_supply_context_search;

    FUNCTION del_supply_context_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete supply_context';
        g_func_name := upper('del_supply_context_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM supply_context a_sc
             WHERE a_sc.id_institution = i_institution
               AND a_sc.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM supply_context sc
             WHERE sc.id_institution = i_institution;
        
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
        
    END del_supply_context_search;

    FUNCTION set_supply_loc_default_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_supply_loc_default_search');
    
        INSERT INTO supply_loc_default
            (id_supply_loc_default, id_supply_soft_inst, id_supply_location, flg_default)
            SELECT seq_supply_loc_default.nextval,
                   def_data.id_supply_soft_inst,
                   def_data.id_supply_location,
                   def_data.flg_default
              FROM (SELECT temp_data.id_supply_soft_inst,
                           temp_data.id_supply_location,
                           temp_data.flg_default,
                           row_number() over(PARTITION BY temp_data.id_supply_soft_inst, temp_data.id_supply_location ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT -- decode FKS to dest_vals
                             nvl((SELECT a_sl.id_supply_location
                                   FROM supply_location a_sl
                                  WHERE a_sl.id_supply_location = ad_sld.id_supply_location),
                                 0) id_supply_location,
                             ad_sld.flg_default,
                             decode(l_cnt_count,
                                    0,
                                    nvl((SELECT a_ssi.id_supply_soft_inst
                                          FROM supply_soft_inst a_ssi
                                          JOIN supply a_s
                                            ON a_s.id_supply = a_ssi.id_supply
                                          JOIN ad_supply ad_s
                                            ON ad_s.id_content = a_s.id_content
                                         WHERE ad_s.id_supply = ad_ssi.id_supply
                                           AND a_ssi.id_institution = i_institution
                                           AND a_ssi.id_software = i_software(pos_soft)
                                           AND ad_s.flg_available = g_flg_available
                                           AND a_s.flg_available = g_flg_available
                                           AND a_ssi.flg_cons_type = ad_ssi.flg_cons_type),
                                        0),
                                    nvl((SELECT a_ssi.id_supply_soft_inst
                                          FROM supply_soft_inst a_ssi
                                          JOIN supply a_s
                                            ON a_s.id_supply = a_ssi.id_supply
                                          JOIN ad_supply ad_s
                                            ON ad_s.id_content = a_s.id_content
                                         WHERE ad_s.id_supply = ad_ssi.id_supply
                                           AND a_ssi.id_institution = i_institution
                                           AND a_ssi.id_software = i_software(pos_soft)
                                           AND ad_s.flg_available = g_flg_available
                                           AND a_s.flg_available = g_flg_available
                                           AND a_ssi.flg_cons_type = ad_ssi.flg_cons_type
                                           AND a_s.id_content IN
                                               (SELECT /*+ opt_estimate(p rows = 10)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_id_content AS table_varchar)))),
                                        0)) id_supply_soft_inst,
                             ad_ssi.id_software,
                             ad_smv.id_market,
                             ad_smv.version
                              FROM ad_supply_loc_default ad_sld
                             INNER JOIN ad_supply_soft_inst ad_ssi
                                ON ad_ssi.id_supply_soft_inst = ad_sld.id_supply_soft_inst
                             INNER JOIN ad_supply_mrk_vrs ad_smv
                                ON ad_smv.id_supply = ad_ssi.id_supply
                             WHERE ad_ssi.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_smv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND ad_smv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_supply_soft_inst > 0
                       AND temp_data.id_supply_location > 0
                       AND NOT EXISTS (SELECT 0
                              FROM supply_loc_default a_sld
                             WHERE a_sld.id_supply_location = temp_data.id_supply_location
                               AND a_sld.id_supply_soft_inst = temp_data.id_supply_soft_inst)) def_data
             WHERE def_data.records_count = 1;
    
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
        
    END set_supply_loc_default_search;

    FUNCTION del_supply_loc_default_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete supply_loc_default';
        g_func_name := upper('del_supply_loc_default_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM supply_loc_default sld
             WHERE EXISTS
             (SELECT 1
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply_soft_inst = sld.id_supply_soft_inst
                       AND ssi.id_institution = i_institution
                       AND ssi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM supply_loc_default sld
             WHERE EXISTS (SELECT 1
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply_soft_inst = sld.id_supply_soft_inst
                       AND ssi.id_institution = i_institution);
        
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
        
    END del_supply_loc_default_search;

    FUNCTION set_supply_reason_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('supply_reason.code_supply_reason.');
    
    BEGIN
    
        g_func_name := upper('set_supply_reason_search');
    
        INSERT INTO supply_reason
            (id_supply_reason, code_supply_reason, flg_type, id_institution, flg_available, id_content)
            SELECT seq_supply_reason.nextval,
                   l_code_translation || seq_supply_reason.currval,
                   def_data.flg_type,
                   0,
                   g_flg_available,
                   def_data.id_content
              FROM (SELECT temp_data.flg_type,
                           temp_data.id_content,
                           row_number() over(PARTITION BY temp_data.id_content ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT ad_sr.flg_type, ad_sr.id_content, ad_srmv.id_market, ad_srmv.version
                            -- decode FKS to dest_vals
                              FROM ad_supply_reason ad_sr
                             INNER JOIN ad_supply_reason_mrk_vrs ad_srmv
                                ON ad_sr.id_supply_reason = ad_srmv.id_supply_reason
                             WHERE ad_sr.flg_available = g_flg_available
                               AND ad_srmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_srmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM supply_reason a_sr
                     WHERE nvl(a_sr.id_institution, 0) IN (i_institution, 0)
                       AND a_sr.id_content = def_data.id_content
                       AND a_sr.flg_available = g_flg_available);
    
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
        
    END set_supply_reason_search;

    FUNCTION set_supply_relation_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_supply_relation_search');
    
        INSERT INTO supply_relation
            (id_supply, id_supply_item, quantity, id_unit_measure)
            SELECT def_data.id_supply, def_data.id_supply_item, def_data.quantity, def_data.id_unit_measure
              FROM (SELECT temp_data.id_supply,
                           temp_data.id_supply_item,
                           temp_data.quantity,
                           temp_data.id_unit_measure,
                           row_number() over(PARTITION BY temp_data.id_supply, temp_data.id_supply_item ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_s.id_supply
                                                FROM supply a_s
                                                JOIN ad_supply ad_s
                                                  ON ad_s.id_content = a_s.id_content
                                               WHERE ad_s.id_supply = ad_sr.id_supply
                                                 AND a_s.flg_available = g_flg_available
                                                 AND ad_s.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_s.id_supply
                                                FROM supply a_s
                                                JOIN ad_supply ad_s
                                                  ON ad_s.id_content = a_s.id_content
                                               WHERE ad_s.id_supply = ad_sr.id_supply
                                                 AND a_s.flg_available = g_flg_available
                                                 AND ad_s.flg_available = g_flg_available
                                                 AND a_s.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_supply,
                                   nvl((SELECT a_s.id_supply
                                         FROM supply a_s
                                        INNER JOIN ad_supply ad_s
                                           ON ad_s.id_content = a_s.id_content
                                        WHERE ad_s.id_supply = ad_sr.id_supply_item
                                          AND ad_s.flg_available = g_flg_available
                                          AND a_s.flg_available = g_flg_available),
                                       0) id_supply_item,
                                   ad_sr.quantity,
                                   decode(ad_sr.id_unit_measure,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT a_um.id_unit_measure
                                                 FROM unit_measure a_um
                                                WHERE a_um.id_unit_measure = ad_sr.id_unit_measure
                                                  AND a_um.flg_available = g_flg_available),
                                               0))) id_unit_measure,
                                   ad_sr.id_market,
                                   ad_sr.version
                            -- decode FKS to dest_vals
                              FROM ad_supply_relation ad_sr
                             INNER JOIN ad_supply_mrk_vrs ad_smv
                                ON ad_smv.id_supply = ad_sr.id_supply
                             WHERE ad_sr.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_sr.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_smv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_smv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_supply > 0
               AND (def_data.id_unit_measure > 0 OR def_data.id_unit_measure IS NULL)
               AND NOT EXISTS (SELECT 0
                      FROM supply_relation a_sr
                     WHERE a_sr.id_supply = def_data.id_supply
                       AND a_sr.id_supply_item = def_data.id_supply_item);
    
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
        
    END set_supply_relation_search;

    FUNCTION set_supply_soft_inst_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_supply_soft_inst_search');
    
        INSERT INTO supply_soft_inst
            (id_supply_soft_inst,
             id_supply,
             quantity,
             id_unit_measure,
             id_institution,
             flg_cons_type,
             flg_reusable,
             flg_editable,
             total_avail_quantity,
             flg_preparing,
             flg_countable,
             id_software)
            SELECT seq_supply_soft_inst.nextval,
                   def_data.id_supply,
                   def_data.quantity,
                   def_data.id_unit_measure,
                   i_institution,
                   def_data.flg_cons_type,
                   def_data.flg_reusable,
                   def_data.flg_editable,
                   def_data.total_avail_quantity,
                   def_data.flg_preparing,
                   def_data.flg_countable,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_supply,
                           temp_data.quantity,
                           temp_data.id_unit_measure,
                           temp_data.flg_cons_type,
                           temp_data.flg_reusable,
                           temp_data.flg_editable,
                           temp_data.total_avail_quantity,
                           temp_data.flg_preparing,
                           temp_data.flg_countable,
                           row_number() over(PARTITION BY temp_data.id_supply, temp_data.flg_cons_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT /*+ index(ss SSI_SW_BIDX)*/
                             decode(l_cnt_count,
                                    0,
                                    nvl((SELECT a_s.id_supply
                                          FROM supply a_s
                                         INNER JOIN ad_supply ad_s
                                            ON ad_s.id_content = a_s.id_content
                                         WHERE a_s.flg_available = g_flg_available
                                           AND ad_s.flg_available = g_flg_available
                                           AND ad_s.id_supply = ad_ssi.id_supply),
                                        0),
                                    nvl((SELECT a_s.id_supply
                                          FROM supply a_s
                                         INNER JOIN ad_supply ad_s
                                            ON ad_s.id_content = a_s.id_content
                                         WHERE a_s.flg_available = g_flg_available
                                           AND ad_s.flg_available = g_flg_available
                                           AND ad_s.id_supply = ad_ssi.id_supply
                                           AND a_s.id_content IN
                                               (SELECT /*+ opt_estimate(p rows = 10)*/
                                                 column_value
                                                  FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                        0)) id_supply,
                             ad_ssi.quantity,
                             decode(ad_ssi.id_unit_measure,
                                    NULL,
                                    NULL,
                                    nvl((SELECT um.id_unit_measure
                                          FROM unit_measure um
                                         WHERE um.id_unit_measure = ad_ssi.id_unit_measure
                                           AND um.flg_available = g_flg_available),
                                        0)) id_unit_measure,
                             ad_ssi.flg_cons_type,
                             ad_ssi.flg_reusable,
                             ad_ssi.flg_editable,
                             ad_ssi.total_avail_quantity,
                             ad_ssi.flg_preparing,
                             ad_ssi.flg_countable,
                             ad_ssi.id_software,
                             ad_smv.id_market,
                             ad_smv.version
                            -- decode FKS to dest_vals
                              FROM ad_supply_soft_inst ad_ssi
                              JOIN ad_supply_mrk_vrs ad_smv
                                ON ad_smv.id_supply = ad_ssi.id_supply
                             WHERE ad_smv.id_market IN (SELECT /*+ dynamic_sampling(2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_smv.version IN (SELECT /*+ dynamic_sampling(2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_ssi.id_software IN
                                   (SELECT /*+ dynamic_sampling(2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                     WHERE (temp_data.id_unit_measure > 0 OR temp_data.id_unit_measure IS NULL)
                       AND temp_data.id_supply > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM supply_soft_inst a_ssi
                     WHERE a_ssi.id_institution = i_institution
                       AND a_ssi.id_software = i_software(pos_soft)
                       AND a_ssi.id_supply = def_data.id_supply
                          --added to avoid errors while running default process : alert table allows more than one row
                       AND rownum = 1);
    
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
        
    END set_supply_soft_inst_search;

    FUNCTION del_supply_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete supply_soft_inst';
        g_func_name := upper('del_supply_soft_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM supply_soft_inst ssi
             WHERE ssi.id_institution = i_institution
               AND ssi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM supply_soft_inst ssi
             WHERE ssi.id_institution = i_institution;
        
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
        
    END del_supply_soft_inst_search;

    FUNCTION set_supply_sup_area_search
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
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('set_supply_sup_area_search');
    
        INSERT INTO supply_sup_area
            (id_supply_area, id_supply_soft_inst, flg_available)
            SELECT def_data.id_supply_area, def_data.id_supply_soft_inst, g_flg_available
              FROM (SELECT temp_data.id_supply_area,
                           temp_data.id_supply_soft_inst,
                           row_number() over(PARTITION BY temp_data.id_supply_area, temp_data.id_supply_soft_inst ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT a_sa.id_supply_area
                                         FROM supply_area a_sa
                                        WHERE a_sa.id_supply_area = ad_ssa.id_supply_area),
                                       0) id_supply_area,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_ssi.id_supply_soft_inst
                                                FROM supply_soft_inst a_ssi
                                                JOIN supply a_s
                                                  ON a_s.id_supply = a_ssi.id_supply
                                                JOIN ad_supply ad_s
                                                  ON ad_s.id_content = a_s.id_content
                                               WHERE ad_s.id_supply = ad_ssi.id_supply
                                                 AND a_ssi.id_institution = i_institution
                                                 AND a_ssi.id_software = i_software(pos_soft)
                                                 AND ad_s.flg_available = g_flg_available
                                                 AND a_s.flg_available = g_flg_available
                                                 AND a_ssi.flg_cons_type = ad_ssi.flg_cons_type),
                                              0),
                                          nvl((SELECT a_ssi.id_supply_soft_inst
                                                FROM supply_soft_inst a_ssi
                                                JOIN supply a_s
                                                  ON a_s.id_supply = a_ssi.id_supply
                                                JOIN ad_supply ad_s
                                                  ON ad_s.id_content = a_s.id_content
                                               WHERE ad_s.id_supply = ad_ssi.id_supply
                                                 AND a_ssi.id_institution = i_institution
                                                 AND a_ssi.id_software = i_software(pos_soft)
                                                 AND ad_s.flg_available = g_flg_available
                                                 AND a_s.flg_available = g_flg_available
                                                 AND a_ssi.flg_cons_type = ad_ssi.flg_cons_type
                                                 AND a_s.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)))),
                                              0)) id_supply_soft_inst,
                                   ad_ssa.flg_available,
                                   ad_ssi.id_software,
                                   ad_smv.id_market,
                                   ad_smv.version
                            -- decode FKS to dest_vals
                              FROM ad_supply_sup_area ad_ssa
                             INNER JOIN ad_supply_soft_inst ad_ssi
                                ON ad_ssa.id_supply_soft_inst = ad_ssi.id_supply_soft_inst
                             INNER JOIN ad_supply_mrk_vrs ad_smv
                                ON ad_ssi.id_supply = ad_smv.id_supply
                             WHERE ad_ssa.flg_available = g_flg_available
                               AND ad_ssi.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_smv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_smv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.id_supply_soft_inst > 0
               AND def_data.id_supply_area > 0
               AND NOT EXISTS (SELECT 0
                      FROM supply_sup_area ssa1
                     WHERE ssa1.id_supply_area = def_data.id_supply_area
                       AND ssa1.id_supply_soft_inst = def_data.id_supply_soft_inst
                       AND ssa1.flg_available = g_flg_available);
    
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
        
    END set_supply_sup_area_search;

    -- frequent loader method

    FUNCTION del_supply_sup_area_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete supply_sup_area';
        g_func_name := upper('del_supply_sup_area_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM supply_sup_area ssa
             WHERE EXISTS
             (SELECT 1
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply_soft_inst = ssa.id_supply_soft_inst
                       AND ssi.id_institution = i_institution
                       AND ssi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                                column_value
                                                 FROM TABLE(CAST(i_software AS table_number)) p));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM supply_sup_area ssa
             WHERE EXISTS (SELECT 1
                      FROM supply_soft_inst ssi
                     WHERE ssi.id_supply_soft_inst = ssa.id_supply_soft_inst
                       AND ssi.id_institution = i_institution);
        
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
        
    END del_supply_sup_area_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_supply_prm;
/
