/*-- Last Change Revision: $Rev: 1926389 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2019-12-03 14:28:34 +0000 (ter, 03 dez 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_icnp_prm IS
    -- Package info
    g_package_owner t_low_char := 'alert';
    g_package_name  t_low_char := 'PK_ICNP_prm';
    pos_soft        NUMBER := 1;
    g_table_name    t_med_char;
    -- Private Methods

    -- content loader method

    -- searcheable loader method
    /********************************************************************************************
    * Set Default ICNP TASK COMPOSITION
    *
    * @param i_lang                Prefered language ID
    * @param o_result              Number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/16
    ********************************************************************************************/
    FUNCTION load_icnp_task_comp_def
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_id_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'LOADING ICNP TASK COMPOSITION';
        INSERT INTO icnp_task_composition
            (id_task,
             id_task_type,
             id_composition,
             flg_available,
             id_content)
            SELECT def_data.id_task,
                   def_data.id_task_type,
                   def_data.id_composition,
                   g_flg_available,
                   NULL
            FROM   (SELECT temp_data.id_task,
                           temp_data.id_task_type,
                           temp_data.id_composition,
                           row_number() over(PARTITION BY temp_data.id_task, temp_data.id_task_type, temp_data.id_composition ORDER BY temp_data.l_row) records_count
                    FROM   (SELECT def_tbl.rowid l_row,
                                   pk_default_content.get_dest_task_by_type(i_lang,
                                                                            def_tbl.id_task,
                                                                            def_tbl.id_task_type) id_task,
                                   def_tbl.id_task_type,
                                   nvl((SELECT ic.id_composition
                                       FROM   icnp_composition ic
                                       INNER  JOIN alert_default.icnp_composition def_ic
                                       ON     (def_ic.id_content = ic.id_content AND def_ic.id_software = ic.id_software AND
                                              def_ic.flg_available = g_flg_available AND
                                              ic.id_institution = i_id_institution)
                                       WHERE  ic.flg_available = g_flg_available
                                              AND def_ic.id_composition = def_tbl.id_composition),
                                       0) id_composition
                            FROM   alert_default.icnp_task_composition def_tbl
                            WHERE  def_tbl.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_task > 0
                           AND temp_data.id_composition > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_task_composition dest_tbl
                    WHERE  dest_tbl.id_task = def_data.id_task
                           AND dest_tbl.id_task_type = def_data.id_task_type
                           AND dest_tbl.id_composition = def_data.id_composition);
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_ICNP_TASK_COMPOSITIOM',
                                              o_error);
            RETURN FALSE;
    END load_icnp_task_comp_def;
    /********************************************************************************************
    * Set ICNP_COMPOSITION for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_id_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_icnp_comp_code VARCHAR2(200) := 'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.';
    
    BEGIN
        g_error := 'LOADING ICNP_COMPOSITION ';
        INSERT INTO icnp_composition
            (id_composition,
             flg_type,
             flg_nurse_tea,
             flg_repeat,
             flg_gender,
             flg_available,
             adw_last_update,
             code_icnp_composition,
             id_vs,
             id_doc_template,
             flg_task,
             flg_solved,
             id_content,
             id_institution,
             id_software)
            SELECT seq_icnp_composition.nextval,
                   def_data.flg_type,
                   def_data.flg_nurse_tea,
                   def_data.flg_repeat,
                   def_data.flg_gender,
                   g_flg_available,
                   SYSDATE,
                   l_icnp_comp_code || seq_icnp_composition.currval,
                   def_data.id_vs,
                   def_data.id_doc_template,
                   def_data.flg_task,
                   def_data.flg_solved,
                   def_data.id_content,
                   i_id_institution,
                   def_data.id_software
            FROM   (SELECT temp_data.id_content,
                           temp_data.flg_type,
                           temp_data.flg_nurse_tea,
                           temp_data.flg_repeat,
                           temp_data.flg_gender,
                           temp_data.id_vs,
                           temp_data.id_doc_template,
                           temp_data.flg_task,
                           temp_data.flg_solved,
                           i_id_software(pos_soft) id_software,
                           row_number() over(PARTITION BY temp_data.id_content ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT ic.id_content,
                                   ic.flg_type,
                                   ic.flg_nurse_tea,
                                   ic.flg_repeat,
                                   ic.flg_gender,
                                   ic.id_vs,
                                   ic.id_doc_template,
                                   ic.flg_task,
                                   ic.flg_solved,
                                   ic.id_software,
                                   icmv.id_market,
                                   icmv.version
                            FROM   alert_default.icnp_composition ic
                            INNER  JOIN alert_default.icnp_comp_mkt_vrs icmv
                            ON     (icmv.id_composition = ic.id_composition)
                            WHERE  ic.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                    FROM   TABLE(CAST(i_id_software AS table_number)) p)
                                   AND
                                   icmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_market AS table_number)) p)
                                   AND
                                   icmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                    FROM   TABLE(CAST(i_version AS table_varchar)) p)
                                   AND ic.flg_available = g_flg_available) temp_data) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_composition ext_ic
                    WHERE  ext_ic.id_content = def_data.id_content
                           AND ext_ic.id_institution = i_id_institution
                           AND ext_ic.id_software = i_id_software(pos_soft)
                           AND ext_ic.flg_available = g_flg_available);
    
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_ICNP_COMPOSITION',
                                              o_error);
            RETURN FALSE;
    END set_inst_icnp_composition;

    FUNCTION del_inst_icnp_composition
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_composition';
        g_func_name := upper('del_inst_icnp_composition');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            UPDATE icnp_composition ic
            SET    ic.flg_available = 'N'
            WHERE  ic.id_institution = i_institution
                   AND ic.flg_available = 'Y'
                   AND ic.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                           column_value
                                          FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            UPDATE icnp_composition ic
            SET    ic.flg_available = 'N'
            WHERE  ic.id_institution = i_institution
                   AND ic.flg_available = 'Y';
        
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
    END del_inst_icnp_composition;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_HIST for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_hist
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_id_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'LOADING ICNP_COMPOSITION_HIST ';
    
        INSERT INTO icnp_composition_hist
            (id_composition_hist,
             id_composition,
             flg_most_recent,
             dt_composition_hist,
             flg_cancel)
            SELECT seq_icnp_composition_hist.nextval,
                   def_data.id_composition,
                   g_flg_available,
                   current_timestamp,
                   'N'
            FROM   (SELECT temp_data.id_composition,
                           row_number() over(PARTITION BY temp_data.id_composition
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT nvl((SELECT ext_ic.id_composition
                                       FROM   icnp_composition ext_ic
                                       WHERE  ext_ic.id_content = ic.id_content
                                              AND ext_ic.flg_available = g_flg_available
                                              AND ext_ic.id_institution = i_id_institution
                                              AND ext_ic.id_software = i_id_software(pos_soft)),
                                       0) id_composition,
                                   ic.id_software,
                                   icmv.id_market,
                                   icmv.version
                            FROM   alert_default.icnp_composition ic
                            INNER  JOIN alert_default.icnp_comp_mkt_vrs icmv
                            ON     (icmv.id_composition = ic.id_composition)
                            WHERE  ic.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                    FROM   TABLE(CAST(i_id_software AS table_number)) p)
                                   AND
                                   icmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_market AS table_number)) p)
                                   AND
                                   icmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                    FROM   TABLE(CAST(i_version AS table_varchar)) p)
                                   AND ic.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_composition > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_composition_hist ich
                    WHERE  ich.id_composition = def_data.id_composition);
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_ICNP_COMPOSITION_HIST',
                                              o_error);
            RETURN FALSE;
    END set_inst_icnp_composition_hist;
    /********************************************************************************************
    * Set ICNP_COMPOSITION_TERM for a set of markets, versions and sotwares
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param o_result              Number of records loaded
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2013/01/11
    ********************************************************************************************/
    FUNCTION set_inst_icnp_composition_term
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_id_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'LOADING ICNP_COMPOSITION_TERM ';
        INSERT INTO icnp_composition_term
            (id_composition_term,
             id_term,
             id_composition,
             desc_term,
             rank,
             id_language,
             flg_main_focus)
            SELECT seq_icnp_composition_term.nextval,
                   def_data.id_term,
                   def_data.id_composition,
                   def_data.desc_term,
                   def_data.rank,
                   def_data.id_language,
                   def_data.flg_main_focus
            FROM   (SELECT temp_data.id_term,
                           temp_data.id_composition,
                           temp_data.desc_term,
                           temp_data.rank,
                           temp_data.id_language,
                           temp_data.flg_main_focus,
                           row_number() over(PARTITION BY temp_data.id_composition, temp_data.id_term, temp_data.id_language
                           
                           ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT ict.id_term,
                                   nvl((SELECT ext_ic.id_composition
                                       FROM   icnp_composition ext_ic
                                       WHERE  ext_ic.id_content = ic.id_content
                                              AND ext_ic.flg_available = g_flg_available
                                              AND ext_ic.id_institution = i_id_institution
                                              AND ext_ic.id_software = i_id_software(pos_soft)),
                                       0) id_composition,
                                   ict.desc_term,
                                   ict.rank,
                                   ict.id_language,
                                   ict.flg_main_focus,
                                   icmv.id_market,
                                   icmv.version
                            FROM   alert_default.icnp_composition_term ict
                            INNER  JOIN alert_default.icnp_composition ic
                            ON     (ic.id_composition = ict.id_composition AND ic.flg_available = g_flg_available)
                            INNER  JOIN alert_default.icnp_comp_mkt_vrs icmv
                            ON     (icmv.id_composition = ict.id_composition)
                            WHERE  icmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                       column_value
                                                      FROM   TABLE(CAST(i_market AS table_number)) p)
                                   AND
                                   icmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                     column_value
                                                    FROM   TABLE(CAST(i_version AS table_varchar)) p)) temp_data
                    WHERE  temp_data.id_composition > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_composition_term ext_ict
                    WHERE  ext_ict.id_term = def_data.id_term
                           AND ext_ict.id_composition = def_data.id_composition
                           AND ext_ict.id_language = def_data.id_language);
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_ICNP_COMPOSITION_TERM',
                                              o_error);
            RETURN FALSE;
    END set_inst_icnp_composition_term;
    /********************************************************************************************
    * Set ICNP TASK COMPOSITION BY SOFTWARE AND specified institution.
    *
    * @param i_lang                Prefered language ID
    * @param i_market              Market ID's
    * @param i_version             ALERT version's
    * @param i_id_institution      Institution ID
    * @param o_inst_interv_drug    Cursor of default data
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/17
    ********************************************************************************************/
    FUNCTION set_inst_task_comp_search
    (
        i_lang IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_market IN table_number,
        i_version IN table_varchar,
        i_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'LOADING ICNP_TASK_COMP_SOFT_INST';
        INSERT INTO icnp_task_comp_soft_inst
            (id_task,
             id_task_type,
             id_composition,
             id_software,
             id_institution,
             flg_available)
            SELECT def_data.id_task,
                   def_data.id_task_type,
                   def_data.id_composition,
                   def_data.id_software,
                   i_id_institution,
                   g_flg_available
            FROM   (SELECT temp_data.id_task,
                           temp_data.id_task_type,
                           temp_data.id_composition,
                           i_software(pos_soft) id_software,
                           row_number() over(PARTITION BY temp_data.id_task, temp_data.id_task_type, temp_data.id_composition ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT pk_default_content.get_dest_task_by_type(i_lang,
                                                                            def_tbl.id_task,
                                                                            def_tbl.id_task_type) id_task,
                                   def_tbl.id_task_type,
                                   nvl((SELECT ic.id_composition
                                       FROM   icnp_composition ic
                                       INNER  JOIN alert_default.icnp_composition def_ic
                                       ON     (def_ic.id_content = ic.id_content AND def_ic.id_software = ic.id_software AND
                                              def_ic.flg_available = g_flg_available)
                                       WHERE  ic.flg_available = g_flg_available
                                              AND ic.id_software = i_software(pos_soft)
                                              AND ic.id_institution = i_id_institution
                                              AND def_ic.id_composition = def_tbl.id_composition),
                                       0) id_composition,
                                   def_tbl.id_software,
                                   itcmv.id_market,
                                   itcmv.version
                            FROM   alert_default.icnp_task_composition def_tbl
                            INNER  JOIN alert_default.icnp_task_comp_mkt_vrs itcmv
                            ON     (itcmv.id_icnp_task_composition = def_tbl.id_icnp_task_composition)
                            WHERE  def_tbl.flg_available = g_flg_available
                                   AND def_tbl.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                         column_value
                                        FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND
                                   itcmv.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_market AS table_number)) p)
                                   AND
                                   itcmv.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                     FROM   TABLE(CAST(i_version AS table_varchar)) p)) temp_data
                    WHERE  temp_data.id_task > 0
                           AND temp_data.id_composition > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_task_comp_soft_inst dest_tbl
                    WHERE  dest_tbl.id_task = def_data.id_task
                           AND dest_tbl.id_task_type = def_data.id_task_type
                           AND dest_tbl.id_composition = def_data.id_composition
                           AND dest_tbl.id_software = i_software(pos_soft)
                           AND dest_tbl.id_institution = i_id_institution);
    
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'SET_ICNP_TASK_COMP_SEARCH',
                                              o_error);
            RETURN FALSE;
    END set_inst_task_comp_search;

    FUNCTION del_inst_task_comp_search
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_task_comp_soft_inst';
        g_func_name := upper('del_inst_task_comp_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM icnp_task_comp_soft_inst itcsi
            WHERE  itcsi.id_institution = i_institution
                   AND itcsi.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                              column_value
                                             FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM icnp_task_comp_soft_inst itcsi
            WHERE  itcsi.id_institution = i_institution;
        
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
    END del_inst_task_comp_search;


    FUNCTION set_icnp_predefined_act_search
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_icnp_predefined_act_search');
        INSERT INTO icnp_predefined_action
            (id_predefined_action,
             id_composition,
             id_composition_parent,
             flg_available,
             id_institution,
             id_software)
            SELECT seq_icnp_predefined_action.nextval,
                   def_data.i_composition,
                   def_data.i_composition_parent,
                   g_flg_available,
                   i_institution,
                   i_software(pos_soft)
            FROM   (SELECT temp_data.i_composition,
                           temp_data.i_composition_parent,
                           row_number() over(PARTITION BY temp_data.i_composition, temp_data.i_composition_parent ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT -- decode FKS to dest_vals
                             nvl((SELECT ic.id_composition
                                 FROM   icnp_composition ic
                                 JOIN   alert_default.icnp_composition ic2
                                 ON     ic.id_content = ic2.id_content
                                        AND ic2.id_software IN (i_software(pos_soft),
                                                                0)
                                 WHERE  ic2.id_composition = ica.id_composition
                                        AND ic2.flg_available = g_flg_available
                                        AND ic.flg_available = g_flg_available
                                        AND ic.id_software = i_software(pos_soft)
                                        AND ic.id_institution = i_institution),
                                 0) i_composition,
                             nvl((SELECT ic.id_composition
                                 FROM   icnp_composition ic
                                 JOIN   alert_default.icnp_composition ic2
                                 ON     ic.id_content = ic2.id_content
                                        AND ic2.id_software IN (i_software(pos_soft),
                                                                0)
                                 WHERE  ic2.id_composition = ica.id_composition_parent
                                        AND ic2.flg_available = g_flg_available
                                        AND ic.flg_available = g_flg_available
                                        AND ic.id_software = i_software(pos_soft)
                                        AND ic.id_institution = i_institution),
                                 0) i_composition_parent,
                             ica.id_software,
                             ica.id_market,
                             ica.version
                            FROM   alert_default.icnp_predefined_action ica
                            WHERE  ica.flg_available = g_flg_available
                                   AND ica.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                         column_value
                                        FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND
                                   ica.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                     FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                  
                                   AND ica.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
            WHERE  def_data.records_count = 1
                   AND def_data.i_composition_parent > 0
                   AND def_data.i_composition > 0
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_predefined_action ica1
                    WHERE  ica1.id_institution = i_institution
                           AND ica1.flg_available = g_flg_available
                           AND ica1.id_software = i_software(pos_soft)
                           AND ica1.id_composition = def_data.i_composition
                           AND ica1.id_composition_parent = def_data.i_composition_parent);
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
    END set_icnp_predefined_act_search;

    FUNCTION del_icnp_predefined_act_search
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_predefined_action';
        g_func_name := upper('del_icnp_predefined_act_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            UPDATE icnp_predefined_action ipa
            SET    ipa.flg_available = 'N'
            WHERE  ipa.flg_most_freq IS NULL
                   AND ipa.id_institution = i_institution
                   AND ipa.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                            column_value
                                           FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            UPDATE icnp_predefined_action ipa
            SET    ipa.flg_available = 'N'
            WHERE  ipa.flg_most_freq IS NULL
                   AND ipa.id_institution = i_institution;
        
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
    END del_icnp_predefined_act_search;

    FUNCTION set_icnp_pa_hist_search
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_icnp_predef_action_hist_search');
        INSERT INTO icnp_predefined_action_hist
            (id_predefined_action_hist,
             id_predefined_action,
             flg_most_recent,
             dt_predefined_action_hist,
             flg_cancel)
            SELECT seq_icnp_predef_action_hist.nextval,
                   def_data.id_predefined_action,
                   g_flg_available,
                   current_timestamp,
                   'N'
            FROM   (SELECT id_predefined_action
                    FROM   icnp_predefined_action ipa
                    WHERE  ipa.flg_available = g_flg_available
                           AND NOT EXISTS (SELECT 0
                            FROM   icnp_predefined_action_hist ipah
                            WHERE  ipah.id_predefined_action = ipa.id_predefined_action
                                   AND ipah.flg_most_recent = g_flg_available)) def_data;
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
    END set_icnp_pa_hist_search;

    /********************************************************************************************
    * Set ICNP DEFAULT INSTRUCTIONS BY SOFTWARE, MARKET AND specified institution.
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_market              Market ID's
    * @param i_version             CONTENT version's
    * @param i_software            ALERT software modules
    * @param o_result_tbl          Number of records inserted
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.4.1
    * @since                       2014/07/02
    ********************************************************************************************/
    FUNCTION set_icnp_def_instructions_msi
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        o_result OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_inst_market market.id_market%TYPE;
        pos_soft      NUMBER := 1;
    BEGIN
        g_error       := 'GEt institution market';
        l_inst_market := pk_utils.get_institution_market(i_lang,
                                                         i_institution);
        g_error       := 'Load icnp_default_instructions_msi';
        INSERT INTO icnp_default_instructions_msi
            (id_composition,
             id_order_recurr_option,
             flg_prn,
             prn_notes,
             flg_time,
             id_institution,
             id_software,
             id_market,
             flg_available)
            SELECT def_data.id_composition,
                   def_data.id_order_recurr_option,
                   def_data.flg_prn,
                   def_data.prn_notes,
                   def_data.flg_time,
                   i_institution,
                   def_data.id_software,
                   l_inst_market,
                   g_flg_available
            FROM   (SELECT temp_data.id_composition,
                           temp_data.id_order_recurr_option,
                           temp_data.flg_prn,
                           temp_data.prn_notes,
                           temp_data.flg_time,
                           i_software(pos_soft) id_software,
                           row_number() over(PARTITION BY temp_data.id_composition
                           
                           ORDER BY temp_data.id_software DESC, temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                    FROM   (SELECT nvl((SELECT ic.id_composition
                                       FROM   icnp_composition ic
                                       INNER  JOIN alert_default.icnp_composition def_ic
                                       ON     (def_ic.id_content = ic.id_content AND def_ic.id_software = ic.id_software AND
                                              def_ic.flg_available = g_flg_available)
                                       WHERE  ic.flg_available = g_flg_available
                                              AND ic.id_software = i_software(pos_soft)
                                              AND ic.id_institution = i_institution
                                              AND def_ic.id_composition = src_tbl.id_composition),
                                       0) id_composition,
                                   nvl((SELECT oro.id_order_recurr_option
                                       FROM   order_recurr_option oro
                                       WHERE  oro.id_order_recurr_option = src_tbl.id_order_recurr_option),
                                       0) id_order_recurr_option,
                                   src_tbl.flg_prn,
                                   src_tbl.prn_notes,
                                   src_tbl.flg_time,
                                   src_tbl.id_software,
                                   src_tbl.id_market,
                                   src_tbl.version
                            
                            FROM   alert_default.icnp_default_instructions_msi src_tbl
                            WHERE  src_tbl.id_market IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                     column_value
                                    FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND
                                   src_tbl.version IN (SELECT /*+ opt_estimate(p rows = 10)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                  
                                   AND src_tbl.id_software IN
                                   (SELECT /*+ opt_estimate(p rows = 10)*/
                                         column_value
                                        FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND src_tbl.flg_available = g_flg_available) temp_data
                    WHERE  temp_data.id_composition > 0
                           AND temp_data.id_order_recurr_option > 0) def_data
            WHERE  def_data.records_count = 1
                   AND NOT EXISTS (SELECT 0
                    FROM   icnp_default_instructions_msi idim
                    WHERE  idim.id_composition = def_data.id_composition
                           AND idim.id_institution = i_institution
                           AND idim.id_software = def_data.id_software
                           AND idim.id_market = l_inst_market);
    
        o_result := SQL%ROWCOUNT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_ICNP_PRM',
                                              'SET_ICNP_DEF_INSTRUCTIONS_MSI',
                                              o_error);
            RETURN FALSE;
    END set_icnp_def_instructions_msi;

    FUNCTION del_icnp_def_instructions_msi
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_default_instructions_msi';
        g_func_name := upper('del_icnp_def_instructions_msi');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM icnp_default_instructions_msi idim
            WHERE  idim.id_institution = i_institution
                   AND idim.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                             column_value
                                            FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM icnp_default_instructions_msi idim
            WHERE  idim.id_institution = i_institution;
        
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
    END del_icnp_def_instructions_msi;

    -- frequent loader method
    FUNCTION set_icnp_axis_freq
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        i_clin_serv_in IN table_number,
        i_clin_serv_out IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_icnp_version  sys_config.id_sys_config%TYPE := 'ICNP_VERSION';
        l_icnp_vers_val sys_config.value%TYPE := NULL;
    
    BEGIN
        g_func_name := upper('set_icnp_axis_freq');
    
        l_icnp_vers_val := pk_sysconfig.get_config(l_icnp_version,
                                                   i_institution,
                                                   i_software(pos_soft));
        INSERT INTO icnp_axis_dcs
            (id_icnp_axis_dcs,
             id_axis,
             id_term,
             id_composition,
             id_dep_clin_serv,
             id_software,
             id_institution)
            SELECT seq_icnp_axis_dcs.nextval,
                   def_data.id_axis,
                   def_data.id_term,
                   NULL,
                   i_dep_clin_serv_out,
                   id_software,
                   i_institution
            FROM   (SELECT it.id_axis,
                           it.id_term,
                           i_software(pos_soft) id_software,
                           row_number() over(PARTITION BY it.id_axis, it.id_term ORDER BY it.rowid) records_count
                    FROM   icnp_axis ia
                    INNER  JOIN icnp_term it
                    ON     (it.id_axis = ia.id_axis AND it.flg_available = g_flg_available)
                    WHERE  ia.id_icnp_version = l_icnp_vers_val
                           AND NOT EXISTS (SELECT 0
                            FROM   icnp_axis_dcs iad
                            WHERE  iad.id_term = it.id_term
                                   AND iad.id_dep_clin_serv = i_dep_clin_serv_out
                                   AND iad.id_software = i_software(pos_soft)
                                   AND iad.id_institution = i_institution
                                   AND iad.id_axis = it.id_axis)) def_data
            WHERE  def_data.records_count = 1;
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
    END set_icnp_axis_freq;

    FUNCTION del_icnp_axis_freq
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
        o_dcs_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_axis_dcs';
        g_func_name := upper('del_icnp_axis_freq');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
        BULK   COLLECT
        INTO   o_soft_all
        FROM   TABLE(CAST(i_software AS table_number)) sw_list
        WHERE  column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            DELETE FROM icnp_axis_dcs iad
            WHERE  iad.id_institution = i_institution
                   AND iad.id_software IN (SELECT /*+ dynamic_sampling(2)*/
                                            column_value
                                           FROM   TABLE(CAST(i_software AS table_number)) p);
        
            o_result_tbl := SQL%ROWCOUNT;
        ELSE
            DELETE FROM icnp_axis_dcs iad
            WHERE  iad.id_institution = i_institution;
        
            o_result_tbl := SQL%ROWCOUNT;
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
    END del_icnp_axis_freq;

    FUNCTION set_icnp_composition_freq
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt IN table_number,
        i_vers IN table_varchar,
        i_software IN table_number,
        i_clin_serv_in IN table_number,
        i_clin_serv_out IN clinical_service.id_clinical_service%TYPE,
        i_dep_clin_serv_out IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('set_icnp_composition_freq');
        INSERT INTO icnp_compo_dcs
            (id_icnp_compo_dcs,
             id_composition,
             id_dep_clin_serv)
            SELECT seq_icnp_comp_dcs.nextval,
                   def_data.id_composition,
                   i_dep_clin_serv_out
            FROM   (SELECT temp_data.my_rowid,
                           temp_data.id_composition,
                           row_number() over(PARTITION BY temp_data.id_composition ORDER BY temp_data.my_rowid) frecords_count
                    FROM   (SELECT icc.rowid my_rowid,
                                   nvl((SELECT ic1.id_composition
                                       FROM   icnp_composition ic1
                                       WHERE  ic1.id_content = ic.id_content
                                              AND ic1.flg_available = g_flg_available
                                              AND ic1.id_software = i_software(pos_soft)
                                              AND ic1.id_institution = i_institution),
                                       0) id_composition
                            FROM   alert_default.icnp_compo_cs icc
                            INNER  JOIN alert_default.icnp_composition ic
                            ON     ic.id_composition = icc.id_composition
                                   AND ic.flg_available = g_flg_available
                            WHERE  icc.id_software IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                     column_value
                                    FROM   TABLE(CAST(i_software AS table_number)) p)
                                   AND
                                   icc.id_market IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                      column_value
                                                     FROM   TABLE(CAST(i_mkt AS table_number)) p)
                                   AND icc.version IN (SELECT /*+ dynamic_sampling(p 2)*/
                                                        column_value
                                                       FROM   TABLE(CAST(i_vers AS table_varchar)) p)
                                   AND icc.id_clinical_service IN
                                   (SELECT /*+ dynamic_sampling(p 2)*/
                                         column_value
                                        FROM   TABLE(CAST(i_clin_serv_in AS table_number)) p)) temp_data
                    WHERE  temp_data.id_composition > 0
                           AND NOT EXISTS (SELECT 0
                            FROM   icnp_compo_dcs icdcs
                            WHERE  icdcs.id_composition = temp_data.id_composition
                                   AND icdcs.id_dep_clin_serv = i_dep_clin_serv_out)) def_data
            WHERE  def_data.frecords_count = 1;
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
    END set_icnp_composition_freq;

    FUNCTION del_icnp_composition_freq
    (
        i_lang IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software IN table_number,
        o_result_tbl OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
        o_dcs_list table_number := table_number();
    
    BEGIN
        g_error     := 'delete icnp_compo_dcs';
        g_func_name := upper('del_icnp_composition_freq');
    
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
    
        DELETE FROM icnp_compo_dcs icd
        WHERE  icd.id_dep_clin_serv IN (SELECT /*+ dynamic_sampling(2)*/
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
    END del_icnp_composition_freq;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner,
                         NAME  => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;
    g_no            := pk_alert_constant.g_no;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_icnp_prm;
/
