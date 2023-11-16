/*-- Last Change Revision: $Rev: 1905124 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 14:57:52 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_necessity_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_NECESSITY_prm';

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_necessity_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('NECESSITY.code_NECESSITY.');
    BEGIN
        g_func_name := upper('load_NECESSITY_def');
        INSERT INTO necessity
            (id_necessity, code_necessity, flg_available, flg_mov, rank, flg_comb, id_content)
            SELECT seq_necessity.nextval,
                   l_code_translation || seq_necessity.currval,
                   def_data.flg_available,
                   def_data.flg_mov,
                   def_data.rank,
                   def_data.flg_comb,
                   def_data.id_content
              FROM (SELECT source_tbl.flg_available,
                           source_tbl.flg_mov,
                           source_tbl.rank,
                           source_tbl.flg_comb,
                           source_tbl.id_content
                      FROM alert_default.necessity source_tbl
                     WHERE source_tbl.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM necessity dest_tbl
                             WHERE dest_tbl.id_content = source_tbl.id_content
                               AND dest_tbl.flg_available = g_flg_available)) def_data;
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
    END load_necessity_def;
    -- searcheable loader method
    /********************************************************************************************
    * Set Default Necessity Configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_mkt                 Market ID list
    * @param i_vers                Content Version tag list
    * @param i_software            Software ID list
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.3.8
    * @since                       2013/09/26
    ********************************************************************************************/
    FUNCTION set_necessity_search
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
        g_func_name := upper('set_necessity_search');
        g_error     := 'Load Necessity Default Configuration ';
        INSERT INTO necessity_dept_inst_soft
            (id_necessity, flg_type, id_institution, id_software, id_nect_dept_inst_soft, flg_selected, flg_area)
            SELECT def_data.id_necessity,
                   def_data.flg_type,
                   i_institution,
                   i_software(1),
                   seq_necessity_dept_inst_soft.nextval,
                   def_data.flg_selected,
                   def_data.flg_area
              FROM (SELECT temp_data.id_necessity,
                           temp_data.flg_type,
                           temp_data.flg_selected,
                           temp_data.flg_area,
                           row_number() over(PARTITION BY temp_data.id_necessity, temp_data.flg_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT nvl((SELECT n.id_necessity
                                         FROM necessity n
                                        INNER JOIN alert_default.necessity def_n
                                           ON (def_n.id_content = n.id_content)
                                        WHERE n.flg_available = g_flg_available
                                          AND def_n.flg_available = g_flg_available
                                          AND def_n.id_necessity = src_tbl.id_necessity),
                                       g_generic_id) id_necessity,
                                   src_tbl.flg_type,
                                   src_tbl.flg_selected,
                                   src_tbl.flg_area,
                                   src_tbl.id_software,
                                   src_tbl.id_market,
                                   src_tbl.version
                              FROM alert_default.necessity_dept_smv src_tbl
                             WHERE src_tbl.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND src_tbl.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND src_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                     WHERE temp_data.id_necessity > g_generic_id) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS
             (SELECT 0
                      FROM necessity_dept_inst_soft dest_tbl
                     WHERE dest_tbl.id_necessity = def_data.id_necessity
                       AND (dest_tbl.flg_type = def_data.flg_type OR
                           (dest_tbl.flg_type IS NULL AND def_data.flg_type IS NULL))
                       AND (dest_tbl.id_institution = i_institution OR dest_tbl.id_institution = g_generic_id)
                       AND (dest_tbl.id_software = i_software(1) OR dest_tbl.id_software = g_generic_id));
    
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
    END set_necessity_search;
    -- frequent loader method

    FUNCTION del_necessity_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete necessity_dept_inst_soft';
        g_func_name := upper('del_necessity_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM necessity_dept_inst_soft ndis
             WHERE ndis.id_institution = i_institution
               AND ndis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM necessity_dept_inst_soft ndis
             WHERE ndis.id_institution = i_institution;
        
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
    END del_necessity_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_generic_id  := 0;
    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_necessity_prm;
/