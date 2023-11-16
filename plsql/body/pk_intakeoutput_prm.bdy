/*-- Last Change Revision: $Rev: 1938248 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-03 08:39:57 +0000 (ter, 03 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_intakeoutput_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_INTAKEOUTPUT_PRM';
    pos_soft        NUMBER := 1;
    g_cfg_done      t_low_char;
    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_hidrics_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('HIDRICS.CODE_HIDRICS.');
    BEGIN
        g_func_name := upper('LOAD_HIDRICS_DEF');
        INSERT INTO hidrics
            (id_hidrics,
             code_hidrics,
             id_content,
             flg_type,
             flg_available,
             id_unit_measure,
             flg_gender,
             age_min,
             age_max,
             flg_free_txt,
             rank,
             flg_nr_times)
            SELECT seq_hidrics.nextval,
                   l_code_translation || seq_hidrics.currval,
                   def_data.id_content,
                   def_data.flg_type,
                   def_data.flg_available,
                   def_data.id_unit_measure,
                   def_data.flg_gender,
                   def_data.age_min,
                   def_data.age_max,
                   def_data.flg_free_txt,
                   def_data.rank,
                   def_data.flg_nr_times
            FROM   (SELECT source_tbl.id_content,
                           source_tbl.flg_type,
                           source_tbl.flg_available,
                           source_tbl.id_unit_measure,
                           source_tbl.flg_gender,
                           source_tbl.age_min,
                           source_tbl.age_max,
                           source_tbl.flg_free_txt,
                           source_tbl.rank,
                           source_tbl.flg_nr_times
                    FROM   alert_default.hidrics source_tbl
                    WHERE  source_tbl.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   hidrics dest_tbl
                            WHERE  dest_tbl.id_content = source_tbl.id_content
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
    END load_hidrics_def;

    FUNCTION load_hidrics_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('HIDRICS_TYPE.CODE_HIDRICS_TYPE.');
    
        o_level_array table_number;
    BEGIN
    
        o_result_tbl := 0;
        g_func_name  := upper('LOAD_HIDRICS_TYPE_DEF');
        SELECT DISTINCT LEVEL
        BULK   COLLECT
        INTO   o_level_array
        FROM   alert_default.hidrics_type ht
        WHERE  ht.flg_available = g_flg_available
        START  WITH ht.id_parent IS NULL
        CONNECT BY PRIOR ht.id_hidrics_type = ht.id_parent
        ORDER  BY LEVEL ASC;
    
        FORALL i IN 1 .. o_level_array.count
        
            INSERT INTO hidrics_type
                (id_hidrics_type, code_hidrics_type, id_content, flg_available, acronym, rank, flg_ti_type, id_parent)
            
                SELECT seq_hidrics_type.nextval,
                       l_code_translation || seq_hidrics_type.currval,
                       def_data.id_content,
                       def_data.flg_available,
                       def_data.acronym,
                       def_data.rank,
                       def_data.flg_ti_type,
                       def_data.i_parent
                
                FROM   (SELECT source_tbl.id_content,
                               source_tbl.flg_available,
                               source_tbl.acronym,
                               source_tbl.rank,
                               source_tbl.flg_ti_type,
                               
                               decode(source_tbl.id_parent,
                                      NULL,
                                      NULL,
                                      nvl((SELECT ht.id_hidrics_type
                                          FROM   hidrics_type ht
                                          INNER  JOIN alert_default.hidrics_type ht1
                                          ON     ht1.id_content = ht.id_content
                                          WHERE  ht1.id_hidrics_type = source_tbl.id_parent
                                                 AND ht1.flg_available = g_flg_available
                                                 AND ht.flg_available = g_flg_available),
                                          0)) i_parent,
                               LEVEL lvl
                        FROM   alert_default.hidrics_type source_tbl
                        WHERE  source_tbl.flg_available = g_flg_available
                               AND NOT EXISTS (SELECT 0
                                FROM   hidrics_type dest_tbl
                                WHERE  dest_tbl.id_content = source_tbl.id_content
                                       AND dest_tbl.flg_available = g_flg_available)
                        
                        START  WITH source_tbl.id_parent IS NULL
                        CONNECT BY nocycle PRIOR source_tbl.id_hidrics_type = source_tbl.id_parent) def_data
                WHERE  def_data.lvl = o_level_array(i)
                       AND (def_data.i_parent IS NULL OR def_data.i_parent > 0);
    
        o_result_tbl := o_result_tbl + SQL%ROWCOUNT;
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
    END load_hidrics_type_def;

    FUNCTION load_hidrics_charact_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('HIDRICS_CHARACT.CODE_HIDRICS_CHARACT.');
    
    BEGIN
    
        g_func_name := upper('LOAD_HIDRICS_CHARACT_DEF');
    
        INSERT INTO hidrics_charact
            (id_hidrics_charact, code_hidrics_charact, code, flg_available, id_content)
            SELECT seq_hidrics_charact.nextval,
                   l_code_translation || seq_hidrics_charact.currval,
                   def_data.code,
                   def_data.flg_available,
                   def_data.id_content
            FROM   (SELECT ad_hc.code, ad_hc.flg_available, ad_hc.id_content
                    FROM   ad_hidrics_charact ad_hc
                    WHERE  ad_hc.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   hidrics_charact a_hc
                            WHERE  a_hc.id_content = ad_hc.id_content
                                   AND a_hc.flg_available = g_flg_available)) def_data;
    
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
    END load_hidrics_charact_def;

    FUNCTION load_hidrics_device_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('HIDRICS_DEVICE.CODE_HIDRICS_DEVICE.');
    
    BEGIN
    
        g_func_name := upper('LOAD_HIDRICS_DEVICE_DEF');
    
        INSERT INTO hidrics_device
            (id_hidrics_device, code_hidrics_device, code, flg_available, id_content, flg_free_txt)
            SELECT seq_hidrics_device.nextval,
                   l_code_translation || seq_hidrics_device.currval,
                   def_data.code,
                   def_data.flg_available,
                   def_data.id_content,
                   def_data.flg_free_txt
            FROM   (SELECT ad_hd.code, ad_hd.flg_available, ad_hd.id_content, ad_hd.flg_free_txt
                    FROM   ad_hidrics_device ad_hd
                    WHERE  ad_hd.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   hidrics_device a_hd
                            WHERE  a_hd.id_content = ad_hd.id_content
                                   AND a_hd.flg_available = g_flg_available)) def_data;
    
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
    END load_hidrics_device_def;

    FUNCTION load_hidrics_occurs_type_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('HIDRICS_OCCURS_TYPE.CODE_HIDRICS_OCCURS_TYPE.');
    
    BEGIN
    
        g_func_name := upper('LOAD_HIDRICS_OCCURS_TYPE_DEF');
    
        INSERT INTO hidrics_occurs_type
            (id_hidrics_occurs_type, code_hidrics_occurs_type, code, flg_available, id_content)
            SELECT seq_hidrics_occurs_type.nextval,
                   l_code_translation || seq_hidrics_occurs_type.currval,
                   def_data.code,
                   def_data.flg_available,
                   def_data.id_content
            FROM   (SELECT ad_hot.code, ad_hot.flg_available, ad_hot.id_content
                    FROM   ad_hidrics_occurs_type ad_hot
                    WHERE  ad_hot.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   hidrics_occurs_type a_hot
                            WHERE  a_hot.id_content = ad_hot.id_content
                                   AND a_hot.flg_available = g_flg_available)) def_data;
    
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
        
    END load_hidrics_occurs_type_def;

    FUNCTION load_way_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('WAY.CODE_WAY.');
    
    BEGIN
    
        g_func_name := upper('LOAD_WAY_DEF');
    
        INSERT INTO way
            (id_way, code_way, code, flg_available, id_content, flg_way_type, flg_type)
            SELECT seq_way.nextval,
                   l_code_translation || seq_way.currval,
                   def_data.code,
                   def_data.flg_available,
                   def_data.id_content,
                   def_data.flg_way_type,
                   def_data.flg_type
            FROM   (SELECT ad_w.code, ad_w.flg_available, ad_w.id_content, ad_w.flg_way_type, ad_w.flg_type
                    FROM   ad_way ad_w
                    WHERE  ad_w.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   way a_w
                            WHERE  a_w.id_content = ad_w.id_content
                                   AND a_w.flg_available = g_flg_available)) def_data;
    
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
        
    END load_way_def;

    FUNCTION load_hidrics_location_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_HIDRICS_LOCATION_DEF');
    
        INSERT INTO hidrics_location
            (id_hidrics_location, id_body_part, id_body_side, flg_available)
            SELECT seq_hidrics_location.nextval, def_data.id_body_part, def_data.id_body_side, g_flg_available
            FROM   (SELECT temp_data.id_body_part, temp_data.id_body_side
                    FROM   (SELECT decode(ad_hl.id_body_part,
                                          NULL,
                                          NULL,
                                          (nvl((SELECT a_bp.id_body_part
                                               FROM   body_part a_bp
                                               WHERE  a_bp.flg_available = g_flg_available
                                                      AND a_bp.id_body_part = ad_hl.id_body_part),
                                               0))) id_body_part,
                                   ad_hl.id_body_side
                            FROM   ad_hidrics_location ad_hl
                            WHERE  ad_hl.flg_available = g_flg_available) temp_data) def_data
            WHERE  def_data.id_body_part != 0
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_location a_hl
                    WHERE  (a_hl.id_body_part = def_data.id_body_part OR
                           (a_hl.id_body_part IS NULL AND def_data.id_body_part IS NULL))
                           AND (a_hl.id_body_side = def_data.id_body_side OR
                           (a_hl.id_body_side IS NULL AND def_data.id_body_side IS NULL))
                           AND a_hl.flg_available = g_flg_available);
    
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
        
    END load_hidrics_location_def;

    -- searcheable loader method
    /*
    Institution market api introduced to collect destination market as frontend configuration logics will only show specific market or generic market records
    market parameter is only used in source data collection
    */
    FUNCTION set_hidrics_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_SEARCH');
    
        INSERT INTO hidrics_relation
            (id_hidrics_relation,
             id_hidrics,
             id_hidrics_type,
             id_institution,
             id_dept,
             flg_available,
             flg_state,
             id_software,
             id_department,
             id_market)
            SELECT seq_hidrics_relation.nextval,
                   def_data.id_hidrics,
                   def_data.id_hidrics_type,
                   i_institution,
                   0 id_dept,
                   g_flg_available,
                   def_data.flg_state,
                   i_software(pos_soft),
                   0 id_department,
                   l_market
            FROM   (SELECT temp_data.id_hidrics,
                           temp_data.id_hidrics_type,
                           temp_data.flg_state,
                           row_number() over(PARTITION BY temp_data.id_hidrics, temp_data.id_hidrics_type ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              INNER  JOIN ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              INNER  JOIN ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   nvl((SELECT a_ht.id_hidrics_type
                                       FROM   hidrics_type a_ht
                                       INNER  JOIN ad_hidrics_type ad_ht
                                       ON     ad_ht.id_content = a_ht.id_content
                                       WHERE  ad_ht.flg_available = g_flg_available
                                              AND a_ht.flg_available = g_flg_available
                                              AND ad_ht.id_hidrics_type = ad_hr.id_hidrics_type),
                                       0) id_hidrics_type,
                                   ad_hr.flg_state,
                                   ad_htmv.id_market,
                                   ad_htmv.version
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_relation ad_hr
                            INNER  JOIN ad_hidrics_relation_mrk_vrs ad_htmv
                            ON     ad_htmv.id_hidrics_relation = ad_hr.id_hidrics_relation
                                   AND
                                   ad_hr.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_mkt AS table_number)) p)
                            WHERE  ad_hr.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                    FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND ad_htmv.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_htmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND ad_hr.flg_state = pk_alert_constant.g_active
                                   AND ad_hr.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_hidrics_type != 0
                           AND temp_data.id_hidrics != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_relation a_hr
                    WHERE  a_hr.id_hidrics_type = def_data.id_hidrics_type
                           AND a_hr.id_hidrics = def_data.id_hidrics
                           AND a_hr.id_institution = i_institution
                           AND a_hr.id_software = i_software(pos_soft)
                           AND a_hr.id_department = 0
                           AND a_hr.id_dept = 0
                           AND a_hr.id_market = l_market);
    
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
        
    END set_hidrics_search;

    FUNCTION del_hidrics_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_relation';
        g_func_name := upper('DEL_HIDRICS_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM hidrics_relation hr
            WHERE  hr.id_institution = i_institution
                   AND hr.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                          FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM hidrics_relation hr WHERE hr.id_institution = i_institution;
        
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
    END del_hidrics_search;

    -- way
    FUNCTION set_way_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_WAY_SEARCH');
    
        INSERT INTO hidrics_way_rel
            (id_way,
             id_hidrics_type,
             id_hidrics,
             id_department,
             id_dept,
             id_institution,
             id_market,
             rank,
             flg_available)
            SELECT def_data.id_way,
                   def_data.id_hidrics_type,
                   def_data.id_hidrics,
                   0                        id_department,
                   0                        id_dept,
                   i_institution            id_institution,
                   l_market,
                   def_data.rank,
                   g_flg_available          flg_available
            FROM   (SELECT temp_data.id_way,
                           temp_data.id_hidrics_type,
                           temp_data.id_hidrics,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_way, temp_data.id_hidrics_type, temp_data.id_hidrics ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hwr.rowid l_row,
                                   nvl((SELECT a_w.id_way
                                       FROM   way a_w
                                       INNER  JOIN ad_way ad_w
                                       ON     ad_w.id_content = a_w.id_content
                                       WHERE  a_w.flg_available = g_flg_available
                                              AND ad_w.flg_available = g_flg_available
                                              AND ad_w.id_way = ad_hwr.id_way),
                                       0) id_way,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              INNER  JOIN ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hwr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              INNER  JOIN ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hwr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   nvl((SELECT a_ht.id_hidrics_type
                                       FROM   hidrics_type a_ht
                                       INNER  JOIN ad_hidrics_type ad_ht
                                       ON     ad_ht.id_content = a_ht.id_content
                                       WHERE  ad_ht.flg_available = g_flg_available
                                              AND a_ht.flg_available = g_flg_available
                                              AND ad_ht.id_hidrics_type = ad_hwr.id_hidrics_type),
                                       0) id_hidrics_type,
                                   ad_hwr.rank
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_way_rel ad_hwr
                            WHERE  ad_hwr.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ad_hwr.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_hidrics_type != 0
                           AND temp_data.id_hidrics != 0
                           AND temp_data.id_way != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_way_rel a_hwr
                    WHERE  a_hwr.id_way = def_data.id_way
                           AND a_hwr.id_hidrics = def_data.id_hidrics
                           AND a_hwr.id_hidrics_type = def_data.id_hidrics_type
                           AND a_hwr.id_department = 0
                           AND a_hwr.id_dept = 0
                           AND a_hwr.id_institution = i_institution
                           AND a_hwr.id_market = l_market);
    
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
    END set_way_search;

    FUNCTION del_way_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_way_rel';
        g_func_name := upper('DEL_WAY_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_way_rel hwr WHERE hwr.id_institution = i_institution;
        
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
    END del_way_search;

    -- hidrics_location
    FUNCTION set_hidrics_location_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
        cc          VARCHAR(39);
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_LOCATION_SEARCH');
    
        INSERT INTO hidrics_location_rel
            (id_hidrics_location,
             id_way,
             id_hidrics,
             id_department,
             id_dept,
             id_institution,
             id_market,
             rank,
             flg_available)
            SELECT def_data.id_hidrics_location,
                   def_data.id_way,
                   def_data.id_hidrics,
                   0                            id_department,
                   0                            id_dept,
                   i_institution                id_institution,
                   l_market,
                   def_data.rank,
                   g_flg_available              flg_available
            FROM   (SELECT temp_data.id_hidrics_location,
                           temp_data.id_way,
                           temp_data.id_hidrics,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_hidrics_location, temp_data.id_way, temp_data.id_hidrics ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hlr.rowid l_row,
                                   nvl((SELECT a_hl.id_hidrics_location
                                       FROM   hidrics_location a_hl
                                       WHERE  (a_hl.id_body_part = ad_hl.id_body_part OR
                                              (a_hl.id_body_part IS NULL AND ad_hl.id_body_part IS NULL))
                                              AND (a_hl.id_body_side = ad_hl.id_body_side OR
                                              (a_hl.id_body_side IS NULL AND ad_hl.id_body_side IS NULL))
                                              AND a_hl.flg_available = g_flg_available
                                              AND ad_hl.flg_available = g_flg_available
                                              AND rownum = 1),
                                       0) id_hidrics_location,
                                   nvl((SELECT a_w.id_way
                                       FROM   way a_w
                                       JOIN   ad_way ad_w
                                       ON     ad_w.id_content = a_w.id_content
                                       WHERE  a_w.flg_available = g_flg_available
                                              AND ad_w.flg_available = g_flg_available
                                              AND ad_w.id_way = ad_hlr.id_way),
                                       0) id_way,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hlr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hlr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   rank
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_location_rel ad_hlr
                            JOIN   ad_hidrics_location ad_hl
                            ON     ad_hl.id_hidrics_location = ad_hlr.id_hidrics_location
                            WHERE  ad_hlr.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ad_hlr.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_hidrics_location != 0
                           AND temp_data.id_way != 0
                           AND temp_data.id_hidrics != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_location_rel a_hlr
                    WHERE  a_hlr.id_way = def_data.id_way
                           AND a_hlr.id_hidrics = def_data.id_hidrics
                           AND a_hlr.id_hidrics_location = def_data.id_hidrics_location
                           AND a_hlr.id_department = 0
                           AND a_hlr.id_dept = 0
                           AND (a_hlr.id_institution = i_institution OR a_hlr.id_institution = 0)
                           AND a_hlr.id_market = l_market);
    
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
    END set_hidrics_location_search;

    FUNCTION del_hidrics_location_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_location_rel';
        g_func_name := upper('DEL_HIDRICS_LOCATION_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_location_rel hlr WHERE hlr.id_institution = i_institution;
        
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
    END del_hidrics_location_search;

    -- hidrics_characterization
    FUNCTION set_hidrics_charact_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_CHARACT_SEARCH');
    
        INSERT INTO hidrics_charact_rel
            (id_hidrics,
             id_hidrics_charact,
             id_way,
             id_department,
             id_dept,
             id_institution,
             id_market,
             rank,
             flg_available)
            SELECT def_data.id_hidrics,
                   def_data.id_hidrics_charact,
                   def_data.id_way,
                   0                           id_department,
                   0                           id_dept,
                   i_institution               id_institution,
                   l_market,
                   def_data.rank,
                   g_flg_available
            FROM   (SELECT temp_data.id_hidrics,
                           temp_data.id_hidrics_charact,
                           temp_data.id_way,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_hidrics, temp_data.id_hidrics_charact, temp_data.id_way ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hcr.rowid l_row,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hcr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hcr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   nvl((SELECT a_hc.id_hidrics_charact
                                       FROM   hidrics_charact a_hc
                                       INNER  JOIN ad_hidrics_charact ad_hc
                                       ON     ad_hc.id_content = a_hc.id_content
                                       WHERE  a_hc.flg_available = g_flg_available
                                              AND ad_hc.flg_available = g_flg_available
                                              AND ad_hc.id_hidrics_charact = ad_hcr.id_hidrics_charact),
                                       0) id_hidrics_charact,
                                   nvl((SELECT a_w.id_way
                                       FROM   way a_w
                                       INNER  JOIN ad_way ad_w
                                       ON     ad_w.id_content = a_w.id_content
                                       WHERE  a_w.flg_available = g_flg_available
                                              AND ad_w.flg_available = g_flg_available
                                              AND ad_w.id_way = ad_hcr.id_way),
                                       0) id_way,
                                   ad_hcr.rank
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_charact_rel ad_hcr
                            WHERE  ad_hcr.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ad_hcr.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_hidrics_charact != 0
                           AND temp_data.id_hidrics != 0
                           AND temp_data.id_way != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_charact_rel a_hcr
                    WHERE  a_hcr.id_hidrics_charact = def_data.id_hidrics_charact
                           AND a_hcr.id_hidrics = def_data.id_hidrics
                           AND a_hcr.id_department = 0
                           AND a_hcr.id_dept = 0
                           AND a_hcr.id_institution = i_institution
                           AND a_hcr.id_market = l_market
                           AND a_hcr.id_way = def_data.id_way);
    
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
    END set_hidrics_charact_search;

    FUNCTION del_hidrics_charact_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_charact_rel';
        g_func_name := upper('DEL_HIDRICS_CHARACT_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_charact_rel hcr WHERE hcr.id_institution = i_institution;
        
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
    END del_hidrics_charact_search;

    -- configuration
    FUNCTION set_hidrics_config_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_CONFIG_SEARCH');
    
        INSERT INTO hidrics_configurations
            (id_hidrics_configurations,
             id_hidrics_interval,
             id_institution,
             id_department,
             id_dept,
             dt_def_next_balance,
             almost_max_int,
             id_market)
            SELECT seq_hidrics_configurations.nextval,
                   def_data.id_hidrics_interval,
                   i_institution,
                   0                                  id_department,
                   0                                  id_dept,
                   def_data.dt_def_next_balance,
                   def_data.almost_max_int,
                   l_market
            FROM   (SELECT temp_data.id_hidrics_interval,
                           temp_data.dt_def_next_balance,
                           temp_data.almost_max_int,
                           row_number() over(PARTITION BY temp_data.id_hidrics_interval ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hc.rowid l_row,
                                   nvl((SELECT a_hi.id_hidrics_interval
                                       FROM   hidrics_interval a_hi
                                       WHERE  a_hi.flg_available = g_flg_available
                                              AND a_hi.id_hidrics_interval = ad_hc.id_hidrics_interval),
                                       0) id_hidrics_interval,
                                   ad_hc.dt_def_next_balance,
                                   ad_hc.almost_max_int
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_configurations ad_hc
                            WHERE  ad_hc.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                    WHERE  temp_data.id_hidrics_interval != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_configurations a_hc
                    WHERE  a_hc.id_hidrics_interval = def_data.id_hidrics_interval
                           AND a_hc.id_department = 0
                           AND a_hc.id_dept = 0
                           AND (a_hc.id_institution = i_institution OR a_hc.id_institution = 0)
                           AND a_hc.id_market = l_market);
    
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
    END set_hidrics_config_search;

    FUNCTION del_hidrics_config_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_configurations';
        g_func_name := upper('DEL_HIDRICS_CONFIG_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_configurations hc WHERE hc.id_institution = i_institution;
        
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
    END del_hidrics_config_search;

    FUNCTION set_hidrics_device_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_DEVICE_SEARCH');
    
        INSERT INTO hidrics_device_rel
            (id_hidrics_device,
             id_hidrics,
             id_way,
             id_department,
             id_dept,
             id_institution,
             id_market,
             rank,
             flg_available)
            SELECT def_data.id_hidrics_device,
                   def_data.id_hidrics,
                   def_data.id_way,
                   0                          id_department,
                   0                          id_dept,
                   i_institution,
                   l_market,
                   def_data.rank,
                   g_flg_available
            FROM   (SELECT temp_data.id_hidrics_device,
                           temp_data.id_hidrics,
                           temp_data.id_way,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_hidrics_device, temp_data.id_hidrics, temp_data.id_way ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hdr.rowid l_row,
                                   nvl((SELECT a_hd.id_hidrics_device
                                       FROM   hidrics_device a_hd
                                       JOIN   ad_hidrics_device ad_hd
                                       ON     ad_hd.id_content = a_hd.id_content
                                       WHERE  a_hd.flg_available = g_flg_available
                                              AND ad_hd.flg_available = g_flg_available
                                              AND ad_hd.id_hidrics_device = ad_hdr.id_hidrics_device),
                                       0) id_hidrics_device,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hdr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hdr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   nvl((SELECT a_w.id_way
                                       FROM   way a_w
                                       JOIN   ad_way ad_w
                                       ON     ad_w.id_content = a_w.id_content
                                       WHERE  a_w.flg_available = g_flg_available
                                              AND ad_w.flg_available = g_flg_available
                                              AND ad_w.id_way = ad_hdr.id_way),
                                       0) id_way,
                                   ad_hdr.rank
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_device_rel ad_hdr
                            JOIN   ad_hidrics_device_mrk_vrs ad_hdmv
                            ON     ad_hdmv.id_hidrics_device = ad_hdr.id_hidrics_device
                            WHERE  ad_hdmv.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                    FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_hdmv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND ad_hdr.flg_available = g_flg_available
                                   AND
                                   ad_hdr.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                         column_value
                                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                    WHERE  temp_data.id_hidrics_device != 0
                           AND temp_data.id_hidrics != 0
                           AND temp_data.id_way != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_device_rel a_hdr
                    WHERE  a_hdr.id_hidrics_device = def_data.id_hidrics_device
                           AND a_hdr.id_hidrics = def_data.id_hidrics
                           AND a_hdr.id_way = def_data.id_way
                           AND a_hdr.id_institution = i_institution
                           AND a_hdr.id_market = l_market
                           AND a_hdr.id_dept = 0
                           AND a_hdr.id_department = 0
                           AND a_hdr.flg_available = g_flg_available);
    
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
    END set_hidrics_device_search;

    FUNCTION del_hidrics_device_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_device_rel';
        g_func_name := upper('DEL_HIDRICS_DEVICE_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_device_rel hdr WHERE hdr.id_institution = i_institution;
        
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
    END del_hidrics_device_search;

    FUNCTION set_hidrics_occurs_type_search
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
    
        l_market    market.id_market%TYPE;
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        l_market    := pk_utils.get_institution_market(i_lang, i_institution);
        g_func_name := upper('SET_HIDRICS_OCCURS_TYPE_SEARCH');
    
        INSERT INTO hidrics_occurs_type_rel
            (id_hidrics,
             id_hidrics_occurs_type,
             id_department,
             id_dept,
             id_institution,
             id_market,
             rank,
             flg_available)
            SELECT def_data.id_hidrics,
                   def_data.id_hidrics_occurs_type,
                   0                               id_department,
                   0                               id_dept,
                   i_institution,
                   l_market,
                   def_data.rank,
                   g_flg_available
            FROM   (SELECT temp_data.id_hidrics,
                           temp_data.id_hidrics_occurs_type,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_hidrics, temp_data.id_hidrics_occurs_type ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT ad_hotr.rowid l_row,
                                   decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hotr.id_hidrics),
                                              0),
                                          nvl((SELECT a_h.id_hidrics
                                              FROM   hidrics a_h
                                              JOIN   ad_hidrics ad_h
                                              ON     a_h.id_content = ad_h.id_content
                                              WHERE  a_h.flg_available = g_flg_available
                                                     AND ad_h.flg_available = g_flg_available
                                                     AND ad_h.id_hidrics = ad_hotr.id_hidrics
                                                     AND ad_h.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_hidrics,
                                   nvl((SELECT a_hot.id_hidrics_occurs_type
                                       FROM   hidrics_occurs_type a_hot
                                       INNER  JOIN ad_hidrics_occurs_type ad_hot
                                       ON     ad_hot.id_content = a_hot.id_content
                                       WHERE  a_hot.flg_available = g_flg_available
                                              AND ad_hot.flg_available = g_flg_available
                                              AND ad_hot.id_hidrics_occurs_type = ad_hotr.id_hidrics_occurs_type),
                                       0) id_hidrics_occurs_type,
                                   ad_hotr.rank
                            -- decode FKS to dest_vals
                            FROM   ad_hidrics_occurs_type_rel ad_hotr
                            INNER  JOIN ad_hidrics_occurs_type_mrk_vrs ad_hotmv
                            ON     (ad_hotmv.id_hidrics_occurs_type = ad_hotr.id_hidrics_occurs_type)
                            WHERE  ad_hotmv.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                    FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                  
                                   AND ad_hotmv.version IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                        FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND ad_hotr.flg_available = g_flg_available
                                   AND ad_hotr.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                        FROM   TABLE(CAST(i_mkt AS table_number)) p)) temp_data
                    WHERE  temp_data.id_hidrics_occurs_type != 0
                           AND temp_data.id_hidrics != 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   hidrics_occurs_type_rel a_hotr
                    WHERE  a_hotr.id_hidrics_occurs_type = def_data.id_hidrics_occurs_type
                           AND a_hotr.id_hidrics = def_data.id_hidrics
                           AND a_hotr.id_institution = i_institution
                           AND a_hotr.id_market = l_market
                           AND a_hotr.id_dept = 0
                           AND a_hotr.id_department = 0
                           AND a_hotr.flg_available = g_flg_available);
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
    END set_hidrics_occurs_type_search;
    -- frequent loader method

    FUNCTION del_hidrics_occurs_type_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete hidrics_occurs_type_rel';
        g_func_name := upper('DEL_HIDRICS_OCCURS_TYPE_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_sw_list
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_sw_list.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE FROM hidrics_occurs_type_rel hotr WHERE hotr.id_institution = i_institution;
        
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
    END del_hidrics_occurs_type_search;

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

    pk_alertlog.who_am_i(owner => g_package_owner, NAME => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
    g_cfg_done    := 'FALSE';

END pk_intakeoutput_prm;
/
/
