CREATE OR REPLACE PACKAGE BODY pk_sampletext_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_SAMPLETEXT_prm';
    pos_soft        NUMBER := 1;

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method

    FUNCTION set_sample_tt_cat_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt_count NUMBER := i_id_content.count;
    
    BEGIN
    
        g_func_name := upper('SET_SAMPLE_TT_CAT_SEARCH');
    
        INSERT INTO sample_text_type_cat
            (id_sample_text_type, id_category, id_institution)
            SELECT def_data.id_sample_text_type, def_data.id_category, i_institution
            FROM   (SELECT temp_data.id_sample_text_type,
                           temp_data.id_category,
                           row_number() over(PARTITION BY temp_data.id_sample_text_type, temp_data.id_category ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT DISTINCT a_stt.id_sample_text_type
                                              FROM   sample_text_type a_stt
                                              WHERE  a_stt.id_sample_text_type = ad_sttc.id_sample_text_type
                                                     AND a_stt.flg_available = g_flg_available
                                                     AND a_stt.id_software IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_software AS table_number)) p)),
                                              0),
                                          nvl((SELECT DISTINCT a_stt.id_sample_text_type
                                              FROM   sample_text_type a_stt
                                              WHERE  a_stt.id_sample_text_type = ad_sttc.id_sample_text_type
                                                     AND a_stt.flg_available = g_flg_available
                                                     AND a_stt.id_software IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_software AS table_number)) p)
                                                     AND a_stt.intern_name_sample_text_type IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                           column_value
                                                          FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_sample_text_type,
                                   ad_sttc.id_category,
                                   ad_sttc.id_market,
                                   ad_sttc.version
                            -- decode fks TO dest_vals
                            FROM   ad_sample_text_type_cat ad_sttc
                            INNER  JOIN sample_text_type a_stt
                            ON     a_stt.id_sample_text_type = ad_sttc.id_sample_text_type
                                   AND a_stt.flg_available = g_flg_available
                            INNER  JOIN category a_c
                            ON     a_c.id_category = ad_sttc.id_category
                                   AND a_c.flg_available = g_flg_available
                            WHERE  ad_sttc.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                    FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   ad_sttc.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
            WHERE  def_data.records_count = 1
                   AND def_data.id_sample_text_type > 0
                   AND NOT EXISTS (SELECT 0
                    FROM   sample_text_type_cat a_sttc1
                    WHERE  a_sttc1.id_sample_text_type = def_data.id_sample_text_type
                           AND a_sttc1.id_category = def_data.id_category
                           AND a_sttc1.id_institution = i_institution);
    
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
        
    END set_sample_tt_cat_search;

    FUNCTION del_sample_tt_cat_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_sw_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete sample_text_type_cat';
        g_func_name := upper('del_sample_tt_cat_search');
    
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
            DELETE FROM sample_text_type_cat sttc WHERE sttc.id_institution = i_institution;
        
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
    END del_sample_tt_cat_search;

    -- frequent loader method
    FUNCTION set_sampletext_freq
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
    
        l_cnt_count NUMBER := i_id_content.count;
        dd          table_number;
    
    BEGIN
    
        g_func_name := upper('SET_SAMPLETEXT_FREQ');
    
        INSERT INTO sample_text_freq
            (id_freq_sample_text, id_sample_text, id_dep_clin_serv)
            SELECT seq_sample_text_freq.nextval, temp_data.id_sample_text, i_dep_clin_serv_out
            FROM   (SELECT decode(l_cnt_count,
                                  0,
                                  nvl((SELECT DISTINCT a_st.id_sample_text
                                      FROM   sample_text a_st
                                      JOIN   sample_text_type a_stt
                                      ON     a_stt.id_sample_text_type = a_st.id_sample_text_type
                                             AND a_st.flg_available = g_flg_available
                                      WHERE  a_st.id_sample_text = ad_dstf.id_sample_text
                                             AND a_stt.flg_available = g_flg_available
                                             AND a_stt.id_software IN
                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                                   column_value
                                                  FROM   TABLE(CAST(i_software AS table_number)) p)),
                                      0),
                                  nvl((SELECT DISTINCT a_st.id_sample_text
                                      FROM   sample_text a_st
                                      JOIN   sample_text_type a_stt
                                      ON     a_stt.id_sample_text_type = a_st.id_sample_text_type
                                             AND a_st.flg_available = g_flg_available
                                      WHERE  a_st.id_sample_text = ad_dstf.id_sample_text
                                             AND a_stt.flg_available = g_flg_available
                                             AND a_stt.id_software IN
                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                                   column_value
                                                  FROM   TABLE(CAST(i_software AS table_number)) p)
                                             AND a_stt.intern_name_sample_text_type IN
                                             (SELECT /*+ opt_estimate(p rows = 10)*/
                                                   column_value
                                                  FROM   TABLE(CAST(i_id_content AS table_varchar)) p)),
                                      0)) id_sample_text,
                           row_number() over(PARTITION BY ad_dstf.id_sample_text ORDER BY ad_dstf.id_market DESC, decode(ad_dstf.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   ad_sample_text_freq ad_dstf
                    WHERE  ad_dstf.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                column_value
                                               FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                           AND
                           ad_dstf.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                  column_value
                                                 FROM   TABLE(CAST(i_mkt AS table_number)) p)
                           AND ad_dstf.id_clinical_service IN
                           (SELECT /*+ dynamic_sampling(p 2)*/
                                 column_value
                                FROM   TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
            WHERE  records_count = 1
                   AND temp_data.id_sample_text > 0
                   AND NOT EXISTS (SELECT 0
                    FROM   sample_text_freq a_stf
                    WHERE  a_stf.id_sample_text = temp_data.id_sample_text
                           AND a_stf.id_dep_clin_serv = i_dep_clin_serv_out);
    
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
    END set_sampletext_freq;

    FUNCTION del_sampletext_freq
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
        g_error     := 'delete sample_text_freq';
        g_func_name := upper('del_sampletext_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT dcs.id_dep_clin_serv
            BULK   COLLECT
            INTO   o_dcs_list
            FROM   dep_clin_serv dcs
            INNER  JOIN department d
            ON     (d.id_department = dcs.id_department)
            INNER  JOIN dept dp
            ON     (dp.id_dept = d.id_dept)
            INNER  JOIN software_dept sd
            ON     (sd.id_dept = dp.id_dept)
            WHERE  dcs.flg_available = g_flg_available
                   AND d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND d.id_institution = i_institution
                   AND d.id_institution = dp.id_institution
                   AND dcs.id_clinical_service != 0
                   AND sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                           column_value
                                          FROM   TABLE(CAST(i_software AS table_number)) sw_list);
        ELSE
            SELECT dcs.id_dep_clin_serv
            BULK   COLLECT
            INTO   o_dcs_list
            FROM   dep_clin_serv dcs
            INNER  JOIN department d
            ON     (d.id_department = dcs.id_department)
            INNER  JOIN dept dp
            ON     (dp.id_dept = d.id_dept)
            INNER  JOIN software_dept sd
            ON     (sd.id_dept = dp.id_dept)
            WHERE  dcs.flg_available = g_flg_available
                   AND d.flg_available = g_flg_available
                   AND dp.flg_available = g_flg_available
                   AND d.id_institution = i_institution
                   AND d.id_institution = dp.id_institution
                   AND dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM sample_text_freq stf
        WHERE  stf.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                        FROM   TABLE(CAST(o_dcs_list AS table_number)) p);
    
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
    END del_sampletext_freq;

    FUNCTION set_sampletext_search
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
    
        g_func_name := upper('SET_SAMPLETEXT_SEARCH');
    
        MERGE INTO sample_text_soft_inst a_stsi
        USING (SELECT def_data.id_sample_text,
                      def_data.id_sample_text_type,
                      i_software(pos_soft) id_software,
                      def_data.flg_available,
                      def_data.rank
               
                 FROM (SELECT temp_data.id_sample_text,
                              temp_data.flg_available,
                              temp_data.rank,
                              temp_data.id_sample_text_type,
                              row_number() over(PARTITION BY temp_data.id_sample_text, temp_data.id_sample_text_type ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                         FROM (SELECT ad_sts.id_sample_text,
                                      ad_sts.flg_available,
                                      ad_sts.rank,
                                      decode(l_cnt_count,
                                             0,
                                             ad_sts.id_sample_text_type,
                                             nvl((SELECT a_stt.id_sample_text_type
                                                   FROM sample_text_type a_stt
                                                  WHERE a_stt.id_sample_text_type = ad_sts.id_sample_text_type
                                                    AND a_stt.intern_name_sample_text_type IN
                                                        (SELECT /*+ opt_estimate(p rows = 10)*/
                                                          column_value
                                                           FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                                 0)) id_sample_text_type,
                                      ad_sts.id_software,
                                      ad_stmv.id_market,
                                      ad_stmv.version
                                 FROM ad_sample_text_software ad_sts
                                 JOIN ad_sample_text_mkt_vrs ad_stmv
                                   ON ad_stmv.id_sample_text = ad_sts.id_sample_text
                                 JOIN sample_text_type_soft stts
                                   ON stts.id_sample_text_type = ad_sts.id_sample_text_type
                                WHERE ad_sts.flg_available = g_flg_available
                                  AND ad_stmv.id_market IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                        column_value
                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  AND ad_stmv.version IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                        column_value
                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                  AND ad_sts.id_software IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p)
                                  AND stts.id_software IN
                                      (SELECT /*+ opt_estimate(p rows = 10)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
                WHERE def_data.records_count = 1
                  AND def_data.id_sample_text_type > 0) result_data
        ON (a_stsi.id_sample_text = result_data.id_sample_text AND a_stsi.id_software = result_data.id_software AND a_stsi.id_sample_text_type = result_data.id_sample_text_type AND a_stsi.id_institution = i_institution)
        
        WHEN MATCHED THEN
            UPDATE
               SET a_stsi.flg_available = result_data.flg_available
             WHERE a_stsi.flg_available = 'N'
            
        
        WHEN NOT MATCHED THEN
        
            INSERT
                (id_sample_text, id_sample_text_type, id_institution, id_software, flg_available, rank)
            VALUES
                (result_data.id_sample_text,
                 result_data.id_sample_text_type,
                 i_institution,
                 i_software(pos_soft),
                 result_data.flg_available,
                 result_data.rank);
    
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
    END set_sampletext_search;


   FUNCTION del_sampletext_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete sample_text_soft_inst';
        g_func_name := upper('del_sampletext_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM sample_text_soft_inst stsi
             WHERE stsi.id_institution = i_institution
               AND stsi.id_software IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM sample_text_soft_inst stsi
             WHERE stsi.id_institution = i_institution;
        
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
    END del_sampletext_search;



-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, NAME => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_sampletext_prm;
/
