/*-- Last Change Revision: $Rev: 1469740 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-21 16:52:14 +0100 (ter, 21 mai 2013) $*/

CREATE OR REPLACE PACKAGE BODY pk_admission_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_admission_prm';

    -- Private Methods

    -- content loader method

    -- searcheable loader method
    FUNCTION set_wtl_urg_level_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        
        i_software   IN table_number,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_group            NUMBER;
        l_code_translation translation.code_translation%TYPE := upper('WTL_URG_LEVEL.CODE.');
    
    BEGIN
        g_func_name := upper('set_wtl_urg_level_search');

        o_result_tbl := 0;
    
        SELECT nvl((SELECT ig.id_group
                     FROM institution_group ig
                    WHERE ig.id_institution = i_institution
                      AND ig.flg_relation = 'INST_CNT'),
                   0)
          INTO l_group
          FROM dual;
       
        IF l_group != 0
        THEN
           
            INSERT INTO wtl_urg_level
                (id_wtl_urg_level,
                 code,
                 duration,
                 id_content,
                 flg_status,
                 flg_parameterization_type,
                 desc_wtl_urg_level,
                 id_group,
                 flg_available)
                SELECT seq_wtl_urg_level.nextval,
                       l_code_translation || seq_wtl_urg_level.currval,
                       def_data.duration,
                       def_data.id_content,
                       def_data.flg_status,
                       def_data.flg_parameterization_type,
                       def_data.desc_wtl_urg_level,
                       l_group,
                       g_flg_available
                
                  FROM (SELECT temp_data.duration,
                               temp_data.id_content,
                               temp_data.id_wtl_urg_level,
                               temp_data.flg_status,
                               temp_data.flg_parameterization_type,
                               temp_data.desc_wtl_urg_level,
                               
                               row_number() over(PARTITION BY temp_data.id_content
                               
                               ORDER BY temp_data.l_row) records_count
                          FROM (SELECT wul.rowid l_row,
                                       -- decode FKS to dest_vals
                                       wul.duration,
                                       wul.id_content,
                                       wul.id_wtl_urg_level,
                                       wul.flg_status,
                                       wul.flg_parameterization_type,
                                       wul.desc_wtl_urg_level
                                  FROM alert_default.wtl_urg_level wul
                                
                                 WHERE wul.flg_available = g_flg_available
                                   AND NOT EXISTS (SELECT 0
                                        
                                          FROM wtl_urg_level wul1
                                         WHERE wul1.id_content = wul.id_content
                                           AND wul1.flg_available = g_flg_available
                                           AND wul1.id_institution IS NULL
                                           AND wul1.id_group = l_group)) temp_data) def_data
                 WHERE def_data.records_count = 1;
        
            o_result_tbl := SQL%ROWCOUNT;
        
        END IF;
    
        INSERT INTO wtl_urg_level
            (id_wtl_urg_level,
             code,
             duration,
             id_content,
             flg_status,
             flg_parameterization_type,
             desc_wtl_urg_level,
             id_institution,
             flg_available)
            SELECT seq_wtl_urg_level.nextval,
                   l_code_translation || seq_wtl_urg_level.currval,
                   def_data.duration,
                   def_data.id_content,
                   def_data.flg_status,
                   def_data.flg_parameterization_type,
                   def_data.desc_wtl_urg_level,
                   i_institution,
                   g_flg_available
            
              FROM (SELECT temp_data.duration,
                           temp_data.id_content,
                           temp_data.id_wtl_urg_level,
                           temp_data.flg_status,
                           temp_data.flg_parameterization_type,
                           temp_data.desc_wtl_urg_level,
                           
                           row_number() over(PARTITION BY temp_data.id_content
                           
                           ORDER BY temp_data.l_row) records_count
                      FROM (SELECT wul.rowid l_row,
                                   -- decode FKS to dest_vals
                                   wul.duration,
                                   wul.id_content,
                                   wul.id_wtl_urg_level,
                                   wul.flg_status,
                                   wul.flg_parameterization_type,
                                   wul.desc_wtl_urg_level
                              FROM alert_default.wtl_urg_level wul
                            
                             WHERE wul.flg_available = g_flg_available
                               AND NOT EXISTS (SELECT 0
                                      FROM wtl_urg_level wul1
                                     WHERE wul1.id_content = wul.id_content
                                       AND wul1.flg_available = g_flg_available
                                       AND wul1.id_institution = i_institution
                                       AND wul1.id_group IS NULL)) temp_data) def_data
             WHERE def_data.records_count = 1;
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
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
    END set_wtl_urg_level_search;

-- frequent loader method

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_admission_prm;
/