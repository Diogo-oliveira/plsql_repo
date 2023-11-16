/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/ 

CREATE OR REPLACE PACKAGE BODY pk_allergy_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_allergy_prm';
    pos_soft        NUMBER := 1;

    /**
    * Configure allergies per software and institution
    *
    * @param i_lang                   Prefered language ID
    * @param i_mkt                    Market ID
    * @param i_vers                   Content Version
    * @param i_id_software            Software ID
    * @param i_id_content             Product id content
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    /*    FUNCTION set_allergy_inst_soft
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
    
    BEGIN
    
    END set_allergy_inst_soft;*/

    /**
    * Delete association of allergies to software and institution - allergy_inst_soft
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

   /* FUNCTION del_allergy_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete allergy_inst_soft';
        g_func_name := upper('del_allergy_inst_soft');
    
        SELECT \*+ opt_estimate(soft_list rows = 10)*\
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
        
            DELETE FROM allergy_inst_soft a_ais
             WHERE a_ais.id_institution = i_institution
               AND a_ais.id_software IN (SELECT \*+ dynamic_sampling(2)*\
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM allergy_inst_soft a_ais
             WHERE a_ais.id_institution = i_institution;
        
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
        
    END del_allergy_inst_soft;*/

    /**
    * Configure allergies per software, institution and market
    *
    * @param i_lang                   Prefered language ID
    * @param i_mkt                    Market ID
    * @param i_vers                   Content Version
    * @param i_id_software            Software ID
    * @param i_id_content             Product id content
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    FUNCTION set_allergy_inst_soft_market
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
    
        l_id_market NUMBER := pk_utils.get_institution_market(i_lang, i_institution);
    
    BEGIN
    
        INSERT INTO allergy_inst_soft_market
            (id_allergy, id_allergy_parent, id_institution, id_software, id_market, flg_freq)
            SELECT def_data.id_allergy,
                   def_data.id_allergy_parent,
                   i_institution,
                   i_software(pos_soft),
                   l_id_market AS id_market,
                   def_data.flg_freq
              FROM (SELECT temp_data.id_allergy,
                           temp_data.id_allergy_parent,
                           temp_data.flg_freq,
                           row_number() over(PARTITION BY temp_data.id_allergy, temp_data.id_allergy_parent ORDER BY temp_data.id_market DESC, temp_data.id_software DESC) records_count
                      FROM (SELECT nvl((SELECT a_e.id_allergy
                                         FROM allergy a_e
                                        WHERE ad_as.id_allergy = a_e.id_allergy
                                          AND a_e.flg_available = g_flg_available
                                          AND a_e.flg_active = g_active),
                                       0) AS id_allergy,
                                   ad_as.id_allergy_parent,
                                   ad_as.flg_freq,
                                   ad_as.id_software,
                                   ad_mv.id_market
                              FROM ad_allergy_software ad_as
                              JOIN ad_allergy_mkt_vrs ad_mv
                                ON ad_mv.id_allergy = ad_as.id_allergy
                             WHERE ad_as.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_mv.id_market IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_mv.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                      column_value
                                                       FROM TABLE(CAST(i_vers AS table_varchar)) p)
                               AND ad_as.flg_available = g_flg_available) temp_data
                     WHERE temp_data.id_allergy > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM allergy_inst_soft_market a_ism
                     WHERE a_ism.id_allergy = def_data.id_allergy
                       AND a_ism.id_institution = i_institution
                       AND a_ism.id_software = i_software(pos_soft)
                       AND a_ism.id_market = l_id_market);
    
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
        
    END set_allergy_inst_soft_market;

    /**
    * Delete association of allergies to software, institution and market - allergy_inst_soft_market
    *
    * @param i_lang                   Prefered language ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID
    * @param o_result_tbl             Number of records inserted
    * @param o_error                  Error
    *
    *
    * @return                         true or false on success or error
    *
    * @author                         Adriana Salgueiro
    * @version                        v2.8.2.4
    * @since                          2020/04/15
    */

    FUNCTION del_allergy_inst_soft_market
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete allergy_inst_soft_market';
        g_func_name := upper('del_allergy_inst_soft_market');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
        
            DELETE FROM allergy_inst_soft_market a_aism
             WHERE a_aism.id_institution = i_institution
               AND a_aism.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM allergy_inst_soft_market a_aism
             WHERE a_aism.id_institution = i_institution;
        
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
        
    END del_allergy_inst_soft_market;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_allergy_prm;
/