/*-- Last Change Revision: $Rev: 1941669 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-03-20 10:22:41 +0000 (sex, 20 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_positioning_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_POSITIONING_PRM';
    pos_soft        NUMBER := 1;

    -- g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    /**
    * Load positioning 
    *
    * @param i_lang                        Prefered language ID
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    *
    * @return                                    true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2013/03/28
    */

    FUNCTION load_positioning
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'SET POSITIONING BY MARKET AND CONTENT VERSION';
    
        INSERT INTO positioning
            (id_positioning, code_positioning, rank, flg_available, id_content)
            SELECT seq_positioning.nextval,
                   'POSITIONING.CODE_POSITIONING.' || seq_positioning.currval,
                   def_data.rank,
                   g_flg_available,
                   def_data.id_content
              FROM (SELECT ad_p.rank, ad_p.id_content
                      FROM ad_positioning ad_p
                     WHERE ad_p.flg_available = g_flg_available) def_data
             WHERE NOT EXISTS (SELECT 0
                      FROM positioning a_p
                     WHERE a_p.id_content = def_data.id_content);
    
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
                                              'SET_DEF_POSITIONING',
                                              o_error);
            RETURN FALSE;
        
    END load_positioning;

    -- searcheable loader method signature
    /**
    *Set Default Positionings
    *
    * @param i_lang                Prefered language ID
    * @param o_positioning         Positioning
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/16
    */

    FUNCTION set_positioning_search
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
    
        g_error := 'SET POSITIONING BY MARKET AND CONTENT VERSION';
    
        INSERT INTO positioning_instit_soft
            (id_positioning_instit_soft, id_positioning, id_institution, id_software, flg_available, rank, posit_type)
            SELECT seq_positioning_instit_soft.nextval,
                   def_data.id_positioning,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available,
                   def_data.rank,
                   def_data.posit_type
              FROM (SELECT temp_data.id_positioning,
                           temp_data.rank,
                           temp_data.posit_type,
                           row_number() over(PARTITION BY temp_data.id_positioning ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_p.id_positioning
                                                FROM positioning a_p
                                                JOIN ad_positioning ad_p
                                                  ON ad_p.id_content = a_p.id_content
                                               WHERE ad_p.id_positioning = ad_ps.id_positioning
                                                 AND a_p.flg_available = g_flg_available),
                                              0),
                                          nvl((SELECT a_p.id_positioning
                                                FROM positioning a_p
                                                JOIN ad_positioning ad_p
                                                  ON ad_p.id_content = a_p.id_content
                                               WHERE ad_p.id_positioning = ad_ps.id_positioning
                                                 AND a_p.flg_available = g_flg_available
                                                 AND ad_p.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_positioning,
                                   ad_ps.rank,
                                   ad_ps.posit_type,
                                   ad_pmv.id_market,
                                   ad_pmv.version,
                                   ad_ps.id_software
                              FROM ad_positioning_software ad_ps
                              JOIN ad_positioning_mrk_vrs ad_pmv
                                ON ad_pmv.id_positioning = ad_ps.id_positioning
                             WHERE ad_ps.flg_available = g_flg_available
                               AND ad_ps.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_pmv.id_market IN (SELECT /*+ dynamic_sampling(2) */
                                                         column_value
                                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_pmv.version IN (SELECT /*+ dynamic_sampling(2) */
                                                       column_value
                                                        FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_rank = 1
               AND def_data.id_positioning != 0
               AND NOT EXISTS (SELECT 0
                      FROM positioning_instit_soft a_pis
                     WHERE a_pis.id_positioning = def_data.id_positioning
                       AND a_pis.id_institution = i_institution
                       AND a_pis.id_software = i_software(pos_soft));
    
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
                                              'SET_DEF_POSITIONING',
                                              o_error);
            RETURN FALSE;
        
    END set_positioning_search;

    /**
    *Delete Default Positionings
    *
    * @param i_lang                Prefered language ID
    * @param o_positioning         Positioning
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/16
    */

    FUNCTION del_positioning_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete positioning_instit_soft';
        g_func_name := upper('POSITIONING_INSTIT_SOFT');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM positioning_instit_soft a_pis
             WHERE a_pis.id_institution = i_institution
               AND a_pis.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM positioning_instit_soft a_pis
             WHERE a_pis.id_institution = i_institution;
        
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
        
    END del_positioning_search;

    /**
    *Load Positionings relation
    *
    * @param i_lang                        Prefered language ID
    * @param o_result_tbl                Number of records inserted
    * @param o_error                       Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     2.8.1.0
    * @since                        2020/03/18
    */

    FUNCTION load_sr_posit_rel
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'LOAD POSITIONING RELATION';
    
        INSERT INTO sr_posit_rel
            (id_sr_posit_rel, id_sr_posit, id_sr_posit_relation, flg_type, flg_available)
            SELECT seq_sr_posit_rel.nextval, id_positioning, id_positioning_relation, flg_type, g_flg_available
              FROM (SELECT nvl((SELECT a_p.id_positioning
                                 FROM ad_positioning ad_p
                                 JOIN positioning a_p
                                   ON ad_p.id_content = a_p.id_content
                                WHERE ad_p.id_positioning = ad_srpr.id_positioning),
                               0) AS id_positioning,
                           nvl((SELECT a_p.id_positioning
                                 FROM ad_positioning ad_p
                                 JOIN positioning a_p
                                   ON ad_p.id_content = a_p.id_content
                                WHERE ad_p.id_positioning = ad_srpr.id_positioning_relation),
                               0) AS id_positioning_relation,
                           ad_srpr.flg_type
                      FROM ad_sr_posit_rel ad_srpr
                     WHERE ad_srpr.flg_available = g_flg_available) def_data
             WHERE def_data.id_positioning != 0
               AND def_data.id_positioning_relation != 0
               AND NOT EXISTS (SELECT 0
                      FROM sr_posit_rel a_srpr
                     WHERE a_srpr.id_sr_posit = def_data.id_positioning
                       AND a_srpr.id_sr_posit_relation = def_data.id_positioning_relation
                       AND a_srpr.flg_type = def_data.flg_type);
    
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
                                              'SET_DEF_POSITIONING',
                                              o_error);
            RETURN FALSE;
        
    END load_sr_posit_rel;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_positioning_prm;
/