/*-- Last Change Revision: $Rev: 2026626 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_aih IS

    g_exception EXCEPTION;

    g_debug_enable BOOLEAN;

    --CEMR-1519: In order to maintain compatibility, sets the show code = 'N'
    g_flg_show_code VARCHAR2(1 CHAR) := pk_alert_constant.g_no;

    FUNCTION get_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_component.internal_name%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SECTION_EVENTS_LIST';
        l_dbg_msg VARCHAR2(100 CHAR);
    
    BEGIN
    
        l_dbg_msg := 'CALL pk_dynamic_screen.get_ds_section_events_list';
        IF NOT pk_dynamic_screen.get_ds_section_events_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_component_name => i_component_name,
                                                            i_component_type => pk_dynamic_screen.c_root_component,
                                                            o_section        => o_section,
                                                            o_def_events     => o_def_events,
                                                            o_error          => o_error)
        THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
        
    END get_section_events_list;

    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_DATA';
        --
        l_tbl_section      t_table_ds_sections; --o_section
        l_tbl_def_events   t_table_ds_def_events; --o_def_events cursor
        l_tbl_events       t_table_ds_events; --o_events cursor
        l_tbl_items_values t_table_ds_items_values; --o_items_values
    
        l_aux_data_val xmltype; --o_data_val
        --   
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_SECTION_DATA_DB';
    
        IF NOT get_section_data_db(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_patient      => i_patient,
                                   i_episode      => i_episode,
                                   i_ds_component => i_ds_component,
                                   i_aih_simple   => i_aih_simple,
                                   i_params       => i_params,
                                   o_section      => l_tbl_section,
                                   o_def_events   => l_tbl_def_events,
                                   o_events       => l_tbl_events,
                                   o_items_values => l_tbl_items_values,
                                   o_data_val     => l_aux_data_val,
                                   o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN O_SECTION';
        OPEN o_section FOR
            SELECT id_ds_cmpt_mkt_rel,
                   id_ds_component_parent,
                   id_ds_component,
                   component_desc,
                   internal_name,
                   flg_component_type,
                   flg_data_type,
                   slg_internal_name,
                   addit_info_xml_value,
                   rank,
                   max_len,
                   min_value,
                   max_value
              FROM (SELECT b.id_ds_cmpt_mkt_rel,
                           b.id_ds_component_parent,
                           b.id_ds_component,
                           b.component_desc,
                           b.internal_name,
                           b.flg_component_type,
                           b.flg_data_type,
                           b.slg_internal_name,
                           b.addit_info_xml_value,
                           pk_dynamic_screen.get_section_rank(i_tbl_section     => l_tbl_section,
                                                              i_ds_cmpt_mkt_rel => b.id_ds_cmpt_mkt_rel) rank,
                           b.max_len,
                           b.min_value,
                           b.max_value
                      FROM (SELECT c.id_ds_cmpt_mkt_rel,
                                   c.id_ds_component_parent,
                                   c.id_ds_component,
                                   c.component_desc,
                                   c.internal_name,
                                   c.flg_component_type,
                                   c.flg_data_type,
                                   c.slg_internal_name,
                                   c.addit_info_xml_value,
                                   c.max_len,
                                   c.min_value,
                                   c.max_value
                              FROM TABLE(l_tbl_section) c) b) a
             ORDER BY a.rank;
    
        g_error := 'OPEN O_EVENTS';
    
        OPEN o_events FOR
            SELECT *
              FROM TABLE(l_tbl_events);
    
        g_error := 'OPEN O_DEF_EVENTS';
    
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_tbl_def_events);
    
        g_error := 'OPEN O_ITEMS_VALUES';
    
        --o_items_values - This cursor has all multichoice options for all multichoice fields
        OPEN o_items_values FOR
            SELECT *
              FROM TABLE(l_tbl_items_values);
    
        IF l_aux_data_val IS NOT NULL
        THEN
            --o_data_val - Has all the default/saved data fields values
            SELECT xmlelement("COMPONENTS", l_aux_data_val).getclobval()
              INTO o_data_val
              FROM dual;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
    END get_section_data;

    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_DATA_DB';
        --    
        l_parameter rec_aih_section_data_param;
        --   
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PARSE_VAL_FILL_SECT_PARAM';
    
        IF NOT parse_val_fill_sect_param(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_patient      => i_patient,
                                         i_episode      => i_episode,
                                         i_ds_component => i_ds_component,
                                         i_params       => i_params,
                                         o_params       => l_parameter,
                                         o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL GET_SECTION_DATA_DB';
    
        IF NOT get_section_data_db_type(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_patient      => i_patient,
                                        i_episode      => i_episode,
                                        i_ds_component => i_ds_component,
                                        i_aih_simple   => i_aih_simple,
                                        i_params       => l_parameter,
                                        i_xml          => i_params,
                                        o_section      => o_section,
                                        o_def_events   => o_def_events,
                                        o_events       => o_events,
                                        o_items_values => o_items_values,
                                        o_data_val     => o_data_val,
                                        o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_section_data_db;

    FUNCTION get_section_data_db_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN rec_aih_section_data_param,
        i_xml          IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_DATA_DB';
        --   
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_SECTION_DATA_INT';
    
        IF NOT get_section_data_int(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_patient      => i_patient,
                                    i_episode      => i_episode,
                                    i_ds_component => i_ds_component,
                                    i_aih_simple   => i_aih_simple,
                                    i_params       => i_params,
                                    i_xml          => i_xml,
                                    o_section      => o_section,
                                    o_def_events   => o_def_events,
                                    o_events       => o_events,
                                    o_items_values => o_items_values,
                                    o_data_val     => o_data_val,
                                    o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_section_data_db_type;

    FUNCTION get_section_data_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN rec_aih_section_data_param,
        i_xml          IN CLOB,
        o_section      OUT t_table_ds_sections,
        o_def_events   OUT t_table_ds_def_events,
        o_events       OUT t_table_ds_events,
        o_items_values OUT t_table_ds_items_values,
        o_data_val     OUT xmltype,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_DATA_INT';
        --
        --SECTION VARS
        l_tbl_sections t_table_ds_sections; --Unchanged table, used to loop through each section
        r_section      t_rec_ds_sections; --auxiliar var that has the current record when looping through l_tbl_sections table
    
        --OUTPUT CURSORS
        l_final_tbl_sections t_table_ds_sections := t_table_ds_sections(); -- o_section cursor 
        l_tbl_events         t_table_ds_events; --o_events cursor
        l_tbl_def_events     t_table_ds_def_events; --o_def_events cursor
        l_tbl_items_values   t_table_ds_items_values; --o_items_values
    
        l_aux_data_val xmltype := NULL; --auxiliar var used to keep default data or previous saved data
        --
    
        l_value_solic      VARCHAR2(2 CHAR);
        l_dummy            pk_translation.t_desc_translation;
        l_value_inst_exec  VARCHAR2(30 CHAR);
        l_diag_princ_value VARCHAR2(30 CHAR);
        l_has_diag_princ   VARCHAR2(1 CHAR) := 'N';
    
        l_id_diagnosis       diagnosis.id_diagnosis%TYPE;
        l_id_alert_diagnosis alert_diagnosis.id_alert_diagnosis%TYPE;
    
        -- PROC SPECIAL COUNT
        l_special_count_inc NUMBER(24) := 0;
        l_special_count     NUMBER(24) := 0;
    
        l_tbl_term alert_core_func.table_t_ts_term := alert_core_func.table_t_ts_term();
    
        --
        --LOCAL EXCEPTIONS
        l_exception EXCEPTION;
        --
        --INNER PROCS/FUNCS
        PROCEDURE add_procedures
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
            i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_tbl_item_values t_table_ds_items_values;
        BEGIN
        
            IF i_id_diagnosis IS NOT NULL
            THEN
                SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                             id_ds_component    => i_ds_component,
                                             internal_name      => i_internal_name,
                                             flg_component_type => i_flg_component_type,
                                             item_desc          => t.desc_translation,
                                             item_value         => t.id_concept_version,
                                             item_alt_value     => t.id_concept_term,
                                             item_xml_value     => NULL,
                                             item_rank          => t.rank)
                  BULK COLLECT
                  INTO l_tbl_item_values
                  FROM TABLE(pk_ts1_api.tf_aih_procedures_main(i_lang               => i_lang,
                                                               i_id_institution     => i_prof.institution,
                                                               i_id_software        => i_prof.software,
                                                               i_id_diagnosis       => i_id_diagnosis,
                                                               i_id_alert_diagnosis => i_id_alert_diagnosis,
                                                               i_text_search        => NULL,
                                                               i_highlight          => NULL)) t;
            
                io_tbl_items_values := io_tbl_items_values MULTISET UNION ALL l_tbl_item_values;
            
            END IF;
        END add_procedures;
    
        PROCEDURE add_procedures_special
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
            i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_tbl_item_values t_table_ds_items_values;
        BEGIN
            g_error := 'LOOP THROUGH ALL DIAGNOSES TYPES';
        
            SELECT t_rec_ds_items_values(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                         id_ds_component    => i_ds_component,
                                         internal_name      => i_internal_name,
                                         flg_component_type => i_flg_component_type,
                                         item_desc          => t.desc_translation,
                                         item_value         => t.id_concept_version,
                                         item_alt_value     => t.id_concept_term,
                                         item_xml_value     => NULL,
                                         item_rank          => t.rank)
              BULK COLLECT
              INTO l_tbl_item_values
              FROM TABLE(pk_ts1_api.tf_aih_procedures_special(i_lang               => i_lang,
                                                              i_id_institution     => i_prof.institution,
                                                              i_id_software        => i_prof.software,
                                                              i_id_diagnosis       => i_id_diagnosis,
                                                              i_id_alert_diagnosis => i_id_alert_diagnosis,
                                                              i_text_search        => NULL,
                                                              i_highlight          => NULL)) t;
        
            io_tbl_items_values := io_tbl_items_values MULTISET UNION ALL l_tbl_item_values;
        
        END add_procedures_special;
    
        PROCEDURE add_diag
        (
            i_lang               IN language.id_language%TYPE,
            i_prof               IN profissional,
            i_episode            IN episode.id_episode%TYPE,
            i_patient            IN patient.id_patient%TYPE,
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            r_final_type t_rec_values_domain_mkt;
        
            l_coll_epis_diagnosis_wth_proc t_coll_episode_diagnosis;
        
            tbl_id_diag       table_number := table_number();
            tbl_id_alert_diag table_number := table_number();
        
            tbl_term alert_core_func.table_t_ts_term := alert_core_func.table_t_ts_term();
        BEGIN
        
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => CASE
                                                     WHEN i_internal_name IN (g_aihs_proc_old,
                                                                              g_aihs_proc_special,
                                                                              g_aihs_proc_special2,
                                                                              g_aihs_proc_special3,
                                                                              g_aihs_proc_special4,
                                                                              g_aihs_proc_special5,
                                                                              g_aihs_proc_special6,
                                                                              g_aihs_proc_special7,
                                                                              g_aihs_proc_special8,
                                                                              g_aihs_proc_special9,
                                                                              g_aihs_proc_special10,
                                                                              g_aihs_proc_special11,
                                                                              g_aihs_proc_special12,
                                                                              g_aihs_proc_special13,
                                                                              g_aihs_proc_special14,
                                                                              g_aihs_proc_special15,
                                                                              g_aihs_proc_special16,
                                                                              g_aihs_proc_special17,
                                                                              g_aihs_proc_special18,
                                                                              g_aihs_proc_special19) THEN
                                                      pk_message.get_message(i_lang => i_lang, i_code_mess => 'AIH_T021')
                                                     WHEN i_internal_name IN (g_aihs_causes, g_aih_diag_cause) THEN
                                                      pk_message.get_message(i_lang => i_lang, i_code_mess => 'AIH_T020')
                                                     ELSE
                                                      pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'SURG_ADM_REQUEST_T028')
                                                 END,
                         i_item_value         => -1,
                         i_item_alt_value     => -1,
                         i_item_xml_value     => NULL,
                         i_item_rank          => r_final_type.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            IF i_internal_name NOT IN (g_aihs_proc_special,
                                       g_aihs_proc_special2,
                                       g_aihs_proc_special3,
                                       g_aihs_proc_special4,
                                       g_aihs_proc_special5,
                                       g_aihs_proc_special6,
                                       g_aihs_proc_special7,
                                       g_aihs_proc_special8,
                                       g_aihs_proc_special9,
                                       g_aihs_proc_special10,
                                       g_aihs_proc_special11,
                                       g_aihs_proc_special12,
                                       g_aihs_proc_special13,
                                       g_aihs_proc_special14,
                                       g_aihs_proc_special15,
                                       g_aihs_proc_special16,
                                       g_aihs_proc_special17,
                                       g_aihs_proc_special18,
                                       g_aihs_proc_special19)
            THEN
            
                SELECT /*+OPT_ESTIMATE(TABLE d ROWS=1)*/ /*+OPT_ESTIMATE(TABLE t ROWS=2)*/
                
                 d.id_diagnosis, d.id_alert_diagnosis
                  BULK COLLECT
                  INTO tbl_id_diag, tbl_id_alert_diag
                  FROM TABLE(pk_diagnosis_core.tb_get_epis_diagnosis_list(i_lang                  => i_lang,
                                                                          i_prof                  => i_prof,
                                                                          i_patient               => i_patient,
                                                                          i_id_scope              => i_episode,
                                                                          i_flg_scope             => pk_diagnosis_core.g_scope_episode,
                                                                          i_flg_type              => 'D',
                                                                          i_criteria              => '',
                                                                          i_format_text           => '',
                                                                          i_translation_desc_only => NULL,
                                                                          
                                                                          i_tbl_status => NULL)) d;
            
                IF tbl_id_alert_diag IS NOT NULL
                   AND tbl_id_alert_diag.count > 0
                THEN
                
                    SELECT t_ts_term(id_concept_term        => d.id_concept_term,
                                     code                   => d.code,
                                     desc_translation       => d.desc_translation,
                                     term_type              => d.term_type,
                                     gender                 => d.gender,
                                     age_min                => d.age_min,
                                     age_max                => d.age_max,
                                     rank                   => d.rank,
                                     flg_select             => d.flg_select,
                                     flg_default            => d.flg_default,
                                     relevance              => d.relevance,
                                     position               => d.position,
                                     code_translation       => d.code_translation,
                                     id_concept_version     => d.id_concept_version,
                                     id_terminology_version => d.id_terminology_version)
                      BULK COLLECT
                      INTO tbl_term
                      FROM TABLE(pk_ts1_api.tf_aih_main_diagnosis_list(i_lang                      => i_lang,
                                                                       i_id_institution            => i_prof.institution,
                                                                       i_id_software               => i_prof.software,
                                                                       i_id_diagnosis_filter       => tbl_id_diag,
                                                                       i_id_alert_diagnosis_filter => tbl_id_alert_diag)) d;
                
                    FOR i IN 1 .. tbl_term.count
                    LOOP
                        add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                     i_ds_component       => i_ds_component,
                                     i_internal_name      => i_internal_name,
                                     i_flg_component_type => i_flg_component_type,
                                     i_item_desc          => tbl_term(i).desc_translation,
                                     i_item_value         => tbl_term(i).id_concept_version,
                                     i_item_alt_value     => tbl_term(i).id_concept_term,
                                     i_item_xml_value     => NULL,
                                     i_item_rank          => r_final_type.rank,
                                     io_tbl_items_values  => io_tbl_items_values);
                    END LOOP;
                
                END IF;
            END IF;
        
        END add_diag;
    
        PROCEDURE add_sys_domains
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
        
            c_list      pk_types.cursor_type;
            l_inst_desc VARCHAR2(300 CHAR);
            l_id_inst   VARCHAR2(5 CHAR);
            l_img_name  VARCHAR2(200 CHAR);
            l_rank      NUMBER;
        
            l_domain_value VARCHAR2(50 CHAR);
        
        BEGIN
        
            CASE i_internal_name
                WHEN g_aihs_uti THEN
                    l_domain_value := g_domain_uti;
                
                WHEN g_aihs_solic THEN
                    l_domain_value := g_domain_solic;
                ELSE
                    l_domain_value := NULL;
            END CASE;
        
            IF NOT pk_sysdomain.get_values_domain(l_domain_value, i_lang, c_list)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'ADD ALL INST LOCATIONS';
            LOOP
                FETCH c_list
                    INTO l_inst_desc, l_id_inst, l_img_name, l_rank;
                EXIT WHEN c_list%NOTFOUND;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => l_inst_desc,
                             i_item_value         => l_id_inst,
                             i_item_alt_value     => NULL, --l_id_inst,
                             i_item_rank          => NULL,
                             io_tbl_items_values  => io_tbl_items_values);
            END LOOP;
        
            CLOSE c_list;
        END add_sys_domains;
    
        PROCEDURE add_inst_exec
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
        
            l_tbl_config t_tbl_config_table;
        
        BEGIN
        
            l_tbl_config := pk_core_config.get_values_by_mkt_inst_sw(i_lang => 11,
                                                                     i_prof => profissional(247032, 76073, 11),
                                                                     i_area => 'AIH_EXEC_INSTIT');
        
            g_error := 'ADD ALL INST LOCATIONS';
            FOR rec IN (SELECT *
                          FROM TABLE(l_tbl_config)
                         ORDER BY to_number(field_03))
            LOOP
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => rec.field_01,
                             i_item_value         => rec.id_record,
                             i_item_alt_value     => NULL, --l_id_inst,
                             i_item_rank          => rec.field_03,
                             io_tbl_items_values  => io_tbl_items_values);
            END LOOP;
        
        END add_inst_exec;
    
    BEGIN
    
        IF NOT get_count_proc_special(i_lang => i_lang, i_xml => i_xml, o_count => l_special_count, o_error => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF i_params.tbl_sections.exists(1)
        THEN
            l_tbl_sections     := i_params.tbl_sections;
            l_tbl_def_events   := t_table_ds_def_events();
            l_tbl_events       := t_table_ds_events();
            l_tbl_items_values := t_table_ds_items_values();
        ELSE
            g_error := 'CALL PK_DYNAMIC_SCREEN.GET_DS_SECTION_COMPLETE_STRUCT';
        
            IF NOT pk_dynamic_screen.get_ds_section_complete_struct(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_component_name => i_ds_component,
                                                                    i_component_type => pk_dynamic_screen.c_node_component,
                                                                    o_section        => l_tbl_sections,
                                                                    o_def_events     => l_tbl_def_events,
                                                                    o_events         => l_tbl_events,
                                                                    o_items_values   => l_tbl_items_values,
                                                                    o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        IF l_tbl_sections IS NOT NULL
           AND l_tbl_sections.count > 0
        THEN
            g_error := 'LOOP THROUGH DS SECTIONS';
        
            --l_tbl_sections - has all triage form fields
            FOR i IN l_tbl_sections.first .. l_tbl_sections.last
            LOOP
            
                r_section := l_tbl_sections(i);
            
                g_error := 'ADD CURRENT SECTION TO FINAL TBL_SECTION';
            
                l_final_tbl_sections.extend();
                l_final_tbl_sections(l_final_tbl_sections.count) := r_section;
            
                --I only want multichoice fields and only a restrite group of them
                --For instance, multichoice fields based on sys_list come automatically filled 
                --from the pk_dynamic_screen.get_ds_section_complete_struct function call
                IF r_section.flg_data_type = pk_dynamic_screen.c_data_type_ms
                THEN
                    CASE
                        WHEN r_section.internal_name = g_aih_procedure THEN
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aih_diag_first,
                                                      o_value         => l_id_diagnosis,
                                                      o_alt_value     => l_id_alert_diagnosis,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            add_procedures(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type,
                                           i_id_diagnosis       => l_id_diagnosis,
                                           i_id_alert_diagnosis => l_id_alert_diagnosis,
                                           io_tbl_items_values  => l_tbl_items_values);
                        
                        WHEN r_section.internal_name IN (g_aih_procedure, g_aihs_proc_princ, g_aihs_proc_change) THEN
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_diag_princ,
                                                      o_value         => l_id_diagnosis,
                                                      o_alt_value     => l_id_alert_diagnosis,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_solic,
                                                      o_value         => l_value_solic,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF (r_section.internal_name = g_aihs_proc_change AND l_value_solic = g_solic_mudanca)
                               OR (r_section.internal_name = g_aihs_proc_princ AND l_value_solic = g_solic_special)
                            THEN
                                IF l_value_solic IS NOT NULL
                                THEN
                                    g_error := 'ADD SECTIONS AND ITEMS_VALUES FOR: ' || r_section.internal_name;
                                    add_procedures(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                   i_ds_component       => r_section.id_ds_component,
                                                   i_internal_name      => r_section.internal_name,
                                                   i_flg_component_type => r_section.flg_component_type,
                                                   i_id_diagnosis       => l_id_diagnosis,
                                                   i_id_alert_diagnosis => l_id_alert_diagnosis,
                                                   io_tbl_items_values  => l_tbl_items_values);
                                END IF;
                            END IF;
                        
                        WHEN r_section.internal_name = g_aihs_solic THEN
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_solic,
                                                      o_value         => l_value_solic,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            add_sys_domains(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                            i_ds_component       => r_section.id_ds_component,
                                            i_internal_name      => r_section.internal_name,
                                            i_flg_component_type => r_section.flg_component_type,
                                            io_tbl_items_values  => l_tbl_items_values);
                        
                        WHEN r_section.internal_name = g_aihs_inst_exec THEN
                        
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_inst_exec,
                                                      o_value         => l_value_inst_exec,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_solic,
                                                      o_value         => l_value_solic,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_value_solic IS NOT NULL
                            THEN
                                add_inst_exec(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                              i_ds_component       => r_section.id_ds_component,
                                              i_internal_name      => r_section.internal_name,
                                              i_flg_component_type => r_section.flg_component_type,
                                              io_tbl_items_values  => l_tbl_items_values);
                            END IF;
                        WHEN r_section.internal_name = g_aihs_uti THEN
                        
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aihs_solic,
                                                      o_value         => l_value_solic,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_value_solic IS NOT NULL
                            THEN
                                add_sys_domains(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                i_ds_component       => r_section.id_ds_component,
                                                i_internal_name      => r_section.internal_name,
                                                i_flg_component_type => r_section.flg_component_type,
                                                io_tbl_items_values  => l_tbl_items_values);
                            END IF;
                        
                        ELSE
                            NULL;
                    END CASE;
                ELSIF r_section.flg_data_type = c_data_type_md
                THEN
                    CASE
                        WHEN r_section.internal_name IN (g_aih_diag_first,
                                                         g_aih_diag_second,
                                                         g_aihs_proc_old,
                                                         g_aihs_diag_princ,
                                                         g_aihs_diag_sec,
                                                         g_aihs_proc_special,
                                                         g_aihs_proc_special2,
                                                         g_aihs_proc_special3,
                                                         g_aihs_proc_special4,
                                                         g_aihs_proc_special5,
                                                         g_aihs_proc_special6,
                                                         g_aihs_proc_special7,
                                                         g_aihs_proc_special8,
                                                         g_aihs_proc_special9,
                                                         g_aihs_proc_special10,
                                                         g_aihs_proc_special11,
                                                         g_aihs_proc_special12,
                                                         g_aihs_proc_special13,
                                                         g_aihs_proc_special14,
                                                         g_aihs_proc_special15,
                                                         g_aihs_proc_special16,
                                                         g_aihs_proc_special17,
                                                         g_aihs_proc_special18,
                                                         g_aihs_proc_special19) THEN
                        
                            IF NOT get_value_from_xml(i_lang          => i_lang,
                                                      i_xml           => i_xml,
                                                      i_internal_name => g_aih_diag_first,
                                                      o_value         => l_diag_princ_value,
                                                      o_alt_value     => l_dummy,
                                                      o_error         => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            IF l_diag_princ_value IS NOT NULL
                            THEN
                                l_has_diag_princ := pk_alert_constant.g_yes;
                            END IF;
                        
                            add_diag(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_episode            => i_episode,
                                     i_patient            => i_patient,
                                     i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type,
                                     io_tbl_items_values  => l_tbl_items_values);
                        ELSE
                            NULL;
                    END CASE;
                ELSIF r_section.flg_data_type = c_data_type_mmd
                THEN
                    CASE
                        WHEN r_section.internal_name IN (g_aih_diag_cause, g_aihs_causes) THEN
                            add_diag(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_episode            => i_episode,
                                     i_patient            => i_patient,
                                     i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                     i_ds_component       => r_section.id_ds_component,
                                     i_internal_name      => r_section.internal_name,
                                     i_flg_component_type => r_section.flg_component_type,
                                     io_tbl_items_values  => l_tbl_items_values);
                        ELSE
                            NULL;
                    END CASE;
                
                END IF;
            
                IF NOT add_data_val(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_patient         => i_patient,
                                    i_episode         => i_episode,
                                    i_ds_cmpt_mkt_rel => r_section.id_ds_cmpt_mkt_rel,
                                    i_internal_name   => r_section.internal_name,
                                    
                                    i_flg_edit_mode   => pk_alert_constant.g_no,
                                    io_tbl_sections   => l_final_tbl_sections,
                                    io_tbl_def_events => l_tbl_def_events,
                                    io_data_values    => l_aux_data_val,
                                    o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        
        END IF;
    
        o_section    := l_final_tbl_sections;
        o_events     := l_tbl_events;
        o_def_events := l_tbl_def_events;
    
        --o_items_values - This table has all multichoice options for all multichoice fields
        o_items_values := l_tbl_items_values;
    
        --o_data_val := l_aux_data_val;
        IF i_xml IS NOT NULL
        THEN
            o_data_val := xmltype.createxml(xmldata => i_xml);
        ELSE
            o_data_val := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            o_data_val := NULL;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            o_data_val := NULL;
            RETURN FALSE;
    END get_section_data_int;

    FUNCTION parse_val_fill_sect_param
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_params       IN CLOB,
        o_params       OUT rec_aih_section_data_param,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'PARSE_VAL_FILL_SECT_PARAM';
    
        --
        l_exception EXCEPTION;
        --
    
        FUNCTION get_table_sections(i_ds_components IN xmltype) RETURN t_table_ds_sections IS
            l_table_sections t_table_ds_sections;
        
            FUNCTION get_ds_sections RETURN t_table_ds_sections IS
                l_ret t_table_ds_sections;
            BEGIN
                WITH tbl_components AS
                 (SELECT id_ds_cmpt_mkt_rel,
                         id_ds_component_parent,
                         id_ds_component,
                         component_desc,
                         internal_name,
                         flg_component_type,
                         flg_data_type,
                         slg_internal_name,
                         NULL addit_info_xml_value,
                         rank,
                         max_len,
                         min_value,
                         max_value,
                         gender,
                         age_min_value,
                         age_min_unit_measure,
                         age_max_value,
                         age_max_unit_measure
                    FROM (SELECT VALUE(p) ds_component
                            FROM TABLE(xmlsequence(extract(i_ds_components, '/DS_COMPONENTS/DS_COMPONENT'))) p) b,
                         xmltable('/DS_COMPONENT' passing b.ds_component columns --
                                  "ID_DS_CMPT_MKT_REL" NUMBER(24) path '@ID_DS_CMPT_MKT_REL', --
                                  "ID_DS_COMPONENT_PARENT" NUMBER(24) path '@ID_DS_COMPONENT_PARENT', --
                                  "ID_DS_COMPONENT" NUMBER(24) path '@ID_DS_COMPONENT', --
                                  "COMPONENT_DESC" VARCHAR2(1000 CHAR) path '@COMPONENT_DESC', --
                                  "INTERNAL_NAME" VARCHAR2(200 CHAR) path '@INTERNAL_NAME', --
                                  "FLG_COMPONENT_TYPE" VARCHAR2(1 CHAR) path '@FLG_COMPONENT_TYPE', --
                                  "FLG_DATA_TYPE" VARCHAR2(2 CHAR) path '@FLG_DATA_TYPE', --
                                  "SLG_INTERNAL_NAME" VARCHAR2(200 CHAR) path '@SLG_INTERNAL_NAME', --
                                  "RANK" NUMBER(24) path '@RANK', --
                                  "MAX_LEN" NUMBER(24) path '@MAX_LEN', --
                                  "MIN_VALUE" NUMBER(24) path '@MIN_VALUE', --
                                  "MAX_VALUE" NUMBER(24) path '@MAX_VALUE', --
                                  "GENDER" VARCHAR2(1 CHAR) path '@GENDER', --
                                  "AGE_MIN_VALUE" NUMBER(24) path '@AGE_MIN_VALUE', --
                                  "AGE_MIN_UNIT_MEASURE" NUMBER(24) path '@AGE_MIN_UNIT_MEASURE', --
                                  "AGE_MAX_VALUE" NUMBER(5, 2) path '@AGE_MAX_VALUE', --
                                  "AGE_MAX_UNIT_MEASURE" NUMBER(24) path '@AGE_MAX_UNIT_MEASURE' --
                                  ))
                SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                         id_ds_component_parent => a.id_ds_component_parent,
                                         id_ds_component        => a.id_ds_component,
                                         component_desc         => a.component_desc,
                                         internal_name          => a.internal_name,
                                         flg_component_type     => a.flg_component_type,
                                         flg_data_type          => a.flg_data_type,
                                         slg_internal_name      => a.slg_internal_name,
                                         addit_info_xml_value   => a.addit_info_xml_value,
                                         rank                   => a.rank,
                                         max_len                => a.max_len,
                                         min_value              => a.min_value,
                                         max_value              => a.max_value,
                                         gender                 => a.gender,
                                         age_min_value          => a.age_min_value,
                                         age_min_unit_measure   => a.age_min_unit_measure,
                                         age_max_value          => a.age_max_value,
                                         age_max_unit_measure   => a.age_max_unit_measure,
                                         component_values       => NULL)
                  BULK COLLECT
                  INTO l_ret
                  FROM tbl_components a;
            
                RETURN l_ret;
            END get_ds_sections;
        
            PROCEDURE add_child_sections(io_tbl_sections IN OUT t_table_ds_sections) IS
                l_tbl_aux t_table_ds_sections;
            BEGIN
                IF io_tbl_sections.exists(1)
                THEN
                    FOR i IN io_tbl_sections.first .. io_tbl_sections.last
                    LOOP
                        SELECT t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
                                                 id_ds_component_parent => a.id_ds_component_parent,
                                                 id_ds_component        => a.id_ds_component,
                                                 component_desc         => a.component_desc,
                                                 internal_name          => a.internal_name,
                                                 flg_component_type     => a.flg_component_type,
                                                 flg_data_type          => a.flg_data_type,
                                                 slg_internal_name      => a.slg_internal_name,
                                                 addit_info_xml_value   => a.addit_info_xml_value,
                                                 rank                   => a.rank,
                                                 max_len                => a.max_len,
                                                 min_value              => a.min_value,
                                                 max_value              => a.max_value,
                                                 gender                 => a.gender,
                                                 age_min_value          => a.age_min_value,
                                                 age_min_unit_measure   => a.age_min_unit_measure,
                                                 age_max_value          => a.age_max_value,
                                                 age_max_unit_measure   => a.age_max_unit_measure,
                                                 component_values       => NULL)
                          BULK COLLECT
                          INTO l_tbl_aux
                          FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_component_name => io_tbl_sections(i).internal_name,
                                                                      i_component_type => io_tbl_sections(i)
                                                                                          .flg_component_type)) a
                         WHERE a.id_ds_component_parent = io_tbl_sections(i).id_ds_component;
                    END LOOP;
                
                    io_tbl_sections := io_tbl_sections MULTISET UNION ALL l_tbl_aux;
                END IF;
            END add_child_sections;
        BEGIN
            IF i_ds_components IS NOT NULL
            THEN
                l_table_sections := get_ds_sections();
            ELSE
                l_table_sections := t_table_ds_sections();
            END IF;
        
            add_child_sections(io_tbl_sections => l_table_sections);
        
            RETURN l_table_sections;
        END get_table_sections;
        --
        FUNCTION get_parameters RETURN rec_aih_section_data_param IS
            l_tbl_section t_table_ds_sections;
            l_ret         rec_aih_section_data_param;
        BEGIN
            IF i_params IS NOT NULL
            THEN
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error       := 'CALL GET_TABLE_SECTIONS';
                l_tbl_section := get_table_sections(i_ds_components => xmltype.createxml(i_params));
            
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error                          := 'FILL RETURN VALUE';
                l_ret.is_to_fill_with_saved_data := pk_alert_constant.g_yes;
            
                l_ret.tbl_sections := l_tbl_section;
            END IF;
        
            RETURN l_ret;
        EXCEPTION
            WHEN OTHERS THEN
                l_ret := NULL;
                RETURN l_ret;
        END get_parameters;
        --
        PROCEDURE fill_params_with_saved_data
        (
            i_tumor_num IN PLS_INTEGER,
            io_params   IN OUT rec_aih_section_data_param
        ) IS
        BEGIN
            --verify if id_diagnosis/id_alert_diagnosis has been already registered in the current patient
            --if so, get the most recent epis_diagnosis id and fill the form with it's data
            NULL;
        
        END fill_params_with_saved_data;
    BEGIN
        g_error := 'EXTRACT PARAMETERS FROM I_PARAMS';
    
        o_params := get_parameters();
    
        --I need to be sure that in the current call we are going only to treat one tumor, for intance, because of the input parameter with the selected topography
        --If the patient has multiple tumors then a call to this function must be made for each tumor 
        IF o_params.tbl_sections.exists(1)
        THEN
            FOR i IN o_params.tbl_sections.first .. o_params.tbl_sections.last
            LOOP
                NULL;
            END LOOP;
        END IF;
    
        g_error := 'FILL PARAMETERS WITH SAVED DATA';
        --fill_params_with_saved_data(i_tumor_num => l_tumor_num, io_params => o_params);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END parse_val_fill_sect_param;

    FUNCTION add_data_val
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_flg_edit_mode   IN VARCHAR2,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_DATA_VAL';
        --
        l_exception EXCEPTION;
    BEGIN
        IF i_flg_edit_mode = pk_alert_constant.g_no
        THEN
            g_error := 'CALL ADD_DEFAULT_VALUES';
            add_default_values(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_patient         => i_patient,
                               i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                               i_internal_name   => i_internal_name,
                               io_tbl_sections   => io_tbl_sections,
                               io_tbl_def_events => io_tbl_def_events,
                               io_data_values    => io_data_values);
        ELSE
            g_error := 'CALL ADD_SAVED_VALUES';
            IF NOT add_saved_values(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_episode         => i_episode,
                                    i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                    i_internal_name   => i_internal_name,
                                    i_flg_edit_mode   => i_flg_edit_mode,
                                    io_tbl_sections   => io_tbl_sections,
                                    io_tbl_def_events => io_tbl_def_events,
                                    io_data_values    => io_data_values,
                                    o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_data_val;

    PROCEDURE add_default_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype
    ) IS
    BEGIN
        CASE i_internal_name
            WHEN g_aih_procedure THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => NULL,
                                       i_alt_value       => NULL,
                                       i_desc_value      => NULL,
                                       i_is_saved_value  => FALSE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            WHEN g_aih_diag_second THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => NULL,
                                       i_alt_value       => NULL,
                                       i_desc_value      => NULL,
                                       i_is_saved_value  => FALSE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
                /*WHEN g_aih_diag_cause THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => NULL,
                                       i_alt_value       => NULL,
                                       i_desc_value      => NULL,
                                       i_is_saved_value  => FALSE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);*/
            ELSE
                NULL;
        END CASE;
    END add_default_values;

    FUNCTION add_saved_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_flg_edit_mode   IN VARCHAR2,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_SAVED_VALUES';
    
        --
        l_exception_wrong_params EXCEPTION;
        l_exception              EXCEPTION;
        --
    
        l_row_aih aih_simple%ROWTYPE;
    
    BEGIN
    
        /*SELECT a.*
         INTO l_row_aih
         FROM aih_simple a
        WHERE a.id_aih_simple = i_aih_simple;*/
    
        CASE i_internal_name
            WHEN g_aih_diag_first THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => l_row_aih.id_princ_diag,
                                       i_alt_value       => l_row_aih.id_princ_alert,
                                       i_desc_value      => 'FONIX',
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            WHEN g_aih_procedure THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => l_row_aih.id_proc_diag,
                                       i_alt_value       => l_row_aih.id_proc_alert,
                                       i_desc_value      => 'FONIX1',
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            WHEN g_aih_diag_second THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => l_row_aih.id_sec_diag,
                                       i_alt_value       => l_row_aih.id_sec_alert,
                                       i_desc_value      => 'FONIX3',
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
                /*            WHEN g_aih_diag_cause THEN
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_value           => l_row_aih.id_cause_diag,
                                       i_alt_value       => l_row_aih.id_cause_alert,
                                       i_desc_value      => 'FONIX3',
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);*/
            ELSE
                NULL;
        END CASE;
    
        --Mapping between DS component leafs and PK_DIAGNOSIS_CORE.GET_EPIS_DIAG_REC output vars
        --BEGIN SECTION CARACTERIZATION
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_saved_values;

    PROCEDURE set_nls_numeric_characters(i_prof IN profissional) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'SET_NLS_NUMERIC_CHARACTERS';
        --
        l_decimal_symbol  sys_config.value%TYPE;
        l_grouping_symbol VARCHAR2(1);
    BEGIN
        IF g_is_to_reset_nls
           AND g_back_nls IS NOT NULL
        THEN
            g_error := 'RESET NLS_NUMERIC_CHARACTERS';
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || g_nls_num_char || ' = ''' || g_back_nls || '''';
        
            g_is_to_reset_nls := FALSE;
        ELSIF NOT g_is_to_reset_nls
        THEN
            g_error          := 'GET DECIMAL SYMBOL';
            l_decimal_symbol := '.'; -- Flash is going to send all numbers with the . as decimal separator so I'm not goign to use this call pk_sysconfig.get_config(g_cfg_dec_symbol, i_prof);
        
            g_error := 'SET GROUPING SYMBOL';
            IF l_decimal_symbol = ','
            THEN
                l_grouping_symbol := '.';
            ELSE
                l_grouping_symbol := ',';
            END IF;
        
            g_error := 'GET NLS_NUMERIC_CHARACTERS';
            SELECT VALUE
              INTO g_back_nls
              FROM nls_session_parameters
             WHERE parameter = g_nls_num_char;
        
            g_error := 'SET NLS_NUMERIC_CHARACTERS';
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || g_nls_num_char || ' = ''' || l_decimal_symbol ||
                              l_grouping_symbol || '''';
        
            g_is_to_reset_nls := TRUE;
        END IF;
    END set_nls_numeric_characters;

    PROCEDURE add_to_data_values_obj
    (
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_value           IN VARCHAR2,
        i_alt_value       IN VARCHAR2,
        i_desc_value      IN VARCHAR2,
        i_xml_value       IN xmltype DEFAULT NULL,
        i_is_saved_value  IN BOOLEAN DEFAULT FALSE,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TO_DATA_VALUES_OBJ';
        --
        l_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    BEGIN
        IF i_value IS NOT NULL
           OR i_desc_value IS NOT NULL
           OR i_is_saved_value = FALSE
        THEN
            g_error := 'ADD TO DATA VALUES OBJ';
            SELECT xmlconcat(io_data_values,
                             xmlelement("COMPONENT_LEAF",
                                        xmlattributes(a.id_ds_cmpt_mkt_rel,
                                                      a.internal_name,
                                                      a.desc_value,
                                                      a.value,
                                                      a.alt_value),
                                        i_xml_value))
              INTO io_data_values
              FROM (SELECT i_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                           i_internal_name   AS internal_name,
                           i_desc_value      AS desc_value,
                           i_value           AS VALUE,
                           i_alt_value       AS alt_value
                      FROM dual) a;
        
            /*IF i_is_saved_value
               AND i_internal_name NOT IN (pk_diagnosis_form.g_dsc_cancer_staging_basis,
                                           pk_diagnosis_form.g_dsc_general_princ_diag,
                                           pk_diagnosis_form.g_dsc_cancer_princ_diag,
                                           pk_diagnosis_form.g_dsc_general_age_init_diag,
                                           pk_diagnosis_form.g_dsc_cancer_age_init_diag,
                                           pk_diagnosis_form.g_dsc_cancer_stage_grp,
                                           pk_diagnosis_form.g_dsc_cancer_stage,
                                           pk_diagnosis_form.g_dsc_acc_emer_sub_analysis,
                                           pk_diagnosis_form.g_dsc_acc_emer_anat_area,
                                           pk_diagnosis_form.g_dsc_acc_emer_anat_side,
                                           pk_diagnosis_form.g_dsc_cancer_progn_factors,
                                           pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                                           pk_diagnosis_form.g_dsc_cancer_progn_factors_cli,
                                           pk_diagnosis_form.g_dsc_general_invest_stat,
                                           pk_diagnosis_form.g_dsc_general_add_problem,
                                           pk_diagnosis_form.g_dsc_lesion_location,
                                           pk_diagnosis_form.g_dsc_lesion_type)
            THEN
                IF io_tbl_sections IS NOT NULL
                   AND io_tbl_def_events IS NOT NULL
                   AND io_tbl_sections.count > 0
                   AND io_tbl_def_events.count > 0
                THEN
                    g_error := 'GET PK OF SECTION: ' || i_internal_name;
                    SELECT sct.id_ds_cmpt_mkt_rel
                      INTO l_ds_cmpt_mkt_rel
                      FROM TABLE(io_tbl_sections) sct
                     WHERE sct.internal_name = i_internal_name;
                
                    FOR i IN io_tbl_def_events.first .. io_tbl_def_events.last
                    LOOP
                        IF io_tbl_def_events(i).id_ds_cmpt_mkt_rel = l_ds_cmpt_mkt_rel
                        THEN
                            io_tbl_def_events(i).flg_event_type := pk_alert_constant.g_active;
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            END IF;*/
        END IF;
    END add_to_data_values_obj;

    FUNCTION xml_to_aih_simple_record
    (
        i_lang                 language.id_language%TYPE,
        i_xml                  IN CLOB,
        o_aih_simple_row       OUT aih_simple%ROWTYPE,
        o_external_causes_rows OUT ts_aih_abs_data.aih_abs_data_tc,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_func_name CONSTANT VARCHAR2(30) := 'XML_TO_AIH_SIMPLE_RECORD';
        l_row_aih_simple      aih_simple%ROWTYPE;
        l_row_external_causes aih_abs_data%ROWTYPE;
    
        l_external_causes_id PLS_INTEGER := 1;
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_nlen NUMBER;
    
        tbl_causes_diag_ids  table_number;
        tbl_causes_alert_ids table_number;
    
    BEGIN
    
        l_p := xmlparser.newparser;
        xmlparser.parsebuffer(l_p, i_xml);
        l_doc := xmlparser.getdocument(l_p);
    
        l_nl   := xmldom.getelementsbytagname(l_doc, '*');
        l_nlen := xmldom.getlength(l_nl);
    
        l_row_aih_simple.id_aih_simple := seq_aih_simple.nextval;
    
        FOR j IN 0 .. l_nlen - 1
        LOOP
        
            l_n := xmldom.item(l_nl, j);
            l_e := xmldom.makeelement(l_n);
        
            CASE xmldom.getattribute(l_e, g_xml_internal_name)
                WHEN g_aih_diag_first THEN
                    l_row_aih_simple.id_princ_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_simple.id_princ_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN g_aih_procedure THEN
                    l_row_aih_simple.id_proc_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_simple.id_proc_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN g_aih_diag_second THEN
                    l_row_aih_simple.id_sec_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_simple.id_sec_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN g_aih_diag_cause THEN
                
                    tbl_causes_diag_ids  := pk_utils.str_split_n(i_list  => xmldom.getattribute(l_e, g_xml_value),
                                                                 i_delim => ',');
                    tbl_causes_alert_ids := pk_utils.str_split_n(i_list  => xmldom.getattribute(l_e, g_xml_alt_value),
                                                                 i_delim => ',');
                
                    FOR i IN 1 .. tbl_causes_diag_ids.count
                    LOOP
                    
                        l_row_external_causes.id_aih_data     := l_row_aih_simple.id_aih_simple;
                        l_row_external_causes.id_aih_abs_data := seq_aih_abs_data.nextval;
                        l_row_external_causes.flg_aih_type    := g_aih_simple_si;
                        l_row_external_causes.flg_field_type  := g_aih_external_causes_field_ec;
                        l_row_external_causes.id_diag         := tbl_causes_diag_ids(i);
                        l_row_external_causes.id_alert_diag := CASE
                                                                   WHEN tbl_causes_alert_ids.exists(1) THEN
                                                                    tbl_causes_alert_ids(i)
                                                                   ELSE
                                                                    NULL
                                                               END;
                    
                        o_external_causes_rows(l_external_causes_id) := l_row_external_causes;
                        l_external_causes_id := l_external_causes_id + 1;
                    END LOOP;
                ELSE
                    NULL;
            END CASE;
        
        END LOOP;
    
        o_aih_simple_row := l_row_aih_simple;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END xml_to_aih_simple_record;

    FUNCTION get_config_table_ea_value(i_id_record config_table.id_record%TYPE) RETURN NUMBER AS
        l_ret NUMBER;
    BEGIN
    
        SELECT a.field_02
          INTO l_ret
          FROM config_table a
         WHERE a.config_table = 'AIH_EXEC_INSTIT'
           AND a.id_record = i_id_record;
    
        RETURN l_ret;
    END get_config_table_ea_value;

    FUNCTION xml_to_aih_special_record
    (
        i_lang                 language.id_language%TYPE,
        i_xml                  IN CLOB,
        o_aih_special_row      OUT aih_special%ROWTYPE,
        o_external_causes_rows OUT ts_aih_abs_data.aih_abs_data_tc,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_func_name CONSTANT VARCHAR2(30) := 'XML_TO_AIH_SPECIAL_RECORD';
        l_row_aih_special     aih_special%ROWTYPE;
        l_row_external_causes aih_abs_data%ROWTYPE;
    
        l_external_causes_id PLS_INTEGER := 1;
        l_proc_special_id    PLS_INTEGER := 1;
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_nlen NUMBER;
    
        tbl_causes_diag_ids  table_number;
        tbl_causes_alert_ids table_number;
        l_cnes               VARCHAR2(20 CHAR);
    
    BEGIN
    
        l_p := xmlparser.newparser;
        xmlparser.parsebuffer(l_p, i_xml);
        l_doc := xmlparser.getdocument(l_p);
    
        l_nl   := xmldom.getelementsbytagname(l_doc, '*');
        l_nlen := xmldom.getlength(l_nl);
    
        l_row_aih_special.id_aih_special := seq_aih_special.nextval;
    
        FOR j IN 0 .. l_nlen - 1
        LOOP
        
            l_n := xmldom.item(l_nl, j);
            l_e := xmldom.makeelement(l_n);
        
            CASE
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_solic THEN
                    l_row_aih_special.id_solic_type := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_inst_exec THEN
                    l_row_aih_special.id_inst_exec := xmldom.getattribute(l_e, g_xml_value);
                
                    l_cnes := get_config_table_ea_value(l_row_aih_special.id_inst_exec);
                
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_inst_exec_oth THEN
                    l_row_aih_special.inst_exec_oth := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_cnes THEN
                    l_row_aih_special.inst_cnes := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_resp_name THEN
                    l_row_aih_special.resp_name := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_phone THEN
                    l_row_aih_special.resp_phone := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_proc_old THEN
                    l_row_aih_special.id_proc_diag_old  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_special.id_proc_alert_old := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_diag_princ THEN
                    l_row_aih_special.id_princ_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_special.id_princ_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_proc_princ THEN
                    l_row_aih_special.id_proc_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_special.id_proc_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_proc_change THEN
                    l_row_aih_special.id_proc_diag_chg  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_special.id_proc_alert_chg := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_diag_sec THEN
                    l_row_aih_special.id_sec_diag  := xmldom.getattribute(l_e, g_xml_value);
                    l_row_aih_special.id_sec_alert := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_causes THEN
                
                    tbl_causes_diag_ids  := pk_utils.str_split_n(i_list  => xmldom.getattribute(l_e, g_xml_value),
                                                                 i_delim => ',');
                    tbl_causes_alert_ids := pk_utils.str_split_n(i_list  => xmldom.getattribute(l_e, g_xml_alt_value),
                                                                 i_delim => ',');
                
                    FOR i IN 1 .. tbl_causes_diag_ids.count
                    LOOP
                    
                        l_row_external_causes.id_aih_data     := l_row_aih_special.id_aih_special;
                        l_row_external_causes.id_aih_abs_data := seq_aih_abs_data.nextval;
                        l_row_external_causes.flg_aih_type    := g_aih_special_sp;
                        l_row_external_causes.flg_field_type  := g_aih_external_causes_field_ec;
                        l_row_external_causes.id_diag         := tbl_causes_diag_ids(i);
                        l_row_external_causes.id_alert_diag := CASE
                                                                   WHEN tbl_causes_alert_ids.exists(1) THEN
                                                                    tbl_causes_alert_ids(i)
                                                                   ELSE
                                                                    NULL
                                                               END;
                    
                        o_external_causes_rows(l_external_causes_id) := l_row_external_causes;
                        l_external_causes_id := l_external_causes_id + 1;
                    END LOOP;
                
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_uti THEN
                    l_row_aih_special.id_uti := xmldom.getattribute(l_e, g_xml_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) IN
                     (g_aihs_proc_special,
                      g_aihs_proc_special2,
                      g_aihs_proc_special3,
                      g_aihs_proc_special4,
                      g_aihs_proc_special5,
                      g_aihs_proc_special6,
                      g_aihs_proc_special7,
                      g_aihs_proc_special8,
                      g_aihs_proc_special9,
                      g_aihs_proc_special10,
                      g_aihs_proc_special11,
                      g_aihs_proc_special12,
                      g_aihs_proc_special13,
                      g_aihs_proc_special14,
                      g_aihs_proc_special15,
                      g_aihs_proc_special16,
                      g_aihs_proc_special17,
                      g_aihs_proc_special18,
                      g_aihs_proc_special19) THEN
                    l_row_external_causes.id_aih_data     := l_row_aih_special.id_aih_special;
                    l_row_external_causes.id_aih_abs_data := seq_aih_abs_data.nextval;
                    l_row_external_causes.flg_aih_type    := g_aih_special_sp;
                    l_row_external_causes.flg_field_type  := g_aih_proc_special_field_pc;
                    l_row_external_causes.id_diag         := xmldom.getattribute(l_e, g_xml_value);
                    l_row_external_causes.id_alert_diag   := xmldom.getattribute(l_e, g_xml_alt_value);
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) IN
                     (g_aihs_proc_special_q,
                      g_aihs_proc_special_q2,
                      g_aihs_proc_special_q3,
                      g_aihs_proc_special_q4,
                      g_aihs_proc_special_q5,
                      g_aihs_proc_special_q6,
                      g_aihs_proc_special_q7,
                      g_aihs_proc_special_q8,
                      g_aihs_proc_special_q9,
                      g_aihs_proc_special_q10,
                      g_aihs_proc_special_q11,
                      g_aihs_proc_special_q12,
                      g_aihs_proc_special_q13,
                      g_aihs_proc_special_q14,
                      g_aihs_proc_special_q15,
                      g_aihs_proc_special_q16,
                      g_aihs_proc_special_q17,
                      g_aihs_proc_special_q18,
                      g_aihs_proc_special_q19) THEN
                
                    l_row_external_causes.diag_quantity := xmldom.getattribute(l_e, g_xml_value);
                    l_row_external_causes.abs_order     := l_proc_special_id;
                    l_proc_special_id                   := l_proc_special_id + 1;
                
                    o_external_causes_rows(l_external_causes_id) := l_row_external_causes;
                    l_external_causes_id := l_external_causes_id + 1;
                WHEN xmldom.getattribute(l_e, g_xml_internal_name) = g_aihs_just THEN
                    l_row_aih_special.reason := xmldom.getattribute(l_e, g_xml_value);
                
                ELSE
                    NULL;
            END CASE;
        
        END LOOP;
    
        IF l_row_aih_special.inst_cnes IS NULL
        THEN
            l_row_aih_special.inst_cnes := l_cnes;
        END IF;
    
        o_aih_special_row := l_row_aih_special;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END xml_to_aih_special_record;

    FUNCTION get_value_from_xml
    (
        i_lang          language.id_language%TYPE,
        i_xml           IN CLOB,
        i_internal_name ds_component.internal_name%TYPE,
        o_value         OUT VARCHAR,
        o_alt_value     OUT VARCHAR,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_VALUE_FROM_XML';
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_nlen NUMBER;
    
    BEGIN
        IF (i_xml IS NOT NULL)
        THEN
            l_p := xmlparser.newparser;
            xmlparser.parsebuffer(l_p, i_xml);
            l_doc := xmlparser.getdocument(l_p);
        
            l_nl   := xmldom.getelementsbytagname(l_doc, '*');
            l_nlen := xmldom.getlength(l_nl);
        
            FOR j IN 0 .. l_nlen - 1
            LOOP
            
                l_n := xmldom.item(l_nl, j);
                l_e := xmldom.makeelement(l_n);
            
                IF xmldom.getattribute(l_e, g_xml_internal_name) = i_internal_name
                THEN
                    o_value     := xmldom.getattribute(l_e, g_xml_value);
                    o_alt_value := xmldom.getattribute(l_e, g_xml_alt_value);
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_value_from_xml;

    FUNCTION get_count_proc_special
    (
        i_lang  language.id_language%TYPE,
        i_xml   IN CLOB,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_VALUE_FROM_XML';
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_nlen NUMBER;
    
        l_count_proc_special NUMBER := 0;
    
    BEGIN
        IF (i_xml IS NOT NULL)
        THEN
            l_p := xmlparser.newparser;
            xmlparser.parsebuffer(l_p, i_xml);
            l_doc := xmlparser.getdocument(l_p);
        
            l_nl   := xmldom.getelementsbytagname(l_doc, '*');
            l_nlen := xmldom.getlength(l_nl);
        
            FOR j IN 0 .. l_nlen - 1
            LOOP
            
                l_n := xmldom.item(l_nl, j);
                l_e := xmldom.makeelement(l_n);
            
                CASE
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) IN
                         (g_aihs_proc_special,
                          g_aihs_proc_special2,
                          g_aihs_proc_special3,
                          g_aihs_proc_special4,
                          g_aihs_proc_special5,
                          g_aihs_proc_special6,
                          g_aihs_proc_special7,
                          g_aihs_proc_special8,
                          g_aihs_proc_special9,
                          g_aihs_proc_special10,
                          g_aihs_proc_special11,
                          g_aihs_proc_special12,
                          g_aihs_proc_special13,
                          g_aihs_proc_special14,
                          g_aihs_proc_special15,
                          g_aihs_proc_special16,
                          g_aihs_proc_special17,
                          g_aihs_proc_special18,
                          g_aihs_proc_special19)
                    
                     THEN
                        l_count_proc_special := l_count_proc_special + 1;
                    ELSE
                        NULL;
                END CASE;
            
            END LOOP;
        END IF;
    
        o_count := l_count_proc_special;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_count_proc_special;

    /**
    * Log the abd data list sctructure to be used when the log_debug is active
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   05-Set-2017
    */
    PROCEDURE log_abs_data_list(i_list ts_aih_abs_data.aih_abs_data_tc) IS
    BEGIN
        FOR i IN i_list.first .. i_list.last
        LOOP
            pk_alertlog.log_debug(i || '--------------------------------');
            pk_alertlog.log_debug(i_list(i).id_aih_data);
            pk_alertlog.log_debug(i_list(i).id_aih_abs_data);
            pk_alertlog.log_debug(i_list(i).flg_aih_type);
            pk_alertlog.log_debug(i_list(i).flg_field_type);
            pk_alertlog.log_debug(i_list(i).id_diag);
            pk_alertlog.log_debug(i_list(i).id_alert_diag);
        END LOOP;
    END log_abs_data_list;

    FUNCTION set_aih_simple
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_xml        IN CLOB,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_AIH_SIMPLE';
    
        l_row_aih_simple       aih_simple%ROWTYPE;
        l_rows_external_causes ts_aih_abs_data.aih_abs_data_tc;
        l_rows_out             table_varchar;
        l_rows_ext_causes      table_varchar;
        l_id_aih_simple        table_number := table_number();
        l_cancel_notes_desc    pk_translation.t_desc_translation;
        l_count_tasks          PLS_INTEGER;
    
    BEGIN
    
        g_error := 'XML_TO_AIH_SIMPLE_RECORD';
        IF NOT xml_to_aih_simple_record(i_lang                 => i_lang,
                                        i_xml                  => i_xml,
                                        o_aih_simple_row       => l_row_aih_simple,
                                        o_external_causes_rows => l_rows_external_causes,
                                        o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_row_aih_simple.id_episode      := i_episode;
        l_row_aih_simple.id_patient      := i_patient;
        l_row_aih_simple.id_professional := i_prof.id;
        l_row_aih_simple.id_institution  := i_prof.institution;
        l_row_aih_simple.flg_status      := g_aih_flg_status_a;
        l_row_aih_simple.dt_order_tstz   := current_timestamp;
    
        IF (i_id_epis_pn IS NOT NULL)
        THEN
            g_error := 'Call pk_prog_notes_out.get_note_tasks_by_task_type';
            IF NOT pk_prog_notes_out.get_note_tasks_by_task_type(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_epis_pn => i_id_epis_pn,
                                                                 i_id_tl_task => pk_prog_notes_constants.g_task_cits_procedures,
                                                                 o_tasks      => l_id_aih_simple,
                                                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_count_tasks := cardinality(l_id_aih_simple);
        
            IF (l_count_tasks > 0)
            THEN
                l_cancel_notes_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'AIH_M002');
            
                FOR i IN 1 .. l_count_tasks
                LOOP
                    g_error := 'SET_CANCEL_AIH_SIMPLE. i_aih_simple: ' || l_id_aih_simple(i);
                    IF NOT set_cancel_aih_simple(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_aih_simple   => l_id_aih_simple(i),
                                                 i_notes_cancel => l_cancel_notes_desc,
                                                 o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        ts_aih_simple.ins(rec_in => l_row_aih_simple, rows_out => l_rows_out);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'AIH_SIMPLE',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        IF (l_rows_external_causes.count > 0)
        THEN
            IF (g_debug_enable)
            THEN
                pk_alertlog.log_debug('l_rows_external_causes DATA');
                log_abs_data_list(l_rows_external_causes);
            END IF;
        
            g_error := 'Insert external causes data';
            ts_aih_abs_data.ins(rows_in => l_rows_external_causes, rows_out => l_rows_ext_causes);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'AIH_ABS_DATA',
                                          i_rowids     => l_rows_ext_causes,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_aih_simple;

    FUNCTION set_aih_special
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_xml        IN CLOB,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_AIH_SIMPLE';
    
        l_row_aih_special      aih_special%ROWTYPE;
        l_rows_external_causes ts_aih_abs_data.aih_abs_data_tc;
        l_rows_out             table_varchar;
        l_rows_ext_causes      table_varchar;
        l_id_aih_special       table_number := table_number();
        l_count_tasks          PLS_INTEGER;
        l_cancel_notes_desc    pk_translation.t_desc_translation;
    
    BEGIN
        --raise_application_error(-20001,'teste');
        g_error := 'XML_TO_AIH_SPECIAL_RECORD';
        IF NOT xml_to_aih_special_record(i_lang                 => i_lang,
                                         i_xml                  => i_xml,
                                         o_aih_special_row      => l_row_aih_special,
                                         o_external_causes_rows => l_rows_external_causes,
                                         o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_row_aih_special.id_episode      := i_episode;
        l_row_aih_special.id_patient      := i_patient;
        l_row_aih_special.id_professional := i_prof.id;
        l_row_aih_special.id_institution  := i_prof.institution;
        l_row_aih_special.flg_status      := g_aih_flg_status_a;
        l_row_aih_special.dt_order_tstz   := current_timestamp;
    
        IF (i_id_epis_pn IS NOT NULL)
        THEN
            g_error := 'Call pk_prog_notes_out.get_note_tasks_by_task_type';
            IF NOT pk_prog_notes_out.get_note_tasks_by_task_type(i_lang       => i_lang,
                                                                 i_prof       => i_prof,
                                                                 i_id_epis_pn => i_id_epis_pn,
                                                                 i_id_tl_task => pk_prog_notes_constants.g_task_cits_procedures_special,
                                                                 o_tasks      => l_id_aih_special,
                                                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_count_tasks := cardinality(l_id_aih_special);
        
            IF (l_count_tasks > 0)
            THEN
                l_cancel_notes_desc := pk_message.get_message(i_lang => i_lang, i_code_mess => 'AIH_M002');
            
                FOR i IN 1 .. l_count_tasks
                LOOP
                    g_error := 'set_cancel_aih_special. i_aih_special: ' || l_id_aih_special(i);
                    IF NOT set_cancel_aih_special(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_aih_special  => l_id_aih_special(i),
                                                  i_notes_cancel => l_cancel_notes_desc,
                                                  o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        -- IF i_aih_simple IS NULL
        -- OR i_aih_simple = 0
        -- THEN
        ts_aih_special.ins(rec_in => l_row_aih_special, rows_out => l_rows_out);
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'AIH_SPECIAL',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
        --ELSE
        /*ts_aih_simple.upd(rec_in => l_row_aih_simple, rows_out => l_rows_out);
        
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'AIH_SIMPLE',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);*/
    
        -- END IF;
    
        IF (l_rows_external_causes.count > 0)
        THEN
            IF (g_debug_enable)
            THEN
                pk_alertlog.log_debug('l_rows_external_causes DATA');
                log_abs_data_list(l_rows_external_causes);
            END IF;
        
            g_error := 'Insert external causes data';
            ts_aih_abs_data.ins(rows_in => l_rows_external_causes, rows_out => l_rows_ext_causes);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'AIH_ABS_DATA',
                                          i_rowids     => l_rows_ext_causes,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_aih_special;

    PROCEDURE add_new_item
    (
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_item_desc          IN pk_translation.t_desc_translation,
        i_item_value         IN sys_list.id_sys_list%TYPE DEFAULT NULL,
        i_item_alt_value     IN sys_list_group_rel.flg_context%TYPE DEFAULT NULL,
        i_item_xml_value     IN CLOB DEFAULT NULL,
        i_item_rank          IN sys_list_group_rel.rank%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_ITEM';
        --
        r_item_value t_rec_ds_items_values;
    BEGIN
        g_error := 'NEW T_REC_DS_ITEMS_VALUES INSTANCE';
    
        r_item_value := t_rec_ds_items_values(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                              id_ds_component    => i_ds_component,
                                              internal_name      => i_internal_name,
                                              flg_component_type => i_flg_component_type,
                                              item_desc          => i_item_desc,
                                              item_value         => i_item_value,
                                              item_alt_value     => i_item_alt_value,
                                              item_xml_value     => i_item_xml_value,
                                              item_rank          => i_item_rank);
    
        g_error := 'ADD TO TABLE L_TBL_ITEMS_VALUES';
        io_tbl_items_values.extend;
        io_tbl_items_values(io_tbl_items_values.count) := r_item_value;
    END add_new_item;

    PROCEDURE set_tl_aih
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row      task_timeline_ea%ROWTYPE;
        l_func_proc_name   VARCHAR2(30) := 'SET_TL_AIH';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
    
    BEGIN
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := 'U';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            pk_alertlog.log_debug(g_error);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                g_error := 'GET ROWIDS AND INFORMATION';
                pk_alertlog.log_debug(g_error);
                pk_alertlog.log_debug('rowS:' || pk_utils.to_string(i_input => i_rowids));
            
                FOR r_cur IN (SELECT id_external_request,
                                     id_patient,
                                     id_episode,
                                     flg_status,
                                     id_prof_requested,
                                     dt_requested,
                                     id_inst_orig,
                                     code_description,
                                     --  id_prof_requested,
                                     dt_last_interaction_tstz,
                                     id_visit,
                                     flg_outdated,
                                     flg_ongoing,
                                     id_tl_task,
                                     flg_status_epis
                                FROM (SELECT aih.id_aih_simple id_external_request,
                                             aih.id_patient,
                                             aih.id_episode,
                                             aih.flg_status,
                                             aih.id_professional id_prof_requested,
                                             aih.dt_order_tstz dt_requested,
                                             aih.id_institution id_inst_orig,
                                             NULL code_description,
                                             aih.dt_last_update_tstz dt_last_interaction_tstz,
                                             e.id_visit id_visit,
                                             CASE
                                                  WHEN aih.flg_status IN (g_aih_flg_status_c) THEN
                                                   pk_ea_logic_tasktimeline.g_flg_outdated
                                                  ELSE
                                                   pk_ea_logic_tasktimeline.g_flg_not_outdated
                                              END flg_outdated,
                                             CASE
                                                  WHEN aih.flg_status IN (g_aih_flg_status_c) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             pk_prog_notes_constants.g_task_cits_procedures id_tl_task,
                                             e.flg_status flg_status_epis
                                        FROM aih_simple aih
                                        LEFT JOIN episode e
                                          ON aih.id_episode = e.id_episode
                                       WHERE aih.rowid IN (SELECT vc_1
                                                             FROM tbl_temp)
                                         AND i_source_table_name = 'AIH_SIMPLE')
                              UNION ALL
                              SELECT id_external_request,
                                     id_patient,
                                     id_episode,
                                     flg_status,
                                     id_prof_requested,
                                     dt_requested,
                                     id_inst_orig,
                                     code_description,
                                     --  id_prof_requested,
                                     dt_last_interaction_tstz,
                                     id_visit,
                                     flg_outdated,
                                     flg_ongoing,
                                     id_tl_task,
                                     flg_status_epis
                                FROM (SELECT aih.id_aih_special id_external_request,
                                             aih.id_patient,
                                             aih.id_episode,
                                             aih.flg_status,
                                             aih.id_professional id_prof_requested,
                                             aih.dt_order_tstz dt_requested,
                                             aih.id_institution id_inst_orig,
                                             NULL code_description,
                                             aih.dt_last_update_tstz dt_last_interaction_tstz,
                                             e.id_visit id_visit,
                                             CASE
                                                  WHEN aih.flg_status IN (g_aih_flg_status_c) THEN
                                                   pk_ea_logic_tasktimeline.g_flg_outdated
                                                  ELSE
                                                   pk_ea_logic_tasktimeline.g_flg_not_outdated
                                              END flg_outdated,
                                             CASE
                                                  WHEN aih.flg_status IN (g_aih_flg_status_c) THEN
                                                   pk_prog_notes_constants.g_task_finalized_f
                                                  ELSE
                                                   pk_prog_notes_constants.g_task_ongoing_o
                                              END flg_ongoing,
                                             pk_prog_notes_constants.g_task_cits_procedures_special id_tl_task,
                                             e.flg_status flg_status_epis
                                        FROM aih_special aih
                                        LEFT JOIN episode e
                                          ON aih.id_episode = e.id_episode
                                       WHERE aih.rowid IN (SELECT vc_1
                                                             FROM tbl_temp)
                                         AND i_source_table_name = 'AIH_SPECIAL'))
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    g_error := 'CALL set_tl_aih - id_aih: ' || r_cur.id_external_request || ' id_patient: ' ||
                               r_cur.id_patient;
                    pk_alertlog.log_debug(g_error);
                
                    l_new_rec_row.id_tl_task        := r_cur.id_tl_task;
                    l_new_rec_row.table_name        := g_aih_simple;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_external_request;
                    l_new_rec_row.dt_begin          := r_cur.dt_requested;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_requested;
                    l_new_rec_row.dt_req            := r_cur.dt_requested;
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_inst_orig;
                    l_new_rec_row.code_description  := r_cur.code_description;
                    l_new_rec_row.id_prof_exec      := r_cur.id_prof_requested;
                    l_new_rec_row.flg_outdated      := r_cur.flg_outdated;
                    l_new_rec_row.flg_sos           := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing       := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal        := pk_alert_constant.g_yes;
                    l_new_rec_row.flg_has_comments  := pk_alert_constant.g_no;
                    --     l_new_rec_row.status_flg        := r_cur.status_flg;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_interaction_tstz;
                    l_new_rec_row.rank           := 10;
                    --
                
                    pk_alertlog.log_error('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in task_timeline_ea table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status <> 'C' -- Active Data
                       AND r_cur.flg_status_epis <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea ttea
                         WHERE ttea.id_task_refid = l_new_rec_row.id_task_refid
                           AND ttea.id_tl_task = l_new_rec_row.id_tl_task;
                    
                        -- IF exists one registry, information should be UPDATED in task_timeline_ea table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in task_timeline_ea table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSIF r_cur.flg_status = 'C'
                          OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Cancelled data
                        --
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
                    END IF;
                
                    /*
                    * Operations to perform in task_timeline_ea Easy Access table:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_task_timeline_ea.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE:
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin      => TRUE,
                                                dt_req_in       => l_new_rec_row.dt_req,
                                                id_prof_req_nin => TRUE,
                                                id_prof_req_in  => l_new_rec_row.id_prof_req,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => NULL,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                --
                                                table_name_nin       => FALSE,
                                                table_name_in        => l_new_rec_row.table_name,
                                                flg_show_method_nin  => FALSE,
                                                flg_show_method_in   => l_new_rec_row.flg_show_method,
                                                code_description_nin => FALSE,
                                                code_description_in  => l_new_rec_row.code_description,
                                                --
                                                flg_outdated_nin         => TRUE,
                                                flg_outdated_in          => l_new_rec_row.flg_outdated,
                                                rank_nin                 => TRUE,
                                                rank_in                  => l_new_rec_row.rank,
                                                flg_sos_nin              => FALSE,
                                                flg_sos_in               => l_new_rec_row.flg_sos,
                                                id_parent_task_refid_nin => TRUE,
                                                id_parent_task_refid_in  => l_new_rec_row.id_parent_task_refid,
                                                flg_ongoing_nin          => TRUE,
                                                flg_ongoing_in           => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin           => TRUE,
                                                flg_normal_in            => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin         => TRUE,
                                                id_prof_exec_in          => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin     => TRUE,
                                                flg_has_comments_in      => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in        => l_new_rec_row.dt_last_update,
                                                rows_out                 => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        NULL;
                    END IF;
                END LOOP;
                pk_alertlog.log_debug('END LOOP');
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TL_' || upper(i_source_table_name),
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_tl_aih;

    /**
    * Function to get the aih abstract data description. 
    * To be used to get the external causes and the special procedures descriptions.
    * Or other fields that allow the selection of multiple diagnosis 
    *
    * @param   i_lang            Professional preferred language
    * @param   i_prof            Professional identification and its context (institution and software)
    * @param   i_id_aih_data     Link to the aih_simple or aih special table
    * @param   i_flg_aih_type    Type: Simple or special
    * @param   i_fld_field_type  Identifies the field: f.e. external causes
    * @param   i_id_task_type    Task type to diagnosis descriptions
    * @param   i_flg_return_type D - diagnosis description; C-diagnosis code
    *
    * @param   description of the diagnosis in the abstract field
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_abs_data_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_aih_data     IN aih_abs_data.id_aih_data%TYPE,
        i_flg_aih_type    IN aih_abs_data.flg_aih_type%TYPE,
        i_fld_field_type  IN aih_abs_data.flg_field_type%TYPE,
        i_id_task_type    IN task_type.id_task_type%TYPE,
        i_flg_return_type IN VARCHAR2 DEFAULT g_description
    ) RETURN pk_translation.t_desc_translation AS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ABS_DATA_DESC';
        l_desc  pk_translation.t_desc_translation;
        l_error t_error_out;
    BEGIN
        g_error := 'GET_ABS_DATA_DESC. i_id_aih_data: ' || i_id_aih_data || ' i_flg_aih_type: ' || i_flg_aih_type ||
                   ' i_fld_field_type: ' || i_fld_field_type || ' i_id_task_type: ' || i_id_task_type;
        SELECT listagg(CASE
                            WHEN i_flg_return_type = g_description THEN
                             pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_id_concept_term => id_alert_diag,
                                                             i_id_task_type    => i_id_task_type,
                                                             i_flg_show_code   => g_flg_show_code)
                            ELSE
                             pk_ts1_api.get_term_code(id_alert_diag)
                        END,
                        '; ') within GROUP(ORDER BY 1)
          INTO l_desc
          FROM (SELECT aad.id_alert_diag
                  FROM aih_abs_data aad
                 WHERE aad.id_aih_data = i_id_aih_data
                   AND aad.flg_aih_type = i_flg_aih_type
                   AND aad.flg_field_type = i_fld_field_type) t;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END get_abs_data_desc;

    /**
    * Function to return the description of all fields presented in the AIH simple screen.
    * To be used in Single Page
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_aih_simple AIH simple identifier 
    *
    * @param   AIH simple descriptions
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_simple_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_aih_simple IN aih_simple.id_aih_simple%TYPE
    ) RETURN CLOB AS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AIH_SIMPLE_DESC';
        l_desc                  CLOB;
        l_diag_princ_label      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'DIAGNOSIS_DIFF_M001');
        l_procedure_label       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T001');
        l_diag_sec_label        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T002');
        l_external_causes_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T020');
        l_diag_princ_desc       pk_translation.t_desc_translation;
        l_diag_sec_desc         pk_translation.t_desc_translation;
        l_external_causes_desc  pk_translation.t_desc_translation;
        l_procedure_desc        pk_translation.t_desc_translation;
        l_error                 t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET_AIH_SIMPLE_DESC. i_id_aih_simple: ' || i_id_aih_simple;
            SELECT pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_concept_term => aihs.id_princ_alert,
                                                   i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                   i_flg_show_code   => g_flg_show_code) principal_diag_desc,
                   pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_concept_term => aihs.id_sec_alert,
                                                   i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                   i_flg_show_code   => g_flg_show_code) sec_diag_desc,
                   pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_id_concept_term => aihs.id_proc_alert,
                                                   i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                   i_flg_show_code   => g_flg_show_code) procedure_desc,
                   get_abs_data_desc(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_aih_data    => aihs.id_aih_simple,
                                     i_flg_aih_type   => g_aih_simple_si,
                                     i_fld_field_type => g_aih_external_causes_field_ec,
                                     i_id_task_type   => pk_alert_constant.g_task_diagnosis) external_causes_desc
              INTO l_diag_princ_desc, l_diag_sec_desc, l_procedure_desc, l_external_causes_desc
              FROM aih_simple aihs
             WHERE aihs.id_aih_simple = i_id_aih_simple;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'Build description';
        l_desc  := l_diag_princ_label || chr(10) || l_diag_princ_desc;
    
        IF (l_procedure_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_procedure_label || chr(10) || l_procedure_desc;
        END IF;
    
        IF (l_diag_sec_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_diag_sec_label || chr(10) || l_diag_sec_desc;
        END IF;
    
        IF (l_external_causes_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_external_causes_label || chr(10) || l_external_causes_desc;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END get_aih_simple_desc;

    /**
    * Function to cancel a AIH simple record
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_aih_simple   AIH simple identifier
    * @param   i_notes_cancel Cancelation notes
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   01-Set-2017
    */
    FUNCTION set_cancel_aih_simple
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_notes_cancel IN aih_simple.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_CANCEL_AIH_SIMPLE';
        l_rows_out table_varchar;
    
    BEGIN
        g_error := 'SET_CANCEL_AIH_SIMPLE. i_aih_simple: ' || i_aih_simple;
        IF (i_aih_simple IS NOT NULL)
        THEN
            ts_aih_simple.upd(id_aih_simple_in => i_aih_simple,
                              flg_status_in    => g_aih_flg_status_c,
                              notes_cancel_in  => i_notes_cancel,
                              rows_out         => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'AIH_SIMPLE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_cancel_aih_simple;

    /**
    * Function to cancel a AIH simple record
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_aih_simple   AIH simple identifier
    * @param   i_notes_cancel Cancelation notes
    *
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   01-Set-2017
    */
    FUNCTION set_cancel_aih_special
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_aih_special  IN aih_special.id_aih_special%TYPE,
        i_notes_cancel IN aih_special.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_CANCEL_AIH_SPECIAL';
        l_rows_out table_varchar;
    
    BEGIN
        g_error := 'SET_CANCEL_AIH_SPECIAL. i_aih_special: ' || i_aih_special;
        IF (i_aih_special IS NOT NULL)
        THEN
            ts_aih_special.upd(id_aih_special_in => i_aih_special,
                               flg_status_in     => g_aih_flg_status_c,
                               notes_cancel_in   => i_notes_cancel,
                               rows_out          => l_rows_out);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'AIH_SPECIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_cancel_aih_special;

    /**
    * Function to get the aih simple information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_simple_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AIH_SIMPLE_REPORT';
        l_id_aihs table_number;
    BEGIN
    
        g_error := 'PK_PROG_NOTES_OUT.GET_NOTE_TASKS_BY_TASK_TYPE. i_id_epis_pn: ' || i_id_epis_pn;
        IF NOT pk_prog_notes_out.get_note_tasks_by_task_type(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_epis_pn => i_id_epis_pn,
                                                             i_id_tl_task => pk_prog_notes_constants.g_task_cits_procedures,
                                                             o_tasks      => l_id_aihs,
                                                             o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET_AIH_SIMPLE_REPORT. i_id_patient: ' || i_id_patient || ' i_id_episode: ' || i_id_episode;
        OPEN o_data FOR
            SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
             (SELECT pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_concept_term => aihs.id_princ_alert,
                                                     i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                     i_flg_show_code   => g_flg_show_code)
                FROM dual) principal_diag_desc,
             pk_ts1_api.get_term_code(aihs.id_princ_alert) principal_diag_code,
             pk_ts1_api.get_term_code(aihs.id_sec_alert) sec_diag_code,
             get_abs_data_desc(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_id_aih_data     => aihs.id_aih_simple,
                               i_flg_aih_type    => g_aih_simple_si,
                               i_fld_field_type  => g_aih_external_causes_field_ec,
                               i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                               i_flg_return_type => g_code) external_causes_code,
             (SELECT pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_concept_term => aihs.id_proc_alert,
                                                     i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                     i_flg_show_code   => g_flg_show_code)
                FROM dual) procedure_desc,
             pk_ts1_api.get_term_code(aihs.id_proc_alert) procedure_code,
             nvl(aihs.id_prof_last_update, aihs.id_professional) id_prof_last_update,
             (SELECT pk_prof_utils.get_name_signature(i_lang,
                                                      profissional(nvl(aihs.id_prof_last_update, aihs.id_professional),
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                                      nvl(aihs.id_prof_last_update, aihs.id_professional))
                FROM dual) AS prof_name_last_update,
             (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(aihs.dt_last_update_tstz, aihs.dt_order_tstz), i_prof)
                FROM dual) dt_last_update
              FROM aih_simple aihs
              JOIN TABLE(l_id_aihs) t
                ON t.column_value = aihs.id_aih_simple
             WHERE aihs.flg_status = g_flg_status_active;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_aih_simple_report;

    /**
    * Function to get the aih special information to the AIH report
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_episode   Episode identifier
    * @param   i_id_patient   Patient identifier
    * @param   i_id_epis_pn   Single Page note id
    *
    * @param   o_data         AIH episode/patient data
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        o_data          OUT NOCOPY pk_types.cursor_type,
        o_repeated_data OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN AS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AIH_SPECIAL_REPORT';
        l_id_aihs table_number;
    BEGIN
    
        g_error := 'PK_PROG_NOTES_OUT.GET_NOTE_TASKS_BY_TASK_TYPE. i_id_epis_pn: ' || i_id_epis_pn;
        IF NOT pk_prog_notes_out.get_note_tasks_by_task_type(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_id_epis_pn => i_id_epis_pn,
                                                             i_id_tl_task => pk_prog_notes_constants.g_task_cits_procedures_special,
                                                             o_tasks      => l_id_aihs,
                                                             o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET_AIH_SPECIAL_REPORT. i_id_patient: ' || i_id_patient || ' i_id_episode: ' || i_id_episode;
        OPEN o_data FOR
            SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
             pk_sysdomain.get_domain(i_code_dom => g_domain_solic, i_val => aihs.id_solic_type, i_lang => i_lang) solic_desc,
             aihs.id_solic_type,
             pk_sysdomain.get_domain(i_code_dom => g_domain_inst_exec, i_val => aihs.id_inst_exec, i_lang => i_lang) inst_exec_desc,
             aihs.inst_exec_oth,
             aihs.inst_cnes,
             aihs.resp_name,
             aihs.resp_phone,
             decode(aihs.id_proc_alert_old,
                    NULL,
                    NULL,
                    pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_concept_term => aihs.id_proc_alert_old,
                                                    i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                    i_flg_show_code   => g_flg_show_code)) requested_procedure_desc,
             decode(aihs.id_proc_alert_old, NULL, NULL, pk_ts1_api.get_term_code(aihs.id_proc_alert_old)) requested_procedure_code,
             decode(aihs.id_proc_alert_chg,
                    NULL,
                    NULL,
                    pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_concept_term => aihs.id_proc_alert_chg,
                                                    i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                    i_flg_show_code   => g_flg_show_code)) change_procedure_desc,
             decode(aihs.id_proc_alert_chg, NULL, NULL, pk_ts1_api.get_term_code(aihs.id_proc_alert_chg)) change_procedure_code,
             pk_sysdomain.get_domain(i_code_dom => g_domain_uti, i_val => aihs.id_uti, i_lang => i_lang) uti,
             aihs.id_uti,
             decode(aihs.id_princ_alert,
                    NULL,
                    NULL,
                    pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_concept_term => aihs.id_princ_alert,
                                                    i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                    i_flg_show_code   => g_flg_show_code)) principal_diag_desc,
             decode(aihs.id_princ_alert, NULL, NULL, pk_ts1_api.get_term_code(aihs.id_princ_alert)) principal_diag_code,
             decode(aihs.id_sec_alert,
                    NULL,
                    NULL,
                    pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_concept_term => aihs.id_sec_alert,
                                                    i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                    i_flg_show_code   => g_flg_show_code)) sec_diag_desc,
             decode(aihs.id_sec_alert, NULL, NULL, pk_ts1_api.get_term_code(aihs.id_sec_alert)) sec_diag_code,
             decode(aihs.id_proc_alert,
                    NULL,
                    NULL,
                    pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_concept_term => aihs.id_proc_alert,
                                                    i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                    i_flg_show_code   => g_flg_show_code)) procedure_desc,
             decode(aihs.id_proc_alert, NULL, NULL, pk_ts1_api.get_term_code(aihs.id_proc_alert)) procedure_code,
             get_abs_data_desc(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_id_aih_data     => aihs.id_aih_special,
                               i_flg_aih_type    => g_aih_special_sp,
                               i_fld_field_type  => g_aih_external_causes_field_ec,
                               i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                               i_flg_return_type => g_code) external_causes_codes,
             aihs.reason,
             aihs.id_aih_special,
             nvl(aihs.id_prof_last_update, aihs.id_professional) id_prof_last_update,
             (SELECT pk_prof_utils.get_name_signature(i_lang,
                                                      profissional(nvl(aihs.id_prof_last_update, aihs.id_professional),
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                                      nvl(aihs.id_prof_last_update, aihs.id_professional))
                FROM dual) AS prof_name_last_update,
             (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(aihs.dt_last_update_tstz, aihs.dt_order_tstz), i_prof)
                FROM dual) dt_last_update
              FROM aih_special aihs
              JOIN TABLE(l_id_aihs) t
                ON t.column_value = aihs.id_aih_special
             WHERE aihs.flg_status = g_flg_status_active;
    
        OPEN o_repeated_data FOR
            SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
             a.id_aih_data,
             pk_ts1_api.get_term_description(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_concept_term => a.id_alert_diag,
                                             i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                             i_flg_show_code   => g_flg_show_code) special_procedure,
             pk_ts1_api.get_term_code(a.id_alert_diag) special_procedure_code,
             a.diag_quantity
              FROM aih_abs_data a
              JOIN aih_special aihs
                ON aihs.id_aih_special = a.id_aih_data
              JOIN TABLE(l_id_aihs) t
                ON t.column_value = aihs.id_aih_special
             WHERE a.flg_aih_type = g_aih_special_sp
               AND a.flg_field_type = g_aih_proc_special_field_pc
               AND aihs.flg_status = g_flg_status_active
             ORDER BY a.abs_order;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_aih_special_report;

    /**
    * Function to return the description of all fields presented in the AIH special screen.
    * To be used in Single Page
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_aih_simple AIH simple identifier 
    *
    * @param   AIH special descriptions
    *
    * @author  Sofia Mendes
    * @version 2.7.1
    * @since   04-Set-2017
    */
    FUNCTION get_aih_special_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_aih_special IN aih_special.id_aih_special%TYPE
    ) RETURN CLOB AS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AIH_SPECIAL_DESC';
        l_desc                  CLOB;
        l_diag_princ_label      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'DIAGNOSIS_DIFF_M001');
        l_procedure_label       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T001');
        l_diag_sec_label        sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T002');
        l_external_causes_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                        i_code_mess => 'AIH_T003');
    
        l_solic_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                              i_code_mess => 'AIH_T004');
    
        l_institution_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                    i_code_mess => 'AIH_T008');
    
        l_institution_other_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'AIH_T009');
    
        l_cnes_other_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                   i_code_mess => 'AIH_T010');
    
        l_responsible_person_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                           i_code_mess => 'AIH_T011');
    
        l_resp_person_phone_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'AIH_T012');
    
        l_requested_procedure_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                            i_code_mess => 'AIH_T013');
    
        l_main_procedure_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'AIH_T014');
    
        l_change_procedure_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                         i_code_mess => 'AIH_T015');
    
        l_daily_request_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'AIH_T016');
    
        l_special_procedure_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                          i_code_mess => 'AIH_T017');
    
        l_qty_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang => i_lang, i_code_mess => 'AIH_T018');
    
        l_reason_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_code_mess => 'AIH_T019');
    
        l_diag_princ_desc           pk_translation.t_desc_translation;
        l_diag_sec_desc             pk_translation.t_desc_translation;
        l_external_causes_desc      pk_translation.t_desc_translation;
        l_procedure_desc            pk_translation.t_desc_translation;
        l_solic                     pk_translation.t_desc_translation;
        l_instit_exec               pk_translation.t_desc_translation;
        l_instit_other_exec         pk_translation.t_desc_translation;
        l_cnes_other_exec           pk_translation.t_desc_translation;
        l_responsible_person        pk_translation.t_desc_translation;
        l_resp_person_phone         pk_translation.t_desc_translation;
        l_requested_procedure       pk_translation.t_desc_translation;
        l_change_procedure          pk_translation.t_desc_translation;
        l_daily_request             pk_translation.t_desc_translation;
        l_special_procedure_request pk_translation.t_desc_translation;
        l_reason                    pk_translation.t_desc_translation;
        l_id_aih                    aih_special.id_aih_special%TYPE;
        l_error                     t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET_AIH_SPECIAL_DESC. i_id_aih_special: ' || i_id_aih_special;
            SELECT pk_sysdomain.get_domain(i_code_dom => g_domain_solic, i_val => aihs.id_solic_type, i_lang => i_lang),
                   pk_sysdomain.get_domain(i_code_dom => g_domain_inst_exec,
                                           i_val      => aihs.id_inst_exec,
                                           i_lang     => i_lang),
                   aihs.inst_exec_oth,
                   aihs.inst_cnes,
                   aihs.resp_name,
                   aihs.resp_phone,
                   CASE
                        WHEN aihs.id_proc_alert_old IS NULL THEN
                         NULL
                        ELSE
                         pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_concept_term => aihs.id_proc_alert_old,
                                                         i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                         i_flg_show_code   => g_flg_show_code)
                    END requested_procedure_desc,
                   CASE
                        WHEN aihs.id_proc_alert_chg IS NULL THEN
                         NULL
                        ELSE
                         pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_concept_term => aihs.id_proc_alert_chg,
                                                         i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                         i_flg_show_code   => g_flg_show_code)
                    END change_procedure_desc,
                   
                   pk_sysdomain.get_domain(i_code_dom => g_domain_uti, i_val => aihs.id_uti, i_lang => i_lang),
                   CASE
                        WHEN aihs.id_princ_alert IS NULL THEN
                         NULL
                        ELSE
                         pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_concept_term => aihs.id_princ_alert,
                                                         i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                         i_flg_show_code   => g_flg_show_code)
                    END principal_diag_desc,
                   
                   CASE
                        WHEN aihs.id_sec_alert IS NULL THEN
                         NULL
                        ELSE
                         pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_concept_term => aihs.id_sec_alert,
                                                         i_id_task_type    => pk_alert_constant.g_task_diagnosis,
                                                         i_flg_show_code   => g_flg_show_code)
                    END sec_diag_desc,
                   CASE
                        WHEN aihs.id_proc_alert IS NULL THEN
                         NULL
                        ELSE
                         pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_concept_term => aihs.id_proc_alert,
                                                         i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                         i_flg_show_code   => g_flg_show_code)
                    END procedure_desc,
                   get_abs_data_desc(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_aih_data    => aihs.id_aih_special,
                                     i_flg_aih_type   => g_aih_special_sp,
                                     i_fld_field_type => g_aih_external_causes_field_ec,
                                     i_id_task_type   => pk_alert_constant.g_task_diagnosis) external_causes_desc,
                   aihs.reason,
                   aihs.id_aih_special
              INTO l_solic,
                   l_instit_exec,
                   l_instit_other_exec,
                   l_cnes_other_exec,
                   l_responsible_person,
                   l_resp_person_phone,
                   l_requested_procedure,
                   l_change_procedure,
                   l_daily_request,
                   l_diag_princ_desc,
                   l_diag_sec_desc,
                   l_procedure_desc,
                   l_external_causes_desc,
                   l_reason,
                   l_id_aih
              FROM aih_special aihs
             WHERE aihs.id_aih_special = i_id_aih_special;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'Build description';
    
        l_desc := l_solic_label || chr(10) || l_solic;
    
        IF (l_instit_exec IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_institution_label || chr(10) || l_instit_exec;
        END IF;
    
        IF (l_instit_other_exec IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_institution_other_label || chr(10) || l_instit_other_exec;
        END IF;
    
        IF (l_cnes_other_exec IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_cnes_other_label || chr(10) || l_cnes_other_exec;
        END IF;
    
        IF (l_responsible_person IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_responsible_person_label || chr(10) || l_responsible_person;
        END IF;
    
        IF (l_resp_person_phone IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_resp_person_phone_label || chr(10) || l_resp_person_phone;
        END IF;
    
        IF (l_requested_procedure IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_requested_procedure_label || chr(10) || l_requested_procedure;
        END IF;
    
        IF (l_procedure_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_main_procedure_label || chr(10) || l_procedure_desc;
        END IF;
    
        IF (l_change_procedure IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_change_procedure_label || chr(10) || l_change_procedure;
        END IF;
    
        IF (l_daily_request IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_daily_request_label || chr(10) || l_daily_request;
        END IF;
    
        IF (l_diag_princ_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_diag_princ_label || chr(10) || l_diag_princ_desc;
        END IF;
    
        IF (l_diag_sec_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_diag_sec_label || chr(10) || l_diag_sec_desc;
        END IF;
    
        IF (l_external_causes_desc IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_external_causes_label || chr(10) || l_external_causes_desc;
        END IF;
    
        IF (l_reason IS NOT NULL)
        THEN
            l_desc := l_desc || chr(10) || chr(10) || l_reason_label || chr(10) || l_reason;
        END IF;
    
        FOR rec IN (SELECT a.*
                      FROM aih_abs_data a
                     WHERE a.id_aih_data = l_id_aih
                       AND a.flg_aih_type = g_aih_special_sp
                       AND a.flg_field_type = g_aih_proc_special_field_pc
                     ORDER BY a.abs_order)
        LOOP
            IF (rec.id_alert_diag IS NOT NULL)
            THEN
                l_desc := l_desc || chr(10) || chr(10) || l_special_procedure_label || chr(10) ||
                          pk_ts1_api.get_term_description(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_concept_term => rec.id_alert_diag,
                                                          i_id_task_type    => pk_alert_constant.g_task_proc_interv,
                                                          i_flg_show_code   => g_flg_show_code);
            END IF;
        
            IF (rec.diag_quantity IS NOT NULL)
            THEN
                l_desc := l_desc || chr(10) || chr(10) || l_qty_label || chr(10) || rec.diag_quantity;
            END IF;
        
        END LOOP;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END get_aih_special_desc;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Sofia Mendes
    * @version               2.7.1.3
    * @since                 2017/09/15
    ********************************************************************************************/
    FUNCTION match_episode_aih
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'MATCH_EPISODE_AIH';
        l_rowids table_varchar := table_varchar();
    BEGIN
    
        g_error := 'UPD AIH_SIMPLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_rowids := table_varchar();
        ts_aih_simple.upd(id_episode_in => i_episode,
                          where_in      => 'id_episode = ' || i_episode_temp,
                          rows_out      => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'AIH_SIMPLE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'UPD AIH_SPECIAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_aih_special.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'AIH_SPECIAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END match_episode_aih;

    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional
    * @param i_id_patient_temp Temporary patient
    * @param i_id_patient      Patient identifier 
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Sofia Mendes
    * @version               2.7.1.3
    * @since                 2017/09/15
    ********************************************************************************************/
    FUNCTION match_patient_aih
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient_temp IN patient.id_patient%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'MATCH_EPISODE_AIH';
        l_rowids table_varchar := table_varchar();
    BEGIN
    
        g_error := 'UPD AIH_SIMPLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_rowids := table_varchar();
        ts_aih_simple.upd(id_patient_in  => i_id_patient,
                          id_patient_nin => FALSE,
                          where_in       => 'id_patient = ' || i_id_patient_temp,
                          rows_out       => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'AIH_SIMPLE',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPD AIH_SPECIAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_aih_special.upd(id_patient_in  => i_id_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_patient = ' || i_id_patient_temp,
                           rows_out       => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'AIH_SPECIAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END match_patient_aih;

BEGIN
    g_debug_enable := pk_alertlog.is_debug_enabled(i_object_name => g_package_name);

END pk_aih;
/
