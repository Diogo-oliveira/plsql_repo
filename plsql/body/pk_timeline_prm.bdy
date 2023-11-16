/*-- Last Change Revision: $Rev: 2027795 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_timeline_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_TIMELINE_prm';
    pos_soft        NUMBER := 1;

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_tl_va_ism_search
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
        g_func_name := upper('set_tl_va_ism_search');
        INSERT INTO tl_va_inst_soft_market
            ( id_tl_timeline, rank, flg_available, id_market, id_institution, id_software)
            SELECT 
                   def_data.id_tl_timeline,
                   def_data.rank,
                   def_data.flg_available,
                   def_data.id_market,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_tl_timeline,
                           temp_data.rank,
                           temp_data.flg_available,
                           temp_data.id_market,
                           row_number() over(PARTITION BY temp_data.id_tl_timeline
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT tvism.id_tl_timeline,
                                   tvism.rank,
                                   tvism.flg_available,
                                   tvism.id_market,
                                   tvism.version,
                                   tvism.id_software
                            -- decode FKS to dest_vals
                              FROM alert_default.tl_va_inst_soft_market tvism
                            
                             WHERE tvism.flg_available = g_flg_available
                               AND tvism.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND tvism.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND tvism.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM tl_va_inst_soft_market tvism1
                     WHERE tvism1.id_tl_timeline = def_data.id_tl_timeline
                       AND tvism1.id_tl_software = i_software(pos_soft)
                       AND tvism1.flg_available = def_data.flg_available
                       AND tvism1.id_market = def_data.id_market
                       AND tvism1.id_institution = i_institution);
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
    END set_tl_va_ism_search;

    FUNCTION del_tl_va_ism_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete tl_va_inst_soft_market';
        g_func_name := upper('del_tl_va_ism_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM tl_va_inst_soft_market tlvaism
             WHERE tlvaism.id_institution = i_institution
               AND tlvaism.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                            column_value
                                             FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM tl_va_inst_soft_market tlvaism
             WHERE tlvaism.id_institution = i_institution;
        
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
    END del_tl_va_ism_search;

    FUNCTION set_tl_scale_ism_search
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
        g_func_name := upper('set_tl_scale_ism_search');
        INSERT INTO tl_scale_inst_soft_market
            (
             id_tl_timeline,
             rank,
             flg_available,
             id_market,
             flg_default,
             id_tl_scale_xupper,
             id_tl_scale_xlower,
             id_institution,
             id_software)
            SELECT --seq_tl_va_inst_soft_market.nextval,
                   def_data.id_tl_timeline,
                   def_data.rank,
                   def_data.flg_available,
                   def_data.id_market,
                   def_data.flg_default,
                   def_data.id_tl_scale_xupper,
                   def_data.id_tl_scale_xlower,
                   i_institution,
                   i_software(pos_soft)
              FROM (SELECT temp_data.id_tl_timeline,
                           temp_data.rank,
                           temp_data.flg_available,
                           temp_data.id_market,
                           temp_data.flg_default,
                           temp_data.id_tl_scale_xupper,
                           temp_data.id_tl_scale_xlower,
                           
                           row_number() over(PARTITION BY temp_data.id_tl_timeline
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT tsism.id_tl_timeline,
                                   tsism.rank,
                                   tsism.flg_available,
                                   tsism.id_market,
                                   tsism.flg_default,
                                   tsism.id_tl_scale_xupper,
                                   tsism.id_tl_scale_xlower,
                                   tsism.id_software,
                                   tsism.version
                            -- decode FKS to dest_vals
                              FROM alert_default.tl_scale_inst_soft_market tsism
                            
                             WHERE tsism.flg_available = g_flg_available
                               AND tsism.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND tsism.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND tsism.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM tl_scale_inst_soft_market tsism1
                     WHERE tsism1.id_tl_timeline = def_data.id_tl_timeline
                       AND tsism1.id_software = i_software(pos_soft)
                       AND tsism1.flg_available = def_data.flg_available
                       AND tsism1.id_market = def_data.id_market
                       AND tsism1.id_institution = i_institution);
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
    END set_tl_scale_ism_search;
    -- frequent loader method

    FUNCTION del_tl_scale_ism_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete tl_scale_inst_soft_market';
        g_func_name := upper('del_tl_scale_ism_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM tl_scale_inst_soft_market tlsism
             WHERE tlsism.id_institution = i_institution
               AND tlsism.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM tl_scale_inst_soft_market tlsism
             WHERE tlsism.id_institution = i_institution;
        
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
    END del_tl_scale_ism_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_timeline_prm;
/
