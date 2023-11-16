/*-- Last Change Revision: $Rev: 2026935 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY alert.pk_default_content IS

    -- Package info
    g_package_owner t_low_char := 'ALERT';
    g_package_name  t_low_char := 'PK_DEFAULT_CONTENT';
    g_validation_pattern CONSTANT t_low_char := '^[A-Z_1]+\.[A-Z_1]+\.[-0-9A-Z]+';
    g_table_name t_med_char;
    -- Private Methods
    FUNCTION get_validation_pattern RETURN t_med_char IS
    BEGIN
        RETURN g_validation_pattern;
    END get_validation_pattern;
    FUNCTION get_tbl_ext_owner
    (
        i_lang IN language.id_language%TYPE,
        i_tbl  IN all_tables.table_name%TYPE
    ) RETURN all_tables.owner%TYPE IS
        l_out_owner all_tables.owner%TYPE := '';
        l_int_owner all_tables.owner%TYPE := 'ALERT_DEFAULT';
        l_error_out t_error_out;
    BEGIN
        g_func_name := upper('get_tbl_ext_owner');
        g_error     := 'Getting table owner from data dictionary ' || i_tbl;
        SELECT dd_tbls.owner
        INTO   l_out_owner
        FROM   all_tables dd_tbls
        WHERE  dd_tbls.table_name = i_tbl
               AND dd_tbls.owner != l_int_owner;
    
        RETURN l_out_owner;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              l_error_out);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_tbl_ext_owner;

    -- Public Methods
    /********************************************************************************************
    * Set Default translations 
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/09/25
    ********************************************************************************************/
    FUNCTION set_def_translations
    (
        i_lang  IN language.id_language%TYPE,
        i_table IN user_tables.table_name%TYPE,
        o_res   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        -- new type to be used
        o_trl_table   t_tab_translation;
        o_trl_rec     t_rec_translation;
        l_module      t_low_char := 'PFH';
        l_def_na_lang t_med_char := 'NULL';
        l_table_owner all_tables.owner%TYPE := 'ALERT' /*get_tbl_ext_owner(i_lang, i_table)*/
         ;
        l_sql_first   t_big_char := 'SELECT t_rec_translation(def_data.code_translation,
                                           ''' || l_table_owner || ''',
                                           ''' || l_table_owner ||
                                    '.''||def_data.code_translation,
                                           ''' || i_table || ''',
                                           ''' || l_module || ''',
       def_data.desc_lang_1,
       def_data.desc_lang_2,
       def_data.desc_lang_3,
       def_data.desc_lang_4,
       def_data.desc_lang_5,
       def_data.desc_lang_6,
       def_data.desc_lang_7,
       def_data.desc_lang_8,
       def_data.desc_lang_9,
       def_data.desc_lang_10,
       def_data.desc_lang_11,
       def_data.desc_lang_12,
       def_data.desc_lang_13,
       def_data.desc_lang_14,
       def_data.desc_lang_15,
       def_data.desc_lang_16,
       def_data.desc_lang_17,
       def_data.desc_lang_18,
       def_data.desc_lang_19,
       def_data.desc_lang_20,
       def_data.desc_lang_21,
       def_data.desc_lang_22,
                                           ' || l_def_na_lang || ') 
       FROM (';
        l_sql_last    t_big_char := ') def_data WHERE not exists (select 0 from TABLE(PK_TRANSLATION.get_table_CODE_translation(' ||
                                    i_lang || ',''' || i_table ||
                                    ''')) trl where trl.code_translation = def_data.code_translation)';
        l_sql_midle   t_big_char := '';
    BEGIN
    
        --> TRANSLATIONS
        g_error := 'SET_TRANSLATIONS';
        pk_alertlog.log_info('Set Translations ' || i_table);
        -- no flags
        IF i_table IN ('ANALYSIS_GROUP', 'INTERV_PHYSIATRY_AREA', 'LENS', 'PHYSIATRY_AREA', 'TASK_GOAL')
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
           ext_tbl.code_' || i_table || ' code_translation,
           def_trl.desc_lang_1,
           def_trl.desc_lang_2,
           def_trl.desc_lang_3,
           def_trl.desc_lang_4,
           def_trl.desc_lang_5,
           def_trl.desc_lang_6,
           def_trl.desc_lang_7,
           def_trl.desc_lang_8,
           def_trl.desc_lang_9,
           def_trl.desc_lang_10,
           def_trl.desc_lang_11,
           def_trl.desc_lang_12,
           def_trl.desc_lang_13,
           def_trl.desc_lang_14,
           def_trl.desc_lang_15,
           def_trl.desc_lang_16,
           def_trl.desc_lang_17,
           def_trl.desc_lang_18,
           def_trl.desc_lang_19,
           def_trl.desc_lang_20,
					 def_trl.desc_lang_21,
					 def_trl.desc_lang_22
            FROM alert_default.translation def_trl
           INNER JOIN alert_default.' || i_table || ' def_tbl
              ON (def_tbl.code_' || i_table || ' = def_trl.code_translation)
           INNER JOIN ' || i_table ||
                           ' ext_tbl
              ON (ext_tbl.id_content = def_tbl.id_content)';
            -- Institution Structure tables
        ELSIF i_table IN ('FLOORS', 'BUILDING', 'DEPT', 'DEPARTMENT', 'ROOM', 'BED', 'INSTITUTION')
        THEN
            l_sql_midle := 'SELECT ext_tbl.code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
									   def_trl.desc_lang_18,
									   def_trl.desc_lang_19,
					  				 def_trl.desc_lang_20,
		      					 def_trl.desc_lang_21,
										 def_trl.desc_lang_22
                FROM ' || i_table || ' ext_tbl
               INNER JOIN alert_default.map_content def_mps
                  ON (def_mps.id_alert = ext_tbl.id_' || i_table ||
                           ' AND ext_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.' || i_table || ' def_tbl
                  ON (def_tbl.id_' || i_table ||
                           ' = def_mps.id_default AND def_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.translation def_trl
                  ON (def_trl.code_translation = def_tbl.code_' || i_table || ')
               WHERE def_mps.table_name = ''' || i_table || '''';
            -- tables that use Flg_Status instead of flg_available
        ELSIF i_table IN ('INTERVENTION', 'SR_INTERVENTION')
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
           ext_tbl.code_' || i_table || ' code_translation,
           def_trl.desc_lang_1,
           def_trl.desc_lang_2,
           def_trl.desc_lang_3,
           def_trl.desc_lang_4,
           def_trl.desc_lang_5,
           def_trl.desc_lang_6,
           def_trl.desc_lang_7,
           def_trl.desc_lang_8,
           def_trl.desc_lang_9,
           def_trl.desc_lang_10,
           def_trl.desc_lang_11,
           def_trl.desc_lang_12,
           def_trl.desc_lang_13,
           def_trl.desc_lang_14,
           def_trl.desc_lang_15,
           def_trl.desc_lang_16,
           def_trl.desc_lang_17,
           def_trl.desc_lang_18,
           def_trl.desc_lang_19,
					 def_trl.desc_lang_20,
					 def_trl.desc_lang_21,
					 def_trl.desc_lang_22
            FROM alert_default.translation def_trl
           INNER JOIN alert_default.' || i_table || ' def_tbl
              ON (def_tbl.code_' || i_table || ' = def_trl.code_translation and def_tbl.flg_status = ''A'')
           INNER JOIN ' || i_table ||
                           ' ext_tbl
              ON (ext_tbl.id_content = def_tbl.id_content and ext_tbl.flg_status = ''A'')';
            -- SR_EQUIP code is not equal to common tables (consider adding flg_available in alert_default table)
        ELSIF i_table IN ('SR_EQUIP')
        THEN
        
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                     ext_tbl.code_equip code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
										 def_trl.desc_lang_18,
										 def_trl.desc_lang_19,
      							 def_trl.desc_lang_20,
			   						 def_trl.desc_lang_21,
										 def_trl.desc_lang_22
                    FROM alert_default.translation def_trl
               INNER JOIN alert_default.' || i_table || ' def_tbl
                  ON (def_tbl.code_equip = def_trl.code_translation)
               INNER JOIN ' || i_table ||
                           ' ext_tbl
                  ON (ext_tbl.id_content = def_tbl.id_content AND ext_tbl.flg_available = ''Y'')';
        
            -- rehab don't use flg_available in schema Alert
        ELSIF i_table IN ('REHAB_AREA', 'REHAB_SESSION_TYPE', 'RESULT_NOTES', 'EXAM_GROUP')
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                     ext_tbl.code_' || i_table || ' code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
										 def_trl.desc_lang_18,
                     def_trl.desc_lang_19,
                     def_trl.desc_lang_20,
                     def_trl.desc_lang_21,
                     def_trl.desc_lang_22
                FROM ' || i_table || ' ext_tbl
               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                  ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.translation def_trl
                  ON (def_trl.code_translation = def_tbl.code_' || i_table || ')';
            --> maping column not standard "code" instead of code_WTL_URG_LEVEL
        ELSIF i_table = 'WTL_URG_LEVEL'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                ext_tbl.code code_translation,
                def_trl.desc_lang_1,
                def_trl.desc_lang_2,
                def_trl.desc_lang_3,
                def_trl.desc_lang_4,
                def_trl.desc_lang_5,
                def_trl.desc_lang_6,
                def_trl.desc_lang_7,
                def_trl.desc_lang_8,
                def_trl.desc_lang_9,
                def_trl.desc_lang_10,
                def_trl.desc_lang_11,
                def_trl.desc_lang_12,
                def_trl.desc_lang_13,
                def_trl.desc_lang_14,
                def_trl.desc_lang_15,
                def_trl.desc_lang_16,
                def_trl.desc_lang_17,
                def_trl.desc_lang_18,
                def_trl.desc_lang_19,
                def_trl.desc_lang_20,
                def_trl.desc_lang_21,
                def_trl.desc_lang_22
                 FROM ' || i_table || ' ext_tbl
                INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                   ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                INNER JOIN alert_default.translation def_trl
                   ON (def_trl.code_translation = def_tbl.code)
                WHERE ext_tbl.flg_available = ''Y''';
            --> mapping column not standard, uk validation (no id_content in table)
        ELSIF i_table = 'CHECKLIST_VERSION'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                               ext_tbl.code_name code_translation,
                               def_trl.desc_lang_1,
                               def_trl.desc_lang_2,
                               def_trl.desc_lang_3,
                               def_trl.desc_lang_4,
                               def_trl.desc_lang_5,
                               def_trl.desc_lang_6,
                               def_trl.desc_lang_7,
                               def_trl.desc_lang_8,
                               def_trl.desc_lang_9,
                               def_trl.desc_lang_10,
                               def_trl.desc_lang_11,
                               def_trl.desc_lang_12,
                               def_trl.desc_lang_13,
                               def_trl.desc_lang_14,
                               def_trl.desc_lang_15,
                               def_trl.desc_lang_16,
                               def_trl.desc_lang_17,
															 def_trl.desc_lang_18,
															 def_trl.desc_lang_19,
															 def_trl.desc_lang_20,
															 def_trl.desc_lang_21,
															 def_trl.desc_lang_22
                                FROM ' || i_table ||
                           ' ext_tbl
                               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                                  ON (def_tbl.flg_content_creator = ext_tbl.flg_content_creator AND def_tbl.version = ext_tbl.version AND
                                     def_tbl.id_checklist =
                                     (SELECT ck.id_checklist
                                         FROM alert_default.checklist ck
                                        INNER JOIN checklist chk
                                           ON (chk.id_content = ck.id_content AND chk.flg_available = ''Y'' AND chk.flg_status = ''A'')
                                        WHERE ck.flg_available = ''Y''
                                          AND ck.flg_status = ''A''
                                          AND chk.id_checklist = ext_tbl.id_checklist
                                          AND rownum = 1))
                               INNER JOIN alert_default.translation def_trl
                                  ON (def_trl.code_translation = def_tbl.code_name)
                               WHERE ext_tbl.flg_content_creator = ''A''
                                 AND ext_tbl.code_name IS NOT NULL';
            --> mapping column not standard, uk validation (no id_content in table)
        ELSIF i_table = 'CHECKLIST_ITEM'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                            ext_tbl.code_item_description code_translation,
                            def_trl.desc_lang_1,
                            def_trl.desc_lang_2,
                            def_trl.desc_lang_3,
                            def_trl.desc_lang_4,
                            def_trl.desc_lang_5,
                            def_trl.desc_lang_6,
                            def_trl.desc_lang_7,
                            def_trl.desc_lang_8,
                            def_trl.desc_lang_9,
                            def_trl.desc_lang_10,
                            def_trl.desc_lang_11,
                            def_trl.desc_lang_12,
                            def_trl.desc_lang_13,
                            def_trl.desc_lang_14,
                            def_trl.desc_lang_15,
                            def_trl.desc_lang_16,
                            def_trl.desc_lang_17,
														def_trl.desc_lang_18,
													  def_trl.desc_lang_19,
													  def_trl.desc_lang_20,
														def_trl.desc_lang_21,
													  def_trl.desc_lang_22
                             FROM ' || i_table ||
                           ' ext_tbl
                            INNER JOIN checklist_version ext_cv
                               ON (ext_cv.id_checklist_version = ext_tbl.id_checklist_version AND
                                  ext_cv.flg_content_creator = ext_tbl.flg_content_creator AND ext_tbl.version = ext_cv.version)
                            INNER JOIN checklist ext_c
                               ON (ext_c.id_checklist = ext_cv.id_checklist AND ext_c.flg_content_creator = ext_cv.flg_content_creator)
                            INNER JOIN alert_default.checklist def_c
                               ON (def_c.id_content = ext_c.id_content AND def_c.flg_available = ''Y'' and def_c.flg_status = ''A'')
                            INNER JOIN alert_default.checklist_version def_cv
                               ON (def_cv.id_checklist = def_c.id_checklist AND def_cv.flg_content_creator = def_c.flg_content_creator)
                            INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                               ON (def_tbl.flg_content_creator = ext_tbl.flg_content_creator AND
                                  def_tbl.id_checklist_version = def_cv.id_checklist_version AND def_tbl.item = ext_tbl.item)
                            INNER JOIN alert_default.translation def_trl
                               ON (def_trl.code_translation = def_tbl.code_item_description)
                            WHERE ext_tbl.flg_content_creator = ''A''
                              AND ext_tbl.code_item_description IS NOT NULL';
            -- Table with 2 codes referencing translation table
        ELSIF i_table = 'DISCH_INSTRUCTIONS'
        THEN
        
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                                           ext_tbl.code_' || i_table ||
                           ' code_translation,
                                           def_trl.desc_lang_1,
                                           def_trl.desc_lang_2,
                                           def_trl.desc_lang_3,
                                           def_trl.desc_lang_4,
                                           def_trl.desc_lang_5,
                                           def_trl.desc_lang_6,
                                           def_trl.desc_lang_7,
                                           def_trl.desc_lang_8,
                                           def_trl.desc_lang_9,
                                           def_trl.desc_lang_10,
                                           def_trl.desc_lang_11,
                                           def_trl.desc_lang_12,
                                           def_trl.desc_lang_13,
                                           def_trl.desc_lang_14,
                                           def_trl.desc_lang_15,
                                           def_trl.desc_lang_16,
                                           def_trl.desc_lang_17,
																					 def_trl.desc_lang_18,
																					 def_trl.desc_lang_19,
																					 def_trl.desc_lang_20,
																					 def_trl.desc_lang_21,
																					 def_trl.desc_lang_22
                                            FROM ' || i_table ||
                           ' ext_tbl
                                           INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                                              ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                           INNER JOIN alert_default.translation def_trl
                                              ON (def_trl.code_translation = def_tbl.code_' ||
                           i_table || ')
                                           WHERE ext_tbl.flg_available = ''Y''
                                          UNION ALL
                                          SELECT /* +all_rows */
                                           ext_tbl.code_' || i_table ||
                           '_title code_translation,
                                           def_trl.desc_lang_1,
                                           def_trl.desc_lang_2,
                                           def_trl.desc_lang_3,
                                           def_trl.desc_lang_4,
                                           def_trl.desc_lang_5,
                                           def_trl.desc_lang_6,
                                           def_trl.desc_lang_7,
                                           def_trl.desc_lang_8,
                                           def_trl.desc_lang_9,
                                           def_trl.desc_lang_10,
                                           def_trl.desc_lang_11,
                                           def_trl.desc_lang_12,
                                           def_trl.desc_lang_13,
                                           def_trl.desc_lang_14,
                                           def_trl.desc_lang_15,
                                           def_trl.desc_lang_16,
                                           def_trl.desc_lang_17,
																					 def_trl.desc_lang_18,
																					 def_trl.desc_lang_19,
																					 def_trl.desc_lang_20,
																					 def_trl.desc_lang_21,
																					 def_trl.desc_lang_22
                                            FROM ' || i_table ||
                           ' ext_tbl
                                           INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                                              ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                           INNER JOIN alert_default.translation def_trl
                                              ON (def_trl.code_translation = def_tbl.code_' ||
                           i_table || '_title)
                                           WHERE ext_tbl.flg_available = ''Y''';
        ELSIF i_table = 'NURSE_TEA_TOPIC'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
       ext_tbl.code_nurse_tea_topic code_translation,
       def_trl.desc_lang_1,
       def_trl.desc_lang_2,
       def_trl.desc_lang_3,
       def_trl.desc_lang_4,
       def_trl.desc_lang_5,
       def_trl.desc_lang_6,
       def_trl.desc_lang_7,
       def_trl.desc_lang_8,
       def_trl.desc_lang_9,
       def_trl.desc_lang_10,
       def_trl.desc_lang_11,
       def_trl.desc_lang_12,
       def_trl.desc_lang_13,
       def_trl.desc_lang_14,
       def_trl.desc_lang_15,
       def_trl.desc_lang_16,
       def_trl.desc_lang_17,
       def_trl.desc_lang_18,
       def_trl.desc_lang_19,
       def_trl.desc_lang_20,
       def_trl.desc_lang_21,
       def_trl.desc_lang_22
        FROM ' || i_table || ' ext_tbl
       INNER JOIN alert_default.' || i_table || ' def_tbl
          ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
       INNER JOIN alert_default.translation def_trl
          ON (def_trl.code_translation = def_tbl.code_nurse_tea_topic)
       WHERE ext_tbl.flg_available = ''Y''
      UNION ALL
      SELECT /* +all_rows */
       ext_tbl.code_topic_description code_translation,
       def_trl.desc_lang_1,
       def_trl.desc_lang_2,
       def_trl.desc_lang_3,
       def_trl.desc_lang_4,
       def_trl.desc_lang_5,
       def_trl.desc_lang_6,
       def_trl.desc_lang_7,
       def_trl.desc_lang_8,
       def_trl.desc_lang_9,
       def_trl.desc_lang_10,
       def_trl.desc_lang_11,
       def_trl.desc_lang_12,
       def_trl.desc_lang_13,
       def_trl.desc_lang_14,
       def_trl.desc_lang_15,
       def_trl.desc_lang_16,
       def_trl.desc_lang_17,
       def_trl.desc_lang_18,
       def_trl.desc_lang_19,
       def_trl.desc_lang_20,
       def_trl.desc_lang_21,
       def_trl.desc_lang_22
        FROM ' || i_table || ' ext_tbl
       INNER JOIN alert_default.' || i_table || ' def_tbl
          ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
       INNER JOIN alert_default.translation def_trl
          ON (def_trl.code_translation = def_tbl.code_topic_description)
       WHERE ext_tbl.flg_available = ''Y''
      UNION ALL
      SELECT /* +all_rows */
       ext_tbl.code_topic_context_help code_translation,
       def_trl.desc_lang_1,
       def_trl.desc_lang_2,
       def_trl.desc_lang_3,
       def_trl.desc_lang_4,
       def_trl.desc_lang_5,
       def_trl.desc_lang_6,
       def_trl.desc_lang_7,
       def_trl.desc_lang_8,
       def_trl.desc_lang_9,
       def_trl.desc_lang_10,
       def_trl.desc_lang_11,
       def_trl.desc_lang_12,
       def_trl.desc_lang_13,
       def_trl.desc_lang_14,
       def_trl.desc_lang_15,
       def_trl.desc_lang_16,
       def_trl.desc_lang_17,
       def_trl.desc_lang_18,
       def_trl.desc_lang_19,
       def_trl.desc_lang_20,
       def_trl.desc_lang_21,
       def_trl.desc_lang_22
        FROM ' || i_table || ' ext_tbl
       INNER JOIN alert_default.' || i_table || ' def_tbl
          ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
       INNER JOIN alert_default.translation def_trl
          ON (def_trl.code_translation = def_tbl.code_topic_context_help)
       WHERE ext_tbl.flg_available = ''Y''';
            -- table with different codes 
        ELSIF i_table = 'P1_SPEC_HELP'
        THEN
        
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                               ext_tbl.code_title code_translation,
                               def_trl.desc_lang_1,
                               def_trl.desc_lang_2,
                               def_trl.desc_lang_3,
                               def_trl.desc_lang_4,
                               def_trl.desc_lang_5,
                               def_trl.desc_lang_6,
                               def_trl.desc_lang_7,
                               def_trl.desc_lang_8,
                               def_trl.desc_lang_9,
                               def_trl.desc_lang_10,
                               def_trl.desc_lang_11,
                               def_trl.desc_lang_12,
                               def_trl.desc_lang_13,
                               def_trl.desc_lang_14,
                               def_trl.desc_lang_15,
                               def_trl.desc_lang_16,
                               def_trl.desc_lang_17,
															 def_trl.desc_lang_18,
															 def_trl.desc_lang_19,
															 def_trl.desc_lang_20,
															 def_trl.desc_lang_21,
															 def_trl.desc_lang_22
                                FROM ' || i_table ||
                           ' ext_tbl
                               INNER JOIN speciality ext_s
                                  ON (ext_s.id_speciality = ext_tbl.id_speciality AND ext_s.flg_available = ''Y'')
                               INNER JOIN alert_default.speciality def_s
                                  ON (def_s.id_content = ext_s.id_content AND def_s.flg_available = ''Y'')
                               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                                  ON (def_tbl.id_speciality = def_s.id_speciality AND def_tbl.flg_available = ''Y'')
                               INNER JOIN alert_default.translation def_trl
                                  ON (def_trl.code_translation = def_tbl.code_title)
                               WHERE ext_tbl.flg_available = ''Y''
                              UNION ALL
                              SELECT /* +all_rows */
                               ext_tbl.code_text code_translation,
                               def_trl.desc_lang_1,
                               def_trl.desc_lang_2,
                               def_trl.desc_lang_3,
                               def_trl.desc_lang_4,
                               def_trl.desc_lang_5,
                               def_trl.desc_lang_6,
                               def_trl.desc_lang_7,
                               def_trl.desc_lang_8,
                               def_trl.desc_lang_9,
                               def_trl.desc_lang_10,
                               def_trl.desc_lang_11,
                               def_trl.desc_lang_12,
                               def_trl.desc_lang_13,
                               def_trl.desc_lang_14,
                               def_trl.desc_lang_15,
                               def_trl.desc_lang_16,
                               def_trl.desc_lang_17,
															 def_trl.desc_lang_18,
															 def_trl.desc_lang_19,
															 def_trl.desc_lang_20,
															 def_trl.desc_lang_21,
															 def_trl.desc_lang_22
                                FROM ' || i_table ||
                           ' ext_tbl
                               INNER JOIN speciality ext_s
                                  ON (ext_s.id_speciality = ext_tbl.id_speciality AND ext_s.flg_available = ''Y'')
                               INNER JOIN alert_default.speciality def_s
                                  ON (def_s.id_content = ext_s.id_content AND def_s.flg_available = ''Y'')
                               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                                  ON (def_tbl.id_speciality = def_s.id_speciality AND def_tbl.flg_available = ''Y'')
                               INNER JOIN alert_default.translation def_trl
                                  ON (def_trl.code_translation = def_tbl.code_text)
                               WHERE ext_tbl.flg_available = ''Y''';
        
        ELSIF i_table = 'ANALYSIS_DESC'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                               ext_tbl.code_translation,
                               def_trl.desc_lang_1,
                               def_trl.desc_lang_2,
                               def_trl.desc_lang_3,
                               def_trl.desc_lang_4,
                               def_trl.desc_lang_5,
                               def_trl.desc_lang_6,
                               def_trl.desc_lang_7,
                               def_trl.desc_lang_8,
                               def_trl.desc_lang_9,
                               def_trl.desc_lang_10,
                               def_trl.desc_lang_11,
                               def_trl.desc_lang_12,
                               def_trl.desc_lang_13,
                               def_trl.desc_lang_14,
                               def_trl.desc_lang_15,
                               def_trl.desc_lang_16,
                               def_trl.desc_lang_17,
															 def_trl.desc_lang_18,
															 def_trl.desc_lang_19,
															 def_trl.desc_lang_20,
															 def_trl.desc_lang_21,
															 def_trl.desc_lang_22
                                FROM (SELECT ad.code_analysis_desc code_translation, ad.id_content,st.id_content id_cont_st,ad.value, a.id_content labt_cnt, ap.id_content param_cnt
                                        FROM analysis_desc ad
                                       INNER JOIN analysis a
                                          ON (a.id_analysis = ad.id_analysis AND a.flg_available = ''Y'')
                                          join sample_type st on (ad.id_sample_type = st.id_sample_type and st.flg_available = ''Y'')
                                        LEFT JOIN analysis_parameter ap
                                          ON (ap.id_analysis_parameter = ad.id_analysis_parameter AND ap.flg_available = ''Y'')
                                       WHERE ad.flg_available = ''Y'') ext_tbl
                               INNER JOIN (SELECT def_ad.code_analysis_desc code_translation,
                                                  def_ad.id_content,
                                                  def_ad.value,
                                                  def_st.id_content id_cont_st,
                                                  def_a.id_content          labt_cnt,
                                                  def_ap.id_content         param_cnt
                                             FROM alert_default.analysis_desc def_ad
                                            INNER JOIN alert_default.analysis def_a
                                               ON (def_a.id_analysis = def_ad.id_analysis AND def_a.flg_available = ''Y'')
                                               join alert_default.sample_type def_st on (def_ad.id_sample_type = def_st.id_sample_type and def_st.flg_available = ''Y'' )
                                             LEFT JOIN alert_default.analysis_parameter def_ap
                                               ON (def_ap.id_analysis_parameter = def_ad.id_analysis_parameter AND def_ap.flg_available = ''Y'')
                                            WHERE def_ad.flg_available = ''Y'') def_tbl
                                  ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.labt_cnt = ext_tbl.labt_cnt AND (def_tbl.value = ext_tbl.value or (def_tbl.value is null and ext_tbl.value is null)) and
                                  def_tbl.id_cont_st = ext_tbl.id_cont_st and
                                     (def_tbl.param_cnt = ext_tbl.param_cnt OR (def_tbl.param_cnt IS NULL AND ext_tbl.param_cnt IS NULL)))
                               INNER JOIN alert_default.translation def_trl
                                  ON (def_trl.code_translation = def_tbl.code_translation)';
        
        ELSIF i_table = 'ANALYSIS_SPECIMEN_CONDITION'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                         ext_tbl.code_specimen_condition code_translation,
                         def_trl.desc_lang_1,
                         def_trl.desc_lang_2,
                         def_trl.desc_lang_3,
                         def_trl.desc_lang_4,
                         def_trl.desc_lang_5,
                         def_trl.desc_lang_6,
                         def_trl.desc_lang_7,
                         def_trl.desc_lang_8,
                         def_trl.desc_lang_9,
                         def_trl.desc_lang_10,
                         def_trl.desc_lang_11,
                         def_trl.desc_lang_12,
                         def_trl.desc_lang_13,
                         def_trl.desc_lang_14,
                         def_trl.desc_lang_15,
                         def_trl.desc_lang_16,
                         def_trl.desc_lang_17,
                         def_trl.desc_lang_18,
                         def_trl.desc_lang_19,
										     def_trl.desc_lang_20,
												 def_trl.desc_lang_21,
												 def_trl.desc_lang_22
                    FROM ' || i_table || ' ext_tbl
                   INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                      ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                   INNER JOIN alert_default.translation def_trl
                      ON (def_trl.code_translation = def_tbl.code_specimen_condition)
                   WHERE ext_tbl.flg_available = ''Y''';
        
        ELSIF i_table = 'PO_PARAM'
        THEN
            l_sql_midle := 'SELECT res.code_translation,
         res.desc_lang_1,
         res.desc_lang_2,
         res.desc_lang_3,
         res.desc_lang_4,
         res.desc_lang_5,
         res.desc_lang_6,
         res.desc_lang_7,
         res.desc_lang_8,
         res.desc_lang_9,
         res.desc_lang_10,
         res.desc_lang_11,
         res.desc_lang_12,
         res.desc_lang_13,
         res.desc_lang_14,
         res.desc_lang_15,
         res.desc_lang_16,
         res.desc_lang_17,
         res.desc_lang_18,
         res.desc_lang_19,
				 res.desc_lang_20,
				 res.desc_lang_21,
				 res.desc_lang_22
    FROM (SELECT ext_tbl.id_content,
                 ext_tbl.id_parameter,
                 ext_tbl.code_' || i_table || ' code_translation,
                 def_trl.desc_lang_1,
                 def_trl.desc_lang_2,
                 def_trl.desc_lang_3,
                 def_trl.desc_lang_4,
                 def_trl.desc_lang_5,
                 def_trl.desc_lang_6,
                 def_trl.desc_lang_7,
                 def_trl.desc_lang_8,
                 def_trl.desc_lang_9,
                 def_trl.desc_lang_10,
                 def_trl.desc_lang_11,
                 def_trl.desc_lang_12,
                 def_trl.desc_lang_13,
                 def_trl.desc_lang_14,
                 def_trl.desc_lang_15,
                 def_trl.desc_lang_16,
                 def_trl.desc_lang_17,
                 def_trl.desc_lang_18,
                 def_trl.desc_lang_19,
								 def_trl.desc_lang_20,
								 def_trl.desc_lang_21,
							   def_trl.desc_lang_22,         
                 row_number() over(PARTITION BY ext_tbl.id_content, ext_tbl.id_parameter ORDER BY def_tbl.id_po_param DESC) unique_rows
            FROM ' || i_table || ' ext_tbl
           INNER JOIN alert_default.' || i_table || ' def_tbl
              ON (def_tbl.id_content = ext_tbl.id_content AND
                 (pk_periodicobservation_prm.get_dest_parameter_map(1, def_tbl.flg_type, def_tbl.id_parameter) =
                 ext_tbl.id_parameter) AND def_tbl.flg_available = ''Y'')
           INNER JOIN alert_default.translation def_trl
              ON (def_trl.code_translation = def_tbl.code_po_param)
           WHERE ext_tbl.flg_available = ''Y'') res
   WHERE unique_rows = 1';
        ELSIF i_table = 'PO_PARAM_MC'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=1000)*/
   res_tbl.code_translation,
   def_trl.desc_lang_1,
   def_trl.desc_lang_2,
   def_trl.desc_lang_3,
   def_trl.desc_lang_4,
   def_trl.desc_lang_5,
   def_trl.desc_lang_6,
   def_trl.desc_lang_7,
   def_trl.desc_lang_8,
   def_trl.desc_lang_9,
   def_trl.desc_lang_10,
   def_trl.desc_lang_11,
   def_trl.desc_lang_12,
   def_trl.desc_lang_13,
   def_trl.desc_lang_14,
   def_trl.desc_lang_15,
   def_trl.desc_lang_16,
   def_trl.desc_lang_17,
   def_trl.desc_lang_18,
   def_trl.desc_lang_19,
   def_trl.desc_lang_20,
   def_trl.desc_lang_21,
   def_trl.desc_lang_22
    FROM (
         SELECT tbl1.code_' || i_table || ' default_code_trl,
                 tbl1.id_content,
                 tbl1.id_po_param,
                 ext_tbl.code_' || i_table || ' code_translation,
                 row_number() over(PARTITION BY tbl1.id_content, tbl1.id_po_param ORDER BY 1) rws
            FROM (SELECT def_tbl.code_' || i_table || ',
                         def_tbl.id_content,
                         (SELECT pk_periodicobservation_prm.get_dest_pop_id(1, def_tbl.id_po_param)
                            FROM dual) id_po_param
                    FROM alert_default.' || i_table || ' def_tbl
                    where def_tbl.flg_available = ''Y'') tbl1
           INNER JOIN ' || i_table || ' ext_tbl
              ON (ext_tbl.id_content = tbl1.id_content AND ext_tbl.flg_available = ''Y'' AND
                 ext_tbl.id_po_param = tbl1.id_po_param)
    
    ) res_tbl
   INNER JOIN alert_default.translation def_trl
      ON (def_trl.code_translation = res_tbl.default_code_trl)
   WHERE res_tbl.rws = 1';
   ELSIF i_table = 'APPOINTMENT'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                     ext_tbl.code_' || i_table || ' code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
                     def_trl.desc_lang_18,
                     def_trl.desc_lang_19,
                     def_trl.desc_lang_20,
                     def_trl.desc_lang_21,
                     def_trl.desc_lang_22
                FROM ' || i_table || ' ext_tbl
               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                  ON (def_tbl.id_content = ext_tbl.id_appointment AND def_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.translation def_trl
                  ON (def_trl.code_translation = def_tbl.code_' || i_table || ')
               WHERE ext_tbl.flg_available = ''Y''';
ELSIF i_table = 'APPOINTMENT'
        THEN
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                     ext_tbl.code_' || i_table || ' code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
                     def_trl.desc_lang_18,
                     def_trl.desc_lang_19,
                     def_trl.desc_lang_20,
                     def_trl.desc_lang_21,
                     def_trl.desc_lang_22
                FROM ' || i_table || ' ext_tbl
               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                  ON (def_tbl.id_content = ext_tbl.id_appointment AND def_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.translation def_trl
                  ON (def_trl.code_translation = def_tbl.code_' || i_table || ')
               WHERE ext_tbl.flg_available = ''Y''';
        ELSE
            l_sql_midle := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                     ext_tbl.code_' || i_table || ' code_translation,
                     def_trl.desc_lang_1,
                     def_trl.desc_lang_2,
                     def_trl.desc_lang_3,
                     def_trl.desc_lang_4,
                     def_trl.desc_lang_5,
                     def_trl.desc_lang_6,
                     def_trl.desc_lang_7,
                     def_trl.desc_lang_8,
                     def_trl.desc_lang_9,
                     def_trl.desc_lang_10,
                     def_trl.desc_lang_11,
                     def_trl.desc_lang_12,
                     def_trl.desc_lang_13,
                     def_trl.desc_lang_14,
                     def_trl.desc_lang_15,
                     def_trl.desc_lang_16,
                     def_trl.desc_lang_17,
										 def_trl.desc_lang_18,
                     def_trl.desc_lang_19,
										 def_trl.desc_lang_20,
				  					 def_trl.desc_lang_21,
				  					 def_trl.desc_lang_22
                FROM ' || i_table || ' ext_tbl
               INNER JOIN alert_default.' || i_table ||
                           ' def_tbl
                  ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
               INNER JOIN alert_default.translation def_trl
                  ON (def_trl.code_translation = def_tbl.code_' || i_table || ')
               WHERE ext_tbl.flg_available = ''Y''';
        
        END IF;
        IF l_sql_midle IS NOT NULL
        THEN
            EXECUTE IMMEDIATE l_sql_first || l_sql_midle || l_sql_last BULK COLLECT
                INTO o_trl_table;
        
            IF o_trl_table.count > 0
            THEN
                o_res := pk_translation.ins_bulk_translation(o_trl_table, g_flg_available);
            ELSE
                o_res := 0;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              'SET_TRANSLATIONS',
                                              o_error);
            RETURN FALSE;
    END set_def_translations;

    /********************************************************************************************
    * Set Default Content Parametrizations
    *
    * @param i_lang                Prefered language ID
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/16
    ********************************************************************************************/
    FUNCTION set_def_content
    (
        i_lang                   IN language.id_language%TYPE,
        o_health_plan_entities   OUT table_number,
        o_health_plans           OUT table_number,
        o_clinical_services      OUT pk_types.cursor_type,
        o_analysis_parameters    OUT table_number,
        o_sample_types           OUT table_number,
        o_sample_rec             OUT table_number,
        o_exam_cat               OUT table_number,
        o_analysis               OUT table_number,
        o_analysis_res_calcs     OUT table_number,
        o_analysis_res_par_calcs OUT table_number,
        o_analysis_loinc         OUT table_number,
        o_analysis_desc          OUT table_number,
        o_exams                  OUT table_number,
        o_interv                 OUT table_number,
        o_interv_cat             OUT table_number,
        o_supplies               OUT table_number,
        o_habits                 OUT table_number,
        o_habit_char             OUT table_number,
        o_hidrics                OUT table_number,
        o_transp_entity          OUT table_number,
        o_disch_reas             OUT table_number,
        o_disch_dest             OUT table_number,
        o_disch_instr_group      OUT table_number,
        o_disch_instructions     OUT table_number,
        o_icnp_compositions      OUT pk_types.cursor_type,
        o_events                 OUT pk_types.cursor_type,
        o_lens                   OUT table_number,
        o_necessity              OUT table_number,
        o_codification           OUT table_number,
        o_codification_analysis  OUT table_number,
        o_interv_codification    OUT table_number,
        o_exam_codification      OUT table_number,
        o_transfer_option        OUT table_number,
        o_sr_intervention        OUT table_number,
        o_sr_equip               OUT table_number,
        o_sr_equip_kit           OUT table_number,
        o_sr_equip_period        OUT table_number,
        o_diet_parent            OUT pk_types.cursor_type,
        o_diet                   OUT pk_types.cursor_type,
        o_positioning            OUT table_number,
        o_speciality             OUT table_number,
        o_physiatry_area         OUT table_number,
        o_interv_physiatry_area  OUT table_number,
        o_comp_axe               OUT table_number,
        o_complication           OUT table_number,
        o_comp_axe_group         OUT table_number,
        o_checklist              OUT table_number,
        o_rehab_area             OUT table_number,
        o_rehab_session_type     OUT table_varchar,
        o_body_structure         OUT table_number,
        o_questionnaire          OUT pk_types.cursor_type,
        o_response               OUT pk_types.cursor_type,
        o_hidrics_device         OUT pk_types.cursor_type,
        o_hidrics_occurs_type    OUT pk_types.cursor_type,
        o_isencao                OUT table_number,
        --o_id_relation_set       OUT table_number,
        o_supply_type   OUT pk_types.cursor_type,
        o_supply        OUT pk_types.cursor_type,
        o_res_notes     OUT pk_types.cursor_type,
        o_labt_st       OUT pk_types.cursor_type,
        o_labt_bs       OUT pk_types.cursor_type,
        o_labt_compl    OUT pk_types.cursor_type,
        o_mcdt_nature   OUT table_number,
        o_mcdt_nisencao OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_content';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_content;
    /********************************************************************************************
    * Set Default Health Plans
    *
    * @param i_lang                 Prefered language ID
    * @param o_health_plan_entities Health Plan Entities
    * @param o_health_plans         Health Plans
    * @param o_error                Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/16
    ********************************************************************************************/
    FUNCTION set_def_health_plans
    (
        i_lang                 IN language.id_language%TYPE,
        o_health_plan_entities OUT table_number,
        o_health_plans         OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_health_plans';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_health_plans;
    /********************************************************************************************
    * Set Default Clinical Services
    *
    * @param i_lang                Prefered language ID
    * @param o_clinical_services   Clinical Services
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Mauro Sousa
    * @version                     0.4
    * @since                       2010/11/29
    ********************************************************************************************/
    FUNCTION set_def_clinical_services
    (
        i_lang              IN language.id_language%TYPE,
        o_clinical_services OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_clinical_services';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_clinical_services;
    /********************************************************************************************
    * Set Default Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_parameters Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_parameters
    (
        i_lang                IN language.id_language%TYPE,
        o_analysis_parameters OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_parameters';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_parameters;
    /********************************************************************************************
    * Set Default Samples Types
    *
    * @param i_lang                Prefered language ID
    * @param o_sample_types        Samples Types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_sample_types
    (
        i_lang         IN language.id_language%TYPE,
        o_sample_types OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sample_types';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sample_types;
    /********************************************************************************************
    * Set Default Samples Recipients
    *
    * @param i_lang                Prefered language ID
    * @param o_sample_recipients   Sample Recipients
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_sample_recipients
    (
        i_lang              IN language.id_language%TYPE,
        o_sample_recipients OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sample_recipients';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sample_recipients;
    /********************************************************************************************
    * Set Default Exam Categories
    *
    * @param i_lang                Prefered language ID
    * @param o_exam_categories     Exam categories
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_exam_categories
    (
        i_lang            IN language.id_language%TYPE,
        o_exam_categories OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_exam_categories';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_exam_categories;
    /********************************************************************************************
    * Set Default Analysis
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis
    (
        i_lang     IN language.id_language%TYPE,
        o_analysis OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis;
    /********************************************************************************************
    * Set Default Analysis Groups
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_groups     Analysis Groups
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION set_def_analysis_groups
    (
        i_lang            IN language.id_language%TYPE,
        o_analysis_groups OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_groups';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_groups;
    /********************************************************************************************
    * Set Default Analysis Loinc Codes
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_loinc
    (
        i_lang           IN language.id_language%TYPE,
        o_analysis_loinc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_loinc';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_loinc;
    /********************************************************************************************
    * Set Default Analysis Descriptions
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis            Analysis
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/26
    ********************************************************************************************/
    FUNCTION set_def_analysis_desc
    (
        i_lang          IN language.id_language%TYPE,
        o_analysis_desc OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_desc';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_desc;
    /********************************************************************************************
    * Set Default Exams
    *
    * @param i_lang                Prefered language ID
    * @param o_exams               Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/30
    ********************************************************************************************/
    FUNCTION set_def_exams
    (
        i_lang  IN language.id_language%TYPE,
        o_exams OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_exams';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_exams;
    /********************************************************************************************
    * Set Default Interventions
    *
    * @param i_lang                Prefered language ID
    * @param o_interventions       Interventions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/31
    ********************************************************************************************/
    FUNCTION set_def_interventions
    (
        i_lang          IN language.id_language%TYPE,
        o_interventions OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_interventions';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_interventions;
    /********************************************************************************************
    * Set Default Supplies
    *
    * @param i_lang                Prefered language ID
    * @param o_supplies            Supplies
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_supplies
    (
        i_lang     IN language.id_language%TYPE,
        o_supplies OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_supplies';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_supplies;
    /********************************************************************************************
    * Set Default Habits
    *
    * @param i_lang                Prefered language ID
    * @param o_habits              Habits
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_habits
    (
        i_lang   IN language.id_language%TYPE,
        o_habits OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_habits';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_habits;
    /********************************************************************************************
    * Set Default Hidrics Types
    *
    * @param i_lang                Prefered language ID
    * @param o_hidrics_type        Hidrics Types
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_hidrics_type
    (
        i_lang         IN language.id_language%TYPE,
        o_hidrics_type OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_hidrics_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_hidrics_type;
    /*********************************************************************************************
    * Set HIDRICS LOCATION Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_hidrics_location        Cursor of Instituition HIDRICS LOCATIONS
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6
    * @since                           2010/07/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_location
    (
        i_lang             IN language.id_language%TYPE,
        o_hidrics_location OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_hidrics_location';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_hidrics_location;
    /********************************************************************************************
    * Set Default Hidrics
    *
    * @param i_lang                Prefered language ID
    * @param o_hidrics             Hidrics
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/02
    ********************************************************************************************/
    FUNCTION set_def_hidrics
    (
        i_lang    IN language.id_language%TYPE,
        o_hidrics OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_hidrics';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_hidrics;
    /********************************************************************************************
    * Set Default Transport entities
    *
    * @param i_lang                Prefered language ID
    * @param o_transp              Transport entities
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_transp
    (
        i_lang   IN language.id_language%TYPE,
        o_transp OUT table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_transp';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_transp;
    /********************************************************************************************
    * Set Default Discharge Reasons
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_reas          Discharge Reasons
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_discharge_reason
    (
        i_lang       IN language.id_language%TYPE,
        o_disch_reas OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_discharge_reason';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_discharge_reason;
    /********************************************************************************************
    * Set Default Discharge Destinations
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_dest          Discharge Destinations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_discharge_dest
    (
        i_lang       IN language.id_language%TYPE,
        o_disch_dest OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_discharge_dest';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_discharge_dest;
    /********************************************************************************************
    * Set Default Groups of discharge instructions
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_instr_group   Groups of discharge instructions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/03
    ********************************************************************************************/
    FUNCTION set_def_disch_instr_group
    (
        i_lang              IN language.id_language%TYPE,
        o_disch_instr_group OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_disch_instr_group';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_disch_instr_group;
    /********************************************************************************************
    * Set Default Discharge instructions
    *
    * @param i_lang                Prefered language ID
    * @param o_disch_instructions  Discharge instructions
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/06
    ********************************************************************************************/
    FUNCTION set_def_disch_instructions
    (
        i_lang               IN language.id_language%TYPE,
        o_disch_instructions OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_disch_instructions';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_disch_instructions;
    /********************************************************************************************
    * Set Default Events (analysis, habits, vital signs)
    *
    * @param i_lang                Prefered language ID
    * @param o_events              Events (analysis, habits, vital signs)
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION get_def_events
    (
        i_lang   IN language.id_language%TYPE,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_events';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_events;
    /********************************************************************************************
    * Set Default Events (analysis, habits, vital signs)
    *
    * @param i_lang                Prefered language ID
    * @param o_events              Events (analysis, habits, vital signs)
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.2
    * @since                       2012/06/15
    ********************************************************************************************/
    FUNCTION set_def_events
    (
        i_lang   IN language.id_language%TYPE,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_events';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_events;
    /********************************************************************************************
    * Set Default Lens
    *
    * @param i_lang                Prefered language ID
    * @param o_diagnosis           Lens
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/04/16
    ********************************************************************************************/
    FUNCTION set_def_lens
    (
        i_lang  IN language.id_language%TYPE,
        o_lens  OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_lens';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_lens;
    /********************************************************************************************
    * Set Physiatry Area
    *
    * @param i_lang                 Prefered language ID
    * @param o_physiatry_area       Physiatry_area
    * @param o_error                Error
    *
    * @return                       true or false on success or error
    *
    * @author                       MESS
    * @version                      2.6
    * @since                        2010/04/29
    ********************************************************************************************/
    FUNCTION set_def_physiatry_area
    (
        i_lang           IN language.id_language%TYPE,
        o_physiatry_area OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_physiatry_area';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_physiatry_area;
    /********************************************************************************************
    * Set Default INTERV_PHYSIATRY_AREA
    *
    * @param i_lang                Prefered language ID
    * @param o_interv_physiatry_area          interv_physiatry_area
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/29
    ********************************************************************************************/
    FUNCTION set_def_interv_physiatry_area
    (
        i_lang                  IN language.id_language%TYPE,
        o_interv_physiatry_area OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_interv_physiatry_area';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_interv_physiatry_area;
    /********************************************************************************************
    * Set Default Necessity
    *
    * @param i_lang                Prefered language ID
    * @param o_necessity           Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_necessity
    (
        i_lang      IN language.id_language%TYPE,
        o_necessity OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_necessity';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_necessity;
    /********************************************************************************************
    * Set Default CODIFICATION
    *
    * @param i_lang                           Prefered language ID
    * @param o_codification                   External Cause
    * @param o_analysis_codification          External Cause
    * @param o_interv_codification            External Cause
    * @param o_exam_codification              External Cause
    * @param o_error                          Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_codification
    (
        i_lang                  IN language.id_language%TYPE,
        o_codification          OUT table_number,
        o_analysis_codification OUT table_number,
        o_interv_codification   OUT table_number,
        o_exam_codification     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_codification';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_codification;
    /********************************************************************************************
    * Set Default transfer_option
    *
    * @param i_lang                           Prefered language ID
    * @param o_transfer_option                   External Cause
    * @param o_error                          Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/07
    ********************************************************************************************/

    FUNCTION set_def_transfer_option
    (
        i_lang            IN language.id_language%TYPE,
        o_transfer_option OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_transfer_option';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_transfer_option;
    /********************************************************************************************
    * Set Default SR_INTERVENTION
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_intervention           Exams
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6
    * @since                       2010/01/05
    ********************************************************************************************/

    FUNCTION set_def_sr_intervention
    (
        i_lang            IN language.id_language%TYPE,
        o_sr_intervention OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sr_intervention';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sr_intervention;
    /********************************************************************************************
    * Set Default Sr_equip
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip       Sr_equip
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/18
    ********************************************************************************************/
    FUNCTION set_def_sr_equip
    (
        i_lang     IN language.id_language%TYPE,
        o_sr_equip OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sr_equip';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sr_equip;
    /********************************************************************************************
    * Set Default Sr_equip_kit
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip_kit        Sr_equip_kit
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/20
    ********************************************************************************************/
    FUNCTION set_def_sr_equip_kit
    (
        i_lang         IN language.id_language%TYPE,
        o_sr_equip_kit OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sr_equip_kit';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sr_equip_kit;
    /********************************************************************************************
    * Set Default set_def_SR_EQUIP_PERIOD
    *
    * @param i_lang                Prefered language ID
    * @param o_sr_equip_period     sr_equip_period
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SMSS
    * @version                     2.6.0
    * @since                       2010/01/20
    ********************************************************************************************/
    FUNCTION set_def_sr_equip_period
    (
        i_lang            IN language.id_language%TYPE,
        o_sr_equip_period OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_sr_equip_period';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_sr_equip_period;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/28
    ********************************************************************************************/
    FUNCTION set_def_diet
    (
        i_lang        IN language.id_language%TYPE,
        o_diet_parent OUT pk_types.cursor_type,
        o_diet        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_diet';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_diet;
    /********************************************************************************************
    * Set Default Speciality
    *
    * @param i_lang                Prefered language ID
    * @param o_speciality          Speciality
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/04/28
    ********************************************************************************************/
    FUNCTION set_def_speciality
    (
        i_lang       IN language.id_language%TYPE,
        o_speciality OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_speciality';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_speciality;
    /********************************************************************************************
    * Set Default Comp_Axe
    *
    * @param i_lang                Prefered language ID
    * @param o_comp_axe            Comp_Axe
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/20
    ********************************************************************************************/
    FUNCTION set_def_comp_axe
    (
        i_lang     IN language.id_language%TYPE,
        o_comp_axe OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_comp_axe';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_comp_axe;
    /********************************************************************************************
    * Set Default Complications
    *
    * @param i_lang                Prefered language ID
    * @param o_complications       Complications
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/20
    ********************************************************************************************/
    FUNCTION set_def_complication
    (
        i_lang          IN language.id_language%TYPE,
        o_complications OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_complication';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_complication;
    /********************************************************************************************
    * Set Default Comp_Axe_Group
    *
    * @param i_lang                Prefered language ID
    * @param o_comp_axe_group      Comp_Axe_Group
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/05/31
    ********************************************************************************************/
    FUNCTION set_def_comp_axe_group
    (
        i_lang           IN language.id_language%TYPE,
        o_comp_axe_group OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_comp_axe_group';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_comp_axe_group;
    /********************************************************************************************
    * Set Default Checklists
    *
    * @param i_lang                Prefered language ID
    * @param o_checklist           Checklist
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist
    (
        i_lang      IN language.id_language%TYPE,
        o_checklist OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist;
    /*********************************************************************************************
    * Set REHAB_AREA Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_rehab_area              Cursor of Instituition REHAB_AREA
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/23
    ********************************************************************************************/
    FUNCTION set_def_rehab_area
    (
        i_lang       IN language.id_language%TYPE,
        o_rehab_area OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_rehab_area';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_rehab_area;
    /*********************************************************************************************
    * Set REHAB_SESSION_TYPE Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_rehab_session_type      Cursor of Instituition REHAB_SESSION_TYPE
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.3.3
    * @since                           2010/09/23
    ********************************************************************************************/
    FUNCTION set_def_rehab_session_type
    (
        i_lang               IN language.id_language%TYPE,
        o_rehab_session_type OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_rehab_session_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_rehab_session_type;
    /*********************************************************************************************
    * Set BODY_STRUCTURE Value for a specific institution
    *
    * @param i_lang                    Prefered language ID
    * @param o_body_structure          Cursor of Instituition BODY_STRUCTURE
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/08
    ********************************************************************************************/
    FUNCTION set_def_body_structure
    (
        i_lang           IN language.id_language%TYPE,
        o_body_structure OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_body_structure';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_body_structure;
    /********************************************************************************************
    * Set QUESTIONNAIRE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/15
    ********************************************************************************************/
    FUNCTION set_def_questionnaire
    (
        i_lang                 IN language.id_language%TYPE,
        o_id_questionnaire_cnt OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_questionnaire';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_questionnaire;
    /********************************************************************************************
    * Set RESPONSE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION set_def_response
    (
        i_lang            IN language.id_language%TYPE,
        o_id_response_cnt OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_response';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_response;
    /********************************************************************************************
    * Set Default Hidrics_Device
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_device
    (
        i_lang           IN language.id_language%TYPE,
        o_hidrics_device OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_hidrics_device';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_hidrics_device;
    /********************************************************************************************
    * Set Default Hidrics_Occurs_Type
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION set_def_hidrics_occurs_type
    (
        i_lang                IN language.id_language%TYPE,
        o_hidrics_occurs_type OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_hidrics_occurs_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_hidrics_occurs_type;

    /********************************************************************************************
    * Set Default Graph discrete lab results for Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_discrete_lab_results Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     0.1
    * @since                       2010/08/05
    ********************************************************************************************/
    FUNCTION set_def_discrete_lab_results
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_analysis_parameter IN analysis_parameter.id_analysis_parameter%TYPE,
        o_discrete_lab_results  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_discrete_lab_results';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_discrete_lab_results;
    /********************************************************************************************
    * Set Default Graph discrete lab results Relation for Analysis Parameters
    *
    * @param i_lang                Prefered language ID
    * @param o_discrete_lab_results Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6
    * @since                       2010/08/05
    ********************************************************************************************/
    FUNCTION set_def_discrete_lab_res_rel
    (
        i_lang                     IN language.id_language%TYPE,
        o_discrete_lab_results_rel OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_discrete_lab_res_rel';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_discrete_lab_res_rel;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3
    * @since                       2010/12/07
    ********************************************************************************************/
    FUNCTION get_def_diet_parent
    (
        i_lang                  IN language.id_language%TYPE,
        o_id_content            OUT pk_types.cursor_type,
        o_rank                  OUT pk_types.cursor_type,
        o_diet_type             OUT pk_types.cursor_type,
        o_quantity_default      OUT pk_types.cursor_type,
        o_id_unit_measure       OUT pk_types.cursor_type,
        o_energy_quantity_value OUT pk_types.cursor_type,
        o_id_unit_mea_energy    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_diet_parent';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_diet_parent;
    /********************************************************************************************
    * Set Default Diets
    *
    * @param i_lang                Prefered language ID
    * @param o_diet                Diets
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.3
    * @since                       2010/12/07
    ********************************************************************************************/
    FUNCTION get_def_diet
    (
        i_lang                  IN language.id_language%TYPE,
        o_id_content            OUT pk_types.cursor_type,
        o_rank                  OUT pk_types.cursor_type,
        o_diet_type             OUT pk_types.cursor_type,
        o_quantity_default      OUT pk_types.cursor_type,
        o_id_unit_measure       OUT pk_types.cursor_type,
        o_energy_quantity_value OUT pk_types.cursor_type,
        o_id_unit_mea_energy    OUT pk_types.cursor_type,
        o_id_parent             OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_diet';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_diet;
    /********************************************************************************************
    * Set Checklist_Version set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist           Checklist ID's
    * @param o_id_checklist_version   Cursor of id_checklist_version
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist_version
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_checklist         IN checklist.id_checklist%TYPE,
        o_id_checklist_version OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist_version';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist_version;
    /********************************************************************************************
    * Set Checklist_Clin_Serv set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_checklist_clin_serv    Cursor of Clinical Services
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/07
    ********************************************************************************************/
    FUNCTION set_def_checklist_freq
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_clin_serv             OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist_freq';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist_freq;
    /********************************************************************************************
    * Set Checklist_Prof_Templ set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_checklist_clin_serv    Cursor of Clinical Services
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_prof_templ
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_profile_template      OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist_prof_templ';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist_prof_templ;
    /********************************************************************************************
    * Set Checklist_Item set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_checklist_item      Cursor of Checklist ITEMS
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_item
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_checklist_version_def IN checklist_version.id_checklist_version%TYPE,
        i_id_checklist_version     IN checklist_version.id_checklist_version%TYPE,
        o_id_checklist_item        OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist_item';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist_item;

    /********************************************************************************************
    * Set Checklist_ITEM_Prof_Templ set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_profile_template    Cursor of Profile Template
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_chklst_item_prof_templ
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_checklist_item_def IN checklist_item.id_checklist_item%TYPE,
        i_id_checklist_item     IN checklist_item.id_checklist_item%TYPE,
        o_id_profile_template   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_chklst_item_prof_templ';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_chklst_item_prof_templ;
    /********************************************************************************************
    * Set Checklist_ITEM_Dep set 
    *
    * @param i_lang                   Prefered language ID
    * @param i_market                 Market ID's
    * @param i_id_checklist_version   Checklist_Clin_Serv ID's
    * @param o_id_profile_template    Cursor of Profile Template
    * @param o_error                  Error
    *    
    * @return                         true or false on success or error
    *
    * @author                         MESS
    * @version                        2.6
    * @since                          2010/07/08
    ********************************************************************************************/
    FUNCTION set_def_checklist_item_dep
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_checklist_item_def IN checklist_item.id_checklist_item%TYPE,
        o_id_checklist_item_dep OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_checklist_item_dep';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_checklist_item_dep;
    /********************************************************************************************
    * Get QUESTIONNAIRE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/15
    ********************************************************************************************/
    FUNCTION get_def_questionnaire
    (
        i_lang       IN language.id_language%TYPE,
        o_id_content OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_questionnaire';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_questionnaire;
    /********************************************************************************************
    * Get RESPONSE DEFAULT content universe
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/17
    ********************************************************************************************/
    FUNCTION get_def_response
    (
        i_lang          IN language.id_language%TYPE,
        o_id_content    OUT pk_types.cursor_type,
        o_flg_free_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_response';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_response;
    /********************************************************************************************
    * Get Default Hidrics_Device
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_def_hidrics_device
    (
        i_lang          IN language.id_language%TYPE,
        o_code          OUT pk_types.cursor_type,
        o_id_content    OUT pk_types.cursor_type,
        o_flg_free_text OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_hidrics_device';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_hidrics_device;
    /********************************************************************************************
    * Get Default Hidrics_Occurs_Type
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.5.1.3
    * @since                       2011/01/13
    ********************************************************************************************/
    FUNCTION get_def_hidrics_occurs_type
    (
        i_lang       IN language.id_language%TYPE,
        o_code       OUT pk_types.cursor_type,
        o_id_content OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_hidrics_occurs_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_hidrics_occurs_type;
    /********************************************************************************************
    * Get Default Clinical Services
    *
    * @param i_lang                Prefered language ID
    * @return                      true or false on success or error
    *
    * @author                      MESS
    * @version                     2.6.0.4
    * @since                       2010/11/24
    ********************************************************************************************/
    FUNCTION get_def_clinical_services
    (
        i_lang                    IN language.id_language%TYPE,
        o_id_clinical_service_par OUT pk_types.cursor_type,
        o_id_content              OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_clinical_services';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_clinical_services;
    /********************************************************************************************
    * Set APPOINTMENT set of markets, versions and sotwares
    *
    * @param i_lang                  Language ID
    * @param o_id_clinical_service   Cursor of Clinical Services
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        RMGM
    * @version                       2.6.1.3
    * @since                         2011/09/25
    ********************************************************************************************/
    FUNCTION set_appointments_transl
    (
        i_lang                IN language.id_language%TYPE,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        -- new type to be used
        o_trl_table          t_tab_translation;
        l_module             t_low_char := 'PFH';
        l_def_na_lang        t_med_char := 'NULL';
        l_validation_pattern t_low_char := '^[A-Z_1]+\.[A-Z_1]+\.[-0-9A-Z]+';
        l_table_name         all_tables.table_name%TYPE := 'APPOINTMENT';
        l_table_owner        all_tables.owner%TYPE := 'ALERT' /*get_tbl_ext_owner(i_lang, l_table_name)*/
         ;
        l_count              NUMBER;
    
        l_sql_first t_big_char := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=5000) */ t_rec_translation(def_data.code_translation,
                                         ''' || l_table_owner || ''',
                                         ''' || l_table_owner ||
                                  '.''||def_data.code_translation,
                                         ''' || l_table_name || ''',
                                         ''' || l_module || ''',
                                         def_data.desc_lang_1,
                                         def_data.desc_lang_2,
                                         def_data.desc_lang_3,
                                         def_data.desc_lang_4,
                                         def_data.desc_lang_5,
                                         def_data.desc_lang_6,
                                         def_data.desc_lang_7,
                                         def_data.desc_lang_8,
                                         def_data.desc_lang_9,
                                         def_data.desc_lang_10,
                                         def_data.desc_lang_11,
                                         def_data.desc_lang_12,
                                         def_data.desc_lang_13,
                                         def_data.desc_lang_14,
                                         def_data.desc_lang_15,
                                         def_data.desc_lang_16,
                                         def_data.desc_lang_17,
                                         def_data.desc_lang_18,
                                         def_data.desc_lang_19,
                     def_data.desc_lang_20,
                     def_data.desc_lang_21,
                     def_data.desc_lang_22,
                                         ' || l_def_na_lang || ')
  FROM (';
        l_sql_mid   t_big_char := '';
        l_sql_last  t_big_char := ') def_data
        where regexp_like(def_data.code_translation, ''' || l_validation_pattern ||
                                  ''')';
    
    BEGIN
        g_func_name := upper('set_appointments_transl');
        pk_alertlog.log_info('Set Appointment Translations');
        --> TRANSLATIONS    
        IF i_id_clinical_service IS NULL
        THEN
            l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE cst ROWS=5000) */ ''APPOINTMENT.CODE_APPOINTMENT.'' ||
                   to_char(''APP.'' || to_char(sett.id_sch_event) || ''.'' || to_char(cst.id_clinical_service)) AS code_translation,
                   CASE
                       WHEN sett.desc_lang_1 IS NOT NULL
                            AND cst.desc_lang_1 IS NOT NULL THEN
                        decode(sett.desc_lang_1 || '': '' || cst.desc_lang_1, '': '', NULL, sett.desc_lang_1 || '': '' || cst.desc_lang_1)
                   END desc_lang_1,
                   CASE
                       WHEN sett.desc_lang_2 IS NOT NULL
                            AND cst.desc_lang_2 IS NOT NULL THEN
                        decode(sett.desc_lang_2 || '': '' || cst.desc_lang_2, '': '', NULL, sett.desc_lang_2 || '': '' || cst.desc_lang_2)
                   END desc_lang_2,
                   CASE
                       WHEN sett.desc_lang_3 IS NOT NULL
                            AND cst.desc_lang_3 IS NOT NULL THEN
                        decode(sett.desc_lang_3 || '': '' || cst.desc_lang_3, '': '', NULL, sett.desc_lang_3 || '': '' || cst.desc_lang_3)
                   END desc_lang_3,
                   CASE
                       WHEN sett.desc_lang_4 IS NOT NULL
                            AND cst.desc_lang_4 IS NOT NULL THEN
                        decode(sett.desc_lang_4 || '': '' || cst.desc_lang_4, '': '', NULL, sett.desc_lang_4 || '': '' || cst.desc_lang_4)
                   END desc_lang_4,
                   CASE
                       WHEN sett.desc_lang_5 IS NOT NULL
                            AND cst.desc_lang_5 IS NOT NULL THEN
                        decode(sett.desc_lang_5 || '': '' || cst.desc_lang_5, '': '', NULL, sett.desc_lang_5 || '': '' || cst.desc_lang_5)
                   END desc_lang_5,
                   CASE
                       WHEN sett.desc_lang_6 IS NOT NULL
                            AND cst.desc_lang_6 IS NOT NULL THEN
                        decode(sett.desc_lang_6 || '': '' || cst.desc_lang_6, '': '', NULL, sett.desc_lang_6 || '': '' || cst.desc_lang_6)
                   END desc_lang_6,
                   CASE
                       WHEN sett.desc_lang_7 IS NOT NULL
                            AND cst.desc_lang_7 IS NOT NULL THEN
                        decode(sett.desc_lang_7 || '': '' || cst.desc_lang_7, '': '', NULL, sett.desc_lang_7 || '': '' || cst.desc_lang_7)
                   END desc_lang_7,
                   CASE
                       WHEN sett.desc_lang_8 IS NOT NULL
                            AND cst.desc_lang_8 IS NOT NULL THEN
                        decode(sett.desc_lang_8 || '': '' || cst.desc_lang_8, '': '', NULL, sett.desc_lang_8 || '': '' || cst.desc_lang_8)
                   END desc_lang_8,
                   CASE
                       WHEN sett.desc_lang_9 IS NOT NULL
                            AND cst.desc_lang_9 IS NOT NULL THEN
                        decode(sett.desc_lang_9 || '': '' || cst.desc_lang_9, '': '', NULL, sett.desc_lang_9 || '': '' || cst.desc_lang_9)
                   END desc_lang_9,
                   CASE
                       WHEN sett.desc_lang_10 IS NOT NULL
                            AND cst.desc_lang_10 IS NOT NULL THEN
                        decode(sett.desc_lang_10 || '': '' || cst.desc_lang_10, '': '', NULL, sett.desc_lang_10 || '': '' || cst.desc_lang_10)
                   END desc_lang_10,
                   CASE
                       WHEN sett.desc_lang_11 IS NOT NULL
                            AND cst.desc_lang_11 IS NOT NULL THEN
                        decode(sett.desc_lang_11 || '': '' || cst.desc_lang_11, '': '', NULL, sett.desc_lang_11 || '': '' || cst.desc_lang_11)
                   END desc_lang_11,
                   CASE
                       WHEN sett.desc_lang_12 IS NOT NULL
                            AND cst.desc_lang_12 IS NOT NULL THEN
                        decode(sett.desc_lang_12 || '': '' || cst.desc_lang_12, '': '', NULL, sett.desc_lang_12 || '': '' || cst.desc_lang_12)
                   END desc_lang_12,
                   CASE
                       WHEN sett.desc_lang_13 IS NOT NULL
                            AND cst.desc_lang_13 IS NOT NULL THEN
                        decode(sett.desc_lang_13 || '': '' || cst.desc_lang_13, '': '', NULL, sett.desc_lang_13 || '': '' || cst.desc_lang_13)
                   END desc_lang_13,
                   CASE
                       WHEN sett.desc_lang_14 IS NOT NULL
                            AND cst.desc_lang_14 IS NOT NULL THEN
                        decode(sett.desc_lang_14 || '': '' || cst.desc_lang_14, '': '', NULL, sett.desc_lang_14 || '': '' || cst.desc_lang_14)
                   END desc_lang_14,
                   CASE
                       WHEN sett.desc_lang_15 IS NOT NULL
                            AND cst.desc_lang_15 IS NOT NULL THEN
                        decode(sett.desc_lang_15 || '': '' || cst.desc_lang_15, '': '', NULL, sett.desc_lang_15 || '': '' || cst.desc_lang_15)
                   END desc_lang_15,
                   CASE
                       WHEN sett.desc_lang_16 IS NOT NULL
                            AND cst.desc_lang_16 IS NOT NULL THEN
                        decode(sett.desc_lang_16 || '': '' || cst.desc_lang_16, '': '', NULL, sett.desc_lang_16 || '': '' || cst.desc_lang_16)
                   END desc_lang_16,
                   CASE
                       WHEN sett.desc_lang_17 IS NOT NULL
                            AND cst.desc_lang_17 IS NOT NULL THEN
                        decode(sett.desc_lang_17 || '': '' || cst.desc_lang_17, '': '', NULL, sett.desc_lang_17 || '': '' || cst.desc_lang_17)
                   END desc_lang_17,
                                      CASE
                       WHEN sett.desc_lang_18 IS NOT NULL
                            AND cst.desc_lang_18 IS NOT NULL THEN
                        decode(sett.desc_lang_18 || '': '' || cst.desc_lang_18, '': '', NULL, sett.desc_lang_18 || '': '' || cst.desc_lang_18)
                   END desc_lang_18,
                                      CASE
                       WHEN sett.desc_lang_19 IS NOT NULL
                            AND cst.desc_lang_19 IS NOT NULL THEN
                        decode(sett.desc_lang_19 || '': '' || cst.desc_lang_19, '': '', NULL, sett.desc_lang_19 || '': '' || cst.desc_lang_19)
                   END desc_lang_19
              FROM (SELECT cs.id_clinical_service,
                           cs.code_clinical_service,
                           cs_t.desc_lang_1,
                           cs_t.desc_lang_2,
                           cs_t.desc_lang_3,
                           cs_t.desc_lang_4,
                           cs_t.desc_lang_5,
                           cs_t.desc_lang_6,
                           cs_t.desc_lang_7,
                           cs_t.desc_lang_8,
                           cs_t.desc_lang_9,
                           cs_t.desc_lang_10,
                           cs_t.desc_lang_11,
                           cs_t.desc_lang_12,
                           cs_t.desc_lang_13,
                           cs_t.desc_lang_14,
                           cs_t.desc_lang_15,
                           cs_t.desc_lang_16,
                           cs_t.desc_lang_17,
                           cs_t.desc_lang_18,
                           cs_t.desc_lang_19,
               cs_t.desc_lang_20,
                     cs_t.desc_lang_21,
                     cs_t.desc_lang_22
                      FROM clinical_service cs
                     INNER JOIN translation cs_t
                        ON (cs_t.code_translation = cs.code_clinical_service)
                     WHERE cs.flg_available = ''Y'') cst,
                   (SELECT se.id_sch_event,
                           se.code_sch_event,
                           se_t.desc_lang_1,
                           se_t.desc_lang_2,
                           se_t.desc_lang_3,
                           se_t.desc_lang_4,
                           se_t.desc_lang_5,
                           se_t.desc_lang_6,
                           se_t.desc_lang_7,
                           se_t.desc_lang_8,
                           se_t.desc_lang_9,
                           se_t.desc_lang_10,
                           se_t.desc_lang_11,
                           se_t.desc_lang_12,
                           se_t.desc_lang_13,
                           se_t.desc_lang_14,
                           se_t.desc_lang_15,
                           se_t.desc_lang_16,
                           se_t.desc_lang_17,
                           se_t.desc_lang_18,
                           se_t.desc_lang_19,
               se_t.desc_lang_20,
                     se_t.desc_lang_21,
                     se_t.desc_lang_22
                      FROM sch_event se
                     INNER JOIN translation se_t
                        ON (se_t.code_translation = se.code_sch_event)
                     WHERE se.flg_available = ''Y''
                       AND EXISTS (SELECT 1
                              FROM sch_dep_type sdt
                             WHERE sdt.dep_type = se.dep_type
                               AND sdt.dep_type_group = ''C'')) sett
             WHERE EXISTS
             (SELECT 1
                      FROM appointment a
                     WHERE a.id_clinical_service = cst.id_clinical_service
                       AND a.id_sch_event = sett.id_sch_event
                       AND a.flg_available = ''Y''
                       AND NOT EXISTS (SELECT 1
                              FROM translation ta
                             WHERE ta.code_translation = a.code_appointment
                               AND rownum = 1)
                       AND rownum = 1)';
        
        ELSE
            l_sql_mid := 'SELECT ''APPOINTMENT.CODE_APPOINTMENT.'' ||
                   to_char(''APP.'' || to_char(sett.id_sch_event) || ''.'' || to_char(cst.id_clinical_service)) AS code_translation,
                   CASE
                        WHEN sett.desc_lang_1 IS NOT NULL
                             AND cst.desc_lang_1 IS NOT NULL THEN
                         decode(sett.desc_lang_1 || '': '' || cst.desc_lang_1,
                                '': '',
                                NULL,
                                sett.desc_lang_1 || '': '' || cst.desc_lang_1)
                    END desc_lang_1,
                   CASE
                        WHEN sett.desc_lang_2 IS NOT NULL
                             AND cst.desc_lang_2 IS NOT NULL THEN
                         decode(sett.desc_lang_2 || '': '' || cst.desc_lang_2,
                                '': '',
                                NULL,
                                sett.desc_lang_2 || '': '' || cst.desc_lang_2)
                    END desc_lang_2,
                   CASE
                        WHEN sett.desc_lang_3 IS NOT NULL
                             AND cst.desc_lang_3 IS NOT NULL THEN
                         decode(sett.desc_lang_3 || '': '' || cst.desc_lang_3,
                                '': '',
                                NULL,
                                sett.desc_lang_3 || '': '' || cst.desc_lang_3)
                    END desc_lang_3,
                   CASE
                        WHEN sett.desc_lang_4 IS NOT NULL
                             AND cst.desc_lang_4 IS NOT NULL THEN
                         decode(sett.desc_lang_4 || '': '' || cst.desc_lang_4,
                                '': '',
                                NULL,
                                sett.desc_lang_4 || '': '' || cst.desc_lang_4)
                    END desc_lang_4,
                   CASE
                        WHEN sett.desc_lang_5 IS NOT NULL
                             AND cst.desc_lang_5 IS NOT NULL THEN
                         decode(sett.desc_lang_5 || '': '' || cst.desc_lang_5,
                                '': '',
                                NULL,
                                sett.desc_lang_5 || '': '' || cst.desc_lang_5)
                    END desc_lang_5,
                   CASE
                        WHEN sett.desc_lang_6 IS NOT NULL
                             AND cst.desc_lang_6 IS NOT NULL THEN
                         decode(sett.desc_lang_6 || '': '' || cst.desc_lang_6,
                                '': '',
                                NULL,
                                sett.desc_lang_6 || '': '' || cst.desc_lang_6)
                    END desc_lang_6,
                   CASE
                        WHEN sett.desc_lang_7 IS NOT NULL
                             AND cst.desc_lang_7 IS NOT NULL THEN
                         decode(sett.desc_lang_7 || '': '' || cst.desc_lang_7,
                                '': '',
                                NULL,
                                sett.desc_lang_7 || '': '' || cst.desc_lang_7)
                    END desc_lang_7,
                   CASE
                        WHEN sett.desc_lang_8 IS NOT NULL
                             AND cst.desc_lang_8 IS NOT NULL THEN
                         decode(sett.desc_lang_8 || '': '' || cst.desc_lang_8,
                                '': '',
                                NULL,
                                sett.desc_lang_8 || '': '' || cst.desc_lang_8)
                    END desc_lang_8,
                   CASE
                        WHEN sett.desc_lang_9 IS NOT NULL
                             AND cst.desc_lang_9 IS NOT NULL THEN
                         decode(sett.desc_lang_9 || '': '' || cst.desc_lang_9,
                                '': '',
                                NULL,
                                sett.desc_lang_9 || '': '' || cst.desc_lang_9)
                    END desc_lang_9,
                   CASE
                        WHEN sett.desc_lang_10 IS NOT NULL
                             AND cst.desc_lang_10 IS NOT NULL THEN
                         decode(sett.desc_lang_10 || '': '' || cst.desc_lang_10,
                                '': '',
                                NULL,
                                sett.desc_lang_10 || '': '' || cst.desc_lang_10)
                    END desc_lang_10,
                   CASE
                        WHEN sett.desc_lang_11 IS NOT NULL
                             AND cst.desc_lang_11 IS NOT NULL THEN
                         decode(sett.desc_lang_11 || '': '' || cst.desc_lang_11,
                                '': '',
                                NULL,
                                sett.desc_lang_11 || '': '' || cst.desc_lang_11)
                    END desc_lang_11,
                   CASE
                        WHEN sett.desc_lang_12 IS NOT NULL
                             AND cst.desc_lang_12 IS NOT NULL THEN
                         decode(sett.desc_lang_12 || '': '' || cst.desc_lang_12,
                                '': '',
                                NULL,
                                sett.desc_lang_12 || '': '' || cst.desc_lang_12)
                    END desc_lang_12,
                   CASE
                        WHEN sett.desc_lang_13 IS NOT NULL
                             AND cst.desc_lang_13 IS NOT NULL THEN
                         decode(sett.desc_lang_13 || '': '' || cst.desc_lang_13,
                                '': '',
                                NULL,
                                sett.desc_lang_13 || '': '' || cst.desc_lang_13)
                    END desc_lang_13,
                   CASE
                        WHEN sett.desc_lang_14 IS NOT NULL
                             AND cst.desc_lang_14 IS NOT NULL THEN
                         decode(sett.desc_lang_14 || '': '' || cst.desc_lang_14,
                                '': '',
                                NULL,
                                sett.desc_lang_14 || '': '' || cst.desc_lang_14)
                    END desc_lang_14,
                   CASE
                        WHEN sett.desc_lang_15 IS NOT NULL
                             AND cst.desc_lang_15 IS NOT NULL THEN
                         decode(sett.desc_lang_15 || '': '' || cst.desc_lang_15,
                                '': '',
                                NULL,
                                sett.desc_lang_15 || '': '' || cst.desc_lang_15)
                    END desc_lang_15,
                   CASE
                        WHEN sett.desc_lang_16 IS NOT NULL
                             AND cst.desc_lang_16 IS NOT NULL THEN
                         decode(sett.desc_lang_16 || '': '' || cst.desc_lang_16,
                                '': '',
                                NULL,
                                sett.desc_lang_16 || '': '' || cst.desc_lang_16)
                    END desc_lang_16,
                   CASE
                        WHEN sett.desc_lang_17 IS NOT NULL
                             AND cst.desc_lang_17 IS NOT NULL THEN
                         decode(sett.desc_lang_17 || '': '' || cst.desc_lang_17,
                                '': '',
                                NULL,
                                sett.desc_lang_17 || '': '' || cst.desc_lang_17)
                    END desc_lang_17,
                    CASE
                        WHEN sett.desc_lang_18 IS NOT NULL
                             AND cst.desc_lang_18 IS NOT NULL THEN
                         decode(sett.desc_lang_18 || '': '' || cst.desc_lang_18,
                                '': '',
                                NULL,
                                sett.desc_lang_18 || '': '' || cst.desc_lang_18)
                    END desc_lang_18,
                    CASE
                        WHEN sett.desc_lang_19 IS NOT NULL
                             AND cst.desc_lang_19 IS NOT NULL THEN
                         decode(sett.desc_lang_19 || '': '' || cst.desc_lang_19,
                                '': '',
                                NULL,
                                sett.desc_lang_19 || '': '' || cst.desc_lang_19)
                    END desc_lang_19,
          CASE
                        WHEN sett.desc_lang_20 IS NOT NULL
                             AND cst.desc_lang_20 IS NOT NULL THEN
                         decode(sett.desc_lang_20 || '': '' || cst.desc_lang_20,
                                '': '',
                                NULL,
                                sett.desc_lang_20 || '': '' || cst.desc_lang_20)
                    END desc_lang_20,
          CASE
                        WHEN sett.desc_lang_21 IS NOT NULL
                             AND cst.desc_lang_21 IS NOT NULL THEN
                         decode(sett.desc_lang_21 || '': '' || cst.desc_lang_21,
                                '': '',
                                NULL,
                                sett.desc_lang_21 || '': '' || cst.desc_lang_21)
                    END desc_lang_21,
          CASE
                        WHEN sett.desc_lang_22 IS NOT NULL
                             AND cst.desc_lang_22 IS NOT NULL THEN
                         decode(sett.desc_lang_22 || '': '' || cst.desc_lang_22,
                                '': '',
                                NULL,
                                sett.desc_lang_22 || '': '' || cst.desc_lang_22)
                    END desc_lang_22
              FROM (SELECT cs.id_clinical_service,
                           cs.code_clinical_service,
                           cs_t.desc_lang_1,
                           cs_t.desc_lang_2,
                           cs_t.desc_lang_3,
                           cs_t.desc_lang_4,
                           cs_t.desc_lang_5,
                           cs_t.desc_lang_6,
                           cs_t.desc_lang_7,
                           cs_t.desc_lang_8,
                           cs_t.desc_lang_9,
                           cs_t.desc_lang_10,
                           cs_t.desc_lang_11,
                           cs_t.desc_lang_12,
                           cs_t.desc_lang_13,
                           cs_t.desc_lang_14,
                           cs_t.desc_lang_15,
                           cs_t.desc_lang_16,
                           cs_t.desc_lang_17,
                           cs_t.desc_lang_18,
                           cs_t.desc_lang_19,
               cs_t.desc_lang_20,
               cs_t.desc_lang_21,
               cs_t.desc_lang_22
                      FROM clinical_service cs
                     INNER JOIN translation cs_t
                        ON (cs_t.code_translation = cs.code_clinical_service)
                     WHERE cs.flg_available = ''Y''
                           AND cs.id_clinical_service = ' || i_id_clinical_service ||
                         ') cst,
                   (SELECT se.id_sch_event,
                           se.code_sch_event,
                           se_t.desc_lang_1,
                           se_t.desc_lang_2,
                           se_t.desc_lang_3,
                           se_t.desc_lang_4,
                           se_t.desc_lang_5,
                           se_t.desc_lang_6,
                           se_t.desc_lang_7,
                           se_t.desc_lang_8,
                           se_t.desc_lang_9,
                           se_t.desc_lang_10,
                           se_t.desc_lang_11,
                           se_t.desc_lang_12,
                           se_t.desc_lang_13,
                           se_t.desc_lang_14,
                           se_t.desc_lang_15,
                           se_t.desc_lang_16,
                           se_t.desc_lang_17,
                           se_t.desc_lang_18,
                           cs_t.desc_lang_19,
               cs_t.desc_lang_20,
               cs_t.desc_lang_21,
               cs_t.desc_lang_22
                      FROM sch_event se
                     INNER JOIN translation se_t
                        ON (se_t.code_translation = se.code_sch_event)
                     WHERE se.flg_available = ''Y''
                       AND EXISTS (SELECT 1
                              FROM sch_dep_type sdt
                             WHERE sdt.dep_type = se.dep_type
                               AND sdt.dep_type_group = ''C'')) sett
             WHERE EXISTS
             (SELECT 0
                      FROM appointment a
                     WHERE a.id_clinical_service = cst.id_clinical_service
                       AND a.id_sch_event = sett.id_sch_event
                       AND a.flg_available = ''Y''
                       AND NOT EXISTS (SELECT 0
                              FROM translation ta
                             WHERE ta.code_translation = a.code_appointment))';
        END IF;
        EXECUTE IMMEDIATE l_sql_first || l_sql_mid || l_sql_last BULK COLLECT
            INTO o_trl_table;
        l_count := pk_translation.ins_bulk_translation(o_trl_table);
        pk_alertlog.log_info('Appointments Translations = ' || o_trl_table.count || ' Records');
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_appointments_transl;
    /*********************************************************************************************
    * Set SET_APPOINTMENTS Value for a specific institution
    *
    * @param i_lang                    Prefered language ID   
    * @param i_id_institution          Institution ID
    * @param o_appointments            Cursor of APPOINTMENTS
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          MESS
    * @version                         2.6.0.4
    * @since                           2010/10/19
    ********************************************************************************************/
    FUNCTION set_appointments
    (
        i_lang                IN language.id_language%TYPE,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_appointments        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_appointments';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_appointments;
    /********************************************************************************************
    * Check APPOINTMENT set of markets, versions and softwares
    *
    * @param i_id_institution        Institution ID
    * @param o_id_sch_event          Cursor of Scheduler Events
    * @param o_id_clinical_service   Cursor of Clinical Services
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    *
    * @author                        MESS
    * @version                       2.6.0.4
    * @since                         2010/10/19
    ********************************************************************************************/
    FUNCTION get_appointments
    (
        i_lang                IN language.id_language%TYPE DEFAULT 2,
        i_id_clinical_service IN appointment.id_clinical_service%TYPE DEFAULT NULL,
        o_id_sch_event        OUT pk_types.cursor_type,
        o_id_clinical_service OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_appointments';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_appointments;

    /********************************************************************************************
    * GET Default Habits Characterization
    *
    * @param i_lang                Prefered language ID
    * @param o_habits_charact      Habit characterization array
    * @param o_hc_id_content       Habit characterization id_content array
    * @param o_hc_rank             Habit characterization rank array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/12
    ********************************************************************************************/
    FUNCTION get_def_habit_charact
    (
        i_lang           IN language.id_language%TYPE,
        o_habits_charact OUT table_number,
        o_hc_id_content  OUT table_varchar,
        o_hc_rank        OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_habit_charact';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_habit_charact;
    /********************************************************************************************
    * Set Default Habits
    *
    * @param i_lang                Prefered language ID
    * @param o_habits_charact      Habit Characterization ids array
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2011/04/12
    ********************************************************************************************/
    FUNCTION set_def_habits_charact
    (
        i_lang           IN language.id_language%TYPE,
        o_habits_charact OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_habits_charact';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_habits_charact;
    /********************************************************************************************
    * Get Default isencao
    *
    * @param i_lang                Prefered language ID
    * @param o_isencao              Isencao
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/05/04
    ********************************************************************************************/

    FUNCTION get_def_isencao
    (
        i_lang          IN language.id_language%TYPE,
        o_isencao       OUT table_number,
        o_is_rank       OUT table_number,
        o_is_gender     OUT table_varchar,
        o_is_agemax     OUT table_number,
        o_is_agemin     OUT table_number,
        o_is_id_content OUT table_varchar,
        o_is_status     OUT table_varchar,
        o_is_impcode    OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_isencao';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_isencao;
    /********************************************************************************************
    * Set Default isencao
    *
    * @param i_lang                Prefered language ID
    * @param o_isencao              Isencao
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1
    * @since                       2011/05/04
    ********************************************************************************************/

    FUNCTION set_def_isencao
    (
        i_lang    IN language.id_language%TYPE,
        o_isencao OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_isencao';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_isencao;
    /********************************************************************************************
    * Get the list of supply types
    *
    * @param i_lang                Prefered language ID
    * @param o_id_content          Cursor of default data
    * @param o_code_supply_type    Cursor of default data
    * @param o_id_parent           Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     v2.6.1.5
    * @since                       2011/11/04
    ********************************************************************************************/
    FUNCTION get_supply_type
    (
        i_lang       IN language.id_language%TYPE,
        i_level      IN NUMBER,
        o_id_content OUT pk_types.cursor_type,
        o_id_parent  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_supply_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_supply_type;
    /********************************************************************************************
    * Set supplies types.
    *
    * @param i_lang                    Prefered language ID
    * @param o_code_supply_type        Cursor of supplies types codes
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply_type
    (
        i_lang        IN language.id_language%TYPE,
        o_supply_type OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_supply_type';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_supply_type;
    /********************************************************************************************
    * Get a list of default supplies.
    *
    * @param i_lang                Prefered language ID
    * @param o_id_content          Cursor of default data
    * @param o_id_supply_type      Cursor of default data
    * @param o_flg_type            Cursor of default data
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           07-NOV-2011
    ********************************************************************************************/
    FUNCTION get_supply
    (
        i_lang           IN language.id_language%TYPE,
        o_id_content     OUT pk_types.cursor_type,
        o_id_supply_type OUT pk_types.cursor_type,
        o_flg_type       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_supply';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_supply;
    /********************************************************************************************
    * Set supplies for a specific market.
    *
    * @param i_lang                    Prefered language ID
    * @param o_supply                  Cursor of supplies
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           08-NOV-2011
    ********************************************************************************************/
    FUNCTION set_supply
    (
        i_lang   IN language.id_language%TYPE,
        o_supply OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_supply';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_supply;
    /********************************************************************************************
    * Get Default Content from Result Notes Area (Default)
    *
    * @param i_lang                Prefered language ID
    * @param o_resnt               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2012/04/19
    ********************************************************************************************/
    FUNCTION get_def_result_notes
    (
        i_lang  IN language.id_language%TYPE,
        o_resnt OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_result_notes';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_result_notes;
    /********************************************************************************************
    * Set Default Content on Result Notes Area (Exams)
    *
    * @param i_lang                Prefered language ID
    * @param o_resnt               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2012/04/19
    ********************************************************************************************/
    FUNCTION set_def_result_notes
    (
        i_lang  IN language.id_language%TYPE,
        o_resnt OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_result_notes';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_result_notes;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Sample Type Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labst               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_st
    (
        i_lang  IN language.id_language%TYPE,
        o_labst OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_analysis_st';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_analysis_st;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Body Structure Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labbs               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_bs
    (
        i_lang  IN language.id_language%TYPE,
        o_labbs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_analysis_bs';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_analysis_bs;
    /********************************************************************************************
    * Get Default Configuration on Analysis and Complaint Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labcmpl             Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION get_def_analysis_complaint
    (
        i_lang    IN language.id_language%TYPE,
        o_labcmpl OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_analysis_complaint';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_analysis_complaint;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Sample Type Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labst               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_st
    (
        i_lang  IN language.id_language%TYPE,
        o_labst OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_st';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_st;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Body Structure Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labbs               Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_bs
    (
        i_lang  IN language.id_language%TYPE,
        o_labbs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_bs';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_bs;
    /********************************************************************************************
    * Set Default Configuration on Analysis and Complaint Relation 
    *
    * @param i_lang                Prefered language ID
    * @param o_labcmpl             Cursor with default content details
    * @param o_error               Error  Messages
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/03
    ********************************************************************************************/
    FUNCTION set_def_analysis_complaint
    (
        i_lang    IN language.id_language%TYPE,
        o_labcmpl OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_complaint';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_complaint;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_sr_interv_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_sr_interv_codif';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_sr_interv_codif;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_diag_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_diag_codif';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_diag_codif;
    /********************************************************************************************
    * Configuration of Diagnosis and codification relation
    *
    * @param i_lang                  Language id
    * @param o_result                Number of results configured
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2012/12/13
    * @version                       2.6.1.14
    ********************************************************************************************/
    FUNCTION set_extcause_codif
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_extcause_codif';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_extcause_codif;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_flg_mcdts             array with mcdt type classification
    * @param o_flg_natures           array with mcdt nature flg nature
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/22
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION get_def_mcdt_nature
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_mcdt_nature';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_mcdt_nature;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION set_def_mcdt_nature
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_mcdt_nature';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_mcdt_nature;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_flg_mcdts             array with mcdt type classification
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION get_def_mcdt_nisencao
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.get_def_mcdt_nisencao';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END get_def_mcdt_nisencao;
    /********************************************************************************************
    * Returns True or False 
    *
    * @param i_lang                  Language id
    * @param o_mcdts                 array with mcdt ids
    * @param o_error                 error message
    *
    * @return                        true (sucess), false (error)
    *
    * @author                        RMGM
    * @since                         2011/08/24
    * @version                       2.5.1.5
    ********************************************************************************************/
    FUNCTION set_def_mcdt_nisencao
    (
        i_lang  IN language.id_language%TYPE,
        o_mcdts OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_mcdt_nisencao';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_mcdt_nisencao;
    /********************************************************************************************
    * Set Default Intervention relation with Body structures and laterality definition
    *
    * @param i_lang                Prefered language ID
    * @param o_result_tbl          number of records inserted
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/07/24
    ********************************************************************************************/
    FUNCTION set_def_interv_body_structure
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_interv_body_structure';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_interv_body_structure;
    /********************************************************************************************
    * Get alert default event id by receiving alert event id
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_event            Alert event id
    *
    * @return                      returns alert default id event by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_def_event_id
    (
        i_lang     IN language.id_language%TYPE,
        i_id_event IN periodic_observation_param.id_event%TYPE
    ) RETURN NUMBER IS
        l_def_event_id event.id_event%TYPE := NULL;
        o_error        t_error_out;
    BEGIN
        g_func_name := upper('get_def_event_id');
        g_error     := 'FETCHING DEFAULT EVENT ID FOR ' || i_id_event;
        SELECT (SELECT def_tbl.id_event
                FROM   (SELECT decode(e.flg_group,
                                      NULL,
                                      NULL,
                                      'A',
                                      nvl((SELECT def_a.id_analysis
                                          FROM   alert_default.analysis def_a
                                          INNER  JOIN analysis ext_a
                                          ON     (ext_a.id_content = def_a.id_content AND
                                                 ext_a.flg_available = g_flg_available)
                                          WHERE  def_a.flg_available = g_flg_available
                                                 AND ext_a.id_analysis = e.id_group),
                                          0),
                                      'H',
                                      nvl((SELECT def_h.id_habit
                                          FROM   alert_default.habit def_h
                                          INNER  JOIN habit ext_h
                                          ON     (ext_h.id_content = def_h.id_content AND
                                                 ext_h.flg_available = g_flg_available)
                                          WHERE  def_h.flg_available = g_flg_available
                                                 AND ext_h.id_habit = e.id_group),
                                          0),
                                      'I',
                                      nvl((SELECT def_e.id_exam
                                          FROM   alert_default.exam def_e
                                          INNER  JOIN exam ext_e
                                          ON     (ext_e.id_content = def_e.id_content AND
                                                 ext_e.flg_available = g_flg_available)
                                          WHERE  def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'I'
                                                 AND ext_e.id_exam = e.id_group),
                                          0),
                                      'E',
                                      nvl((SELECT def_e.id_exam
                                          FROM   alert_default.exam def_e
                                          INNER  JOIN exam ext_e
                                          ON     (ext_e.id_content = def_e.id_content AND
                                                 ext_e.flg_available = g_flg_available)
                                          WHERE  def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'E'
                                                 AND ext_e.id_exam = e.id_group),
                                          0),
                                      e.id_group) id_group,
                               e.flg_group,
                               e.id_event_group
                        FROM   event e
                        WHERE  e.id_event = i_id_event) res_tbl
                JOIN   alert_default.event def_tbl
                ON     (def_tbl.flg_group = res_tbl.flg_group AND def_tbl.id_event_group = res_tbl.id_event_group AND
                       (def_tbl.id_group = res_tbl.id_group OR (def_tbl.id_group IS NULL AND res_tbl.id_group IS NULL))))
        INTO   l_def_event_id
        FROM   dual
        WHERE  rownum = 1;
    
        RETURN l_def_event_id;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              g_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_def_event_id;
    /********************************************************************************************
    * Get alert default periodic_observation id by unique properties of equivalent id in ALERT
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_content          Alert periodic_observation id content
    * @param i_id_clinical_service Alert periodic_observation clinical service id
    * @param i_id_software         Alert periodic_observation software id
    * @param i_id_event            Alert periodic_observation event id
    * @param i_id_institution      Alert periodic_observation institution id
    *
    * @return                      returns alert default id periodic observation by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_def_periodic_obs_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_content          IN periodic_observation_param.id_content%TYPE,
        i_id_clinical_service IN periodic_observation_param.id_clinical_service%TYPE,
        i_id_software         IN periodic_observation_param.id_software%TYPE,
        i_id_event            IN periodic_observation_param.id_event%TYPE,
        i_id_institution      IN periodic_observation_param.id_institution%TYPE
    ) RETURN NUMBER IS
        l_id_pop periodic_observation_param.id_periodic_observation_param%TYPE := NULL;
        -- auxiliar conversion vars
        l_clinical_service_id clinical_service.id_clinical_service%TYPE := NULL;
    
        l_def_event_id event.id_event%TYPE := NULL;
        l_market_id    market.id_market%TYPE := NULL;
        o_error        t_error_out;
    BEGIN
        g_error := 'GET MARKET ID FOR INSTITUTION ' || i_id_institution;
        pk_alertlog.log_info(g_error);
        l_market_id := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_id_institution);
        -- convert clinical service id
        IF i_id_clinical_service IS NOT NULL
        THEN
            g_error := 'GET DEFAULT CLINICAL SERVICE ID FOR ' || i_id_clinical_service;
            pk_alertlog.log_info(g_error);
            SELECT nvl((SELECT def_cs.id_clinical_service
                       FROM   alert_default.clinical_service def_cs
                       INNER  JOIN clinical_service ext_cs
                       ON     (ext_cs.id_content = def_cs.id_content AND ext_cs.flg_available = g_flg_available)
                       WHERE  def_cs.flg_available = g_flg_available
                              AND ext_cs.id_clinical_service = i_id_clinical_service),
                       0)
            INTO   l_clinical_service_id
            FROM   dual;
        ELSE
            l_clinical_service_id := NULL;
        END IF;
        -- get_event details and convert event id
        IF i_id_event IS NOT NULL
        THEN
            g_error := 'GET DEFAULT EVENT ID FOR ' || i_id_event;
            pk_alertlog.log_info(g_error);
            l_def_event_id := get_def_event_id(i_lang, i_id_event);
        ELSE
            l_def_event_id := NULL;
        END IF;
        g_func_name := upper('get_def_periodic_obs_id');
        -- fetch result
        IF ((l_def_event_id != 0 OR l_def_event_id IS NULL) AND
           (l_clinical_service_id != 0 OR l_clinical_service_id IS NULL) AND l_market_id IS NOT NULL)
        THEN
            g_error := 'GET DEFAULT PERIODIC OBSERVATION ID FOR ' || l_def_event_id || ',' || i_id_software || ',' ||
                       i_id_content || ',' || l_market_id || ',' || l_clinical_service_id;
            pk_alertlog.log_info(g_error);
            SELECT nvl((SELECT pop.id_periodic_observation_param
                       FROM   alert_default.periodic_observation_param pop
                       WHERE  pop.flg_available = g_flg_available
                              AND pop.id_software = i_id_software
                              AND pop.id_content = i_id_content
                              AND pop.id_market = l_market_id
                              AND (pop.id_clinical_service = l_clinical_service_id OR
                              (pop.id_clinical_service IS NULL AND l_clinical_service_id IS NULL))
                              AND (pop.id_event = l_def_event_id OR (pop.id_event IS NULL AND l_def_event_id IS NULL))
                              AND rownum = 1),
                       0)
            INTO   l_id_pop
            FROM   dual;
        ELSE
            l_id_pop := 0;
        END IF;
        RETURN l_id_pop;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              g_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_def_periodic_obs_id;
    /********************************************************************************************
    * Get alert event id by receiving alert default event id
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_event            Alert DEFAULT event id
    *
    * @return                      returns alert id event by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_alert_event_id
    (
        i_lang     IN language.id_language%TYPE,
        i_id_event IN periodic_observation_param.id_event%TYPE
    ) RETURN NUMBER IS
        l_def_event_id event.id_event%TYPE := NULL;
        o_error        t_error_out;
    BEGIN
        g_func_name := upper('get_alert_event_id');
        g_error     := 'GET EVENT ID FOR ' || i_id_event;
        pk_alertlog.log_info(g_error);
        SELECT (SELECT ext_tbl.id_event
                FROM   (SELECT decode(e.flg_group,
                                      'A',
                                      nvl((SELECT ext_a.id_analysis
                                          FROM   alert_default.analysis def_a
                                          INNER  JOIN analysis ext_a
                                          ON     (ext_a.id_content = def_a.id_content AND
                                                 ext_a.flg_available = g_flg_available)
                                          WHERE  def_a.flg_available = g_flg_available
                                                 AND def_a.id_analysis = e.id_group),
                                          0),
                                      'H',
                                      nvl((SELECT ext_h.id_habit
                                          FROM   alert_default.habit def_h
                                          INNER  JOIN habit ext_h
                                          ON     (ext_h.id_content = def_h.id_content AND
                                                 ext_h.flg_available = g_flg_available)
                                          WHERE  def_h.flg_available = g_flg_available
                                                 AND def_h.id_habit = e.id_group),
                                          0),
                                      'I',
                                      nvl((SELECT ext_e.id_exam
                                          FROM   alert_default.exam def_e
                                          INNER  JOIN exam ext_e
                                          ON     (ext_e.id_content = def_e.id_content AND
                                                 ext_e.flg_available = g_flg_available)
                                          WHERE  def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'I'
                                                 AND def_e.id_exam = e.id_group),
                                          0),
                                      'E',
                                      nvl((SELECT ext_e.id_exam
                                          FROM   alert_default.exam def_e
                                          INNER  JOIN exam ext_e
                                          ON     (ext_e.id_content = def_e.id_content AND
                                                 ext_e.flg_available = g_flg_available)
                                          WHERE  def_e.flg_available = g_flg_available
                                                 AND def_e.flg_type = 'E'
                                                 AND def_e.id_exam = e.id_group),
                                          0),
                                      e.id_group) id_group,
                               e.flg_group,
                               e.id_event_group
                        FROM   alert_default.event e
                        WHERE  e.id_event = i_id_event) res_tbl
                JOIN   event ext_tbl
                ON     (ext_tbl.flg_group = res_tbl.flg_group AND ext_tbl.id_event_group = res_tbl.id_event_group AND
                       (ext_tbl.id_group = res_tbl.id_group OR (ext_tbl.id_group IS NULL AND res_tbl.id_group IS NULL))))
        INTO   l_def_event_id
        FROM   dual
        WHERE  rownum = 1;
    
        RETURN l_def_event_id;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              g_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_alert_event_id;
    /********************************************************************************************
    * Get alert periodic_observation id by unique properties of equivalent id in ALERT default
    *
    * @param i_lang                Prefered language ID (only used in when logging)
    * @param i_id_content          Alert default periodic_observation id content
    * @param i_id_clinical_service Alert default periodic_observation clinical service id
    * @param i_id_software         Alert default periodic_observation software id
    * @param i_id_event            Alert default periodic_observation event id
    * @param i_id_institution      Alert default periodic_observation market id
    *
    * @return                      returns alert id periodic observation by matching record
    *
    * @author                      RMGM
    * @version                     2.6.1.8
    * @since                       2012/05/09
    ********************************************************************************************/
    FUNCTION get_alert_periodic_obs_id
    (
        i_lang                IN language.id_language%TYPE,
        i_id_content          IN periodic_observation_param.id_content%TYPE,
        i_id_clinical_service IN periodic_observation_param.id_clinical_service%TYPE,
        i_id_software         IN periodic_observation_param.id_software%TYPE,
        i_id_event            IN periodic_observation_param.id_event%TYPE,
        i_id_market           IN institution.id_market%TYPE
    ) RETURN NUMBER IS
        l_id_pop periodic_observation_param.id_periodic_observation_param%TYPE := NULL;
        -- auxiliar conversion vars
        l_clinical_service_id clinical_service.id_clinical_service%TYPE := NULL;
    
        l_def_event_id event.id_event%TYPE := NULL;
        o_error        t_error_out;
    BEGIN
        -- convert clinical service id
        IF i_id_clinical_service IS NOT NULL
        THEN
            g_error := 'GET CLINICAL SERVICE ID FOR ' || i_id_clinical_service;
            pk_alertlog.log_info(g_error);
            SELECT nvl((SELECT ext_cs.id_clinical_service
                       FROM   alert_default.clinical_service def_cs
                       INNER  JOIN clinical_service ext_cs
                       ON     (ext_cs.id_content = def_cs.id_content AND ext_cs.flg_available = g_flg_available)
                       WHERE  def_cs.flg_available = g_flg_available
                              AND def_cs.id_clinical_service = i_id_clinical_service),
                       0)
            INTO   l_clinical_service_id
            FROM   dual;
        ELSE
            l_clinical_service_id := NULL;
        END IF;
    
        -- get_event details and convert event id
        IF i_id_event IS NOT NULL
        THEN
            g_error := 'GET ALERT EVENT ID FOR ' || i_id_event;
            pk_alertlog.log_info(g_error);
            l_def_event_id := get_alert_event_id(i_lang, i_id_event);
        ELSE
            l_def_event_id := NULL;
        END IF;
        g_func_name := upper('get_alert_periodic_obs_id');
        -- fetch result
        IF ((l_def_event_id != 0 OR l_def_event_id IS NULL) AND
           (l_clinical_service_id != 0 OR l_clinical_service_id IS NULL))
        THEN
            g_error := 'GET ALERT PERIODIC OBSERVATION ID FOR ' || l_def_event_id || ',' || i_id_software || ',' ||
                       i_id_content || ',' || i_id_market || ',' || l_clinical_service_id;
            pk_alertlog.log_info(g_error);
            SELECT nvl((SELECT pop.id_periodic_observation_param
                       FROM   periodic_observation_param pop
                       WHERE  pop.flg_available = g_flg_available
                              AND pop.id_software = i_id_software
                              AND pop.id_content = i_id_content
                              AND nvl(pk_utils.get_institution_market(i_lang, pop.id_institution), 0) = i_id_market
                              AND (pop.id_clinical_service = l_clinical_service_id OR
                              (pop.id_clinical_service IS NULL AND l_clinical_service_id IS NULL))
                              AND (pop.id_event = l_def_event_id OR (pop.id_event IS NULL AND l_def_event_id IS NULL))
                              AND rownum = 1),
                       0)
            INTO   l_id_pop
            FROM   dual;
        ELSE
            l_id_pop := 0;
        END IF;
        RETURN l_id_pop;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_owner,
                                              g_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
    END get_alert_periodic_obs_id;
    /********************************************************************************************
      * Set Default calculators for Analysis parameters
    *
    * @param i_lang                   Prefered language ID
    * @param o_analysis_res_calc      Analysis calculations
    * @param o_error                  Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     2.6.1.14
    * @since                       2012/02/28
    ********************************************************************************************/
    FUNCTION set_def_analysis_res_calcs
    (
        i_lang              IN language.id_language%TYPE,
        o_analysis_res_calc OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_res_calcs';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_res_calcs;
    /********************************************************************************************
    * Set Default calculators for Analysis results
    *
    * @param i_lang                Prefered language ID
    * @param o_analysis_res_par_calc Analysis Parameters
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      LCRS
    * @version                     2.6.1.14
    * @since                       2012/02/29
    ********************************************************************************************/
    FUNCTION set_def_analysis_res_par_calcs
    (
        i_lang                  IN language.id_language%TYPE,
        o_analysis_res_par_calc OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_function_name VARCHAR2(200) := 'pk_default_content.set_def_analysis_res_par_calcs';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_def_analysis_res_par_calcs;
    /********************************************************************************************
    * Set Default Exam Complaint association
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
    * @since                       2013/05/16
    ********************************************************************************************/
    FUNCTION load_exam_complaint_def
    (
        i_lang       IN language.id_language%TYPE,
        o_result_tbl OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.load_exam_complaint_def';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END load_exam_complaint_def;
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
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
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_intervplan_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_intervplan_def';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_intervplan_def;
    /********************************************************************************************
    * Set Default Interv Plan content Social Worker
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
    * @since                       2013/05/17
    ********************************************************************************************/
    FUNCTION set_taksgoal_def
    (
        i_lang   IN language.id_language%TYPE,
        o_result OUT NUMBER,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name VARCHAR2(200) := 'pk_default_content.set_taksgoal_def';
    BEGIN
    
        g_error := k_function_name ||
                   ' Method No longer in use please check documentation in order to user new engine methods';
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        RETURN TRUE;
    
    END set_taksgoal_def;
    /********************************************************************************************
    * Decode Task by id task type
    *
    * @param i_lang                Prefered language ID
    * @param i_task_id             Task ID
    * @param i_task_type           Task Type Id
    *
    *
    * @return                      Decoded destination task id
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/01/16
    ********************************************************************************************/
    FUNCTION get_dest_task_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_task_id   IN icnp_task_composition.id_task%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN NUMBER IS
        -- tasks supported by 
        l_id_tt_labtest   task_type.id_task_type%TYPE := 11;
        l_id_tt_procedure task_type.id_task_type%TYPE := 43;
        l_id_tt_oexam     task_type.id_task_type%TYPE := 8;
        l_id_tt_monit     task_type.id_task_type%TYPE := 9;
        l_id_tt_sr_proc   task_type.id_task_type%TYPE := 27;
        l_id_tt_hidric    task_type.id_task_type%TYPE := 47;
        l_id_tt_posit     task_type.id_task_type%TYPE := 48;
        l_id_tt_rehab     task_type.id_task_type%TYPE := 50;
    
        o_dest_task_id NUMBER := 0;
        l_error        t_error_out;
    BEGIN
    
        IF i_task_type = l_id_tt_labtest
        THEN
            SELECT nvl((SELECT a.id_analysis
                       FROM   analysis a
                       INNER  JOIN alert_default.analysis def_a
                       ON     (def_a.id_content = a.id_content AND def_a.flg_available = g_flg_available)
                       WHERE  a.flg_available = g_flg_available
                              AND def_a.id_analysis = i_task_id),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_procedure
        THEN
            SELECT nvl((SELECT i.id_intervention
                       FROM   intervention i
                       INNER  JOIN alert_default.intervention def_i
                       ON     (def_i.id_content = i.id_content AND def_i.flg_status = 'A')
                       WHERE  i.flg_status = 'A'
                              AND def_i.id_intervention = i_task_id),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_oexam
        THEN
            SELECT nvl((SELECT e.id_exam
                       FROM   exam e
                       INNER  JOIN alert_default.exam def_e
                       ON     (def_e.id_content = e.id_content AND def_e.flg_available = g_flg_available)
                       WHERE  e.flg_available = g_flg_available
                              AND e.flg_type = 'E'
                              AND def_e.id_exam = i_task_id),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_monit
        THEN
            SELECT nvl((SELECT vs.id_vital_sign
                       FROM   vital_sign vs
                       WHERE  vs.id_vital_sign = i_task_id
                              AND vs.flg_available = g_flg_available),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_hidric
        THEN
            SELECT nvl((SELECT h.id_hidrics
                       FROM   hidrics h
                       INNER  JOIN alert_default.hidrics def_h
                       ON     (def_h.id_content = h.id_content AND def_h.flg_available = g_flg_available)
                       WHERE  h.flg_available = g_flg_available
                              AND def_h.id_hidrics = i_task_id),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_posit
        THEN
            SELECT nvl((SELECT p.id_positioning
                       FROM   positioning p
                       INNER  JOIN alert_default.positioning def_p
                       ON     (def_p.id_content = p.id_content AND def_p.flg_available = g_flg_available)
                       WHERE  def_p.id_positioning = i_task_id
                              AND p.flg_available = g_flg_available),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        ELSIF i_task_type = l_id_tt_rehab
        THEN
            SELECT nvl((SELECT i.id_intervention
                       FROM   intervention i
                       INNER  JOIN alert_default.intervention def_i
                       ON     (def_i.id_content = i.id_content AND def_i.flg_status = 'A')
                       WHERE  i.flg_status = 'A'
                              AND def_i.id_intervention = i_task_id),
                       0)
            INTO   o_dest_task_id
            FROM   dual;
        END IF;
        RETURN o_dest_task_id;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_BACKOFFICE_DEFAULT',
                                              'GET_DEST_TASK_BY_TYPE',
                                              l_error);
            RETURN 0;
    END get_dest_task_by_type;
    /********************************************************************************************
    * Get number of levels in child relationship in supply_type
    *
    * @param i_table_name              table being processed
    * @param o_level_array             Array of levels in configuration
    * @param o_error                   Error
    *
    * @return                          true or false on success or error
    *
    * @author                          RMGM
    * @version                         v2.6.1.5
    * @since                           07-NOV-2011
    ********************************************************************************************/
    FUNCTION get_table_levels
    (
        i_lang        IN language.id_language%TYPE,
        i_table_name  IN all_objects.object_name%TYPE,
        o_level_array OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_func_name := upper('get_table_levels');
        IF i_table_name = 'SUPPLY_TYPE'
        THEN
            g_error := 'Get levels from ' || i_table_name;
            SELECT DISTINCT LEVEL
            BULK   COLLECT
            INTO   o_level_array
            FROM   alert_default.supply_type st
            WHERE  st.flg_available = pk_alert_constant.get_available
            START  WITH st.id_parent IS NULL
            CONNECT BY PRIOR st.id_supply_type = st.id_parent
            ORDER  BY LEVEL ASC;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_table_levels;

    /********************************************************************************************
    * Fix sequences related to Default Process
    *
    * @author                        LCRS
    * @version                       2.6.3
    * @since                         2013/06/28
    ********************************************************************************************/
    PROCEDURE fix_default_sequences
    (
        i_lang      IN language.id_language%TYPE,
        i_table     IN VARCHAR2 DEFAULT NULL,
        o_tables    OUT table_varchar,
        o_actions   OUT table_varchar,
        o_positions OUT table_number,
        o_error     OUT t_error_out
    ) IS
        l_seq_prefix CONSTANT VARCHAR2(4) := 'SEQ_';
        l_id_prefix  CONSTANT VARCHAR2(3) := 'ID_';
        l_avl_val   NUMBER(38); -- valor max na tabela, max_value de NUMBER tem 38 digitos
        l_id_exists NUMBER := 0;
        l_range CONSTANT NUMBER(6) := 20000;
        l_new_seq_value    NUMBER(38);
        l_seq_max_val      NUMBER(38);
        l_seq_increment    NUMBER(38);
        l_max_number       NUMBER(38) := 99999999999999999999999999999999999999;
        l_col_precision    NUMBER(6);
        l_owners_to_ignore table_varchar := table_varchar('ALERT_DEFAULT',
                                                          'ALERT_APEX_TOOLS_CONTENT',
                                                          'ALERT_APSSCHDLR_MT',
                                                          'ALERT_IDP',
                                                          'ALERT_PDMS_TR',
                                                          'ALERT_MIGRA_MAP',
                                                          'ALERT_INTER',
                                                          'INTER_ALERT_V3',
                                                          'INTER_ALERT_V2',
                                                          'ALERT_CONTENT',
                                                          'INTER_MAP',
                                                          'INTER_HL7',
                                                          'FINGER_DB',
                                                          'INTERFACE_XPLORE_V2',
                                                          'ALERTLOG');
    
        l_owner VARCHAR2(20);
    
        sequence_not_exist EXCEPTION;
        PRAGMA EXCEPTION_INIT(sequence_not_exist, -02289);
    
    BEGIN
    
        IF i_table IS NULL
        THEN
            alert_core_func.pk_tool_utils.get_core_tables(i_lang            => i_lang,
                                                          o_tool_table_name => o_tables,
                                                          o_error           => o_error);
        ELSE
            o_tables := table_varchar(i_table);
        
        END IF;
    
        o_actions   := table_varchar();
        o_positions := table_number();
    
        FOR i IN 1 .. o_tables.count
        LOOP
            o_actions.extend;
            o_positions.extend;
        
            SELECT COUNT(0)
            INTO   l_id_exists
            FROM   all_tab_columns cols
            WHERE  cols.owner NOT IN (SELECT column_value FROM TABLE(l_owners_to_ignore))
                   AND cols.table_name = o_tables(i)
                   AND cols.column_name = l_id_prefix || o_tables(i);
        
            IF (upper(o_tables(i)) = 'CODIFICATION_INSTIT_SOFT' OR upper(o_tables(i)) = 'NECESSITY_DEPT_INST_SOFT' OR
               upper(o_tables(i)) = 'RESULT_NOTES_INSTIT_SOFT')
            THEN
                l_id_exists := 1;
            END IF;
        
            IF l_id_exists = 1
            THEN
            
                SELECT owner
                INTO   l_owner
                FROM   dba_tables
                WHERE  table_name = o_tables(i)
                       AND owner NOT IN (SELECT column_value FROM TABLE(l_owners_to_ignore))
                       AND rownum = 1;
            
                BEGIN
                
                    IF upper(o_tables(i)) = 'CODIFICATION_INSTIT_SOFT'
                    THEN
                        EXECUTE IMMEDIATE 'select max(ID_CODIF_INSTIT_SOFT) from ' || l_owner || '.' || o_tables(i)
                            INTO l_avl_val;
                    
                    ELSIF upper(o_tables(i)) = 'NECESSITY_DEPT_INST_SOFT'
                    THEN
                        EXECUTE IMMEDIATE 'select max(ID_NECT_DEPT_INST_SOFT) from ' || l_owner || '.' || o_tables(i)
                            INTO l_avl_val;
                    ELSIF upper(o_tables(i)) = 'RESULT_NOTES_INSTIT_SOFT'
                    THEN
                        EXECUTE IMMEDIATE 'select max(ID_RES_NOTES_INSTIT_SOFT) from ' || l_owner || '.' || o_tables(i)
                            INTO l_avl_val;
                    ELSE
                    
                        EXECUTE IMMEDIATE 'select max(' || l_id_prefix || o_tables(i) || ') from ' || l_owner || '.' ||
                                          o_tables(i)
                            INTO l_avl_val;
                    END IF;
                
                    IF (l_avl_val IS NULL OR l_avl_val < 0)
                    THEN
                        l_avl_val := 0;
                    END IF;
                
                    SELECT max_value
                    INTO   l_seq_max_val
                    FROM   all_sequences
                    WHERE  sequence_name = l_seq_prefix || o_tables(i)
                           AND sequence_owner = l_owner;
                
                    SELECT a.increment_by
                    INTO   l_seq_increment
                    FROM   all_sequences a
                    WHERE  sequence_name = l_seq_prefix || o_tables(i)
                           AND sequence_owner = l_owner;
                
                    IF l_seq_increment != 1
                    THEN
                        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || l_owner || '.' || l_seq_prefix || o_tables(i) ||
                                          ' INCREMENT BY 1';
                    END IF;
                
                    IF l_avl_val > l_seq_max_val
                    THEN
                    
                        SELECT data_precision
                        INTO   l_col_precision
                        FROM   all_tab_columns cols
                        WHERE  cols.table_name = o_tables(i)
                               AND cols.owner NOT IN (SELECT column_value FROM TABLE(l_owners_to_ignore))
                               AND cols.column_name = l_id_prefix || o_tables(i);
                    
                        o_actions(i) := 'Altering sequence to support column size';
                        o_positions(i) := substr(l_max_number, 1, l_col_precision);
                    
                        EXECUTE IMMEDIATE 'ALTER SEQUENCE ' || l_owner || '.' || l_seq_prefix || o_tables(i) ||
                                          ' MAXVALUE ' || substr(l_max_number, 1, l_col_precision);
                    
                    ELSIF l_seq_max_val - l_avl_val > l_range
                    --ver se existe um range decente ap?s este valor
                    THEN
                    
                        pk_utils.reset_sequence(seq_name   => l_owner || '.' || l_seq_prefix || o_tables(i),
                                                startvalue => l_avl_val + 1);
                    
                        o_actions(i) := 'Sequence updated to current max id in table';
                        o_positions(i) := l_avl_val + 1;
                    ELSE
                        --else correr bloco para procurar um bom range o mais prox possivel
                        EXECUTE IMMEDIATE ' SELECT a.next_val
    FROM (SELECT t.' || l_id_prefix || o_tables(i) ||
                                          ' + 1 next_val
            FROM (SELECT ' || l_id_prefix || o_tables(i) || ',
                         lead(' || l_id_prefix || o_tables(i) ||
                                          ', 1, 0) over(ORDER BY ' || l_id_prefix || o_tables(i) || ') - ' ||
                                          l_id_prefix || o_tables(i) || ' diff
                    FROM ' || l_owner || '.' || o_tables(i) || ') t
           WHERE diff > ' || l_range || '
           ORDER BY next_val) a
   WHERE rownum = 1'
                            INTO l_new_seq_value;
                    
                        o_actions(i) := 'Sequence updated to new range';
                        o_positions(i) := l_new_seq_value;
                    
                        pk_utils.reset_sequence(seq_name   => l_owner || '.' || l_seq_prefix || o_tables(i),
                                                startvalue => l_new_seq_value);
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        o_actions(i) := 'Error: No data found in table or sequence info';
                    WHEN invalid_number THEN
                        o_actions(i) := 'Error: Invalid id for sequence use';
                    WHEN sequence_not_exist THEN
                        o_actions(i) := 'Error: No privileges to alter sequence';
                END;
            ELSE
                o_actions(i) := 'Error: no matching id';
            END IF;
        END LOOP;
    
    END fix_default_sequences;

    /********************************************************************************************
    * Pre Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION pre_default_content
    (
        i_lang        IN language.id_language%TYPE,
        i_sync_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lucene IN VARCHAR2 DEFAULT 'N',
        i_drop_lang   IN VARCHAR2 DEFAULT 'N',
        i_sequence    IN VARCHAR2 DEFAULT 'N',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_log_group_def  NUMBER := 100;
        l_table_name_trl t_low_char := 'TRANSLATION';
        l_owner_trl      t_low_char := 'ALERT_CORE_DATA';
    
        l_wrong_config EXCEPTION;
    
        l_tv_actions table_varchar := table_varchar();
        l_tv_tbls    table_varchar := table_varchar();
        l_tv_posit   table_number := table_number();
    BEGIN
        --> sequence validation
        IF i_sequence = g_flg_available
        THEN
            g_error := 'RESETING ALL INVALID .NEXTVAL SEQUENCES';
            fix_default_sequences(i_lang      => i_lang,
                                  o_tables    => l_tv_tbls,
                                  o_actions   => l_tv_actions,
                                  o_positions => l_tv_posit,
                                  o_error     => o_error);
        END IF;
        -- > Lucene Management on translation table
        IF ((i_drop_lucene = g_flg_available OR i_drop_lang = g_flg_available) AND i_sync_lucene = g_flg_available)
        THEN
            g_error := 'i_drop_lucene AND i_sync_lucene CANNOT BE BOTH ENABLED! (reconfigure and recall method please)';
            RAISE l_wrong_config;
        END IF;
    
        IF i_sync_lucene = g_flg_available
        THEN
            g_error := 'LUCENE SYNCH';
            pk_lucene_index_admin.sync_indexes(l_owner_trl, l_table_name_trl);
        ELSE
            IF i_drop_lang = g_flg_available
            THEN
                g_error := 'DROPING ALL INDEXES EXCEPTION INSTITUTION LANGUAGE INDEX ';
                pk_lucene_index_admin.drop_indexes(l_owner_trl, l_table_name_trl, i_lang);
            ELSE
                g_error := 'DROPING ALL INDEXES';
                pk_lucene_index_admin.drop_indexes(l_owner_trl, l_table_name_trl);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_wrong_config THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END pre_default_content;
    /********************************************************************************************
    * Post Default Execution Validations
    *
    * @author                        RMGM
    * @version                       2.6.1
    * @since                         2011/04/28
    ********************************************************************************************/
    FUNCTION post_default_content
    (
        i_create_lucene_all   IN VARCHAR2 DEFAULT 'N',
        i_create_lucene_byjob IN VARCHAR2 DEFAULT 'N',
        i_start_bylang        IN NUMBER DEFAULT NULL,
        i_sync_lucene         IN VARCHAR2 DEFAULT 'N',
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_log_group_def  NUMBER := 100;
        l_table_name_trl t_low_char := 'TRANSLATION';
        l_owner_trl      t_low_char := 'ALERT_CORE_DATA';
    
        l_wrong_config EXCEPTION;
    BEGIN
        g_func_name := upper('pre_default_content');
        -- > Lucene Management on translation table
        IF (i_create_lucene_all = g_flg_available AND i_create_lucene_byjob = g_flg_available)
           OR ((i_create_lucene_all = g_flg_available OR i_create_lucene_byjob = g_flg_available) AND
           i_sync_lucene = g_flg_available)
        THEN
            g_error := 'CANNOT USE ALL OPTIONS (i_sync_lucene, i_create_lucene_all, i_create_lucene_byjob) = Y, PLEASE RECONFIGURE AND EXECUTE AGAIN';
            RAISE l_wrong_config;
        END IF;
    
        IF i_sync_lucene = g_flg_available
        THEN
            g_error := 'LUCENE SYNCH';
            pk_lucene_index_admin.sync_indexes(l_owner_trl, l_table_name_trl);
        ELSIF (i_create_lucene_byjob = g_flg_available AND i_start_bylang IS NOT NULL)
        THEN
            g_error := 'LUCENE CREATE STARTING BY LANGUAGE ' || i_start_bylang;
            pk_lucene_index_admin.create_serie_indexes(l_owner_trl, l_table_name_trl, i_start_bylang);
        ELSIF i_create_lucene_all = g_flg_available
        THEN
            g_error := 'LUCENE CREATE';
            pk_lucene_index_admin.create_indexes(l_owner_trl, l_table_name_trl);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_wrong_config THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(1,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END post_default_content;
    /********************************************************************************************
    * Set Default translations In existing content but with new language translated
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/09/25
    ********************************************************************************************/
    FUNCTION get_default_cnt_tables
    (
        i_lang   IN language.id_language%TYPE,
        o_tables OUT table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT fo.obj_name
        BULK   COLLECT
        INTO   o_tables
        FROM   frmw_objects fo
        WHERE  fo.owner = 'ALERT_DEFAULT'
               AND fo.category = 'CNT'
               AND fo.flg_alert_default = g_flg_available
              -- exclude tables without code_translation field
               AND fo.obj_name NOT IN
               ('CHECKLIST', 'GUIDELINE', 'ORDER_SET', 'PROTOCOL', 'QUESTIONNAIRE_RESPONSE', 'ROOM', 'TRANSLATION')
              -- exclude temporary and auxiliary tables defined to load content to def
               AND NOT regexp_like(fo.obj_name, '[1234567890$]')
        ORDER  BY 1 ASC;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_default_cnt_tables;
    /********************************************************************************************
    * Set Default translations In existing content but with new language translated
    *
    * @param i_lang                Prefered language ID
    * @param i_table               Table Name for get translations
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     2.6.1.3
    * @since                       2011/09/25
    ********************************************************************************************/
    FUNCTION upd_new_translations
    (
        i_lang  IN language.id_language%TYPE,
        i_table IN user_tables.table_name%TYPE DEFAULT NULL,
        o_res   OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- auxiliar vars
        l_error       t_error_out;
        l_table_owner all_tables.owner%TYPE := 'ALERT' /*get_tbl_ext_owner(i_lang, i_table)*/
         ;
    
        -- new type to be used
        o_trl_table   t_tab_translation;
        l_module      t_low_char := 'PFH';
        l_def_na_lang t_med_char := 'NULL';
        -- tables to process array
        l_tables table_varchar := table_varchar();
    
        -- dinamic execution command
        l_sql_first t_big_char := 'SELECT t_rec_translation(def_data.code_translation,
                                               ''' || l_table_owner || ''',
                                               ''' || l_table_owner ||
                                  '.''||def_data.code_translation,
                                               ''' || i_table || ''',
                                               ''' || l_module || ''',
                                               def_data.desc_lang_1,
                                               def_data.desc_lang_2,
                                               def_data.desc_lang_3,
                                               def_data.desc_lang_4,
                                               def_data.desc_lang_5,
                                               def_data.desc_lang_6,
                                               def_data.desc_lang_7,
                                               def_data.desc_lang_8,
                                               def_data.desc_lang_9,
                                               def_data.desc_lang_10,
                                               def_data.desc_lang_11,
                                               def_data.desc_lang_12,
                                               def_data.desc_lang_13,
                                               def_data.desc_lang_14,
                                               def_data.desc_lang_15,
                                               def_data.desc_lang_16,
                                               def_data.desc_lang_17,
                                             def_data.desc_lang_18,
                                              def_data.desc_lang_19,
                        def_data.desc_lang_20,
                        def_data.desc_lang_21,
                        def_data.desc_lang_22,
                         ' || l_def_na_lang || ')
        FROM (';
        l_sql_mid   t_big_char := '';
        l_sql_last  t_big_char := ') def_data
       WHERE (def_data.desc_lang_1 IS NOT NULL OR def_data.desc_lang_2 IS NOT NULL OR def_data.desc_lang_3 IS NOT NULL OR
             def_data.desc_lang_4 IS NOT NULL OR def_data.desc_lang_5 IS NOT NULL OR def_data.desc_lang_6 IS NOT NULL OR
             def_data.desc_lang_7 IS NOT NULL OR def_data.desc_lang_8 IS NOT NULL OR def_data.desc_lang_9 IS NOT NULL OR
             def_data.desc_lang_10 IS NOT NULL OR def_data.desc_lang_11 IS NOT NULL OR def_data.desc_lang_12 IS NOT NULL OR
             def_data.desc_lang_13 IS NOT NULL OR def_data.desc_lang_14 IS NOT NULL OR def_data.desc_lang_15 IS NOT NULL OR
             def_data.desc_lang_16 IS NOT NULL OR def_data.desc_lang_17 IS NOT NULL OR def_data.desc_lang_18 IS NOT NULL or
             def_data.desc_lang_19 is not null or def_data.desc_lang_20 is not null or def_data.desc_lang_21 is not null or
       def_data.desc_lang_22 is not null)';
    
        --error handling
        l_exception EXCEPTION;
    BEGIN
        g_func_name := 'UPD_NEW_TRANSLATIONS';
        -- check if is to load all default content tables or a specific and identified table
        IF i_table IS NOT NULL
        THEN
            l_tables.extend;
            l_tables(1) := upper(i_table);
        ELSE
            g_error := 'GET ALL DEF TABLES';
            IF NOT pk_default_content.get_default_cnt_tables(i_lang, l_tables, l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        FOR b IN 1 .. l_tables.count
        LOOP
            --pk_alertlog.log_info('Set ' || l_tables(b) || ' NEW Translations');
            pk_alertlog.log_info(l_tables(b));
            g_error := 'GET TRANSLATION INFO';
            IF l_tables(b) IN ('ANALYSIS_GROUP', 'INTERV_PHYSIATRY_AREA', 'LENS', 'PHYSIATRY_AREA', 'TASK_GOAL')
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_content,
                                             ext_trl.code_translation,
                                             decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                             decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                             decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                             decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                             decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                             decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                             decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                             decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                             decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                             decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                             decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                             decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                             decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                             decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                             decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                             decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                             decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                        FROM ' || l_tables(b) ||
                             ' ext_tbl
                                       INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                          ON (def_tbl.id_content = ext_tbl.id_content)
                                       INNER JOIN translation ext_trl
                                          ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) || ')
                                       INNER JOIN alert_default.translation def_trl
                                          ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || ')
                                       WHERE ext_tbl.id_content IS NOT NULL';
                -- tables that use Flg_Status instead of flg_available
            ELSIF l_tables(b) IN ('INTERVENTION')
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                                           ext_tbl.id_content,
                                           ext_trl.code_translation,
                                           decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                           decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                           decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                           decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                           decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                           decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                           decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                           decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                           decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                           decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                           decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                           decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                           decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                           decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                           decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                           decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                           decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                            FROM ' || l_tables(b) ||
                             ' ext_tbl
                                           INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                              ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_status = ''A'')
                                           INNER JOIN translation ext_trl
                                              ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) || ')
                                           INNER JOIN alert_default.translation def_trl
                                              ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || ')
                                           WHERE ext_tbl.flg_status = ''A''
                                             AND ext_tbl.id_content IS NOT NULL';
                -- SR_EQUIP code is not equal to common tables
            ELSIF l_tables(b) IN ('SR_EQUIP')
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                                           ext_tbl.id_content,
                                           ext_trl.code_translation,
                                           decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                           decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                           decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                           decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                           decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                           decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                           decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                           decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                           decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                           decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                           decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                           decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                           decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                           decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                           decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                           decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                           decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                            FROM ' || l_tables(b) ||
                             ' ext_tbl
                                           INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                              ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                           INNER JOIN translation ext_trl
                                              ON (ext_trl.code_translation = ext_tbl.code_equip)
                                           INNER JOIN alert_default.translation def_trl
                                              ON (def_trl.code_translation = def_tbl.code_equip)
                                           WHERE ext_tbl.flg_available = ''Y''
                                             AND ext_tbl.id_content IS NOT NULL';
            
                -- rehab don't use flg_available in schema Alert
            ELSIF l_tables(b) IN ('REHAB_AREA', 'REHAB_SESSION_TYPE', 'RESULT_NOTES', 'EXAM_GROUP')
            THEN
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_content,
                                              ext_trl.code_translation,
                                              decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                              decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                              decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                              decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                              decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                              decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                              decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                              decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                              decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                              decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                              decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                              decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                              decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                              decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                              decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                              decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                              decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                         FROM ' || l_tables(b) ||
                             ' ext_tbl
                                        INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                           ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                        INNER JOIN translation ext_trl
                                           ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) || ')
                                        INNER JOIN alert_default.translation def_trl
                                           ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || ')
                                        WHERE ext_tbl.id_content IS NOT NULL';
                --> maping column not standard "code" instead of code_WTL_URG_LEVEL
            ELSIF l_tables(b) = 'WTL_URG_LEVEL'
            THEN
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_content,
                                              ext_trl.code_translation,
                                              decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                              decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                              decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                              decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                              decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                              decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                              decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                              decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                              decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                              decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                              decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                              decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                              decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                              decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                              decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                              decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                              decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                         FROM ' || l_tables(b) ||
                             ' ext_tbl
                                        INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                           ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                        INNER JOIN translation ext_trl
                                           ON (ext_trl.code_translation = ext_tbl.code)
                                        INNER JOIN alert_default.translation def_trl
                                           ON (def_trl.code_translation = def_tbl.code)
                                        WHERE ext_tbl.flg_available = ''Y''';
            
                --> mapping column not standard, uk validation (no id_content in table)
            ELSIF l_tables(b) = 'CHECKLIST_VERSION'
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_checklist_version,
                                          ext_trl.code_translation,
                                          decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                          decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                          decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                          decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                          decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                          decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                          decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                          decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                          decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                          decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                          decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                          decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                          decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                          decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                          decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                          decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                          decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                     FROM ' || l_tables(b) ||
                             ' ext_tbl
                                    INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                       ON (def_tbl.flg_content_creator = ext_tbl.flg_content_creator AND def_tbl.version = ext_tbl.version AND
                                          def_tbl.id_checklist =
                                          (SELECT ck.id_checklist
                                              FROM alert_default.checklist ck
                                             INNER JOIN checklist chk
                                                ON (chk.id_content = ck.id_content AND chk.flg_available = ''Y'' AND chk.flg_status = ''A'')
                                             WHERE ck.flg_available = ''Y''
                                               AND ck.flg_status = ''A''
                                               AND chk.id_checklist = ext_tbl.id_checklist
                                               AND rownum = 1))
                                    INNER JOIN translation ext_trl
                                       ON (ext_trl.code_translation = ext_tbl.code_name)
                                    INNER JOIN alert_default.translation def_trl
                                       ON (def_trl.code_translation = def_tbl.code_name)
                                    WHERE ext_tbl.flg_content_creator = ''A''
                                      AND ext_tbl.code_name IS NOT NULL';
            
                --> mapping column not standard, uk validation (no id_content in table)
            ELSIF l_tables(b) = 'CHECKLIST_ITEM'
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_checklist_item,
                                          ext_trl.code_translation,
                                          decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                          decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                          decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                          decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                          decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                          decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                          decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                          decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                          decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                          decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                          decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                          decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                          decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                          decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                          decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                          decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                          decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                     FROM ' || l_tables(b) ||
                             ' ext_tbl
                                    INNER JOIN checklist_version ext_cv
                                       ON (ext_cv.id_checklist_version = ext_tbl.id_checklist_version AND
                                          ext_cv.flg_content_creator = ext_tbl.flg_content_creator AND ext_tbl.version = ext_cv.version)
                                    INNER JOIN checklist ext_c
                                       ON (ext_c.id_checklist = ext_cv.id_checklist AND ext_c.flg_content_creator = ext_cv.flg_content_creator)
                                    INNER JOIN translation ext_trl
                                       ON (ext_trl.code_translation = ext_tbl.code_item_description)
                                    INNER JOIN alert_default.checklist def_c
                                       ON (def_c.id_content = ext_c.id_content AND def_c.flg_available = ''Y'' AND def_c.flg_status = ''A'')
                                    INNER JOIN alert_default.checklist_version def_cv
                                       ON (def_cv.id_checklist = def_c.id_checklist AND def_cv.flg_content_creator = def_c.flg_content_creator)
                                    INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                       ON (def_tbl.flg_content_creator = ext_tbl.flg_content_creator AND
                                          def_tbl.id_checklist_version = def_cv.id_checklist_version AND def_tbl.item = ext_tbl.item)
                                    INNER JOIN alert_default.translation def_trl
                                       ON (def_trl.code_translation = def_tbl.code_item_description)
                                    WHERE ext_tbl.flg_content_creator = ''A''
                                      AND ext_tbl.code_item_description IS NOT NULL';
            ELSIF l_tables(b) = 'ANALYSIS_DESC'
            THEN
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
     ext_tbl.id_content,
     ext_trl.code_translation,
     decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
     decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
     decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
     decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
     decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
     decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
     decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
     decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
     decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
     decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
     decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
     decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
     decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
     decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
     decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
     decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
     decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
     decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
     decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
   decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
      FROM (SELECT ad.code_analysis_desc code_translation,
                   ad.id_content,
                   st.id_content         id_cont_st,
                   ad.value,
                   a.id_content          labt_cnt,
                   ap.id_content         param_cnt
              FROM analysis_desc ad
             INNER JOIN analysis a
                ON (a.id_analysis = ad.id_analysis AND a.flg_available = ''Y'')
              JOIN sample_type st
                ON (ad.id_sample_type = st.id_sample_type AND st.flg_available = ''Y'')
              LEFT JOIN analysis_parameter ap
                ON (ap.id_analysis_parameter = ad.id_analysis_parameter AND ap.flg_available = ''Y'')
             WHERE ad.flg_available = ''Y'') ext_tbl
     INNER JOIN (SELECT def_ad.code_analysis_desc code_translation,
                        def_ad.id_content,
                        def_ad.value,
                        def_st.id_content         id_cont_st,
                        def_a.id_content          labt_cnt,
                        def_ap.id_content         param_cnt
                   FROM alert_default.analysis_desc def_ad
                  INNER JOIN alert_default.analysis def_a
                     ON (def_a.id_analysis = def_ad.id_analysis AND def_a.flg_available = ''Y'')
                   JOIN alert_default.sample_type def_st
                     ON (def_ad.id_sample_type = def_st.id_sample_type AND def_st.flg_available = ''Y'')
                   LEFT JOIN alert_default.analysis_parameter def_ap
                     ON (def_ap.id_analysis_parameter = def_ad.id_analysis_parameter AND def_ap.flg_available = ''Y'')
                  WHERE def_ad.flg_available = ''Y'') def_tbl
        ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.labt_cnt = ext_tbl.labt_cnt AND
           (def_tbl.value = ext_tbl.value or (def_tbl.value is null and ext_tbl.value is null)) AND def_tbl.id_cont_st = ext_tbl.id_cont_st AND
           (def_tbl.param_cnt = ext_tbl.param_cnt OR (def_tbl.param_cnt IS NULL AND ext_tbl.param_cnt IS NULL)))
     INNER JOIN alert_default.translation def_trl
        ON (def_trl.code_translation = def_tbl.code_translation)
     INNER JOIN translation ext_trl
        ON (ext_trl.code_translation = ext_tbl.code_translation)';
                -- Table with 2 codes referencing translation table
            ELSIF l_tables(b) = 'DISCH_INSTRUCTIONS'
            THEN
            
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_content,
                                         ext_trl.code_translation,
                                         decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                         decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                         decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                         decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                         decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                         decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                         decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                         decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                         decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                         decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                         decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                         decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                         decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                         decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                         decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                         decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                         decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                    FROM ' || l_tables(b) ||
                             ' ext_tbl
                                   INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                      ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                   INNER JOIN translation ext_trl
                                      ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) || ')
                                   INNER JOIN alert_default.translation def_trl
                                      ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || ')
                                   WHERE ext_tbl.flg_available = ''Y''
                                  UNION ALL
                                  SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_content,
                                         ext_trl.code_translation,
                                         decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                         decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                         decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                         decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                         decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                         decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                         decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                         decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                         decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                         decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                         decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                         decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                         decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                         decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                         decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                         decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                         decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                    FROM ' || l_tables(b) ||
                             ' ext_tbl
                                   INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                      ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                       INNER JOIN translation ext_trl
                                      ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) ||
                             '_title)
                                   INNER JOIN alert_default.translation def_trl
                                      ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || '_title)
                                   WHERE ext_tbl.flg_available = ''Y''';
            
                -- table with different codes 
            ELSIF l_tables(b) = 'P1_SPEC_HELP'
            THEN
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_spec_help,
                                             ext_trl.code_translation,
                                             decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                             decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                             decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                             decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                             decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                             decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                             decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                             decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                             decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                             decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                             decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                             decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                             decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                             decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                             decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                             decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                             decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                        FROM ' || l_tables(b) ||
                             ' ext_tbl
                                       INNER JOIN speciality ext_s
                                          ON (ext_s.id_speciality = ext_tbl.id_speciality AND ext_s.flg_available = ''Y'')
                                       INNER JOIN alert_default.speciality def_s
                                          ON (def_s.id_content = ext_s.id_content AND def_s.flg_available = ''Y'')
                                       INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                          ON (def_tbl.id_speciality = def_s.id_speciality AND def_tbl.flg_available = ''Y'')
                                       INNER JOIN translation ext_trl
                                          ON (ext_trl.code_translation = ext_tbl.code_title)
                                       INNER JOIN alert_default.translation def_trl
                                          ON (def_trl.code_translation = def_tbl.code_title)
                                       WHERE ext_tbl.flg_available = ''Y''
                                      UNION ALL
                                      SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/ ext_tbl.id_spec_help,
                                             ext_trl.code_translation,
                                             decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                             decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                             decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                             decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                             decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                             decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                             decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                             decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                             decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                             decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                             decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                             decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                             decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                             decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                             decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                             decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                             decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                        FROM ' || l_tables(b) ||
                             ' ext_tbl
                                       INNER JOIN speciality ext_s
                                          ON (ext_s.id_speciality = ext_tbl.id_speciality AND ext_s.flg_available = ''Y'')
                                       INNER JOIN alert_default.speciality def_s
                                          ON (def_s.id_content = ext_s.id_content AND def_s.flg_available = ''Y'')
                                       INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                          ON (def_tbl.id_speciality = def_s.id_speciality AND def_tbl.flg_available = ''Y'')
                                       INNER JOIN translation ext_trl
                                          ON (ext_trl.code_translation = ext_tbl.code_text)
                                       INNER JOIN alert_default.translation def_trl
                                          ON (def_trl.code_translation = def_tbl.code_text)
                                       WHERE ext_tbl.flg_available = ''Y''';
            
            ELSIF l_tables(b) = 'ANALYSIS_SPECIMEN_CONDITION'
            THEN
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                                         ext_tbl.id_content,
                                         ext_trl.code_translation code_translation,
                                         decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                         decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                         decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                         decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                         decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                         decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                         decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                         decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                         decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                         decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                         decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                         decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                         decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                         decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                         decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                         decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                         decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                       decode(ext_trl.desc_lang_20, NULL, def_trl.desc_lang_20) desc_lang_20,
                       decode(ext_trl.desc_lang_21, NULL, def_trl.desc_lang_21) desc_lang_21,
                       decode(ext_trl.desc_lang_22, NULL, def_trl.desc_lang_22) desc_lang_22
                                          FROM ' || l_tables(b) ||
                             ' ext_tbl
                                         INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                            ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                         INNER JOIN translation ext_trl
                                            ON (ext_trl.code_translation = ext_tbl.code_specimen_condition)
                                         INNER JOIN alert_default.translation def_trl
                                            ON (def_trl.code_translation = def_tbl.code_specimen_condition)
                                         WHERE ext_tbl.flg_available = ''Y''
                                           AND ext_tbl.id_content IS NOT NULL';
            ELSIF l_tables(b) = 'PO_PARAM'
            THEN
                l_sql_mid := 'SELECT res.id_content,
           res.code_translation,
           decode(res.desc_lang_1, NULL, res.def_desc_lang_1) desc_lang_1,
           decode(res.desc_lang_2, NULL, res.def_desc_lang_2) desc_lang_2,
           decode(res.desc_lang_3, NULL, res.def_desc_lang_3) desc_lang_3,
           decode(res.desc_lang_4, NULL, res.def_desc_lang_4) desc_lang_4,
           decode(res.desc_lang_5, NULL, res.def_desc_lang_5) desc_lang_5,
           decode(res.desc_lang_6, NULL, res.def_desc_lang_6) desc_lang_6,
           decode(res.desc_lang_7, NULL, res.def_desc_lang_7) desc_lang_7,
           decode(res.desc_lang_8, NULL, res.def_desc_lang_8) desc_lang_8,
           decode(res.desc_lang_9, NULL, res.def_desc_lang_9) desc_lang_9,
           decode(res.desc_lang_10, NULL, res.def_desc_lang_10) desc_lang_10,
           decode(res.desc_lang_11, NULL, res.def_desc_lang_11) desc_lang_11,
           decode(res.desc_lang_12, NULL, res.def_desc_lang_12) desc_lang_12,
           decode(res.desc_lang_13, NULL, res.def_desc_lang_13) desc_lang_13,
           decode(res.desc_lang_14, NULL, res.def_desc_lang_14) desc_lang_14,
           decode(res.desc_lang_15, NULL, res.def_desc_lang_15) desc_lang_15,
           decode(res.desc_lang_16, NULL, res.def_desc_lang_16) desc_lang_16,
           decode(res.desc_lang_17, NULL, res.def_desc_lang_17) desc_lang_17,
           decode(res.desc_lang_18, NULL, res.def_desc_lang_18) desc_lang_18,
           decode(res.desc_lang_19, NULL, res.def_desc_lang_19) desc_lang_19,
       decode(res.desc_lang_20, NULL, res.def_desc_lang_20) desc_lang_20,
       decode(res.desc_lang_21, NULL, res.def_desc_lang_21) desc_lang_21,
       decode(res.desc_lang_22, NULL, res.def_desc_lang_22) desc_lang_22
      FROM (SELECT def_tbl.id_po_param,
                   def_trl.desc_lang_1 def_desc_lang_1,
                   def_trl.desc_lang_2 def_desc_lang_2,
                   def_trl.desc_lang_3 def_desc_lang_3,
                   def_trl.desc_lang_4 def_desc_lang_4,
                   def_trl.desc_lang_5 def_desc_lang_5,
                   def_trl.desc_lang_6 def_desc_lang_6,
                   def_trl.desc_lang_7 def_desc_lang_7,
                   def_trl.desc_lang_8 def_desc_lang_8,
                   def_trl.desc_lang_9 def_desc_lang_9,
                   def_trl.desc_lang_10 def_desc_lang_10,
                   def_trl.desc_lang_11 def_desc_lang_11,
                   def_trl.desc_lang_12 def_desc_lang_12,
                   def_trl.desc_lang_13 def_desc_lang_13,
                   def_trl.desc_lang_14 def_desc_lang_14,
                   def_trl.desc_lang_15 def_desc_lang_15,
                   def_trl.desc_lang_16 def_desc_lang_16,
                   def_trl.desc_lang_17 def_desc_lang_17,
                   def_trl.desc_lang_18 def_desc_lang_18,
                   def_trl.desc_lang_19 def_desc_lang_19,
           def_trl.desc_lang_19 def_desc_lang_20,
           def_trl.desc_lang_19 def_desc_lang_21,
           def_trl.desc_lang_19 def_desc_lang_22,
                   *,
                   row_number() over(PARTITION BY id_content, id_parameter ORDER BY def_tbl.id_po_param DESC) unique_rows
              FROM (SELECT ext_trl.*, ext_tbl.id_content, ext_tbl.id_parameter
                      FROM ' || l_tables(b) || ' ext_tbl
                     INNER JOIN translation ext_trl
                        ON (ext_trl.code_translation = ext_tbl.code_po_param AND ext_trl.table_owner = ''ALERT'')
                     WHERE ext_tbl.flg_available = ''Y'') alert
             INNER JOIN alert_default.' || l_tables(b) || ' def_tbl
                ON (def_tbl.id_content = id_content AND
                   (pk_periodicobservation_prm.get_dest_parameter_map(1, def_tbl.flg_type, def_tbl.id_parameter) =
                   id_parameter) AND def_tbl.flg_available = ''Y'')
             INNER JOIN alert_default.translation def_trl
                ON (def_trl.code_translation = def_tbl.code_po_param)) res
     WHERE unique_rows = 1';
            ELSIF l_tables(b) = 'PO_PARAM_MC'
            THEN
                l_sql_mid := 'SELECT res.id_content,
           res.code_translation,
           decode(res.desc_lang_1, NULL, res.def_desc_lang_1) desc_lang_1,
           decode(res.desc_lang_2, NULL, res.def_desc_lang_2) desc_lang_2,
           decode(res.desc_lang_3, NULL, res.def_desc_lang_3) desc_lang_3,
           decode(res.desc_lang_4, NULL, res.def_desc_lang_4) desc_lang_4,
           decode(res.desc_lang_5, NULL, res.def_desc_lang_5) desc_lang_5,
           decode(res.desc_lang_6, NULL, res.def_desc_lang_6) desc_lang_6,
           decode(res.desc_lang_7, NULL, res.def_desc_lang_7) desc_lang_7,
           decode(res.desc_lang_8, NULL, res.def_desc_lang_8) desc_lang_8,
           decode(res.desc_lang_9, NULL, res.def_desc_lang_9) desc_lang_9,
           decode(res.desc_lang_10, NULL, res.def_desc_lang_10) desc_lang_10,
           decode(res.desc_lang_11, NULL, res.def_desc_lang_11) desc_lang_11,
           decode(res.desc_lang_12, NULL, res.def_desc_lang_12) desc_lang_12,
           decode(res.desc_lang_13, NULL, res.def_desc_lang_13) desc_lang_13,
           decode(res.desc_lang_14, NULL, res.def_desc_lang_14) desc_lang_14,
           decode(res.desc_lang_15, NULL, res.def_desc_lang_15) desc_lang_15,
           decode(res.desc_lang_16, NULL, res.def_desc_lang_16) desc_lang_16,
           decode(res.desc_lang_17, NULL, res.def_desc_lang_17) desc_lang_17,
           decode(res.desc_lang_18, NULL, res.def_desc_lang_18) desc_lang_18,
           decode(res.desc_lang_19, NULL, res.def_desc_lang_19) desc_lang_19,
       decode(res.desc_lang_19, NULL, res.def_desc_lang_19) desc_lang_20,
       decode(res.desc_lang_19, NULL, res.def_desc_lang_19) desc_lang_21,
       decode(res.desc_lang_19, NULL, res.def_desc_lang_19) desc_lang_22
      FROM (SELECT /*+ dynamic_sampling (alert_data 2)*/
             alert_data.*,
             def_trl.desc_lang_1  def_desc_lang_1,
             def_trl.desc_lang_2  def_desc_lang_2,
             def_trl.desc_lang_3  def_desc_lang_3,
             def_trl.desc_lang_4  def_desc_lang_4,
             def_trl.desc_lang_5  def_desc_lang_5,
             def_trl.desc_lang_6  def_desc_lang_6,
             def_trl.desc_lang_7  def_desc_lang_7,
             def_trl.desc_lang_8  def_desc_lang_8,
             def_trl.desc_lang_9  def_desc_lang_9,
             def_trl.desc_lang_10 def_desc_lang_10,
             def_trl.desc_lang_11 def_desc_lang_11,
             def_trl.desc_lang_12 def_desc_lang_12,
             def_trl.desc_lang_13 def_desc_lang_13,
             def_trl.desc_lang_14 def_desc_lang_14,
             def_trl.desc_lang_15 def_desc_lang_15,
             def_trl.desc_lang_16 def_desc_lang_16,
             def_trl.desc_lang_17 def_desc_lang_17,
             def_trl.desc_lang_18 def_desc_lang_18,
             def_trl.desc_lang_19 def_desc_lang_19,
       def_trl.desc_lang_19 def_desc_lang_20,
       def_trl.desc_lang_19 def_desc_lang_21,
       def_trl.desc_lang_19 def_desc_lang_22
              FROM (SELECT ext_tbl.id_po_param, ext_tbl.id_content, ext_trl.*
                      FROM ' || l_tables(b) || ' ext_tbl
                     INNER JOIN po_param ext_tbl1
                        ON (ext_tbl1.id_po_param = ext_tbl.id_po_param AND ext_tbl1.id_inst_owner = ext_tbl.id_inst_owner)
                     INNER JOIN translation ext_trl
                        ON (ext_trl.code_translation = ext_tbl.code_po_param_mc)
                     WHERE ext_tbl.flg_available = ''Y'') alert_data
             INNER JOIN (SELECT def_tbl.id_content,
                               def_tbl.code_' || l_tables(b) ||
                             ' code_translation,
                               (SELECT pk_periodicobservation_prm.get_dest_pop_id(1, def_tbl.id_po_param)
                                  FROM dual) id_po_param
                          FROM alert_default.' || l_tables(b) || ' def_tbl
                         INNER JOIN alert_default.translation def_trl
                            ON (def_trl.code_translation = def_tbl.code_po_param_mc)
                         WHERE def_tbl.flg_available = ''Y'') def_data
                ON (def_data.id_content = alert_data.id_content AND def_data.id_po_param = alert_data.id_po_param)
             INNER JOIN alert_default.translation def_trl
                ON (def_trl.code_translation = def_data.code_translation)
            ) res ';
            ELSE
                l_sql_mid := 'SELECT /*+ OPT_ESTIMATE(TABLE def_data ROWS=100)*/
                                         ext_tbl.id_content,
                                         ext_trl.code_translation code_translation,
                                         decode(ext_trl.desc_lang_1, NULL, def_trl.desc_lang_1) desc_lang_1,
                                         decode(ext_trl.desc_lang_2, NULL, def_trl.desc_lang_2) desc_lang_2,
                                         decode(ext_trl.desc_lang_3, NULL, def_trl.desc_lang_3) desc_lang_3,
                                         decode(ext_trl.desc_lang_4, NULL, def_trl.desc_lang_4) desc_lang_4,
                                         decode(ext_trl.desc_lang_5, NULL, def_trl.desc_lang_5) desc_lang_5,
                                         decode(ext_trl.desc_lang_6, NULL, def_trl.desc_lang_6) desc_lang_6,
                                         decode(ext_trl.desc_lang_7, NULL, def_trl.desc_lang_7) desc_lang_7,
                                         decode(ext_trl.desc_lang_8, NULL, def_trl.desc_lang_8) desc_lang_8,
                                         decode(ext_trl.desc_lang_9, NULL, def_trl.desc_lang_9) desc_lang_9,
                                         decode(ext_trl.desc_lang_10, NULL, def_trl.desc_lang_10) desc_lang_10,
                                         decode(ext_trl.desc_lang_11, NULL, def_trl.desc_lang_11) desc_lang_11,
                                         decode(ext_trl.desc_lang_12, NULL, def_trl.desc_lang_12) desc_lang_12,
                                         decode(ext_trl.desc_lang_13, NULL, def_trl.desc_lang_13) desc_lang_13,
                                         decode(ext_trl.desc_lang_14, NULL, def_trl.desc_lang_14) desc_lang_14,
                                         decode(ext_trl.desc_lang_15, NULL, def_trl.desc_lang_15) desc_lang_15,
                                         decode(ext_trl.desc_lang_16, NULL, def_trl.desc_lang_16) desc_lang_16,
                                         decode(ext_trl.desc_lang_17, NULL, def_trl.desc_lang_17) desc_lang_17,
                                           decode(ext_trl.desc_lang_18, NULL, def_trl.desc_lang_18) desc_lang_18,
                                           decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_19,
                        decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_20,
                       decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_21,
                        decode(ext_trl.desc_lang_19, NULL, def_trl.desc_lang_19) desc_lang_22
                                          FROM ' || l_tables(b) ||
                             ' ext_tbl
                                         INNER JOIN alert_default.' || l_tables(b) ||
                             ' def_tbl
                                            ON (def_tbl.id_content = ext_tbl.id_content AND def_tbl.flg_available = ''Y'')
                                         INNER JOIN translation ext_trl
                                            ON (ext_trl.code_translation = ext_tbl.code_' ||
                             l_tables(b) || ')
                                         INNER JOIN alert_default.translation def_trl
                                            ON (def_trl.code_translation = def_tbl.code_' ||
                             l_tables(b) || ')
                                         WHERE ext_tbl.flg_available = ''Y''
                                           AND ext_tbl.id_content IS NOT NULL';
            END IF;
        
            EXECUTE IMMEDIATE l_sql_first || l_sql_mid || l_sql_last BULK COLLECT
                INTO o_trl_table;
            g_error := 'UPDATE TRANSLATION WITH NEW DESCS';
            IF o_trl_table.count > 0
            THEN
                o_res := pk_translation.upd_bulk_translation(o_trl_table);
            ELSE
                o_res := 0;
            END IF;
        END LOOP;
        --------------------------------------------------
    
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
    END upd_new_translations;
    /********************************************************************************************
    * Set Default Content using new engine
    *
    * @param i_lang                Prefered language ID
    * @param i_commit_at_end       Commit automatic in transaction (Y, N)
    * @param o_results             Generic cursor with execution details        
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2013/05/05
    ********************************************************************************************/
    FUNCTION set_def_content_new
    (
        i_lang          IN language.id_language%TYPE,
        i_commit_at_end IN VARCHAR2,
        o_results       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        i_institution         institution.id_institution%TYPE := NULL;
        i_d_institution       institution.id_institution%TYPE := NULL;
        i_market              table_number := table_number();
        i_version             table_varchar := table_varchar();
        i_software            table_number := table_number();
        i_id_content          table_varchar := table_varchar();
        i_id_clinical_service table_number := table_number();
        i_dep_clin_serv       table_number := table_number();
        i_process_type        table_varchar := table_varchar('CONTENT', 'TRANSLATION');
        i_areas               table_varchar := table_varchar();
        i_tables              table_varchar := table_varchar();
        i_flg_dcs_all         VARCHAR2(1) := 'N';
        i_dependencies        VARCHAR2(1) := 'N';
        o_execution_id        NUMBER := 0;
        l_exception EXCEPTION;
    BEGIN
        alert_core_func.pk_tool_engine.set_default_configuration(i_lang                => i_lang,
                                                                 i_market              => i_market,
                                                                 i_version             => i_version,
                                                                 i_institution         => i_institution,
                                                                 i_d_institution       => i_d_institution,
                                                                 i_software            => i_software,
                                                                 i_id_content          => i_id_content,
                                                                 i_flg_dcs_all         => i_flg_dcs_all,
                                                                 i_id_clinical_service => i_id_clinical_service,
                                                                 i_dep_clin_serv       => i_dep_clin_serv,
                                                                 i_dependencies        => i_dependencies,
                                                                 i_process_type        => i_process_type,
                                                                 i_areas               => i_areas,
                                                                 i_tables              => i_tables,
                                                                 o_execution_id        => o_execution_id,
                                                                 o_error               => o_error);
    
        OPEN o_results FOR
            SELECT ex_det.id_execution_det,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_area), ex_det.tool_area_name) area_name,
                   ex_det.tool_table_name table_name,
                   nvl(pk_translation.get_translation(i_lang, ex_det.code_tool_process_type), ex_det.internal_name) process_name,
                   ex_det.rec_inserted,
                   ex_det.execution_status,
                   ex_det.execution_length
            FROM   alert_core_data.v_exec_hist_details ex_det
            WHERE  ex_det.id_execution = o_execution_id;
    
        IF i_commit_at_end = g_flg_available
        THEN
            COMMIT;
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
                                              'SET_DEF_CONTENT_NEW',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_def_content_new;

BEGIN
    -- Initializes log context
    pk_alertlog.who_am_i(owner => g_package_owner, NAME => g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_flg_available := pk_alert_constant.g_available;
    g_yes           := pk_alert_constant.g_yes;
    g_active        := pk_alert_constant.g_active;

    g_array_size  := 100;
    g_array_size1 := 10000;

END pk_default_content;
/
