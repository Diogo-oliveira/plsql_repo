/*-- Last Change Revision: $Rev: 1986627 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2021-04-21 15:04:46 +0100 (qua, 21 abr 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_periodicobservation_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_PERIODICOBSERVATION_prm';
    pos_soft        NUMBER := 1;

    -- Private Methods
    /********************************************************************************************
    * Get Periodic observation parameters dest id
    *
    * @param i_lang                Prefered language ID
    * @param i_id_po_param         Periodic Obs Parameter ID
    * @param i_from                Flg that show the id request (D - DEFAULT, A - ALERT)
    *
    *
    * @return                      Destination DB equivalent id
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION get_dest_pop_id
    (
        i_lang        IN language.id_language%TYPE,
        i_id_po_param IN po_param.id_po_param%TYPE,
        i_from        IN VARCHAR2 DEFAULT 'D'
    ) RETURN NUMBER IS
    
        l_pop_id po_param.id_po_param%TYPE := NULL;
    
    BEGIN
    
        IF i_from = 'D'
        THEN
        
            SELECT nvl((SELECT id_po_param
                         FROM (SELECT a_pop.id_po_param,
                                      ad_pop.flg_type,
                                      ad_pop.id_parameter ad_id_parameter,
                                      a_pop.id_parameter  a_id_parameter
                                 FROM po_param a_pop
                                 JOIN ad_po_param ad_pop
                                   ON ad_pop.id_content = a_pop.id_content
                                WHERE ad_pop.id_po_param = i_id_po_param
                                  AND a_pop.id_inst_owner = 0
                                  AND a_pop.flg_available = g_flg_available
                                  AND rownum > 0) t
                        WHERE get_dest_parameter_map(1, t.flg_type, t.ad_id_parameter) = t.a_id_parameter),
                       0)
              INTO l_pop_id
              FROM dual;
        
            dbms_output.put_line(l_pop_id);
        
        ELSE
        
            SELECT nvl((SELECT id_po_param
                         FROM (SELECT a_pop.id_po_param,
                                      ad_pop.flg_type,
                                      ad_pop.id_parameter ad_id_parameter,
                                      a_pop.id_parameter  a_id_parameter
                                 FROM po_param a_pop
                                 JOIN ad_po_param ad_pop
                                   ON ad_pop.id_content = a_pop.id_content
                                WHERE ad_pop.id_po_param = i_id_po_param
                                  AND a_pop.flg_available = g_flg_available
                                  AND rownum > 0) t
                        WHERE get_dest_parameter_map(1, t.flg_type, t.ad_id_parameter) = t.a_id_parameter),
                       0)
              INTO l_pop_id
              FROM dual;
        
        END IF;
        -- double check content id reffers to the same
    
        RETURN l_pop_id;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_dest_pop_id;

    /********************************************************************************************
    * Set Default Periodic observation parameters
    *
    * @param i_lang                Prefered language ID
    * @param i_flg_type            Type of parameter configured in default
    * @param i_parameter           Parameter id in default
    *
    *
    * @return                      Destination DB equivalent id
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION get_dest_parameter_map
    (
        i_lang      IN language.id_language%TYPE,
        i_flg_type  IN po_param.flg_type%TYPE,
        i_parameter IN po_param.id_parameter%TYPE
    ) RETURN NUMBER IS
    
        l_dest_parameter NUMBER(24) := NULL;
    
    BEGIN
        SELECT decode(i_flg_type,
                      'A',
                      nvl((SELECT a_a.id_analysis
                            FROM analysis a_a
                            JOIN ad_analysis ad_a
                              ON ad_a.id_content = a_a.id_content
                             AND ad_a.flg_available = g_flg_available
                           WHERE a_a.flg_available = g_flg_available
                             AND ad_a.id_analysis = i_parameter),
                          0),
                      'E',
                      nvl((SELECT a_e.id_exam
                            FROM exam a_e
                            JOIN alert_default.exam ad_e
                              ON ad_e.id_content = a_e.id_content
                             AND ad_e.flg_available = g_flg_available
                           WHERE a_e.flg_available = g_flg_available
                             AND ad_e.id_exam = i_parameter),
                          0),
                      'H',
                      nvl((SELECT a_h.id_habit
                            FROM habit a_h
                            JOIN ad_habit ad_h
                              ON ad_h.id_content = a_h.id_content
                             AND ad_h.flg_available = g_flg_available
                           WHERE a_h.flg_available = g_flg_available
                             AND ad_h.id_habit = i_parameter),
                          0),
                      'VS',
                      nvl((SELECT vs.id_vital_sign
                            FROM vital_sign vs
                           WHERE vs.flg_available = g_flg_available
                             AND vs.id_vital_sign = i_parameter),
                          0),
                      'O',
                      nvl(i_parameter, 0))
          INTO l_dest_parameter
          FROM dual;
        RETURN l_dest_parameter;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_dest_parameter_map;

    -- content loader method
    /********************************************************************************************
    * Set Default Periodic observation parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/

    FUNCTION set_def_poparam
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_pop VARCHAR2(200) := 'PO_PARAM.CODE_PO_PARAM.';
    
    BEGIN
    
        g_func_name := 'set_def_poparam';
        g_error     := 'GET PERIODIC OBSERVATION PARAMETERS DATA FROM DEF';
    
        INSERT INTO po_param
            (id_po_param,
             id_inst_owner,
             code_po_param,
             flg_type,
             id_parameter,
             flg_fill_type,
             rank,
             flg_available,
             id_content,
             flg_domain,
             id_sample_type)
            SELECT seq_po_param.nextval,
                   0,
                   l_code_pop || seq_po_param.currval,
                   def_data.flg_type,
                   def_data.id_parameter,
                   def_data.flg_fill_type,
                   def_data.rank,
                   g_flg_available,
                   def_data.id_content,
                   def_data.flg_domain,
                   decode(def_data.flg_type,
                          'A',
                          nvl((SELECT a_st.id_sample_type
                                FROM ad_sample_type ad_st
                                JOIN sample_type a_st
                                  ON a_st.id_content = ad_st.id_content
                                 AND a_st.flg_available = ad_st.flg_available
                               WHERE ad_st.flg_available = g_flg_available
                                 AND ad_st.id_sample_type = def_data.id_sample_type),
                              0),
                          NULL) AS id_sample_type
              FROM (SELECT ad_pop.flg_type,
                           get_dest_parameter_map(i_lang, ad_pop.flg_type, ad_pop.id_parameter) id_parameter,
                           ad_pop.flg_fill_type,
                           ad_pop.rank,
                           ad_pop.id_content,
                           ad_pop.flg_domain,
                           ad_pop.id_sample_type
                      FROM ad_po_param ad_pop
                     WHERE ad_pop.flg_available = g_flg_available) def_data
             WHERE def_data.id_parameter > 0
               AND (id_sample_type IS NULL OR id_sample_type > 0)
               AND NOT EXISTS (SELECT 0
                      FROM po_param a_pop
                     WHERE a_pop.id_content = def_data.id_content
                       AND a_pop.flg_available = g_flg_available
                       AND a_pop.id_inst_owner = 0);
    
        o_result := SQL%ROWCOUNT;
    
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
        
    END set_def_poparam;

    /********************************************************************************************
    * Set Default Periodic observation parameters multichoice values
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/28
    ********************************************************************************************/
    FUNCTION set_def_poparam_mc
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_pop  VARCHAR2(200) := 'PO_PARAM_MC.CODE_PO_PARAM_MC.';
        l_code_icon VARCHAR2(200) := 'PO_PARAM_MC.CODE_ICON.';
    
    BEGIN
    
        g_error := 'GET ALL PERIODIC OBSERVATION BY UNIT MEASURE PK';
    
        INSERT INTO po_param_mc
            (id_po_param_mc, code_po_param_mc, id_po_param, id_inst_owner, code_icon, rank, flg_available, id_content)
            SELECT seq_po_param_mc.nextval,
                   l_code_pop || seq_po_param_mc.currval,
                   def_data.id_po_param,
                   0,
                   l_code_icon || seq_po_param_mc.currval,
                   def_data.rank,
                   g_flg_available,
                   def_data.id_content
              FROM (SELECT ad_ppm.rowid l_row,
                           get_dest_pop_id(1, ad_ppm.id_po_param) id_po_param,
                           ad_ppm.code_icon,
                           ad_ppm.rank,
                           ad_ppm.id_content
                      FROM ad_po_param_mc ad_ppm
                      JOIN ad_po_param ad_pop
                        ON ad_pop.id_po_param = ad_ppm.id_po_param
                       AND ad_pop.flg_available = g_flg_available
                     WHERE ad_ppm.flg_available = g_flg_available) def_data
             WHERE def_data.id_po_param > 0
               AND NOT EXISTS (SELECT 0
                      FROM po_param_mc a_ppm
                     WHERE a_ppm.id_content = def_data.id_content
                       AND a_ppm.id_po_param = def_data.id_po_param
                       AND a_ppm.flg_available = g_flg_available
                       AND a_ppm.id_inst_owner = 0);
    
        o_result := SQL%ROWCOUNT;
    
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
        
    END set_def_poparam_mc;

    -- searcheable loader method
    /********************************************************************************************
    * Set Default Periodic observation parameters by institution health program
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_hpg_search
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
        /*INSERT INTO po_param_hpg
        (id_po_param_hpg,
         id_po_param,
         id_inst_owner,
         id_health_program,
         id_institution,
         id_software,
         rank,
         flg_available)
        SELECT seq_po_param_hpg.nextval,
               def_data.id_po_param,
               0,
               def_data.id_health_program,
               i_institution,
               i_software(pos_soft),
               def_data.rank,
               g_flg_available
          FROM (SELECT temp_data.id_health_program,
                       temp_data.id_po_param,
                       temp_data.rank,
                       row_number() over(PARTITION BY temp_data.id_health_program, temp_data.id_po_param
        
                       ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                  FROM (SELECT pophpg.id_health_program,
                               get_dest_pop_id(1, pophpg.id_po_param) id_po_param,
                               pophpg.rank,
                               pophpg.id_software,
                               pophmv.id_market,
                               pophmv.version
                          FROM alert_default.po_param_hpg pophpg
                         INNER JOIN alert_default.po_param_hpg_mkt_vers pophmv
                            ON (pophmv.id_po_param_hpg = pophpg.id_po_param_hpg)
                         WHERE pophpg.flg_available = g_flg_available
                           AND pophpg.id_software IN
                               (SELECT \*+ opt_estimate(TABLE p rows = 1) *\
                                 column_value
                                  FROM TABLE(CAST(i_software AS table_number)) p)
                           AND pophmv.id_market IN (SELECT \*+ opt_estimate(TABLE p rows = 1) *\
                                                     column_value
                                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                           AND pophmv.version IN (SELECT \*+ opt_estimate(TABLE p rows = 1) *\
                                                   column_value
                                                    FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                 WHERE temp_data.id_po_param > 0
                   AND EXISTS (SELECT 0
                          FROM health_program hp
                         WHERE hp.id_health_program = temp_data.id_health_program)) def_data
         WHERE def_data.records_count = 1
           AND EXISTS (SELECT 0
                  FROM health_program_soft_inst hpsi
                 WHERE hpsi.id_health_program = def_data.id_health_program
                   AND hpsi.id_institution = i_institution
                   AND hpsi.id_software = i_software(pos_soft))
           AND NOT EXISTS (SELECT 0
                  FROM po_param_hpg po_hpg
                 WHERE po_hpg.id_po_param = def_data.id_po_param
                   AND po_hpg.id_inst_owner = 0
                   AND po_hpg.id_health_program = def_data.id_health_program
                   AND po_hpg.id_institution = i_institution
                   AND po_hpg.id_software = i_software(pos_soft)
                   AND po_hpg.flg_available = g_flg_available);*/
        o_result_tbl := 0;
        g_error      := 'Deprecated table in ALERT-305021';
        RETURN FALSE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_POP_HPG_SEARCH',
                                              o_error);
            RETURN FALSE;
    END set_pop_hpg_search;

    /********************************************************************************************
    * Set Default Periodic observation parameters by institution unit measure
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_vers             Content Version
    * @param i_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_um_search
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
    
        INSERT INTO po_param_um
            (id_po_param_um,
             id_po_param,
             id_inst_owner,
             id_institution,
             id_software,
             id_unit_measure_type,
             id_unit_measure_subtype,
             val_min,
             val_max,
             format_num,
             flg_available)
            SELECT seq_po_param_um.nextval,
                   def_data.id_po_param,
                   0,
                   i_institution,
                   i_software(pos_soft),
                   def_data.id_unit_measure_type,
                   def_data.id_unit_measure_subtype,
                   def_data.val_min,
                   def_data.val_max,
                   def_data.format_num,
                   g_flg_available
              FROM (SELECT temp_data.id_unit_measure_type,
                           temp_data.id_po_param,
                           temp_data.id_unit_measure_subtype,
                           temp_data.val_min,
                           temp_data.val_max,
                           temp_data.format_num,
                           row_number() over(PARTITION BY temp_data.id_unit_measure_subtype, temp_data.id_unit_measure_type, temp_data.id_po_param ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT get_dest_pop_id(1, ad_ppu.id_po_param) id_po_param,
                                   decode(ad_ppu.id_unit_measure_type,
                                          NULL,
                                          NULL,
                                          nvl((SELECT id_unit_measure_type
                                                FROM unit_measure_type umt
                                               WHERE umt.id_unit_measure_type = ad_ppu.id_unit_measure_type),
                                              0)) id_unit_measure_type,
                                   decode(ad_ppu.id_unit_measure_subtype,
                                          NULL,
                                          NULL,
                                          nvl((SELECT umst.id_unit_measure_subtype
                                                FROM unit_measure_subtype umst
                                               WHERE umst.id_unit_measure_subtype = ad_ppu.id_unit_measure_subtype),
                                              0)) id_unit_measure_subtype,
                                   ad_ppu.val_min,
                                   ad_ppu.val_max,
                                   ad_ppu.format_num,
                                   ad_ppu.id_software,
                                   ad_ppuv.id_market,
                                   ad_ppuv.version
                              FROM ad_po_param_um ad_ppu
                              JOIN ad_po_param_um_mkt_vrs ad_ppuv
                                ON ad_ppuv.id_po_param_um = ad_ppu.id_po_param_um
                             WHERE ad_ppu.flg_available = g_flg_available
                               AND ad_ppu.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_ppuv.id_market IN
                                   (SELECT /*+ dynamic_sampling(p 2) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_ppuv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_po_param > 0
                       AND (temp_data.id_unit_measure_type IS NULL OR temp_data.id_unit_measure_type > 0)
                       AND (temp_data.id_unit_measure_subtype IS NULL OR temp_data.id_unit_measure_subtype > 0)) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM po_param_um a_ppu
                     WHERE a_ppu.id_po_param = def_data.id_po_param
                       AND a_ppu.id_inst_owner = 0
                       AND a_ppu.id_institution = i_institution
                       AND a_ppu.id_software = i_software(pos_soft)
                       AND a_ppu.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_POP_UM_SEARCH',
                                              o_error);
            RETURN FALSE;
        
    END set_pop_um_search;

    FUNCTION del_pop_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete po_param_um';
        g_func_name := upper('del_pop_um_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_um a_ppu
             WHERE a_ppu.id_institution = i_institution
               AND a_ppu.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            DELETE FROM po_param_um a_ppu
             WHERE a_ppu.id_institution = i_institution;
        
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
        
    END del_pop_um_search;

    /********************************************************************************************
    * Set Default Periodic observation parameters ranks
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_vers             Content Version
    * @param i_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_pop_rk_search
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
    
        INSERT INTO po_param_rank
            (id_po_param_rank, id_po_param, id_inst_owner, rank, id_institution, id_software, flg_available)
            SELECT seq_po_param_rank.nextval,
                   def_data.id_po_param,
                   0,
                   def_data.rank,
                   i_institution,
                   i_software(pos_soft),
                   g_flg_available
              FROM (SELECT temp_data.id_po_param,
                           temp_data.rank,
                           row_number() over(PARTITION BY temp_data.id_po_param ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT get_dest_pop_id(1, ad_ppr.id_po_param) id_po_param,
                                   ad_ppr.rank,
                                   ad_ppr.id_software,
                                   ad_pprv.id_market,
                                   ad_pprv.version
                              FROM ad_po_param_rank ad_ppr
                              JOIN ad_po_param_rank_mkt_vrs ad_pprv
                                ON ad_pprv.id_po_param_rank = ad_ppr.id_po_param_rank
                             WHERE ad_ppr.flg_available = g_flg_available
                               AND ad_ppr.id_software IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                      FROM TABLE(CAST(i_software AS table_number)) p)
                               AND ad_pprv.id_market IN
                                   (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                     column_value
                                      FROM TABLE(CAST(i_mkt AS table_number)) p)
                               AND ad_pprv.version IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                                        column_value
                                                         FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data
                     WHERE temp_data.id_po_param > 0) def_data
             WHERE def_data.records_count = 1
               AND NOT EXISTS (SELECT 0
                      FROM po_param_rank a_ppr
                     WHERE a_ppr.id_po_param = def_data.id_po_param
                       AND a_ppr.id_inst_owner = 0
                       AND a_ppr.id_institution = i_institution
                       AND a_ppr.id_software = i_software(pos_soft)
                       AND a_ppr.flg_available = g_flg_available);
    
        o_result_tbl := SQL%ROWCOUNT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_POP_RK_SEARCH',
                                              o_error);
            RETURN FALSE;
        
    END set_pop_rk_search;

    FUNCTION del_pop_rk_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
    
        g_error     := 'delete po_param_rank';
        g_func_name := upper('del_pop_rk_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_rank a_ppr
             WHERE a_ppr.id_institution = i_institution
               AND a_ppr.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                          column_value
                                           FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
            DELETE FROM po_param_rank a_ppr
             WHERE a_ppr.id_institution = i_institution;
        
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
        
    END del_pop_rk_search;

    /********************************************************************************************
    * Returns xxxxxxxxxxxx
    *
    * @param i_lang                  Language id
    * @param i_id_professional       Professional identifier
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/18
    * @version                       2.6.1.x
    ********************************************************************************************/
    FUNCTION set_poparamwh_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(100 CHAR) := 'set_poparamwh_search';
    
    BEGIN
    
        g_error := 'LOAD POP_PARAM_WH DEFAULT RECORDS';
    
        IF (i_id_content = table_varchar('WH') OR i_id_content.count = 0)
        THEN
        
            INSERT INTO po_param_wh
                (id_po_param_wh, id_po_param, id_inst_owner, flg_owner, id_institution, id_software, flg_available)
                SELECT seq_po_param_wh.nextval,
                       def_data.id_po_param,
                       0,
                       def_data.flg_owner,
                       i_institution,
                       i_software(pos_soft),
                       g_flg_available
                  FROM (SELECT temp_data.id_po_param,
                               temp_data.flg_owner,
                               row_number() over(PARTITION BY temp_data.id_po_param, temp_data.flg_owner ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                          FROM (SELECT get_dest_pop_id(i_lang, def_ppw.id_po_param) id_po_param,
                                       def_ppw.flg_owner,
                                       def_ppw.id_software,
                                       def_ppw.id_market,
                                       def_ppw.version
                                  FROM alert_default.po_param_wh def_ppw
                                 WHERE def_ppw.flg_available = g_flg_available
                                   AND def_ppw.id_market IN
                                       (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                                   AND def_ppw.version IN
                                       (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND def_ppw.id_software IN
                                       (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p)) temp_data
                         WHERE temp_data.id_po_param > 0) def_data
                 WHERE def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                          FROM po_param_wh ppwh
                         WHERE ppwh.id_po_param = def_data.id_po_param
                           AND ppwh.id_inst_owner = 0
                           AND ppwh.flg_owner = def_data.flg_owner
                           AND ppwh.id_institution = i_institution
                           AND ppwh.id_software = i_software(pos_soft));
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            o_result_tbl := 0;
        
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_poparamwh_search;

    FUNCTION del_poparamwh_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete po_param_wh';
        g_func_name := upper('del_poparamwh_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_wh ppwh
             WHERE ppwh.id_institution = i_institution
               AND ppwh.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM po_param_wh ppwh
             WHERE ppwh.id_institution = i_institution;
        
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
    END del_poparamwh_search;

    /********************************************************************************************
    * Set Default Periodic observation Sets by institution (support for task type 101,7,10)
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_version             Content Version
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.4.3
    * @since                       2014/12/29
    ********************************************************************************************/
    FUNCTION set_pop_sets_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cnt       table_varchar := i_id_content;
        l_run_sets  VARCHAR2(2);
        l_task_type NUMBER;
        l_cnt_count NUMBER := 0;
    
    BEGIN
    
        g_error := 'INSERT DEFAULT CONFIGURATION IN PO_PARAM_SETS';
    
        IF l_cnt.count != 0
        THEN
        
            IF l_cnt.count = 1
            THEN
            
                l_run_sets  := l_cnt(1);
                l_cnt_count := l_cnt.count - 1;
            
            ELSE
            
                l_run_sets  := l_cnt(1);
                l_task_type := to_number(l_cnt(2));
                l_cnt_count := l_cnt.count - 2;
            
            END IF;
        
        END IF;
    
        IF (l_run_sets = 'ST' OR i_id_content.count = 0)
        THEN
        
            INSERT INTO po_param_sets
                (id_po_param,
                 id_inst_owner,
                 id_task_type,
                 task_type_content,
                 id_software,
                 id_institution,
                 rank,
                 flg_available)
                SELECT dest_data.id_po_param,
                       0,
                       dest_data.id_task_type,
                       dest_data.task_type_content,
                       i_software(pos_soft),
                       i_institution,
                       dest_data.rank,
                       'Y'
                  FROM (SELECT def_data.id_po_param,
                               def_data.id_task_type,
                               def_data.task_type_content,
                               def_data.rank,
                               row_number() over(PARTITION BY def_data.id_po_param, def_data.id_task_type, def_data.task_type_content ORDER BY def_data.id_software DESC, def_data.id_market DESC, decode(def_data.version, 'DEFAULT', 0, 1) DESC) records_count
                          FROM (SELECT get_dest_pop_id(i_lang, ad_pps.id_po_param) id_po_param,
                                       ad_pps.id_task_type,
                                       decode(ad_pps.id_task_type,
                                              101, --Health Program (H)
                                              nvl((SELECT a_hp.id_content
                                                    FROM health_program a_hp
                                                   WHERE a_hp.id_content = ad_pps.task_type_content),
                                                  NULL),
                                              10, --Procedures (I)
                                              nvl((SELECT id_content
                                                    FROM intervention a_i
                                                   WHERE a_i.id_content = ad_pps.task_type_content
                                                     AND a_i.flg_status = g_active),
                                                  NULL),
                                              7, --Exams (E)
                                              nvl((SELECT id_content
                                                    FROM exam a_e
                                                   WHERE a_e.id_content = ad_pps.task_type_content
                                                     AND a_e.flg_available = g_flg_available),
                                                  NULL),
                                              147, --Medical Orders (MO)
                                              ad_pps.task_type_content,
                                              83, --Communication Orders (CO)
                                              ad_pps.task_type_content) task_type_content,
                                       ad_pps.id_software,
                                       ad_pps.rank,
                                       ad_pps.id_market,
                                       ad_pps.version
                                  FROM ad_po_param_sets ad_pps
                                 WHERE ad_pps.flg_available = g_flg_available
                                      --1st: when no task_type is selected; 
                                      --2nd: when task_type is selected but no id_content is used to filter; 
                                      --3rd when both task_type and id_content are filled in.
                                   AND ((l_task_type IS NULL) OR (l_cnt_count = 0 AND ad_pps.id_task_type = l_task_type) OR
                                       (l_cnt_count > 0 AND ad_pps.id_task_type = l_task_type AND
                                       ad_pps.task_type_content IN
                                       (SELECT /*+ opt_estimate(p rows = 10)*/
                                           column_value
                                            FROM TABLE(CAST(l_cnt AS table_varchar)) p)))
                                   AND ad_pps.id_software IN
                                       (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p)
                                   AND ad_pps.id_market IN
                                       (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ad_pps.version IN
                                       (SELECT /*+ dynamic_sampling(p 2) */
                                         column_value
                                          FROM TABLE(CAST(i_vers AS table_varchar)) p)) def_data
                         WHERE def_data.id_po_param > 0
                           AND def_data.task_type_content IS NOT NULL) dest_data
                 WHERE dest_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                          FROM po_param_sets a_pps
                         WHERE a_pps.id_po_param = dest_data.id_po_param
                           AND a_pps.id_inst_owner = 0
                           AND a_pps.id_task_type = dest_data.id_task_type
                           AND a_pps.task_type_content = dest_data.task_type_content
                           AND a_pps.id_software = i_software(pos_soft)
                           AND a_pps.id_institution = i_institution);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            o_result_tbl := 0;
        
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
    END set_pop_sets_search;

    -- frequent loader method

    FUNCTION del_pop_sets_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete po_param_sets';
        g_func_name := upper('del_pop_sets_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_sets pps
             WHERE pps.id_institution = i_institution
               AND pps.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                        column_value
                                         FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM po_param_sets pps
             WHERE pps.id_institution = i_institution;
        
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
    END del_pop_sets_search;

    /********************************************************************************************
    * Set Default Periodic observation parameters By clinical Service
    *
    * @param i_lang                Prefered language ID
    * @param i_id_market           Market ID
    * @param i_vers             Content Version
    * @param i_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_clinical_service Destination Clinical service ID
    * @param i_id_dep_clin_serv    Dep_clin_serv ID
    * @param i_base_cs_list        List of base search clinical_service ids
    * @param o_result_tbl              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.5.2
    * @since                       2012/12/27
    ********************************************************************************************/
    FUNCTION set_po_param_cs_freq
    (
        i_lang              IN language.id_language%TYPE,
        i_institution       IN institution.id_institution%TYPE,
        i_mkt               IN table_number,
        i_vers              IN table_varchar,
        i_id_software       IN table_number,
        i_id_content        IN table_varchar,
        i_clin_serv_in      IN table_number,
        i_clin_serv_out     IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl        OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF (i_id_content = table_varchar('CS') OR i_id_content.count = 0)
        THEN
        
            INSERT INTO po_param_cs
                (id_po_param_cs,
                 id_po_param,
                 id_inst_owner,
                 id_clinical_service,
                 id_institution,
                 id_software,
                 flg_available)
                SELECT seq_po_param_cs.nextval,
                       def_data.id_po_param,
                       0,
                       def_data.id_clinical_service,
                       i_institution,
                       i_id_software(pos_soft),
                       g_flg_available
                  FROM (SELECT temp_data.id_clinical_service,
                               temp_data.id_po_param,
                               row_number() over(PARTITION BY temp_data.id_clinical_service, temp_data.id_po_param ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                          FROM (SELECT nvl((SELECT a_pop.id_po_param
                                             FROM po_param a_pop
                                             JOIN ad_po_param ad_pop
                                               ON ad_pop.id_content = a_pop.id_content
                                              AND ad_pop.flg_available = a_pop.flg_available
                                            WHERE ad_pop.id_po_param = ad_popcs.id_po_param
                                                 -- for flg_type A id_analysis (id_parameter) and id_sample_type must be in the join
                                              AND ((ad_pop.flg_type = 'A' AND
                                                  ((a_pop.id_parameter || ',' || a_pop.id_sample_type) IN
                                                  (nvl((SELECT a.id_analysis || ',' || a.id_sample_type
                                                            FROM analysis_sample_type a
                                                            JOIN alert_default.analysis_sample_type def_a
                                                              ON def_a.id_content = a.id_content
                                                             AND def_a.flg_available = g_flg_available
                                                           WHERE a.flg_available = g_flg_available
                                                             AND def_a.id_analysis = ad_pop.id_parameter
                                                             AND def_a.id_sample_type = ad_pop.id_sample_type),
                                                          0)))) OR
                                                  -- all the other parameters only have to have id_parameter in the join
                                                  (ad_pop.flg_type != 'A' AND
                                                  a_pop.id_parameter =
                                                  decode(ad_pop.flg_type,
                                                           'E',
                                                           nvl((SELECT a_e.id_exam
                                                                 FROM exam a_e
                                                                 JOIN ad_exam ad_e
                                                                   ON ad_e.id_content = a_e.id_content
                                                                  AND ad_e.flg_available = g_flg_available
                                                                WHERE a_e.flg_available = g_flg_available
                                                                  AND ad_e.id_exam = ad_pop.id_parameter),
                                                               0),
                                                           'H',
                                                           nvl((SELECT a_h.id_habit
                                                                 FROM habit a_h
                                                                 JOIN ad_habit ad_h
                                                                   ON ad_h.id_content = a_h.id_content
                                                                  AND ad_h.flg_available = g_flg_available
                                                                WHERE a_h.flg_available = g_flg_available
                                                                  AND ad_h.id_habit = ad_pop.id_parameter),
                                                               0),
                                                           'VS',
                                                           nvl((SELECT vs.id_vital_sign
                                                                 FROM vital_sign vs
                                                                WHERE vs.flg_available = g_flg_available
                                                                  AND vs.id_vital_sign = ad_pop.id_parameter),
                                                               0),
                                                           'O',
                                                           nvl(ad_pop.id_parameter, 0))))
                                              AND a_pop.id_inst_owner = 0
                                              AND a_pop.flg_available = g_flg_available),
                                           0) id_po_param,
                                       i_clin_serv_out id_clinical_service,
                                       ad_popcs.id_software,
                                       ad_ppcmv.id_market,
                                       ad_ppcmv.version
                                  FROM alert_default.po_param_cs ad_popcs
                                  JOIN alert_default.po_param_cs_mkt_vrs ad_ppcmv
                                    ON ad_ppcmv.id_po_param_cs = ad_popcs.id_po_param_cs
                                 WHERE ad_popcs.flg_available = g_flg_available
                                   AND ad_popcs.id_software IN
                                       (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                          FROM TABLE(CAST(i_id_software AS table_number)) p)
                                   AND ad_ppcmv.id_market IN
                                       (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                          FROM TABLE(CAST(i_mkt AS table_number)) p)
                                   AND ad_ppcmv.version IN
                                       (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                          FROM TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND ad_popcs.id_clinical_service IN
                                       (SELECT /*+ dynamic_sampling(2) */
                                         column_value
                                          FROM TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data) def_data
                 WHERE def_data.records_count = 1
                   AND def_data.id_po_param > 0
                   AND NOT EXISTS (SELECT 0
                          FROM po_param_cs popcs
                         WHERE popcs.id_po_param = def_data.id_po_param
                           AND popcs.id_inst_owner = 0
                           AND popcs.id_clinical_service = def_data.id_clinical_service
                           AND popcs.id_institution = i_institution
                           AND popcs.id_software = i_id_software(pos_soft)
                           AND popcs.flg_available = g_flg_available);
        
            o_result_tbl := SQL%ROWCOUNT;
        
        ELSE
        
            o_result_tbl := 0;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_PO_PARAM_CS_FREQ',
                                              o_error);
            RETURN FALSE;
        
    END set_po_param_cs_freq;

    FUNCTION del_po_param_cs_freq
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete po_param_cs';
        g_func_name := upper('del_po_param_cs_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM po_param_cs ppcs
             WHERE ppcs.id_institution = i_institution
               AND ppcs.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                         column_value
                                          FROM TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM po_param_cs ppcs
             WHERE ppcs.id_institution = i_institution;
        
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
    END del_po_param_cs_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_periodicobservation_prm;
/
