/*-- Last Change Revision: $Rev: 1905052 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 11:16:23 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_lens_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_LENS_prm';
    pos_soft        NUMBER := 1;
    --g_table_name    t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_lens_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('lens.code_lens.');
        l_level_array      table_number := table_number();
    BEGIN
        g_func_name := upper('load_lens_def');
    
        SELECT DISTINCT LEVEL
          BULK COLLECT
          INTO l_level_array
          FROM alert_default.lens l
         START WITH l.id_parent IS NULL
        CONNECT BY PRIOR l.id_lens = l.id_parent
         ORDER BY LEVEL ASC;
    
        FORALL c_level IN 1 .. l_level_array.count
            INSERT INTO lens
                (id_lens, code_lens, flg_type, id_parent, id_content, flg_undefined)
                SELECT seq_lens.nextval,
                       l_code_translation || seq_lens.currval,
                       flg_type,
                       id_parent,
                       id_content,
                       flg_undefined
                  FROM (SELECT l.id_lens,
                               l.id_content,
                               l.flg_type,
                               decode(l.id_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT ll.id_lens
                                            FROM lens ll
                                            JOIN alert_default.lens al
                                              ON ll.id_content = al.id_content
                                           WHERE al.id_lens = l.id_parent),
                                          
                                          0)) id_parent,
                               l.flg_undefined,
                               LEVEL lvl
                          FROM alert_default.lens l
                         WHERE NOT EXISTS (SELECT 0
                                  FROM lens dest_tbl
                                 WHERE dest_tbl.id_content = l.id_content)
                         START WITH l.id_parent IS NULL
                        CONNECT BY PRIOR l.id_lens = l.id_parent) def_data
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
    END load_lens_def;

    FUNCTION load_lens_advanced_input_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_lens_advanced_input_def');
        INSERT INTO lens_advanced_input
            (id_lens, id_advanced_input)
            SELECT id_lens, id_advanced_input
              FROM (SELECT l.id_lens, lai.id_advanced_input
                      FROM alert_default.lens def_l
                      JOIN alert_default.lens_advanced_input lai
                        ON def_l.id_lens = lai.id_lens
                      JOIN lens l
                        ON l.id_content = def_l.id_content
                     WHERE NOT EXISTS (SELECT 0
                              FROM lens_advanced_input dest_tbl
                             WHERE dest_tbl.id_advanced_input = lai.id_advanced_input
                               AND dest_tbl.id_lens = l.id_lens)) def_data;
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
    END load_lens_advanced_input_def;
    -- searcheable loader method
    FUNCTION set_lens_soft_inst_search
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
        g_func_name := upper('set_lens_soft_inst_search');
        INSERT INTO lens_soft_inst
            (id_lens, flg_available, rank, id_institution, id_software)
        
            SELECT def_data.i_lens, def_data.flg_available, def_data.rank, i_institution, i_software(pos_soft)
            
              FROM (SELECT temp_data.i_lens,
                           temp_data.flg_available,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.i_lens
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT lsi.rowid l_row,
                                   nvl((SELECT l.id_lens
                                         FROM lens l
                                        WHERE l.id_content = ld.id_content
                                          AND rownum = 1),
                                       0) i_lens,
                                   lsi.flg_available,
                                   lsi.rank,
                                   lsi.id_software,
                                   lmv.id_market,
                                   lmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.lens_mrk_vrs lmv
                             INNER JOIN alert_default.lens_soft_inst lsi
                                ON lmv.id_lens = lsi.id_lens
                             INNER JOIN alert_default.lens ld
                                ON ld.id_lens = lsi.id_lens
                             WHERE lsi.flg_available = g_flg_available
                               AND lsi.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND lmv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND lmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_lens > 0
               AND NOT EXISTS (SELECT 0
                      FROM lens_soft_inst lsi1
                     WHERE lsi1.id_lens = def_data.i_lens
                       AND lsi1.flg_available = def_data.flg_available
                       AND lsi1.id_institution = i_institution
                       AND lsi1.id_software = i_software(pos_soft));
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
    END set_lens_soft_inst_search;

    -- frequent loader method

    FUNCTION del_lens_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete lens_soft_inst';
        g_func_name := upper('del_lens_soft_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM lens_soft_inst lsi
             WHERE lsi.id_institution = i_institution
               AND lsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM lens_soft_inst lsi
             WHERE lsi.id_institution = i_institution;
        
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
    END del_lens_soft_inst_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_lens_prm;
/
