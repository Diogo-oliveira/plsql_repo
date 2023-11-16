/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE BODY pk_complaint_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_complaint_prm';
    pos_soft        NUMBER := 1;

    /**
    *  Load of complaints
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.2.0
    * @since                       2020/05/05
    */

    FUNCTION load_complaint
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('COMPLAINT.CODE_COMPLAINT.');
    
    BEGIN
    
        INSERT INTO complaint
            (id_complaint, code_complaint, rank, flg_available, id_content)
            SELECT seq_complaint.nextval,
                   l_code_translation || seq_complaint.currval,
                   rank,
                   g_flg_available,
                   id_content
              FROM (SELECT ad_c.rank, ad_c.id_content
                      FROM ad_complaint ad_c
                     WHERE ad_c.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM complaint a_c
                             WHERE a_c.id_content = ad_c.id_content
                               AND a_c.flg_available = g_flg_available)) def_data;
    
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
        
    END load_complaint;

    /**
    *  Load of complaints' and triage board association
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.2.0
    * @since                       2020/05/05
    */

    FUNCTION load_complaint_triage_board
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO complaint_triage_board
            (id_complaint_triage_board, id_complaint, id_triage_board, flg_available)
            SELECT seq_complaint_triage_board.nextval, def_data.id_complaint, def_data.id_triage_board, g_flg_available
              FROM (SELECT temp_data.id_complaint, temp_data.id_triage_board
                      FROM (SELECT nvl((SELECT a_c.id_complaint
                                         FROM complaint a_c
                                         JOIN ad_complaint ad_c
                                           ON ad_c.id_content = a_c.id_content
                                          AND a_c.flg_available = g_flg_available
                                        WHERE ad_c.id_complaint = ad_ctb.id_complaint),
                                       0) id_complaint,
                                   nvl((SELECT a_tb.id_triage_board
                                         FROM triage_board a_tb
                                        WHERE a_tb.id_triage_board = ad_ctb.id_triage_board
                                          AND a_tb.flg_available = g_flg_available),
                                       0) id_triage_board
                              FROM ad_complaint_triage_board ad_ctb
                             WHERE ad_ctb.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_complaint != 0
                       AND temp_data.id_triage_board != 0) def_data
             WHERE NOT EXISTS (SELECT 1
                      FROM complaint_triage_board a_ctb
                     WHERE a_ctb.id_complaint = def_data.id_complaint
                       AND a_ctb.id_triage_board = def_data.id_triage_board
                       AND a_ctb.flg_available = g_flg_available);
    
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
        
    END load_complaint_triage_board;

    /**
    *  Load of complaints' and codification association
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.0
    * @since                          2020/10/07
    */

    FUNCTION load_complaint_codification
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        INSERT INTO complaint_codification
            (id_codification,
             id_complaint,
             flg_available,
             standard_code,
             standard_desc,
             dt_standard_begin,
             dt_standard_end,
             flg_show_descr_codification)
            SELECT def_data.id_codification,
                   def_data.id_complaint,
                   g_flg_available,
                   def_data.standard_code,
                   def_data.standard_desc,
                   def_data.dt_standard_begin,
                   def_data.dt_standard_end,
                   def_data.flg_show_descr_codification
              FROM (SELECT temp_data.id_codification,
                           temp_data.id_complaint,
                           temp_data.standard_code,
                           temp_data.standard_desc,
                           temp_data.dt_standard_begin,
                           temp_data.dt_standard_end,
                           temp_data.flg_show_descr_codification
                      FROM (SELECT nvl((SELECT a_cod.id_codification
                                         FROM codification a_cod
                                         JOIN ad_codification ad_cod
                                           ON ad_cod.id_content = a_cod.id_content
                                          AND a_cod.flg_available = ad_cod.flg_available
                                        WHERE a_cod.flg_available = g_flg_available
                                          AND a_cod.id_codification = ad_cc.id_codification),
                                       0) id_codification,
                                   nvl((SELECT a_c.id_complaint
                                         FROM complaint a_c
                                         JOIN ad_complaint ad_c
                                           ON ad_c.id_content = a_c.id_content
                                          AND a_c.flg_available = ad_c.flg_available
                                        WHERE a_c.flg_available = g_flg_available
                                          AND ad_c.id_complaint = ad_cc.id_complaint),
                                       0) id_complaint,
                                   ad_cc.standard_code,
                                   ad_cc.standard_desc,
                                   ad_cc.dt_standard_begin,
                                   ad_cc.dt_standard_end,
                                   ad_cc.flg_show_descr_codification
                              FROM ad_complaint_codification ad_cc
                             WHERE ad_cc.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_complaint != 0
                       AND temp_data.id_codification != 0) def_data
             WHERE NOT EXISTS (SELECT 1
                      FROM complaint_codification a_cc
                     WHERE a_cc.id_complaint = def_data.id_complaint
                       AND a_cc.id_codification = def_data.id_codification
                       AND a_cc.flg_available = g_flg_available);
    
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
        
    END load_complaint_codification;

    /**
    *  Load of complaints' alias
    *
    * @param i_lang                   Prefered language ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.0
    * @since                          2020/10/07
    */

    FUNCTION load_complaint_alias
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_translation translation.code_translation%TYPE := upper('COMPLAINT_ALIAS.CODE_COMPLAINT_ALIAS.');
    
    BEGIN
    
        INSERT INTO complaint_alias
            (id_complaint, id_complaint_alias, code_complaint_alias, id_content, flg_available)
            SELECT def_data.id_complaint,
                   seq_complaint_alias.nextval,
                   l_code_translation || seq_complaint_alias.currval,
                   def_data.id_content,
                   g_flg_available
              FROM (SELECT temp_data.id_complaint, temp_data.id_content
                      FROM (SELECT nvl((SELECT a_c.id_complaint
                                         FROM complaint a_c
                                         JOIN ad_complaint ad_c
                                           ON ad_c.id_content = a_c.id_content
                                          AND a_c.flg_available = ad_c.flg_available
                                        WHERE a_c.flg_available = g_flg_available
                                          AND ad_c.id_complaint = ad_ca.id_complaint),
                                       0) id_complaint,
                                   ad_ca.id_content
                              FROM ad_complaint_alias ad_ca
                             WHERE ad_ca.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_complaint != 0) def_data
             WHERE NOT EXISTS (SELECT 1
                      FROM complaint_alias a_ca
                     WHERE a_ca.id_content = def_data.id_content
                       AND a_ca.flg_available = g_flg_available);
    
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
        
    END load_complaint_alias;

    /**
    *  Insert both complaints and its aliases dep_clin_serv
    *
    * @param i_lang                      Prefered language ID
    * @param i_institution               ID institutio
    * @param i_mkt                       ID market
    * @param i_vers                      Content version
    * @param i_software                  Id software
    * @param i_id_content                Id content complaint
    * @param i_clin_serv_in              Id clin serv in
    * @param i_clin_serv_out             Id clin serv out
    * @param i_dep_clin_serv_out         Id dep clin serv
    * @param o_result_tbl                Number of records inserted
    * @param o_error                     Error
    *
    * @return                            true or false on success or error
    *
    * @author                            Adriana Salgueiro
    * @version                           v2.8.2.0
    * @since                             2020/10/07
    */

    FUNCTION set_complaint_freq
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
    
    BEGIN
    
        g_func_name := upper('SET_COMPLAINT_FREQ');
    
        INSERT INTO complaint_dep_clin_serv
            (id_complaint, id_dep_clin_serv, rank, id_software, flg_available, id_complaint_alias)
            SELECT def_data.id_complaint,
                   i_dep_clin_serv_out AS id_dep_clin_serv,
                   10 AS rank,
                   i_software(pos_soft) AS id_software,
                   g_flg_available AS flg_available,
                   def_data.id_complaint_alias
              FROM (SELECT temp_data.id_complaint,
                           temp_data.id_complaint_alias,
                           row_number() over(PARTITION BY temp_data.id_complaint, temp_data.id_complaint_alias ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_c.id_complaint
                                                FROM complaint a_c
                                               WHERE a_c.id_content = ad_c.id_content
                                                 AND a_c.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_c.id_complaint
                                                FROM complaint a_c
                                               WHERE a_c.id_content = ad_c.id_content
                                                 AND a_c.flg_available = g_flg_available
                                                 AND a_c.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_complaint,
                                   decode(ad_ccs.id_complaint_alias,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ca.id_complaint_alias
                                                FROM ad_complaint_alias ad_ca
                                                JOIN complaint_alias a_ca
                                                  ON a_ca.id_content = ad_ca.id_content
                                                 AND ad_ca.flg_available = a_ca.flg_available
                                               WHERE ad_ca.flg_available = g_flg_available
                                                 AND ad_ca.id_complaint = ad_ccs.id_complaint
                                                 AND ad_ca.id_complaint_alias = ad_ccs.id_complaint_alias),
                                              0)) id_complaint_alias,
                                   ad_cmv.id_market,
                                   ad_cmv.version,
                                   ad_ccs.id_software
                              FROM ad_complaint_clin_serv ad_ccs
                              JOIN ad_complaint ad_c
                                ON ad_c.id_complaint = ad_ccs.id_complaint
                               AND ad_c.flg_available = g_flg_available
                              JOIN ad_complaint_mkt_vrs ad_cmv
                                ON ad_cmv.id_complaint = ad_ccs.id_complaint
                               AND nvl(ad_cmv.id_complaint_alias, 1) = nvl(ad_ccs.id_complaint_alias, 1)
                               AND ad_cmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_cmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_ccs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_ccs.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)
                               AND ad_ccs.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_complaint > 0
                       AND (temp_data.id_complaint_alias > 0 OR temp_data.id_complaint_alias IS NULL)) def_data
             WHERE def_data.records_count = 1
               AND EXISTS (SELECT 0
                      FROM complaint_inst_soft a_cis
                     WHERE a_cis.id_complaint = def_data.id_complaint
                       AND a_cis.id_software = i_software(pos_soft)
                       AND a_cis.id_institution = i_institution
                       AND a_cis.flg_available = g_flg_available
                       AND (a_cis.id_complaint_alias = def_data.id_complaint_alias OR
                           (a_cis.id_complaint_alias IS NULL AND def_data.id_complaint_alias IS NULL)))
               AND NOT EXISTS
             (SELECT 0
                      FROM complaint_dep_clin_serv a_cdcs
                     WHERE a_cdcs.id_complaint = def_data.id_complaint
                       AND a_cdcs.id_dep_clin_serv = i_dep_clin_serv_out
                       AND (a_cdcs.id_complaint_alias = def_data.id_complaint_alias OR
                           (a_cdcs.id_complaint_alias IS NULL AND def_data.id_complaint_alias IS NULL)));
    
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
        
    END set_complaint_freq;

    /**
    *  Insert both complaints and its aliases per sw and institution  
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institutio
    * @param i_mkt                         ID market
    * @param i_vers                        Content version
    * @param i_software                    ID software
    * @param i_id_content                  ID content complaint
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION set_complaint_search
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
    
        g_func_name := upper('SET_COMPLAINT_SEARCH');
    
        INSERT INTO complaint_inst_soft
            (id_complaint,
             id_institution,
             id_software,
             rank,
             flg_available,
             flg_gender,
             age_max,
             age_min,
             id_complaint_alias)
            SELECT def_data.id_complaint,
                   i_institution AS id_institution,
                   i_software(pos_soft) AS id_software,
                   10 AS rank,
                   g_flg_available AS flg_available,
                   def_data.flg_gender,
                   def_data.age_max,
                   def_data.age_min,
                   def_data.id_complaint_alias
              FROM (SELECT temp_data.id_complaint,
                           temp_data.flg_gender,
                           temp_data.age_max,
                           temp_data.age_min,
                           temp_data.id_complaint_alias,
                           row_number() over(PARTITION BY temp_data.id_complaint, temp_data.id_complaint_alias ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_c.id_complaint
                                                FROM complaint a_c
                                               WHERE a_c.id_content = ad_c.id_content
                                                 AND a_c.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_c.id_complaint
                                                FROM complaint a_c
                                               WHERE a_c.id_content = ad_c.id_content
                                                 AND a_c.flg_available = g_flg_available
                                                 AND a_c.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_complaint,
                                   decode(ad_cmv.id_complaint_alias,
                                          NULL,
                                          NULL,
                                          nvl((SELECT a_ca.id_complaint_alias
                                                FROM ad_complaint_alias ad_ca
                                                JOIN complaint_alias a_ca
                                                  ON a_ca.id_content = ad_ca.id_content
                                                 AND ad_ca.flg_available = a_ca.flg_available
                                               WHERE ad_ca.flg_available = g_flg_available
                                                 AND ad_ca.id_complaint = ad_cmv.id_complaint
                                                 AND ad_ca.id_complaint_alias = ad_cmv.id_complaint_alias),
                                              0)) id_complaint_alias,
                                   ad_cmv.id_market,
                                   ad_cmv.version,
                                   ad_cs.id_software,
                                   ad_c.flg_gender,
                                   ad_c.age_max,
                                   ad_c.age_min
                              FROM ad_complaint_software ad_cs
                              JOIN ad_complaint ad_c
                                ON ad_c.id_complaint = ad_cs.id_complaint
                               AND ad_c.flg_available = g_flg_available
                              JOIN ad_complaint_mkt_vrs ad_cmv
                                ON ad_cs.id_complaint = ad_cmv.id_complaint
                               AND ad_cmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_cmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_cs.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_cs.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_complaint > 0
                       AND (temp_data.id_complaint_alias > 0 OR temp_data.id_complaint_alias IS NULL)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS
             (SELECT 0
                      FROM complaint_inst_soft a_cis
                     WHERE a_cis.id_complaint = def_data.id_complaint
                       AND a_cis.id_institution = i_institution
                       AND a_cis.id_software = i_software(pos_soft)
                       AND (a_cis.id_complaint_alias = def_data.id_complaint_alias OR
                           (def_data.id_complaint_alias IS NULL AND a_cis.id_complaint_alias IS NULL)));
    
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
        
    END set_complaint_search;

    /**
    * Clean complaint search
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institution
    * @param i_software                    ID software
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION del_complaint_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete complaint_inst_search';
        g_func_name := upper('del_complaint_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM complaint_inst_soft a_cis
             WHERE a_cis.id_institution = i_institution
               AND a_cis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM complaint_inst_soft a_cis
             WHERE a_cis.id_institution = i_institution;
        
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
        
    END del_complaint_inst_search;

    /**
    * Clean complaint most frequent
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institution
    * @param i_software                    ID software
    * @param o_result_tbl                  Number of records inserted
    * @param o_error                       Error
    *
    * @return                              true or false on success or error
    *   
    * @author                              Adriana Salgueiro
    * @version                             v2.8.2.0
    * @since                               2020/10/07
    */

    FUNCTION del_complaint_freq
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
        g_error     := 'delete rehab_dep_clin_serv';
        g_func_name := upper('del_rehab_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            SELECT a_dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv a_dcs
              JOIN department a_d
                ON (a_d.id_department = a_dcs.id_department)
              JOIN dept a_dp
                ON (a_dp.id_dept = a_d.id_dept)
              JOIN software_dept a_sd
                ON (a_sd.id_dept = a_dp.id_dept)
             WHERE a_d.id_institution = i_institution
               AND a_d.id_institution = a_dp.id_institution
               AND a_dcs.id_clinical_service != 0
               AND a_sd.id_software IN (SELECT /*+ opt_estimate(area_list rows = 2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) sw_list);
        ELSE
            SELECT a_dcs.id_dep_clin_serv
              BULK COLLECT
              INTO o_dcs_list
              FROM dep_clin_serv a_dcs
              JOIN department a_d
                ON (a_d.id_department = a_dcs.id_department)
              JOIN dept a_dp
                ON (a_dp.id_dept = a_d.id_dept)
              JOIN software_dept a_sd
                ON (a_sd.id_dept = a_dp.id_dept)
             WHERE a_d.id_institution = i_institution
               AND a_d.id_institution = a_dp.id_institution
               AND a_dcs.id_clinical_service != 0;
        END IF;
    
        DELETE FROM complaint_dep_clin_serv a_cdcs
         WHERE a_cdcs.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
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
        
    END del_complaint_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_complaint_prm;
/
