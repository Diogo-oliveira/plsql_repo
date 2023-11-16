/*-- Last Change Revision: $Rev: 1905056 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2019-06-06 11:20:59 +0100 (qui, 06 jun 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_surgicalpositioning_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_surgicalpositioning_prm';
    pos_soft        NUMBER := 1;
    --    g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_sr_pos_inst_soft_search
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
        g_func_name := upper('set_sr_pos_inst_soft_search');
        INSERT INTO sr_posit_instit_soft
            (id_sr_posit_instit_soft, id_sr_posit, id_sr_parent, rank, flg_available, id_institution, id_software)
            SELECT seq_sr_posit_instit_soft.nextval,
                   def_data.id_sr_posit,
                   def_data.id_sr_parent,
                   def_data.rank,
                   def_data.flg_available,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_sr_posit,
                           temp_data.id_sr_parent,
                           temp_data.rank,
                           temp_data.flg_available,
                           row_number() over(PARTITION BY temp_data.id_sr_posit
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT spis.id_sr_posit,
                                   spis.id_sr_parent,
                                   spis.rank,
                                   spis.flg_available,
                                   spis.id_software,
                                   spmv.id_market,
                                   spmv.version
                              FROM alert_default.sr_posit_mrk_vrs spmv
                             INNER JOIN alert_default.sr_posit_instit_soft spis
                                ON spis.id_sr_posit = spmv.id_sr_posit
                             INNER JOIN sr_posit sp
                                ON sp.id_sr_posit = spmv.id_sr_posit
                               AND sp.flg_available = g_flg_available
                             WHERE spis.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND spmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND spmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                     column_value
                                                      FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM sr_posit_instit_soft spis1
                     WHERE spis1.id_sr_posit = def_data.id_sr_posit
                       AND spis1.id_software = i_software(pos_soft)
                       AND spis1.id_institution = i_institution);
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
    END set_sr_pos_inst_soft_search;

-- frequent loader method

	FUNCTION del_sr_pos_inst_soft_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete sr_posit_instit_soft';
        g_func_name := upper('del_sr_pos_inst_soft_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM sr_posit_instit_soft srpis
             WHERE srpis.id_institution = i_institution
               AND srpis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM sr_posit_instit_soft srpis
             WHERE srpis.id_institution = i_institution;
        
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
    END del_sr_pos_inst_soft_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_surgicalpositioning_prm;
/