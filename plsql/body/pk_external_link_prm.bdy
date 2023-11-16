/*-- Last Change Revision: $Rev:$*/
/*-- Last Change by: $Author:$*/
/*-- Date of last change: $Date:$*/

CREATE OR REPLACE PACKAGE BODY pk_external_link_prm IS

    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'pk_external_link_prm';
    -- Private Methods
    pos_soft NUMBER := 1;

    /**
    * Load external links
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      Adriana Salgueiro
    * @version                     v2.8.2.0
    * @since                       2020/10/16
    */

    FUNCTION load_external_link
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_func_name := upper('LOAD_EXTERNAL_LINK');
    
        --insert of all links regardless of the id_parent
        INSERT INTO external_link a_el
            (id_external_link, internal_name, id_parent, id_content, flg_type, flg_available)
            SELECT seq_external_link.nextval, internal_name, NULL, id_content, flg_type, g_flg_available
              FROM (SELECT ad_el.internal_name, ad_el.id_content, ad_el.flg_type
                      FROM ad_external_link ad_el
                     WHERE ad_el.flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM external_link a_el
                             WHERE a_el.id_content = ad_el.id_content
                               AND a_el.flg_available = g_flg_available));
    
        o_result_tbl := SQL%ROWCOUNT;
    
        --update id parent when it is not null in alert_default
        FOR i IN (SELECT ad_el.id_content, a_el_par.id_external_link AS id_parent
                    FROM external_link a_el
                    JOIN ad_external_link ad_el --to get id content child
                      ON ad_el.id_content = a_el.id_content
                     AND ad_el.flg_available = a_el.flg_available
                     AND ad_el.flg_available = g_flg_available
                     AND ad_el.id_parent IS NOT NULL
                    JOIN ad_external_link ad_el_par
                      ON ad_el_par.id_external_link = ad_el.id_parent
                     AND ad_el_par.flg_available = g_flg_available
                    JOIN external_link a_el_par --to get id_external_link parent
                      ON a_el_par.id_content = ad_el_par.id_content
                     AND a_el_par.flg_available = g_flg_available
                   WHERE a_el.id_parent IS NULL)
        LOOP
        
            UPDATE external_link a_el
               SET a_el.id_parent = i.id_parent
             WHERE a_el.id_content = i.id_content;
        
        END LOOP;
    
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
        
    END load_external_link;

    /**
    *  Insert external links per sw and institution
    *
    * @param i_lang                        Prefered language ID
    * @param i_institution                 ID institution
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
    * @since                               2020/10/16
    */

    FUNCTION set_external_link_search
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
    
        g_func_name := upper('SET_EXTERNAL_LINK_SEARCH');
    
        INSERT INTO external_link_soft_inst
            (id_external_link_soft_instit,
             id_external_link,
             normal_link,
             context_link,
             flg_context,
             flg_visible,
             rank,
             id_institution,
             id_software,
             id_profile_template,
             flg_available)
            SELECT seq_external_link_soft_inst.nextval,
                   def_data.id_external_link,
                   def_data.normal_link,
                   def_data.context_link,
                   def_data.flg_context,
                   def_data.flg_visible,
                   def_data.rank,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_profile_template,
                   g_flg_available
              FROM (SELECT temp_data.id_external_link,
                           temp_data.normal_link,
                           temp_data.id_profile_template,
                           temp_data.context_link,
                           temp_data.flg_context,
                           temp_data.flg_visible,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_external_link, temp_data.id_profile_template ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_rank
                      FROM (SELECT decode(l_cnt_count,
                                          0,
                                          nvl((SELECT a_el.id_external_link
                                                FROM external_link a_el
                                                JOIN ad_external_link ad_el
                                                  ON ad_el.id_content = a_el.id_content
                                                 AND ad_el.flg_available = a_el.flg_available
                                                 AND a_el.flg_available = g_flg_available
                                                 AND ad_el.id_external_link = ad_els.id_external_link),
                                              0),
                                          nvl((SELECT a_el.id_external_link
                                                FROM external_link a_el
                                                JOIN ad_external_link ad_el
                                                  ON ad_el.id_content = a_el.id_content
                                                 AND ad_el.flg_available = a_el.flg_available
                                                 AND a_el.flg_available = g_flg_available
                                                 AND ad_el.id_external_link = ad_els.id_external_link
                                                 AND ad_el.id_content IN
                                                     (SELECT /*+ opt_estimate(p rows = 10)*/
                                                       column_value
                                                        FROM TABLE(CAST(i_id_content AS table_varchar)) p)),
                                              0)) id_external_link,
                                   ad_els.normal_link,
                                   ad_els.id_profile_template,
                                   ad_els.context_link,
                                   ad_els.flg_context,
                                   ad_els.flg_visible,
                                   ad_els.rank,
                                   ad_els.id_software,
                                   ad_elmv.id_market,
                                   ad_elmv.version
                              FROM ad_external_link_software ad_els
                              JOIN ad_external_link_mkt_vrs ad_elmv
                                ON ad_elmv.id_external_link = ad_els.id_external_link
                               AND ad_elmv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_elmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)
                             WHERE ad_els.flg_available = g_flg_available
                               AND ad_els.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)) temp_data) def_data
             WHERE def_data.id_external_link > 0
               AND def_data.records_rank = 1
               AND NOT EXISTS (SELECT 0
                      FROM external_link_soft_inst a_elsi
                     WHERE a_elsi.id_external_link = def_data.id_external_link
                       AND a_elsi.id_institution = i_institution
                       AND a_elsi.id_software = i_software(pos_soft));
    
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
        
    END set_external_link_search;

    /**
    * Delete external links per sw of an institution
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
    * @since                               2020/10/16
    */

    FUNCTION del_external_link_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete external_link_search';
        g_func_name := upper('DEL_EXTERNAL_LINK_SEARCH');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM external_link_soft_inst a_elsi
             WHERE a_elsi.id_institution = i_institution
               AND a_elsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                            FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM external_link_soft_inst a_elsi
             WHERE a_elsi.id_institution = i_institution;
        
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
        
    END del_external_link_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_external_link_prm;
/
