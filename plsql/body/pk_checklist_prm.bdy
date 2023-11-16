/*-- Last Change Revision: $Rev: 2026867 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_checklist_prm IS
    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_CHECKLIST_prm';

    --g_table_name t_med_char;
    -- Private Methods

    -- content loader method
    FUNCTION load_checklist_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_func_name := upper('load_checklist_def');
    
        INSERT INTO checklist
            (flg_content_creator, internal_name, id_checklist, flg_available, flg_status, id_content)
            SELECT flg_content_creator, internal_name, seq_checklist.nextval, g_flg_available, flg_status, id_content
              FROM (SELECT flg_content_creator, internal_name, id_content, flg_status
                      FROM alert_default.checklist source_tbl
                     WHERE flg_available = g_flg_available
                       AND NOT EXISTS (SELECT 0
                              FROM checklist dest_tbl
                             WHERE dest_tbl.id_content = source_tbl.id_content
                               AND dest_tbl.flg_content_creator = source_tbl.flg_content_creator)) def_data;
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
    END load_checklist_def;

    FUNCTION load_checklist_version_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('CHECKLIST_VERSION.CODE_NAME.');
    BEGIN
        g_func_name := upper('load_checklist_version_def');
    
        INSERT INTO checklist_version
            (flg_content_creator,
             internal_name,
             version,
             id_checklist_version,
             id_checklist,
             dt_checklist_version,
             flg_type,
             name,
             code_name,
             flg_use_translation,
             dt_create_time,
             dt_retire_time,
             id_professional)
            SELECT flg_content_creator,
                   internal_name,
                   version,
                   seq_checklist_version.nextval,
                   id_checklist,
                   dt_checklist_version,
                   flg_type,
                   name,
                   decode(flg_use_translation,
                          g_flg_available,
                          l_code_translation || seq_checklist_version.currval,
                          NULL),
                   flg_use_translation,
                   dt_create_time,
                   dt_retire_time,
                   NULL
              FROM (SELECT adcv.flg_content_creator,
                           adcv.internal_name,
                           adc.id_content,
                           adcv.version,
                           nvl((SELECT id_checklist
                                 FROM checklist c
                                WHERE c.id_content = adc.id_content
                                  AND c.flg_content_creator = adc.flg_content_creator
                                  AND c.flg_available = g_flg_available),
                               0) id_checklist,
                           adcv.dt_checklist_version,
                           adcv.flg_type,
                           adcv.name,
                           adcv.flg_use_translation,
                           adcv.dt_create_time,
                           adcv.dt_retire_time
                      FROM alert_default.checklist_version adcv
                      JOIN alert_default.checklist adc
                        ON adcv.flg_content_creator = adc.flg_content_creator
                       AND adcv.id_checklist = adc.id_checklist
                     WHERE adc.flg_available = g_flg_available) temp_data
             WHERE temp_data.id_checklist != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_version cv
                     WHERE cv.version = temp_data.version
                       AND cv.flg_content_creator = temp_data.flg_content_creator
                       AND cv.internal_name = temp_data.internal_name);
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
    END load_checklist_version_def;

    FUNCTION load_checklist_clin_serv_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_func_name := upper('load_checklist_clin_serv_def');
    
        INSERT INTO checklist_clin_serv
            (flg_content_creator, internal_name, version, id_checklist_version, id_clinical_service)
            SELECT flg_content_creator, internal_name, version, id_checklist_version, id_clinical_service
            
              FROM (SELECT cc.flg_content_creator,
                           cc.internal_name,
                           cc.version,
                           nvl((SELECT cvv.id_checklist_version
                                 FROM checklist_version cvv
                                 JOIN alert_default.checklist_version acv
                                   ON cvv.flg_content_creator = acv.flg_content_creator
                                  AND cvv.internal_name = acv.internal_name
                                  AND cvv.version = acv.version
                                WHERE acv.id_checklist_version = cv.id_checklist_version),
                               0) id_checklist_version,
                           nvl((SELECT cs.id_clinical_service
                                 FROM clinical_service cs
                                WHERE cs.id_content = (SELECT cs1.id_content
                                                         FROM alert_default.clinical_service cs1
                                                        WHERE cs1.id_clinical_service = cc.id_clinical_service
                                                          AND cs1.flg_available = g_flg_available)
                                  AND cs.id_content IS NOT NULL
                                  AND cs.flg_available = g_flg_available
                                  AND rownum = 1),
                               0) id_clinical_service
                      FROM alert_default.checklist_version cv
                      JOIN alert_default.checklist_clin_serv cc
                        ON cc.id_checklist_version = cv.id_checklist_version
                       AND cc.flg_content_creator = cv.flg_content_creator
                       AND cc.version = cv.version) def_data
             WHERE def_data.id_clinical_service != 0
               AND def_data.id_checklist_version != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_clin_serv cc
                     WHERE cc.id_checklist_version = def_data.id_checklist_version
                       AND cc.flg_content_creator = def_data.flg_content_creator
                       AND cc.version = def_data.version
                       AND cc.id_clinical_service = def_data.id_clinical_service);
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
    END load_checklist_clin_serv_def;

    FUNCTION load_checklist_prof_templ_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_checklist_prof_templ_def');
    
        INSERT INTO checklist_prof_templ
            (flg_content_creator,
             internal_name,
             version,
             id_checklist_version,
             id_profile_template,
             flg_write,
             flg_default)
            SELECT flg_content_creator,
                   internal_name,
                   version,
                   id_checklist_version,
                   id_profile_template,
                   flg_write,
                   flg_default
              FROM (SELECT acpt.flg_content_creator,
                           acpt.internal_name,
                           acpt.version,
                           nvl((SELECT cvv.id_checklist_version
                                 FROM checklist_version cvv
                                 JOIN alert_default.checklist_version acv
                                   ON cvv.flg_content_creator = acv.flg_content_creator
                                  AND cvv.internal_name = acv.internal_name
                                  AND cvv.version = acv.version
                                WHERE acv.id_checklist_version = cv.id_checklist_version),
                               0) id_checklist_version,
                           
                           acpt.id_profile_template,
                           acpt.flg_write,
                           acpt.flg_default
                      FROM alert_default.checklist_version cv
                      JOIN alert_default.checklist_prof_templ acpt
                        ON acpt.id_checklist_version = cv.id_checklist_version
                       AND acpt.flg_content_creator = cv.flg_content_creator
                       AND acpt.version = cv.version
                       AND NOT EXISTS (SELECT 0
                              FROM checklist_prof_templ cpt
                             WHERE cpt.internal_name = acpt.internal_name
                               AND cpt.flg_content_creator = acpt.flg_content_creator
                               AND cpt.version = acpt.version
                               AND cpt.id_profile_template = acpt.id_profile_template)) def_data
             WHERE def_data.id_checklist_version != 0;
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
    END load_checklist_prof_templ_def;

    FUNCTION load_checklist_item_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_code_translation translation.code_translation%TYPE := upper('CHECKLIST_ITEM.CODE_ITEM_DESCRIPTION.');
    BEGIN
        g_func_name := upper('load_checklist_item_def');
    
        INSERT INTO checklist_item
            (flg_content_creator,
             internal_name,
             version,
             item,
             id_checklist_item,
             id_checklist_version,
             item_description,
             code_item_description,
             flg_use_translation,
             rank)
            SELECT flg_content_creator,
                   internal_name,
                   version,
                   item,
                   seq_checklist_item.nextval,
                   id_checklist_version,
                   item_description,
                   decode(flg_use_translation, g_flg_available, l_code_translation || seq_checklist_item.currval, NULL),
                   flg_use_translation,
                   rank
              FROM (SELECT ci.flg_content_creator,
                           ci.internal_name,
                           ci.version,
                           ci.item,
                           ci.id_checklist_item,
                           nvl((SELECT cvv.id_checklist_version
                                 FROM checklist_version cvv
                                 JOIN alert_default.checklist_version acv
                                   ON cvv.flg_content_creator = acv.flg_content_creator
                                  AND cvv.internal_name = acv.internal_name
                                  AND cvv.version = acv.version
                                WHERE acv.id_checklist_version = cv.id_checklist_version),
                               0) id_checklist_version,
                           ci.item_description,
                           ci.code_item_description,
                           ci.flg_use_translation,
                           ci.rank
                      FROM alert_default.checklist_version cv
                      JOIN alert_default.checklist_item ci
                        ON ci.id_checklist_version = cv.id_checklist_version
                       AND ci.flg_content_creator = cv.flg_content_creator
                       AND ci.version = cv.version) def_data
             WHERE def_data.id_checklist_version != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_item chi
                     WHERE chi.flg_content_creator = def_data.flg_content_creator
                       AND chi.internal_name = def_data.internal_name
                       AND chi.version = def_data.version
                       AND chi.item = def_data.item);
    
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
    END load_checklist_item_def;

    FUNCTION ld_chklst_item_prof_templ_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('ld_chklst_item_prof_templ_def');
    
        INSERT INTO checklist_item_prof_templ
            (flg_content_creator, internal_name, version, item, id_profile_template, id_checklist_item)
            SELECT flg_content_creator, internal_name, version, item, id_profile_template, id_checklist_item
              FROM (SELECT adcipt.flg_content_creator,
                           adcipt.internal_name,
                           adcipt.version,
                           nvl((SELECT ci.id_checklist_item
                                 FROM checklist_item ci
                                WHERE ci.flg_content_creator = adci.flg_content_creator
                                  AND ci.internal_name = adci.internal_name
                                  AND ci.version = adci.version
                                  AND ci.item = adci.item
                                  AND ci.internal_name = adci.internal_name),
                               0) id_checklist_item,
                           nvl((SELECT id_profile_template
                                 FROM checklist_prof_templ cpt
                                WHERE cpt.id_profile_template = adcipt.id_profile_template
                                  AND cpt.flg_content_creator = adcipt.flg_content_creator
                                  AND cpt.version = adcipt.version
                                  AND cpt.internal_name = adcipt.internal_name),
                               0) id_profile_template,
                           adcipt.item
                      FROM alert_default.checklist_item adci
                      JOIN alert_default.checklist_item_prof_templ adcipt
                        ON adcipt.id_checklist_item = adci.id_checklist_item
                       AND adcipt.flg_content_creator = adci.flg_content_creator
                       AND adcipt.version = adci.version
                       AND adcipt.item = adci.item
                       AND adcipt.internal_name = adci.internal_name) def_data
             WHERE def_data.id_checklist_item != 0
               AND def_data.id_profile_template != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_item_prof_templ cipt
                     WHERE cipt.id_checklist_item = def_data.id_checklist_item
                       AND cipt.flg_content_creator = def_data.flg_content_creator
                       AND cipt.version = def_data.version
                       AND cipt.id_profile_template = def_data.id_profile_template
                       AND cipt.item = def_data.item);
    
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
    END ld_chklst_item_prof_templ_def;

    FUNCTION load_checklist_item_dep_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_func_name := upper('load_checklist_item_dep_def');
    
        INSERT INTO checklist_item_dep
            (flg_content_creator, id_checklist_item_src, id_checklist_item_targ, flg_answer)
            SELECT flg_content_creator, id_checklist_item_src, id_checklist_item_targ, flg_answer
              FROM (SELECT ci.flg_content_creator,
                           nvl((SELECT ci.id_checklist_item item_alert
                                 FROM checklist_item ci
                                 JOIN checklist_version cv
                                   ON cv.id_checklist_version = ci.id_checklist_version
                                  AND cv.flg_content_creator = ci.flg_content_creator
                                 JOIN checklist c
                                   ON c.id_checklist = cv.id_checklist
                                  AND c.flg_content_creator = cv.flg_content_creator
                                  AND c.flg_available = g_flg_available
                                 JOIN alert_default.checklist c1
                                   ON c1.id_content = c.id_content
                                  AND c1.flg_available = g_flg_available
                                 JOIN alert_default.checklist_version cv1
                                   ON cv1.id_checklist = c1.id_checklist
                                  AND cv1.flg_content_creator = c1.flg_content_creator
                                 JOIN alert_default.checklist_item ci1
                                   ON ci1.id_checklist_version = cv1.id_checklist_version
                                  AND ci1.flg_content_creator = cv1.flg_content_creator
                                  AND ci1.version = cv1.version
                                  AND ci1.item = ci.item
                                WHERE ci1.id_checklist_item = cid.id_checklist_item_src
                                  AND rownum = 1),
                               0) id_checklist_item_src,
                           nvl((SELECT ci.id_checklist_item item_alert
                                 FROM checklist_item ci
                                 JOIN checklist_version cv
                                   ON cv.id_checklist_version = ci.id_checklist_version
                                  AND cv.flg_content_creator = ci.flg_content_creator
                                 JOIN checklist c
                                   ON c.id_checklist = cv.id_checklist
                                  AND c.flg_content_creator = cv.flg_content_creator
                                  AND c.flg_available = g_flg_available
                                 JOIN alert_default.checklist c1
                                   ON c1.id_content = c.id_content
                                  AND c1.flg_available = g_flg_available
                                 JOIN alert_default.checklist_version cv1
                                   ON cv1.id_checklist = c1.id_checklist
                                  AND cv1.flg_content_creator = c1.flg_content_creator
                                 JOIN alert_default.checklist_item ci1
                                   ON ci1.id_checklist_version = cv1.id_checklist_version
                                  AND ci1.flg_content_creator = cv1.flg_content_creator
                                  AND ci1.version = cv1.version
                                  AND ci1.item = ci.item
                                WHERE ci1.id_checklist_item = cid.id_checklist_item_targ
                                  AND rownum = 1),
                               0) id_checklist_item_targ,
                           cid.flg_answer
                      FROM alert_default.checklist_item ci
                      JOIN alert_default.checklist_item_dep cid
                        ON cid.id_checklist_item_src = ci.id_checklist_item
                       AND (cid.flg_content_creator = ci.flg_content_creator OR
                           cid.id_checklist_item_targ = ci.id_checklist_item)) def_data
             WHERE def_data.id_checklist_item_src != 0
               AND def_data.id_checklist_item_targ != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_item_dep dest_tbl
                     WHERE dest_tbl.id_checklist_item_src = def_data.id_checklist_item_src
                       AND dest_tbl.id_checklist_item_targ = def_data.id_checklist_item_targ
                       AND dest_tbl.flg_content_creator = def_data.flg_content_creator
                       AND dest_tbl.flg_answer = def_data.flg_answer);
    
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
    END load_checklist_item_dep_def;
    -- searcheable loader method
    FUNCTION set_checklist_inst_search
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
        g_func_name := upper('set_checklist_inst_search');
    
        g_func_name := upper('set_checklist_inst_search');
        INSERT INTO checklist_inst
            (flg_content_creator, internal_name, id_checklist, flg_available, flg_status, id_institution)
        
            SELECT def_data.flg_content_creator,
                   def_data.internal_name,
                   def_data.i_checklist,
                   def_data.flg_available,
                   def_data.flg_status,
                   i_institution
            
              FROM (SELECT temp_data.flg_content_creator,
                           temp_data.internal_name,
                           temp_data.i_checklist,
                           temp_data.flg_available,
                           temp_data.flg_status,
                           row_number() over(PARTITION BY temp_data.i_checklist, temp_data.internal_name, temp_data.flg_content_creator ORDER BY temp_data.id_market DESC, decode(temp_data.version, 'DEFAULT', 0, 1) DESC) records_count
                      FROM (SELECT c.flg_content_creator,
                                   c.internal_name,
                                   (nvl((SELECT ca.id_checklist
                                          FROM checklist ca
                                         WHERE ca.id_content = c.id_content
                                           AND ca.flg_content_creator = c.flg_content_creator
                                           AND ca.internal_name = c.internal_name
                                              --AND ca.id_content IS NOT NULL
                                           AND ca.flg_available = g_flg_available
                                        /*AND rownum = 1*/
                                        ),
                                        0)) i_checklist,
                                   c.flg_available,
                                   c.flg_status,
                                   cmv.id_market,
                                   cmv.version
                            -- decode FKS to dest_vals
                              FROM alert_default.checklist c
                              JOIN alert_default.checklist_mrk_vrs cmv
                                ON cmv.flg_content_creator = c.flg_content_creator
                               AND cmv.id_checklist = c.id_checklist
                             WHERE c.flg_available = g_flg_available
                                  
                               AND cmv.id_market IN (SELECT /*+ dynamic_sampling(p 2) */
                                                      column_value
                                                       FROM TABLE(CAST(i_mkt AS table_number)) p)
                                  
                               AND cmv.version IN (SELECT /*+ dynamic_sampling(p 2) */
                                                    column_value
                                                     FROM TABLE(CAST(i_vers AS table_varchar)) p)) temp_data) def_data
             WHERE def_data.records_count = 1
               AND def_data.i_checklist != 0
               AND NOT EXISTS (SELECT 0
                      FROM checklist_inst ci
                     WHERE ci.id_institution = i_institution
                       AND ci.internal_name = def_data.internal_name
                       AND ci.flg_available = g_flg_available
                       AND ci.id_checklist = def_data.i_checklist
                       AND ci.flg_content_creator = def_data.flg_content_creator);
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
    END set_checklist_inst_search;
    -- frequent loader method
	
	FUNCTION del_checklist_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_soft_all table_number := table_number();
    
    BEGIN
        g_error     := 'delete checklist_inst';
        g_func_name := upper('del_checklist_inst_search');
    
        SELECT /*+ opt_estimate(soft_list rows = 10)*/
         column_value
          BULK COLLECT
          INTO o_soft_all
          FROM TABLE(CAST(i_software AS table_number)) sw_list
         WHERE column_value = pk_alert_constant.g_soft_all;
    
        IF o_soft_all.count < 1
        THEN
            RETURN TRUE;
        ELSE
            DELETE checklist_inst ci
             WHERE ci.flg_content_creator = 'A'
               AND ci.id_institution = i_institution;
        
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
    END del_checklist_inst_search;

-- global vars
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;
END pk_checklist_prm;
/