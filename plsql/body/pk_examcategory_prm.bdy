/*-- Last Change Revision: $Rev: 1904835 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-05 09:32:58 +0100 (qua, 05 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_examcategory_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_EXAMCATEGORY_prm';

    -- Private Methods

    -- content loader method
    FUNCTION load_exam_category_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('exam_cat.code_exam_cat.');
        l_level_array      table_number := table_number();
    BEGIN
    
        SELECT DISTINCT LEVEL BULK COLLECT
          INTO l_level_array
          FROM alert_default.exam_cat ec
         WHERE ec.flg_available = g_flg_available
         START WITH ec.parent_id IS NULL
        CONNECT BY PRIOR ec.id_exam_cat = ec.parent_id
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO exam_cat
                (id_exam_cat, code_exam_cat, flg_available, flg_lab, id_content, parent_id, flg_interface, rank)
                SELECT seq_exam_cat.nextval,
                       l_code_translation || seq_exam_cat.currval,
                       g_flg_available,
                       flg_lab,
                       id_content,
                       parent_id,
                       flg_interface,
                       rank
                  FROM (SELECT ec.id_exam_cat,
                               ec.flg_lab,
                               ec.id_content,
                               decode(ec.parent_id,
                                      NULL,
                                      NULL,
                                      nvl((SELECT ecc.id_exam_cat
                                            FROM exam_cat ecc
                                            JOIN alert_default.exam_cat adec
                                              ON ecc.id_content = adec.id_content
                                           WHERE ec.parent_id = adec.id_exam_cat
                                             AND ecc.flg_available = g_flg_available
                                             AND adec.flg_available = g_flg_available),
                                          0)) parent_id,
                               ec.flg_interface,
                               ec.rank,
                               LEVEL lvl
                          FROM alert_default.exam_cat ec
                         WHERE ec.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                                  FROM exam_cat dest_tbl
                                 WHERE ec.id_content = dest_tbl.id_content
                                   AND ec.flg_available = g_flg_available)
                         START WITH ec.parent_id IS NULL
                        CONNECT BY PRIOR ec.id_exam_cat = ec.parent_id) def_data
                
                 WHERE def_data.lvl = l_level_array(c_level)
                   AND (def_data.parent_id > 0 OR def_data.parent_id IS NULL);
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
    END load_exam_category_def;
    -- searcheable loader method

    -- frequent loader method
    FUNCTION set_exam_cat_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_software          IN table_number,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_exam_cat_freq');
        INSERT INTO exam_cat_dcs
            (id_exam_cat_dcs, id_exam_cat, id_dep_clin_serv)
            SELECT seq_exam_cat_dcs.nextval, def_data.id_exam_cat, i_dep_clin_serv_out
              FROM (SELECT temp_data.id_exam_cat,
                           row_number() over(PARTITION BY temp_data.id_exam_cat ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT alert_ec.id_exam_cat
                                         FROM exam_cat alert_ec
                                        INNER JOIN alert_default.exam_cat def_ec
                                           ON (def_ec.id_content = alert_ec.id_content AND
                                              def_ec.flg_available = g_flg_available)
                                        WHERE def_ec.id_exam_cat = ecc.id_exam_cat
                                          AND alert_ec.flg_available = g_flg_available),
                                       0) id_exam_cat,
                                   ecc.id_market,
                                   ecc.version
                              FROM alert_default.exam_cat_cs ecc
                             WHERE ecc.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ecc.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ecc.id_clin_serv IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                     WHERE temp_data.id_exam_cat > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM exam_cat_dcs ecdcs
                     WHERE ecdcs.id_exam_cat = def_data.id_exam_cat
                       AND ecdcs.id_dep_clin_serv = i_dep_clin_serv_out);
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
    END set_exam_cat_freq;
	
	FUNCTION del_exam_cat_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
        o_dcs_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete exam_cat_dcs';
        g_func_name := upper('del_exam_cat_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0
               AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                       column_value
                                        FROM TABLE(CAST(i_software AS table_number)) sw_list);
        ELSE
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv dcs
             INNER JOIN department d
                ON (d.id_department = dcs.id_department)
             INNER JOIN dept dp
                ON (dp.id_dept = d.id_dept)
             INNER JOIN software_dept sd
                ON (sd.id_dept = dp.id_dept)
             WHERE d.id_institution = i_institution
               AND d.id_institution = dp.id_institution
               AND dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM exam_cat_dcs ecdcs
         WHERE ecdcs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(o_dcs_list AS table_number)) p);
    
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
    END del_exam_cat_freq;
	
    -- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_examcategory_prm;
/