/*-- Last Change Revision: $Rev: 2026953 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_diagnosis_form IS

    g_pck_owner VARCHAR2(32) := 'ALERT';
    g_pck_name  VARCHAR2(32) := 'PK_DIAGNOSIS_FORM';

    --Private type declarations
    TYPE table_number_idx IS TABLE OF NUMBER(24) INDEX BY VARCHAR2(24 CHAR);
    TYPE table_leaf_def_data IS TABLE OF t_rec_ds_items_values INDEX BY VARCHAR2(200 CHAR); --Default item values

    TYPE rec_prog_factor_fld_val IS RECORD(
        id_field   epis_diag_stag_pfact.id_field%TYPE,
        item_value t_rec_ds_items_values);

    TYPE table_prog_factor_fld_val IS TABLE OF rec_prog_factor_fld_val;

    -- Private constant declarations
    g_default_rank             CONSTANT PLS_INTEGER := 10;
    g_default_tumor_section_uk CONSTANT VARCHAR2(10) := '90';
    g_prognostic_factor_uk     CONSTANT VARCHAR2(10) := '10';

    g_handle_tumor_sect_list CONSTANT VARCHAR2(1) := 'L'; -- section list
    g_handle_tumor_sect_data CONSTANT VARCHAR2(1) := 'D'; -- section data

    g_nls_num_char CONSTANT VARCHAR2(30) := 'NLS_NUMERIC_CHARACTERS';
    --g_cfg_dec_symbol CONSTANT sys_config.id_sys_config%TYPE := 'DECIMAL_SYMBOL';

    -- Private variable declarations
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_back_nls        VARCHAR2(2) := NULL;
    g_is_to_reset_nls BOOLEAN := FALSE;

    --BEGIN GET_SAVED_VALUES VARIABLES
    --The use of global vars is to prevent multiples and unnecessary calls to PK_DIAGNOSIS_CORE.GET_EPIS_DIAG_REC
    g_svd_val_first_call          BOOLEAN := TRUE;
    g_svd_val_rec_epis_diag       pk_edis_types.rec_epis_diagnosis;
    g_svd_val_rec_epis_stag       pk_edis_types.rec_epis_diag_staging;
    g_svd_val_tab_epis_tumors     pk_edis_types.tab_epis_diag_tumors;
    g_svd_val_tab_diag_factors    pk_edis_types.tab_diag_factors;
    g_svd_val_tab_epis_diag_compl pk_edis_types.table_out_complications;
    --END GET_SAVED_VALUES VARIABLES

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

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
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_proc_name, text => g_error);
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || g_nls_num_char || ' = ''' || g_back_nls || '''';
        
            g_is_to_reset_nls := FALSE;
        ELSIF NOT g_is_to_reset_nls
        THEN
            g_error := 'GET DECIMAL SYMBOL';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_proc_name, text => g_error);
            l_decimal_symbol := '.'; -- Flash is going to send all numbers with the . as decimal separator so I'm not goign to use this call pk_sysconfig.get_config(g_cfg_dec_symbol, i_prof);
        
            g_error := 'SET GROUPING SYMBOL';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_proc_name, text => g_error);
            IF l_decimal_symbol = ','
            THEN
                l_grouping_symbol := '.';
            ELSE
                l_grouping_symbol := ',';
            END IF;
        
            g_error := 'GET NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_proc_name, text => g_error);
            SELECT VALUE
              INTO g_back_nls
              FROM nls_session_parameters
             WHERE parameter = g_nls_num_char;
        
            g_error := 'SET NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_proc_name, text => g_error);
            EXECUTE IMMEDIATE 'ALTER SESSION SET ' || g_nls_num_char || ' = ''' || l_decimal_symbol ||
                              l_grouping_symbol || '''';
        
            g_is_to_reset_nls := TRUE;
        END IF;
    END set_nls_numeric_characters;

    /**
    * Get root ds component based on the type of diagnosis
    * if it's a cancer diag it returns the cancer diag ds_comp, otherwise it returns the general diag ds_comp
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diagnosis                 Diagnosis id
    * @param   o_ds_component              Root component internal name
    * @param   o_ds_comp_type              Root type
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   25-02-2012
    */
    FUNCTION get_root_ds_comp
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_diagnosis    IN concept_version.id_concept_version%TYPE,
        o_ds_component OUT ds_component.internal_name%TYPE,
        o_ds_comp_type OUT ds_component.flg_component_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_EVENTS_LIST';
    BEGIN
        g_error := 'SET COMP TO ROOT TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_ds_comp_type := pk_dynamic_screen.c_root_component;
    
        g_error := 'CALL PK_DIAGNOSIS_CORE.CHECK_DIAG_CANCER';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        CASE pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_concept_type => NULL,
                                         i_diagnosis    => i_diagnosis)
            WHEN pk_diagnosis_core.g_diag_type_diag THEN
                o_ds_component := pk_diagnosis_form.g_dsc_general_diagnosis;
            WHEN pk_diagnosis_core.g_diag_type_cancer THEN
                o_ds_component := pk_diagnosis_form.g_dsc_cancer_diagnosis;
            WHEN pk_diagnosis_core.g_diag_type_acc_emerg THEN
                o_ds_component := pk_diagnosis_form.g_dsc_acc_emerg_diagnosis;
            ELSE
                --This is the default form
                o_ds_component := pk_diagnosis_form.g_dsc_general_diagnosis;
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_root_ds_comp;

    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    * @param o_error                  Error message
    *
    * @return                         true or false
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2.1
    * @since                          2012/03/01
    **********************************************************************************************/
    FUNCTION get_epis_diag_rec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_flg_edit_mode       IN VARCHAR2 DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_EPIS_DIAG_REC';
        --
        l_exception EXCEPTION;
    BEGIN
        IF g_svd_val_first_call
        THEN
            g_error := 'CALL PK_DIAGNOSIS_CORE.GET_EPIS_DIAG_REC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_diagnosis_core.get_epis_diag_rec(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_episode             => i_episode,
                                                       i_epis_diag           => i_epis_diagnosis,
                                                       i_epis_diag_hist      => i_epis_diagnosis_hist,
                                                       i_rec_epis_stag       => NULL,
                                                       i_flg_edit_mode       => i_flg_edit_mode,
                                                       o_rec_epis_stag       => g_svd_val_rec_epis_stag,
                                                       o_tab_epis_tumors     => g_svd_val_tab_epis_tumors,
                                                       o_rec_epis_diag       => g_svd_val_rec_epis_diag,
                                                       o_tab_epis_diag_compl => g_svd_val_tab_epis_diag_compl,
                                                       o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_svd_val_tab_diag_factors := g_svd_val_rec_epis_stag.prog_factors;
            g_svd_val_first_call       := FALSE;
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_epis_diag_rec;

    PROCEDURE remove_section_events
    (
        io_tbl_all_events    IN OUT t_table_ds_events,
        i_tbl_evts_to_remove IN t_table_ds_events
    ) IS
        l_idx              PLS_INTEGER;
        l_tbl_final_events t_table_ds_events;
    BEGIN
        IF i_tbl_evts_to_remove.exists(1)
           AND io_tbl_all_events.exists(1)
        THEN
            --REMOVE EVENTS WHOSE TARGET IS THE TUMOR SECTION
            FOR i IN i_tbl_evts_to_remove.first .. i_tbl_evts_to_remove.last
            LOOP
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF i_tbl_evts_to_remove(i).id_ds_event = io_tbl_all_events(l_idx).id_ds_event
                        AND i_tbl_evts_to_remove(i).target = io_tbl_all_events(l_idx).target
                    THEN
                        io_tbl_all_events.delete(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            END LOOP;
        
            --REORGANIZE TABLE ITEMS
            IF io_tbl_all_events.count > 0
            THEN
                l_tbl_final_events := t_table_ds_events();
            
                l_idx := io_tbl_all_events.first;
                WHILE l_idx IS NOT NULL
                LOOP
                    IF io_tbl_all_events(l_idx).id_ds_event IS NOT NULL
                    THEN
                        l_tbl_final_events.extend;
                        l_tbl_final_events(l_tbl_final_events.count) := io_tbl_all_events(l_idx);
                    END IF;
                
                    l_idx := io_tbl_all_events.next(l_idx);
                END LOOP;
            
                io_tbl_all_events := l_tbl_final_events;
            END IF;
        END IF;
    END remove_section_events;

    /********************************************************************************************
    * In DS table we only have configured one tumor section, but the user can add multiple sections in the application
    * the purpose of this function is to alter and or add in run time those additional sections
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    * @param i_flg_call_orig          Origin of this function call
    * @param i_tumor_num              Tumor number. This value is only necessary when the call origin is made from section data
    * @param io_tab_sections          Sections table
    * @param io_tab_def_events        Default events table
    * @param io_tab_events            Events table
    * @param io_tab_items_values      Items values table
    * @param o_error                  Error message
    *
    * @value i_flg_call_orig          L - section list
    *                                 D - section data
    *
    * @return                         true or false
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2.1
    * @since                          2012/03/01
    **********************************************************************************************/
    FUNCTION handle_tumors
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_flg_call_orig       IN VARCHAR2, --L - section list; D - section data
        i_current_section     IN ds_component.internal_name%TYPE DEFAULT pk_diagnosis_form.g_dsc_cancer_prim_tum,
        i_tumor_num           IN NUMBER DEFAULT 1,
        io_tab_sections       IN OUT t_table_ds_sections,
        io_tab_def_events     IN OUT t_table_ds_def_events,
        io_tab_events         IN OUT t_table_ds_events,
        io_tab_items_values   IN OUT t_table_ds_items_values,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'HANDLE_TUMORS';
        --
        TYPE table_map_pk IS TABLE OF PLS_INTEGER INDEX BY PLS_INTEGER;
        l_tbl_map_components_pk   table_map_pk;
        l_tbl_map_cmpt_mkt_rel_pk table_map_pk;
        --
        l_tab_sections   t_table_ds_sections := t_table_ds_sections();
        l_rec_section    t_rec_ds_sections;
        l_rec_def_event  t_rec_ds_def_events;
        l_rec_event      t_rec_ds_events;
        l_rec_item_value t_rec_ds_items_values;
        --
        l_rec_tumor t_rec_ds_tumor_sections;
        --
        l_tumor_num              PLS_INTEGER := 1;
        l_display_tumor          PLS_INTEGER := 1;
        l_new_ds_comp_pk         PLS_INTEGER := NULL;
        l_new_ds_cmpt_mkt_rel_pk PLS_INTEGER := NULL;
        --
        l_exception EXCEPTION;
        --
        FUNCTION get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_cmpt_mkt_rel_pk;
        END get_new_ds_cmpt_mkt_rel_pk;
    
        FUNCTION get_new_ds_component_pk(i_old_ds_component_pk IN PLS_INTEGER) RETURN PLS_INTEGER IS
        BEGIN
            RETURN l_tbl_map_components_pk(i_old_ds_component_pk);
        EXCEPTION
            WHEN no_data_found THEN
                RETURN i_old_ds_component_pk;
        END get_new_ds_component_pk;
    
        --This function encapsulates the UK creating logic
        FUNCTION get_uk
        (
            i_current_pk IN PLS_INTEGER,
            i_num_tumor  IN PLS_INTEGER
        ) RETURN PLS_INTEGER IS
        BEGIN
            RETURN to_number(i_current_pk || g_default_tumor_section_uk) + i_num_tumor;
        END get_uk;
    
        PROCEDURE change_add_tumor_data
        (
            i_num_tumor              IN PLS_INTEGER,
            i_display_number         IN PLS_INTEGER,
            i_rec_tumor_section      IN t_rec_ds_tumor_sections,
            o_new_ds_cmpt_mkt_rel_pk OUT PLS_INTEGER,
            o_new_ds_comp_pk         OUT PLS_INTEGER
        ) IS
            l_code_msg_princ_primary_tumor CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M010'; --Principal primary tumor
            --
            l_rec_tumor_section t_rec_ds_tumor_sections;
        BEGIN
            l_rec_tumor_section := i_rec_tumor_section;
        
            o_new_ds_cmpt_mkt_rel_pk := get_uk(i_current_pk => l_rec_tumor_section.id_ds_cmpt_mkt_rel,
                                               i_num_tumor  => i_num_tumor);
            o_new_ds_comp_pk         := get_uk(i_current_pk => l_rec_tumor_section.id_ds_component,
                                               i_num_tumor  => i_num_tumor);
        
            l_rec_tumor_section.id_ds_cmpt_mkt_rel := o_new_ds_cmpt_mkt_rel_pk;
        
            IF l_rec_tumor_section.id_ds_component_parent IS NOT NULL
               AND l_rec_tumor.flg_component_type = pk_dynamic_screen.c_leaf_component
            THEN
                l_rec_tumor_section.id_ds_component_parent := get_uk(i_current_pk => l_rec_tumor_section.id_ds_component_parent,
                                                                     i_num_tumor  => i_num_tumor);
            END IF;
        
            l_rec_tumor_section.id_ds_component := o_new_ds_comp_pk;
        
            IF i_num_tumor = 1
               AND l_rec_tumor_section.flg_component_type = pk_dynamic_screen.c_node_component
            THEN
                l_rec_tumor_section.component_desc := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => l_code_msg_princ_primary_tumor);
            END IF;
        
            l_rec_tumor_section.internal_name := l_rec_tumor_section.internal_name;
        
            l_rec_tumor_section.tumor_num      := i_num_tumor;
            l_rec_tumor_section.rank           := l_rec_tumor_section.rank + i_num_tumor;
            l_rec_tumor_section.display_number := i_display_number;
        
            l_tab_sections.extend;
            l_tab_sections(l_tab_sections.count) := l_rec_tumor_section;
        END change_add_tumor_data;
    
        --Returns the ds_events whose target are fields inside the tumor section and don't belong to the tumor section fields
        FUNCTION get_other_section_events RETURN t_table_ds_events IS
            l_tbl_tumor_section t_table_ds_sections;
            l_ret               t_table_ds_events;
        BEGIN
            l_tbl_tumor_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_component_name => pk_diagnosis_form.g_dsc_cancer_prim_tum);
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE det.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                               t.id_ds_cmpt_mkt_rel
                                                FROM TABLE(l_tbl_tumor_section) t)
               AND de.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                  t.id_ds_cmpt_mkt_rel
                                                   FROM TABLE(l_tbl_tumor_section) t);
        
            RETURN l_ret;
        END get_other_section_events;
    
        --Returns the ds_events whose origin are fields inside the tumor section and target are fields from other sections
        FUNCTION get_evts_to_other_sects RETURN t_table_ds_events IS
            l_tbl_tumor_section t_table_ds_sections;
            l_ret               t_table_ds_events;
        BEGIN
            l_tbl_tumor_section := pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_component_name => pk_diagnosis_form.g_dsc_cancer_prim_tum);
        
            SELECT t_rec_ds_events(id_ds_event    => de.id_ds_event,
                                   origin         => de.id_ds_cmpt_mkt_rel,
                                   VALUE          => de.value,
                                   target         => det.id_ds_cmpt_mkt_rel,
                                   flg_event_type => det.flg_event_type)
              BULK COLLECT
              INTO l_ret
              FROM ds_event_target det
              JOIN ds_event de
                ON de.id_ds_event = det.id_ds_event
             WHERE de.id_ds_cmpt_mkt_rel IN (SELECT /*+opt_estimate (table t rows=10)*/
                                              t.id_ds_cmpt_mkt_rel
                                               FROM TABLE(l_tbl_tumor_section) t)
               AND det.id_ds_cmpt_mkt_rel NOT IN (SELECT /*+opt_estimate (table t rows=10)*/
                                                   t.id_ds_cmpt_mkt_rel
                                                    FROM TABLE(l_tbl_tumor_section) t);
        
            RETURN l_ret;
        END get_evts_to_other_sects;
    
        PROCEDURE add_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
        
            IF l_tbl_other_evts IS NOT NULL
               AND l_tbl_other_evts.count > 0
            THEN
                IF io_tab_events IS NULL
                THEN
                    io_tab_events := t_table_ds_events();
                END IF;
            
                FOR i IN l_tbl_other_evts.first .. l_tbl_other_evts.last
                LOOP
                    io_tab_events.extend;
                    io_tab_events(io_tab_events.count) := l_tbl_other_evts(i);
                END LOOP;
            END IF;
        END add_other_section_events;
    
        PROCEDURE remove_other_section_events IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_other_section_events;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_other_section_events;
    
        PROCEDURE remove_evts_to_other_sects IS
            l_tbl_other_evts t_table_ds_events;
        BEGIN
            l_tbl_other_evts := get_evts_to_other_sects;
            remove_section_events(io_tbl_all_events => io_tab_events, i_tbl_evts_to_remove => l_tbl_other_evts);
        END remove_evts_to_other_sects;
    
        FUNCTION has_component_id_changed(i_ds_component_pk IN ds_component.id_ds_component%TYPE) RETURN BOOLEAN IS
        BEGIN
            IF i_ds_component_pk IS NULL
            THEN
                RETURN FALSE;
            ELSE
                RETURN(l_tbl_map_components_pk(i_ds_component_pk) IS NOT NULL);
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END has_component_id_changed;
    BEGIN
        IF i_episode IS NOT NULL
           AND i_flg_call_orig = g_handle_tumor_sect_list
        THEN
            g_error := 'FILL OBJECTS WITH SAVED DATA BY CALLING GET_EPIS_DIAG_REC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT get_epis_diag_rec(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_episode             => i_episode,
                                     i_epis_diagnosis      => i_epis_diagnosis,
                                     i_epis_diagnosis_hist => i_epis_diagnosis_hist,
                                     o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSIF i_flg_call_orig = g_handle_tumor_sect_data
        THEN
            l_tumor_num := nvl(i_tumor_num, 1);
        ELSE
            l_tumor_num := 1;
        END IF;
    
        --When this function is called from section list we must returns all registered tumor sections, in case of creation 1 tumor section.
        --When this function is called from section data we only treat one section at a time.
    
        IF io_tab_sections.exists(1)
        THEN
            FOR i IN io_tab_sections.first .. io_tab_sections.last
            LOOP
                IF io_tab_sections(i) IS OF(t_rec_ds_tumor_sections)
                THEN
                    l_rec_tumor   := treat(io_tab_sections(i) AS t_rec_ds_tumor_sections);
                    l_rec_section := l_rec_tumor;
                ELSIF (io_tab_sections(i).flg_component_type = pk_dynamic_screen.c_node_component AND io_tab_sections(i)
                      .internal_name = pk_diagnosis_form.g_dsc_cancer_prim_tum)
                      OR (io_tab_sections(i).flg_component_type = pk_dynamic_screen.c_leaf_component AND
                       i_current_section = pk_diagnosis_form.g_dsc_cancer_prim_tum)
                THEN
                    l_rec_tumor := t_rec_ds_tumor_sections(ds_section     => io_tab_sections(i),
                                                           tumor_num      => NULL,
                                                           display_number => NULL);
                
                    l_rec_section := l_rec_tumor;
                ELSE
                    l_rec_section := io_tab_sections(i);
                END IF;
            
                l_rec_section.rank := l_rec_section.rank * 100;
            
                IF l_rec_section IS OF(t_rec_ds_tumor_sections)
                THEN
                    l_rec_tumor := treat(l_rec_section AS t_rec_ds_tumor_sections);
                
                    IF i_flg_call_orig = g_handle_tumor_sect_list
                       AND g_svd_val_tab_epis_tumors.count > 0
                    THEN
                        l_display_tumor := 1;
                        l_tumor_num     := g_svd_val_tab_epis_tumors.first;
                        WHILE l_tumor_num IS NOT NULL
                        LOOP
                            change_add_tumor_data(i_num_tumor              => g_svd_val_tab_epis_tumors(l_tumor_num)
                                                                              .tumor_num,
                                                  i_display_number         => l_display_tumor,
                                                  i_rec_tumor_section      => l_rec_tumor,
                                                  o_new_ds_cmpt_mkt_rel_pk => l_new_ds_cmpt_mkt_rel_pk,
                                                  o_new_ds_comp_pk         => l_new_ds_comp_pk);
                        
                            l_tbl_map_components_pk(l_rec_tumor.id_ds_component) := l_new_ds_comp_pk;
                            l_tbl_map_cmpt_mkt_rel_pk(l_rec_tumor.id_ds_cmpt_mkt_rel) := l_new_ds_cmpt_mkt_rel_pk;
                        
                            l_tumor_num     := g_svd_val_tab_epis_tumors.next(l_tumor_num);
                            l_display_tumor := l_display_tumor + 1;
                        END LOOP;
                    ELSE
                        change_add_tumor_data(i_num_tumor              => l_tumor_num,
                                              i_display_number         => nvl(l_rec_tumor.display_number, l_tumor_num),
                                              i_rec_tumor_section      => l_rec_tumor,
                                              o_new_ds_cmpt_mkt_rel_pk => l_new_ds_cmpt_mkt_rel_pk,
                                              o_new_ds_comp_pk         => l_new_ds_comp_pk);
                    
                        l_tbl_map_components_pk(l_rec_tumor.id_ds_component) := l_new_ds_comp_pk;
                        l_tbl_map_cmpt_mkt_rel_pk(l_rec_tumor.id_ds_cmpt_mkt_rel) := l_new_ds_cmpt_mkt_rel_pk;
                    END IF;
                ELSE
                    --I'm assuming that the tumor section node is the first record, so I already have l_old_ds_comp_pk and l_new_ds_comp_pk
                    IF i_flg_call_orig = g_handle_tumor_sect_data
                      --AND has_cmpt_mkt_rel_id_changed(i_ds_cmpt_mkt_rel_pk => l_rec_section.id_ds_cmpt_mkt_rel)
                       AND has_component_id_changed(i_ds_component_pk => l_rec_section.id_ds_component_parent)
                    THEN
                        l_rec_section.id_ds_component_parent := l_tbl_map_components_pk(l_rec_section.id_ds_component_parent);
                    
                        l_tbl_map_components_pk(l_rec_section.id_ds_component) := get_uk(i_current_pk => l_rec_section.id_ds_component,
                                                                                         i_num_tumor  => l_tumor_num);
                        l_tbl_map_cmpt_mkt_rel_pk(l_rec_section.id_ds_cmpt_mkt_rel) := get_uk(i_current_pk => l_rec_section.id_ds_cmpt_mkt_rel,
                                                                                              i_num_tumor  => l_tumor_num);
                    
                        l_rec_section.id_ds_cmpt_mkt_rel := l_tbl_map_cmpt_mkt_rel_pk(l_rec_section.id_ds_cmpt_mkt_rel);
                        l_rec_section.id_ds_component    := l_tbl_map_components_pk(l_rec_section.id_ds_component);
                    END IF;
                
                    l_tab_sections.extend;
                    l_tab_sections(l_tab_sections.count) := l_rec_section;
                END IF;
            END LOOP;
        END IF;
    
        io_tab_sections := l_tab_sections;
    
        IF io_tab_def_events IS NOT NULL
           AND io_tab_def_events.count > 0
        THEN
            FOR i IN io_tab_def_events.first .. io_tab_def_events.last
            LOOP
                l_rec_def_event := io_tab_def_events(i);
            
                l_rec_def_event.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_def_event.id_ds_cmpt_mkt_rel);
            
                io_tab_def_events(i) := l_rec_def_event;
            END LOOP;
        END IF;
    
        IF i_flg_call_orig = g_handle_tumor_sect_data
        THEN
            IF i_current_section = pk_diagnosis_form.g_dsc_cancer_prim_tum
            THEN
                --Add section events whose target is the tumor section
                add_other_section_events;
            ELSE
                --Remove section events whose target is the tumor section
                remove_other_section_events;
            END IF;
        
            IF l_tumor_num != 1
            THEN
                --Remove section events whose origin are fields inside the tumor section 
                --and target are fields from other sections
                remove_evts_to_other_sects;
            END IF;
        
            IF io_tab_events IS NOT NULL
               AND io_tab_events.count > 0
            THEN
                FOR i IN io_tab_events.first .. io_tab_events.last
                LOOP
                    l_rec_event := io_tab_events(i);
                
                    l_rec_event.origin := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.origin);
                    l_rec_event.target := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_event.target);
                
                    io_tab_events(i) := l_rec_event;
                END LOOP;
            END IF;
        
            IF io_tab_items_values IS NOT NULL
               AND io_tab_items_values.count > 0
            THEN
                FOR i IN io_tab_items_values.first .. io_tab_items_values.last
                LOOP
                    l_rec_item_value := io_tab_items_values(i);
                
                    l_rec_item_value.id_ds_cmpt_mkt_rel := get_new_ds_cmpt_mkt_rel_pk(i_old_ds_cmpt_mkt_rel_pk => l_rec_item_value.id_ds_cmpt_mkt_rel);
                    l_rec_item_value.id_ds_component    := get_new_ds_component_pk(i_old_ds_component_pk => l_rec_item_value.id_ds_component);
                
                    io_tab_items_values(i) := l_rec_item_value;
                END LOOP;
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END handle_tumors;

    /********************************************************************************************
    * Change events and default events in runtime according to edit mode flag
    *
    * @param i_lang                   language ID
    * @param i_flg_edit_mode          Edit mode
    * @param io_tab_sections          Sections table
    * @param i_is_stag_basis_filled   Is staging basis filled?
    * @param io_tab_def_events        Default events table
    * @param io_tab_events            Events table
    * @param o_error                  Error message
    *
    * @return                         true or false
    *
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          2013/11/22
    **********************************************************************************************/
    FUNCTION handle_events
    (
        i_lang                 IN language.id_language%TYPE,
        i_flg_edit_mode        IN VARCHAR2,
        i_tab_sections         IN t_table_ds_sections,
        i_is_stag_basis_filled IN BOOLEAN,
        io_tab_def_events      IN OUT t_table_ds_def_events,
        io_tab_events          IN OUT t_table_ds_events,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'HANDLE_EVENTS';
        --
        l_tbl_ds_comp        table_number;
        l_ds_comp_stag_basis ds_component.id_ds_component%TYPE;
        --
        l_tab_def_events t_table_ds_def_events;
        l_tab_events     t_table_ds_events;
    BEGIN
        IF i_flg_edit_mode = pk_diagnosis_core.g_diag_create_mode
           OR (i_flg_edit_mode = pk_diagnosis_core.g_diag_edit_mode_edit AND NOT i_is_stag_basis_filled)
        THEN
            IF io_tab_def_events.exists(1)
            THEN
                SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                 t.id_ds_cmpt_mkt_rel
                  BULK COLLECT
                  INTO l_tbl_ds_comp
                  FROM TABLE(i_tab_sections) t
                 WHERE t.internal_name IN (pk_diagnosis_form.g_dsc_cancer_residual_tum,
                                           pk_diagnosis_form.g_dsc_cancer_surg_margins,
                                           pk_diagnosis_form.g_dsc_cancer_lymp_vasc_inv,
                                           pk_diagnosis_form.g_dsc_cancer_ostaging_sys,
                                           pk_diagnosis_form.g_dsc_cancer_progn_factors);
            
                IF l_tbl_ds_comp.exists(1)
                THEN
                    SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                     t_rec_ds_def_events(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                         id_def_event       => t.id_def_event,
                                         flg_event_type     => nvl2(a.id_ds_cmpt_mkt_rel,
                                                                    pk_alert_constant.g_inactive,
                                                                    t.flg_event_type))
                      BULK COLLECT
                      INTO l_tab_def_events
                      FROM TABLE(io_tab_def_events) t
                      LEFT JOIN (SELECT /*+opt_estimate(TABLE, c, rows = 2))*/
                                  column_value id_ds_cmpt_mkt_rel
                                   FROM TABLE(l_tbl_ds_comp) c) a
                        ON a.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel;
                
                    io_tab_def_events := l_tab_def_events;
                END IF;
            END IF;
        ELSE
            IF io_tab_events.exists(1)
            THEN
                BEGIN
                    SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                     t.id_ds_cmpt_mkt_rel
                      INTO l_ds_comp_stag_basis
                      FROM TABLE(i_tab_sections) t
                     WHERE t.internal_name = pk_diagnosis_form.g_dsc_cancer_staging_basis;
                
                    SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                     t.id_ds_cmpt_mkt_rel
                      BULK COLLECT
                      INTO l_tbl_ds_comp
                      FROM TABLE(i_tab_sections) t
                     WHERE t.internal_name IN (pk_diagnosis_form.g_dsc_cancer_residual_tum,
                                               pk_diagnosis_form.g_dsc_cancer_surg_margins,
                                               pk_diagnosis_form.g_dsc_cancer_lymp_vasc_inv,
                                               pk_diagnosis_form.g_dsc_cancer_ostaging_sys,
                                               pk_diagnosis_form.g_dsc_cancer_progn_factors);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ds_comp_stag_basis := NULL;
                        l_tbl_ds_comp        := NULL;
                END;
            
                IF l_tbl_ds_comp.exists(1)
                   AND l_ds_comp_stag_basis IS NOT NULL
                THEN
                    SELECT t_rec_ds_events(id_ds_event    => d.id_ds_event,
                                           origin         => d.origin,
                                           VALUE          => d.value,
                                           target         => d.target,
                                           flg_event_type => d.flg_event_type)
                      BULK COLLECT
                      INTO l_tab_events
                      FROM (SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                             t.id_ds_event, t.origin, t.value, t.target, t.flg_event_type
                              FROM TABLE(io_tab_events) t
                            MINUS
                            SELECT /*+opt_estimate(TABLE, t, rows = 1))*/
                             t.id_ds_event, t.origin, t.value, t.target, t.flg_event_type
                              FROM TABLE(io_tab_events) t
                             WHERE t.origin = l_ds_comp_stag_basis
                               AND t.target IN (SELECT /*+opt_estimate(TABLE, c, rows = 2))*/
                                                 column_value id_ds_cmpt_mkt_rel
                                                  FROM TABLE(l_tbl_ds_comp) c)) d;
                
                    io_tab_events := l_tab_events;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END handle_events;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diagnosis                 Diagnosis id
    * @param   i_episode                   episode ID
    * @param   i_epis_diag                 episode diagnosis ID
    * @param   i_epis_diag_hist            episode diagnosis ID (history record)
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_diagnosis           IN concept_version.id_concept_version%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        o_diag_ds_int_name    OUT ds_component.internal_name%TYPE,
        o_min_tumor_num       OUT epis_diag_tumors.tumor_num%TYPE,
        o_section             OUT pk_types.cursor_type,
        o_def_events          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_EVENTS_LIST_INT';
        --
        c_min_tumor_num CONSTANT epis_diag_tumors.tumor_num%TYPE := 2;
        --
        l_tbl_sections     t_table_ds_sections;
        l_tbl_def_events   t_table_ds_def_events;
        l_tbl_events       t_table_ds_events;
        l_tbl_items_values t_table_ds_items_values;
        --
        l_ds_comp_type ds_component.flg_component_type%TYPE;
        --
        l_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET DS_COMPONENT OF ID_CONCEPT: ' || i_diagnosis;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_root_ds_comp(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_diagnosis    => i_diagnosis,
                                o_ds_component => o_diag_ds_int_name,
                                o_ds_comp_type => l_ds_comp_type,
                                o_error        => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF o_diag_ds_int_name = pk_diagnosis_form.g_dsc_cancer_diagnosis
        THEN
            IF i_epis_diagnosis IS NOT NULL
               OR i_epis_diagnosis_hist IS NOT NULL
            THEN
                IF i_epis_diagnosis IS NOT NULL
                THEN
                    l_epis_diagnosis := i_epis_diagnosis;
                ELSE
                    SELECT edh.id_epis_diagnosis
                      INTO l_epis_diagnosis
                      FROM epis_diagnosis_hist edh
                     WHERE edh.id_epis_diagnosis_hist = i_epis_diagnosis_hist;
                END IF;
            
                BEGIN
                    SELECT MAX(a.tumor_num) + 1
                      INTO o_min_tumor_num
                      FROM (SELECT edt.tumor_num
                              FROM epis_diag_tumors edt
                             WHERE edt.id_epis_diagnosis = l_epis_diagnosis
                            UNION ALL
                            SELECT edth.tumor_num
                              FROM epis_diag_tumors_hist edth
                             WHERE edth.id_epis_diagnosis = l_epis_diagnosis) a;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_min_tumor_num := c_min_tumor_num;
                END;
            ELSE
                o_min_tumor_num := c_min_tumor_num;
            END IF;
        ELSE
            o_min_tumor_num := NULL;
        END IF;
    
        g_error := 'CALL PK_DYNAMIC_SCREEN.GET_DS_SECTION_EVENTS_LIST';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_dynamic_screen.get_ds_section_events_list(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_component_name => o_diag_ds_int_name,
                                                            i_component_type => l_ds_comp_type,
                                                            o_section        => l_tbl_sections,
                                                            o_def_events     => l_tbl_def_events,
                                                            o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL HANDLE_TUMORS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT handle_tumors(i_lang                => i_lang,
                             i_prof                => i_prof,
                             i_episode             => i_episode,
                             i_epis_diagnosis      => i_epis_diagnosis,
                             i_epis_diagnosis_hist => i_epis_diagnosis_hist,
                             i_flg_call_orig       => g_handle_tumor_sect_list,
                             io_tab_sections       => l_tbl_sections,
                             io_tab_def_events     => l_tbl_def_events,
                             io_tab_events         => l_tbl_events,
                             io_tab_items_values   => l_tbl_items_values,
                             o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'OPEN O_SECTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_section FOR
            SELECT c.id_ds_cmpt_mkt_rel,
                   c.id_ds_component_parent,
                   c.id_ds_component,
                   c.component_desc,
                   c.internal_name,
                   c.flg_component_type,
                   c.flg_data_type,
                   c.slg_internal_name,
                   c.addit_info_xml_value,
                   c.rank,
                   c.max_len,
                   c.min_value,
                   c.max_value,
                   NULL                     tumor_num,
                   NULL                     display_number
              FROM TABLE(l_tbl_sections) c
             WHERE VALUE(c) IS NOT OF TYPE(t_rec_ds_tumor_sections)
            UNION ALL
            SELECT c.id_ds_cmpt_mkt_rel,
                   c.id_ds_component_parent,
                   c.id_ds_component,
                   c.component_desc,
                   c.internal_name,
                   c.flg_component_type,
                   c.flg_data_type,
                   c.slg_internal_name,
                   c.addit_info_xml_value,
                   c.rank,
                   c.max_len,
                   c.min_value,
                   c.max_value,
                   treat                   (VALUE(c) AS t_rec_ds_tumor_sections).tumor_num                    tumor_num,
                   treat                   (VALUE(c) AS t_rec_ds_tumor_sections).display_number                    display_number
              FROM TABLE(l_tbl_sections) c
             WHERE VALUE(c) IS OF TYPE(t_rec_ds_tumor_sections)
             ORDER BY rank;
    
        g_error := 'OPEN O_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_tbl_def_events);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
    END get_section_events_list_int;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_diagnosis                 Diagnosis id
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diagnosis        IN concept_version.id_concept_version%TYPE,
        o_diag_ds_int_name OUT ds_component.internal_name%TYPE,
        o_min_tumor_num    OUT epis_diag_tumors.tumor_num%TYPE,
        o_section          OUT pk_types.cursor_type,
        o_def_events       OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_EVENTS_LIST';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_SECTION_EVENTS_LIST_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_section_events_list_int(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_diagnosis           => i_diagnosis,
                                           i_episode             => NULL,
                                           i_epis_diagnosis      => NULL,
                                           i_epis_diagnosis_hist => NULL,
                                           o_diag_ds_int_name    => o_diag_ds_int_name,
                                           o_min_tumor_num       => o_min_tumor_num,
                                           o_section             => o_section,
                                           o_def_events          => o_def_events,
                                           o_error               => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
    END get_section_events_list;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_diag                 episode diagnosis ID
    * @param   i_epis_diag_hist            episode diagnosis ID (history record)
    * @param   o_diag_ds_int_name          Dynamic screen internal name
    * @param   o_min_tumor_num             Minimum tumor number
    * @param   o_section                   Section cursor
    * @param   o_def_events                Def events cursor
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_events_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        o_diag_ds_int_name    OUT ds_component.internal_name%TYPE,
        o_min_tumor_num       OUT epis_diag_tumors.tumor_num%TYPE,
        o_section             OUT pk_types.cursor_type,
        o_def_events          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SECTION_EVENTS_LIST';
        --
        l_diagnosis           diagnosis.id_diagnosis%TYPE;
        l_episode             episode.id_episode%TYPE;
        l_epis_diagnosis      epis_diagnosis.id_epis_diagnosis%TYPE;
        l_epis_diagnosis_hist epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE;
        --
        l_exception   EXCEPTION;
        l_wrong_param EXCEPTION;
    BEGIN
        IF i_epis_diagnosis IS NULL
           AND i_epis_diagnosis_hist IS NULL
        THEN
            g_error := 'BOTH INP VARS EMPTY. PLEASE FILL AT LEAST ONE OF THEM (I_EPIS_DIAGNOSIS OR I_EPIS_DIAGNOSIS_HIST)';
            pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RAISE l_wrong_param;
        END IF;
    
        BEGIN
            IF i_epis_diagnosis_hist IS NOT NULL
            THEN
                g_error := 'GET EPIS_DIAG - ID_EPIS_DIAG_HIST: ' || i_epis_diagnosis_hist || ';';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                SELECT ed.id_epis_diagnosis, edh.id_epis_diagnosis_hist, ed.id_episode, ed.id_diagnosis
                  INTO l_epis_diagnosis, l_epis_diagnosis_hist, l_episode, l_diagnosis
                  FROM epis_diagnosis ed
                  JOIN epis_diagnosis_hist edh
                    ON edh.id_epis_diagnosis = ed.id_epis_diagnosis
                 WHERE edh.id_epis_diagnosis_hist = i_epis_diagnosis_hist;
            ELSE
                g_error := 'GET EPIS_DIAG - ID_EPIS_DIAG: ' || i_epis_diagnosis || ';';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                SELECT ed.id_epis_diagnosis, NULL, ed.id_episode, ed.id_diagnosis
                  INTO l_epis_diagnosis, l_epis_diagnosis_hist, l_episode, l_diagnosis
                  FROM epis_diagnosis ed
                 WHERE ed.id_epis_diagnosis = i_epis_diagnosis;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ID_EPIS_DIAGNOSIS OR ID_EPIS_DIAGNOSIS_HIST NOT FOUND';
                pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                RAISE l_wrong_param;
        END;
    
        g_error := 'CALL GET_SECTION_EVENTS_LIST_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_section_events_list_int(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_diagnosis           => l_diagnosis,
                                           i_episode             => l_episode,
                                           i_epis_diagnosis      => l_epis_diagnosis,
                                           i_epis_diagnosis_hist => l_epis_diagnosis_hist,
                                           o_diag_ds_int_name    => o_diag_ds_int_name,
                                           o_min_tumor_num       => o_min_tumor_num,
                                           o_section             => o_section,
                                           o_def_events          => o_def_events,
                                           o_error               => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            RETURN FALSE;
    END get_section_events_list;

    /**
    * Add new section to DS sections table
    *
    * @param   i_ds_cmpt_mkt_rel           Component relation
    * @param   i_ds_component_parent       Parent component id
    * @param   i_ds_component              Component id
    * @param   i_component_desc            Section description
    * @param   i_internal_name             Component internal name
    * @param   i_flg_component_type        Component type
    * @param   i_flg_data_type             Component data type
    * @param   i_slg_internal_name         Sys list internal name
    * @param   i_rank                      Section rank
    * @param   io_tbl_sections             DS sections table
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    PROCEDURE add_new_section
    (
        i_ds_cmpt_mkt_rel      IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component_parent  IN ds_cmpt_mkt_rel.id_ds_component_parent%TYPE,
        i_ds_component         IN ds_component.id_ds_component%TYPE,
        i_component_desc       IN pk_translation.t_desc_translation,
        i_internal_name        IN ds_component.internal_name%TYPE,
        i_flg_component_type   IN ds_component.flg_component_type%TYPE DEFAULT pk_dynamic_screen.c_leaf_component,
        i_flg_data_type        IN ds_component.flg_data_type%TYPE,
        i_slg_internal_name    IN ds_component.slg_internal_name%TYPE DEFAULT NULL,
        i_addit_info_xml_value IN CLOB DEFAULT NULL,
        i_rank                 IN ds_cmpt_mkt_rel.rank%TYPE,
        io_tbl_sections        IN OUT NOCOPY t_table_ds_sections
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_SECTION';
        --
        r_section t_rec_ds_sections;
    BEGIN
        g_error := 'NEW T_REC_DS_SECTIONS INSTANCE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        r_section := t_rec_ds_sections(id_ds_cmpt_mkt_rel     => i_ds_cmpt_mkt_rel,
                                       id_ds_component_parent => i_ds_component_parent,
                                       id_ds_component        => i_ds_component,
                                       component_desc         => i_component_desc,
                                       internal_name          => i_internal_name,
                                       flg_component_type     => i_flg_component_type,
                                       flg_data_type          => i_flg_data_type,
                                       slg_internal_name      => i_slg_internal_name,
                                       addit_info_xml_value   => i_addit_info_xml_value,
                                       rank                   => i_rank,
                                       max_len                => NULL,
                                       min_value              => NULL,
                                       max_value              => NULL);
    
        g_error := 'ADD SECTION TO IO_TBL_SECTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        io_tbl_sections.extend;
        io_tbl_sections(io_tbl_sections.count) := r_section;
    END add_new_section;

    /**
    * Add new default event to DS def events table
    *
    * @param   i_pk                        Default event PK
    * @param   i_ds_cmpt_mkt_rel           Component relation
    * @parem   i_flg_event_type            Event type
    * @param   io_tbl_def_events           DS default events table
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    PROCEDURE add_new_def_event
    (
        i_pk              IN ds_def_event.id_def_event%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_flg_event_type  IN ds_def_event.flg_event_type%TYPE,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_DEF_EVENT';
        --
        r_ds_def_event    t_rec_ds_def_events;
        l_def_event_found BOOLEAN := FALSE;
    BEGIN
        IF io_tbl_def_events.exists(1)
        THEN
            FOR i IN io_tbl_def_events.first .. io_tbl_def_events.last
            LOOP
                IF io_tbl_def_events(i).id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel
                THEN
                    io_tbl_def_events(i).flg_event_type := i_flg_event_type;
                    io_tbl_def_events(i).id_def_event := i_pk; --This way I know that the value was changed in code
                    l_def_event_found := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT l_def_event_found
        THEN
            g_error := 'NEW T_REC_DS_DEF_EVENTS INSTANCE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            r_ds_def_event := t_rec_ds_def_events(id_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                                  id_def_event       => i_pk,
                                                  flg_event_type     => i_flg_event_type);
        
            g_error := 'ADD DEF_EVENT TO IO_TBL_DEF_EVENTS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            io_tbl_def_events.extend;
            io_tbl_def_events(io_tbl_def_events.count) := r_ds_def_event;
        END IF;
    END add_new_def_event;

    /**
    * Add new event to DS events table
    *
    * @param   i_pk                        Event PK
    * @param   i_origin                    Component relation id (origin)
    * @param   i_value                     Value that triggers the event
    * @param   i_target                    Component relation id (target)
    * @param   i_flg_event_type            Event type
    * @param   io_def_events               DS events table
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    PROCEDURE add_new_event
    (
        i_pk             IN ds_event.id_ds_event%TYPE,
        i_origin         IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_value          IN ds_event.value%TYPE,
        i_target         IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_flg_event_type IN ds_event_target.flg_event_type%TYPE,
        io_tbl_events    IN OUT NOCOPY t_table_ds_events
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_NEW_EVENT';
        --
        r_ds_event t_rec_ds_events;
    BEGIN
        g_error := 'NEW T_REC_DS_EVENTS INSTANCE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        r_ds_event := t_rec_ds_events(id_ds_event    => i_pk,
                                      origin         => i_origin,
                                      VALUE          => i_value,
                                      target         => i_target,
                                      flg_event_type => i_flg_event_type);
    
        g_error := 'ADD EVENT TO IO_TBL_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        io_tbl_events.extend;
        io_tbl_events(io_tbl_events.count) := r_ds_event;
    END add_new_event;

    /**
    * Add new item to DS items values table
    *
    * @param   i_ds_cmpt_mkt_rel           Component relation
    * @param   i_ds_component              Component id
    * @param   i_internal_name             Component internal name
    * @param   i_flg_component_type        Component type
    * @param   i_item_desc                 Item description
    * @param   i_item_value                Item numeric value
    * @param   i_item_alt_value            Item flag value
    * @param   i_item_xml_value            Item value (Set of all type of values)
    * @param   i_item_rank                 Item rank
    * @param   io_tbl_items_values         DS Items table
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
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
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
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
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        io_tbl_items_values.extend;
        io_tbl_items_values(io_tbl_items_values.count) := r_item_value;
    END add_new_item;

    FUNCTION add_def_events
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_diagnosis_type  IN diagnosis.flg_type%TYPE,
        i_edt_mode        IN VARCHAR2,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_DEF_EVENTS';
        --
        g_manage_principal CONSTANT VARCHAR2(1 CHAR) := 'P';
        g_manage_rank      CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_diag_manage_type VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('DISCHARGE_DIAGNOSIS_MANAGE_BY_RANK_OR_PRINCIPAL',
                                                                             i_prof),
                                                     g_manage_principal);
        --
        l_default_uk          CONSTANT VARCHAR2(10) := '00200';
        l_def_event_mandatory CONSTANT VARCHAR2(1) := 'M';
    BEGIN
        IF i_internal_name IN (pk_diagnosis_form.g_dsc_general_princ_diag,
                               pk_diagnosis_form.g_dsc_cancer_princ_diag,
                               pk_diagnosis_form.g_dsc_general_rank)
        THEN
            IF i_diagnosis_type = pk_diagnosis.g_diag_type_d
               AND (
               -----------------
                (l_diag_manage_type = g_manage_principal AND
                i_internal_name = pk_diagnosis_form.g_dsc_general_princ_diag) OR
               -----------------
                (l_diag_manage_type = g_manage_rank AND i_internal_name = pk_diagnosis_form.g_dsc_general_rank) OR
               -----------------
                i_internal_name = pk_diagnosis_form.g_dsc_cancer_princ_diag)
            THEN
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => l_def_event_mandatory, -- MANDATORY
                                  io_tbl_def_events => io_tbl_def_events);
            ELSE
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 1,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => pk_alert_constant.g_inactive, -- INACTIVE
                                  io_tbl_def_events => io_tbl_def_events);
            END IF;
        ELSIF i_internal_name = pk_diagnosis_form.g_dsc_cancer_staging_basis
        THEN
            IF i_edt_mode = pk_diagnosis_core.g_diag_edit_mode_retreatment
            THEN
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 2,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => l_def_event_mandatory,
                                  io_tbl_def_events => io_tbl_def_events);
            ELSIF i_edt_mode = pk_diagnosis_core.g_diag_create_mode
                  OR g_svd_val_rec_epis_stag.id_staging_basis IS NULL
            THEN
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 2,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => pk_alert_constant.g_active,
                                  io_tbl_def_events => io_tbl_def_events);
            ELSE
                add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 2,
                                  i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                  i_flg_event_type  => pk_alert_constant.g_inactive,
                                  io_tbl_def_events => io_tbl_def_events);
            END IF;
        ELSIF i_internal_name = pk_diagnosis_form.g_dsc_cancer_addit_path_info
        THEN
            add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || l_default_uk || 3,
                              i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_def_events;

    FUNCTION get_prim_tum_unit_meas(i_prof IN profissional) RETURN unit_measure.id_unit_measure%TYPE IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PRIM_TUM_UNIT_MEAS';
    BEGIN
        g_error := 'GET "' || g_cfg_prim_tum_unit_meas || '" SYS_CONFIG';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN to_number(pk_sysconfig.get_config(i_code_cf => pk_diagnosis_form.g_cfg_prim_tum_unit_meas,
                                                 i_prof    => i_prof));
    END get_prim_tum_unit_meas;

    FUNCTION get_treament_group
    (
        i_prof            IN profissional,
        i_topography      IN diagnosis.id_diagnosis%TYPE,
        i_topography_term IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_any_topography  IN diagnosis.id_diagnosis%TYPE,
        i_morphology      IN diagnosis.id_diagnosis%TYPE,
        i_any_morphology  IN diagnosis.id_diagnosis%TYPE
    ) RETURN diagnosis_ea.id_concept_version%TYPE IS
        l_proc_name CONSTANT VARCHAR2(30) := 'GET_TREAMENT_GROUP';
        --
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    BEGIN
        --Due to time limitations of development and content teams we need to add the following code
        --ALERT-301122 Oncology Module - new rules
        --START HAMMER
        IF i_topography_term = 11000008528
        THEN
            RETURN 11000010630;
        ELSIF i_topography_term = 11000008529
        THEN
            RETURN 11000010631;
        ELSIF i_topography_term = 11000008531
        THEN
            RETURN 11000010632;
        ELSIF i_topography_term IN (11000008530, 11000002215)
        THEN
            RETURN 11000010633;
        ELSIF i_topography_term = 11000002585
        THEN
            RETURN 11000010925;
        ELSIF i_topography_term = 11000008532
        THEN
            RETURN 11000010924;
        END IF;
        --END HAMMER
    
        g_error := 'GET R_TREATMENT_GROUP.ID_TREATMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_treatment_group IN pk_diagnosis_form.c_treatment_group(i_prof           => i_prof,
                                                                     i_topography     => i_topography,
                                                                     i_any_topography => i_any_topography,
                                                                     i_morphology     => i_morphology,
                                                                     i_any_morphology => i_any_morphology)
        LOOP
            l_treatment_group := r_treatment_group.id_treatment_group;
            EXIT;
        END LOOP;
    
        RETURN l_treatment_group;
    END get_treament_group;

    /**
    * Set DS leaf value and add it to data values object
    *
    * @param   i_internal_name             Component internal name
    * @param   i_value                     Value
    * @param   i_desc_value                Value Description
    * @param   io_data_values              Default data values
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    PROCEDURE add_to_data_values_obj
    (
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_tumor_num       IN epis_diag_tumors.tumor_num%TYPE,
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
        THEN
            g_error := 'ADD TO DATA VALUES OBJ';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            SELECT xmlconcat(io_data_values,
                             xmlelement("COMPONENT_LEAF",
                                        xmlattributes(a.id_ds_cmpt_mkt_rel,
                                                      a.internal_name,
                                                      a.tumor_num,
                                                      a.desc_value,
                                                      a.value,
                                                      a.alt_value),
                                        i_xml_value))
              INTO io_data_values
              FROM (SELECT i_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel,
                           i_internal_name   AS internal_name,
                           i_tumor_num       AS tumor_num,
                           i_desc_value      AS desc_value,
                           i_value           AS VALUE,
                           i_alt_value       AS alt_value
                      FROM dual) a;
        
            IF i_is_saved_value
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
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
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
            END IF;
        END IF;
    END add_to_data_values_obj;

    /*********************************************************************************
    ********************************************************************************/
    PROCEDURE add_to_data_values_obj_compl
    (
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name     IN ds_component.internal_name%TYPE,
        i_tbl_complications IN pk_edis_types.table_out_complications,
        i_xml_value         IN xmltype DEFAULT NULL,
        io_tbl_sections     IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events   IN OUT NOCOPY t_table_ds_def_events,
        io_data_values      IN OUT NOCOPY xmltype
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TO_DATA_VALUES_OBJ_COMPL';
        --
    
        /*
                id_complication          epis_diag_complications.id_complication%TYPE,
                id_alert_complication    epis_diag_complications.id_alert_complication%TYPE,
                complication_description VARCHAR2(4000 CHAR),
                complication_code        VARCHAR2(200 CHAR),
                rank                     epis_diag_complications.rank%TYPE);
        */
    
        l_id_complication          table_number := table_number();
        l_id_alert_complication    table_number := table_number();
        l_complication_description table_varchar := table_varchar();
        l_complication_code        table_varchar := table_varchar();
        l_rank                     table_number := table_number();
    BEGIN
        IF i_tbl_complications.exists(1)
        THEN
            g_error := 'ADD TO DATA VALUES OBJ';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        
            -- obtain the id_comp and desc_comp from i_tbl_complications
            -- cannot use directly i_tbl_complications because it's a local type
            FOR i IN i_tbl_complications.first .. i_tbl_complications.last
            LOOP
                l_id_complication.extend;
                l_id_complication(l_id_complication.last) := i_tbl_complications(i).id_complication;
            
                l_id_alert_complication.extend;
                l_id_alert_complication(l_id_alert_complication.last) := i_tbl_complications(i).id_alert_complication;
            
                l_complication_description.extend;
                l_complication_description(l_complication_description.last) := i_tbl_complications(i)
                                                                               .complication_description;
            
                l_complication_code.extend;
                l_complication_code(l_complication_code.last) := i_tbl_complications(i).complication_code;
            
                l_rank.extend;
                l_rank(l_rank.last) := i_tbl_complications(i).rank;
            END LOOP;
        
            -- add COMPONENT_LEAF for complications
            -- and SELECTED_ITEM with complication list
            SELECT xmlconcat(io_data_values,
                             xmlelement("COMPONENT_LEAF",
                                        xmlattributes(a.id_ds_cmpt_mkt_rel, a.internal_name), --
                                        (SELECT xmlagg(xmlelement("SELECTED_ITEM",
                                                                  xmlattributes(cp1.id_complication AS "VALUE",
                                                                                cp2.id_alert_complication AS "ALT_VALUE",
                                                                                cp3.complication_description AS "DESC_VALUE",
                                                                                cp4.complication_code AS "CODE",
                                                                                cp5.rank AS "RANK")))
                                           FROM (SELECT rownum AS rn, column_value AS id_complication
                                                   FROM TABLE(l_id_complication)) cp1
                                           JOIN (SELECT rownum AS rn, column_value AS id_alert_complication
                                                  FROM TABLE(l_id_alert_complication)) cp2
                                             ON cp1.rn = cp2.rn
                                           JOIN (SELECT rownum AS rn, column_value AS complication_description
                                                  FROM TABLE(l_complication_description)) cp3
                                             ON cp1.rn = cp3.rn
                                           JOIN (SELECT rownum AS rn, column_value AS complication_code
                                                  FROM TABLE(l_complication_code)) cp4
                                             ON cp1.rn = cp4.rn
                                           JOIN (SELECT rownum AS rn, column_value AS rank
                                                  FROM TABLE(l_rank)) cp5
                                             ON cp1.rn = cp5.rn),
                                        i_xml_value))
              INTO io_data_values
              FROM (SELECT i_ds_cmpt_mkt_rel AS id_ds_cmpt_mkt_rel, i_internal_name AS internal_name
                      FROM dual) a;
        END IF;
    END add_to_data_values_obj_compl;

    /**
    * Add default creation form values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_internal_name             Component internal name
    * @param   io_data_values              Default data values
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    PROCEDURE add_default_values
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name   IN ds_component.internal_name%TYPE,
        i_tumor_num       IN epis_diag_tumors.tumor_num%TYPE,
        io_tbl_sections   IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events,
        io_data_values    IN OUT NOCOPY xmltype
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_DEFAULT_VALUES';
        --
        l_pat_age PLS_INTEGER;
        -- load sys_config to check: Is the date of initial diagnosis automatically fulfilled with the current date when documenting a diagnosis
        l_initial_date_default_config sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => g_initial_date_default_config,
                                                                                       i_prof    => i_prof);
    BEGIN
        IF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_nprim_tum_ms_yn)
        THEN
            g_error := 'ADD NUMBER OF PRIMARY TUMORS YN';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                    i_flg_context       => pk_alert_constant.g_no),
                                   i_alt_value       => pk_alert_constant.g_no,
                                   i_desc_value      => pk_sys_list.get_sys_list_value_desc(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                            i_flg_context       => pk_alert_constant.g_no),
                                   i_is_saved_value  => FALSE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_dt_init_diag)
        THEN
            IF l_initial_date_default_config = pk_alert_constant.g_yes
            THEN
                g_error := 'ADD DT INITIAL DIAG';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                        i_date => g_sysdate_tstz,
                                                                                        i_prof => i_prof),
                                       i_alt_value       => NULL,
                                       i_desc_value      => pk_date_utils.dt_chr_tsz(i_lang => i_lang,
                                                                                     i_date => g_sysdate_tstz,
                                                                                     i_inst => i_prof.institution,
                                                                                     i_soft => i_prof.software),
                                       i_is_saved_value  => FALSE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            END IF;
        ELSIF i_internal_name IN (g_dsc_general_age_init_diag)
        THEN
            IF l_initial_date_default_config = pk_alert_constant.g_yes
            THEN
                g_error := 'GET PATIENT AGE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                l_pat_age := pk_patient.get_pat_age(i_lang     => i_lang,
                                                    i_dt_birth => NULL,
                                                    i_age      => NULL,
                                                    i_patient  => i_patient);
            
                IF l_pat_age IS NOT NULL
                THEN
                    g_error := 'ADD PATIENT AGE';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
                    add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                           i_internal_name   => i_internal_name,
                                           i_tumor_num       => i_tumor_num,
                                           i_value           => l_pat_age,
                                           i_alt_value       => NULL,
                                           i_desc_value      => l_pat_age,
                                           i_is_saved_value  => FALSE,
                                           io_tbl_sections   => io_tbl_sections,
                                           io_tbl_def_events => io_tbl_def_events,
                                           io_data_values    => io_data_values);
                END IF;
            END IF;
        ELSIF i_internal_name = pk_diagnosis_form.g_dsc_cancer_add_problem
        THEN
            g_error := 'ADD FLG_ADD_PROBLEM';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => pk_alert_constant.g_yes,
                                   i_desc_value      => pk_sysdomain.get_domain(i_code_dom => pk_diagnosis.g_code_domain_yes_no,
                                                                                i_val      => pk_alert_constant.g_yes,
                                                                                i_lang     => i_lang),
                                   i_is_saved_value  => FALSE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_general_recur, pk_diagnosis_form.g_dsc_cancer_recur)
        THEN
            g_error := 'ADD RECURRENCE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no_unk,
                                                                                    i_flg_context       => pk_alert_constant.g_no),
                                   i_alt_value       => pk_alert_constant.g_no,
                                   i_desc_value      => pk_sys_list.get_sys_list_value_desc(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no_unk,
                                                                                            i_flg_context       => pk_alert_constant.g_no),
                                   i_is_saved_value  => FALSE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name = pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_unk
        THEN
            g_error := 'ADD PRIMARY_TUMOR_SIZE_UNKNOWN';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                    i_flg_context       => pk_alert_constant.g_no),
                                   i_alt_value       => pk_alert_constant.g_no,
                                   i_desc_value      => pk_sys_list.get_sys_list_value_desc(i_lang              => i_lang,
                                                                                            i_prof              => i_prof,
                                                                                            i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                            i_flg_context       => pk_alert_constant.g_no),
                                   i_is_saved_value  => FALSE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        END IF;
    END add_default_values;

    /**
    * Add saved data form values
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_episode                   Episode id
    * @param   i_internal_name             Component internal name
    * @param   i_tumor_num                 Tumor number
    * @param   i_selected_staging_basis    Selected staging basis id
    * @param   i_epis_diagnosis            Epis diagnosis id
    * @param   i_epis_diagnosis_hist       Epis diagnosis hist id (This value is passed only in cancer diags and when editing the a past staging)
    * @param   i_flg_edit_mode             Edit mode
    * @param   io_data_values              Saved data values
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION add_saved_values
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel        IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name          IN ds_component.internal_name%TYPE,
        i_tumor_num              IN epis_diag_tumors.tumor_num%TYPE,
        i_selected_staging_basis IN epis_diag_stag.id_staging_basis%TYPE,
        i_epis_diagnosis         IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist    IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_flg_edit_mode          IN VARCHAR2,
        io_tbl_sections          IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events        IN OUT NOCOPY t_table_ds_def_events,
        io_data_values           IN OUT NOCOPY xmltype,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_SAVED_VALUES';
        --
        l_tnm_type_t CONSTANT VARCHAR2(1) := 'T';
        l_tnm_type_n CONSTANT VARCHAR2(1) := 'N';
        l_tnm_type_m CONSTANT VARCHAR2(1) := 'M';
        --
        r_diag_factor pk_edis_types.rec_diag_factors;
        --
        l_exception_wrong_params EXCEPTION;
        l_exception              EXCEPTION;
        --
        --DISCHARGE DIAGNOSIS MANAGE BY RANK OR PRINCIPAL
        g_manage_principal CONSTANT VARCHAR2(1 CHAR) := 'P';
        g_manage_rank      CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_diag_manage_type    VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('DISCHARGE_DIAGNOSIS_MANAGE_BY_RANK_OR_PRINCIPAL',
                                                                                i_prof),
                                                        g_manage_principal);
        l_enable_complication VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('DIAGNOSIS_ENABLE_COMPLICATION', i_prof),
                                                        pk_alert_constant.g_no);
        --                                           
        FUNCTION get_tnm_additional_info
        (
            i_code_staging IN VARCHAR2,
            i_concept_code IN VARCHAR2,
            i_tnm_type     IN VARCHAR2 --Possible values: T, N, M
        ) RETURN xmltype IS
            l_xml_value xmltype := NULL;
        BEGIN
            IF i_code_staging IS NOT NULL
               OR i_concept_code IS NOT NULL
            THEN
                SELECT xmlelement("ADDITIONAL_INFO",
                                  xmlattributes(t.code_staging,
                                                t.concept_code,
                                                (t.code_staging || t.concept_code) code,
                                                t.tnm_type))
                  INTO l_xml_value
                  FROM (SELECT i_code_staging code_staging, i_concept_code concept_code, i_tnm_type tnm_type
                          FROM dual) t;
            END IF;
        
            RETURN l_xml_value;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_tnm_additional_info;
        --
        FUNCTION get_histology_addit_info(i_desc_histology IN pk_translation.t_desc_translation) RETURN xmltype IS
            l_xml_value xmltype := NULL;
        BEGIN
            IF i_desc_histology IS NOT NULL
            THEN
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.desc_histology))
                  INTO l_xml_value
                  FROM (SELECT i_desc_histology desc_histology
                          FROM dual) t;
            END IF;
        
            RETURN l_xml_value;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_histology_addit_info;
        --
        FUNCTION get_ograd_sys_addit_info(i_other_grading_sys IN diagnosis_ea.id_concept_version%TYPE) RETURN xmltype IS
            l_xml_value xmltype := NULL;
        BEGIN
            IF i_other_grading_sys IS NOT NULL
            THEN
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.desc_grading_title))
                  INTO l_xml_value
                  FROM (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_id_diagnosis       => pk_diagnosis_core.get_diagnosis_parent(i_other_grading_sys,
                                                                                                                         i_prof.institution,
                                                                                                                         i_prof.software),
                                                          i_diagnosis_language => NULL,
                                                          i_code               => NULL,
                                                          i_flg_other          => pk_alert_constant.g_no,
                                                          i_flg_std_diag       => pk_alert_constant.g_yes,
                                                          i_flg_search_mode    => pk_alert_constant.g_yes) desc_grading_title
                          FROM dual) t;
            END IF;
        
            RETURN l_xml_value;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_ograd_sys_addit_info;
        --
        FUNCTION get_residual_tumor_addit_info(i_residual_tumor IN diagnosis.id_diagnosis%TYPE) RETURN xmltype IS
            l_xml_value xmltype := NULL;
        BEGIN
            IF i_residual_tumor IS NOT NULL
            THEN
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.code))
                  INTO l_xml_value
                  FROM (SELECT d.code_icd code
                          FROM diagnosis d
                         WHERE d.id_diagnosis = (SELECT DISTINCT ad.id_diagnosis
                                                   FROM alert_diagnosis ad
                                                  WHERE ad.id_alert_diagnosis = i_residual_tumor)) t;
            END IF;
        
            RETURN l_xml_value;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_residual_tumor_addit_info;
        --
        FUNCTION get_prog_fact_addit_info(i_field IN diagnosis_ea.id_concept_term%TYPE) RETURN xmltype IS
            l_xml_value xmltype := NULL;
        BEGIN
            IF i_field IS NOT NULL
            THEN
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.id_field))
                  INTO l_xml_value
                  FROM (SELECT i_field id_field
                          FROM dual) t;
            END IF;
        
            RETURN l_xml_value;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_prog_fact_addit_info;
    BEGIN
        g_error := 'FILL OBJECTS WITH SAVED DATA BY CALLING GET_EPIS_DIAG_REC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT get_epis_diag_rec(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_episode             => i_episode,
                                 i_epis_diagnosis      => i_epis_diagnosis,
                                 i_epis_diagnosis_hist => i_epis_diagnosis_hist,
                                 i_flg_edit_mode       => i_flg_edit_mode,
                                 o_error               => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        --Mapping between DS component leafs and PK_DIAGNOSIS_CORE.GET_EPIS_DIAG_REC output vars
        ----------------------------------------------------------
        --BEGIN SECTION CARACTERIZATION
        IF i_internal_name IN (g_dsc_general_dt_init_diag, g_dsc_cancer_dt_init_diag)
        THEN
            g_error := 'ADD DT INIT DIAG';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                    i_date => g_svd_val_rec_epis_diag.dt_initial_diag,
                                                                                    i_prof => i_prof),
                                   i_alt_value       => NULL,
                                   i_desc_value      => pk_date_utils.dt_chr_tsz(i_lang => i_lang,
                                                                                 i_date => g_svd_val_rec_epis_diag.dt_initial_diag,
                                                                                 i_prof => i_prof),
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_age_init_diag, g_dsc_cancer_age_init_diag)
        THEN
            g_error := 'ADD AGE INIT DIAG';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.age_diag,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.age_diag,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_basis_diag_ms)
        THEN
            g_error := 'ADD BASIS DIAG - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_diag_basis,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_diag_basis,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_basis_diag_spec)
        THEN
            g_error := 'ADD BASIS DIAG - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.diag_basis_spec,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.diag_basis_spec,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_nprim_tum_ms_yn)
              AND g_svd_val_rec_epis_diag.flg_mult_tumors IS NOT NULL
        THEN
            g_error := 'ADD NUM PRIM TUMORS - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                    i_flg_context       => g_svd_val_rec_epis_diag.flg_mult_tumors),
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_mult_tumors,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_mult_tumors,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_nprim_tum_num)
        THEN
            g_error := 'ADD NUM PRIM TUMORS - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.num_primary_tumors,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.num_primary_tumors,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_recur, g_dsc_cancer_recur)
        THEN
            g_error := 'ADD RECURRENCE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_recurrence,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_recurrence,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_acc_emer_sub_analysis)
        THEN
            g_error := 'ADD SUB ANALYSIS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_sub_analysis,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_sub_analysis,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_acc_emer_anat_area)
        THEN
            g_error := 'ADD ANATOMICAL AREA';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_anatomical_area,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_anatomical_area,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_acc_emer_anat_side)
        THEN
            g_error := 'ADD ANATOMICAL SIDE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_anatomical_side,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_anatomical_side,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
            --END SECTION CARACTERIZATION
            ----------------------------------------------------------
            --BEGIN SECTION ADDITIONAL INFO
        ELSIF i_internal_name IN (g_dsc_general_princ_diag)
              AND l_diag_manage_type = g_manage_principal
        THEN
            g_error := 'ADD PRINCIPAL DIAG';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_final_type,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_final_type,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_princ_diag)
        THEN
            g_error := 'ADD PRINCIPAL DIAG';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_final_type,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_final_type,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_invest_stat, g_dsc_cancer_invest_stat)
        THEN
            g_error := 'ADD INVESTIGATION STATUS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_status,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_status,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_notes, g_dsc_cancer_notes)
        THEN
            g_error := 'ADD NOTES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.diag_notes,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.diag_notes,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_general_add_problem, g_dsc_cancer_add_problem)
        THEN
            g_error := 'ADD TO PROBLEMS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => NULL,
                                   i_alt_value       => g_svd_val_rec_epis_diag.flg_add_problem,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_add_problem,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_lesion_location)
        THEN
            g_error := 'ADD LESION LOCATION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_lesion_location,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_lesion_location,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_lesion_type)
        THEN
            g_error := 'ADD LESION TYPE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.id_lesion_type,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_lesion_type,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
            -- RANK
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_general_rank)
              AND g_svd_val_rec_epis_diag.flg_type = pk_diagnosis.g_diag_type_d -- only discharge diagnosis have rank
              AND l_diag_manage_type = g_manage_rank
        THEN
            g_error := 'ADD RANK';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_rec_epis_diag.rank,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_rec_epis_diag.desc_rank,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
            -- COMPLICATIONS
        ELSIF i_internal_name IN (g_dsc_complications)
              AND g_svd_val_tab_epis_diag_compl.exists(1)
              AND l_enable_complication = pk_alert_constant.g_yes
        THEN
            g_error := 'ADD COMPLICATIONS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj_compl(i_ds_cmpt_mkt_rel   => i_ds_cmpt_mkt_rel,
                                         i_internal_name     => i_internal_name,
                                         i_tbl_complications => g_svd_val_tab_epis_diag_compl,
                                         io_tbl_sections     => io_tbl_sections,
                                         io_tbl_def_events   => io_tbl_def_events,
                                         io_data_values      => io_data_values);
            --END SECTION ADDITIONAL INFO
            ----------------------------------------------------------
            --BEGIN SECTION PRIMARY TUMOR
        ELSIF i_internal_name IN (g_dsc_cancer_topography)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD TOPOGRAPHY';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_topography,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_topography,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_laterality)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD LATERALITY';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_laterality,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_laterality,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_histology)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD MORPHOLOGY';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_morphology,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_morphology,
                                   i_xml_value       => get_histology_addit_info(i_desc_histology => pk_diagnosis_core.get_desc_histology(i_lang       => i_lang,
                                                                                                                                          i_prof       => i_prof,
                                                                                                                                          i_morphology => pk_diagnosis_core.get_term_diagnosis_id(g_svd_val_tab_epis_tumors(i_tumor_num)
                                                                                                                                                                                                  .id_morphology,
                                                                                                                                                                                                  i_prof.institution,
                                                                                                                                                                                                  i_prof.software))),
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_behavior)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD BEHAVIOR';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_behavior,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_behaviour,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_hist_grade)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD HISTOLOGIC GRADE';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_histological_grade,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_histological_grade,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_ograd_system)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD OTHER GRADING SYSTEM';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).id_other_grading_sys,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_other_grading_sys,
                                   i_xml_value       => get_ograd_sys_addit_info(i_other_grading_sys => g_svd_val_tab_epis_tumors(i_tumor_num)
                                                                                                        .id_other_grading_sys),
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_unk)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
              AND g_svd_val_tab_epis_tumors(i_tumor_num).flg_unknown_dimension IS NOT NULL
        THEN
            g_error := 'ADD PRIMARY TUMOR SIZE - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => pk_sys_list.get_id_sys_list(i_lang              => i_lang,
                                                                                    i_prof              => i_prof,
                                                                                    i_grp_internal_name => pk_diagnosis_form.g_sys_list_yes_no,
                                                                                    i_flg_context       => g_svd_val_tab_epis_tumors(i_tumor_num)
                                                                                                           .flg_unknown_dimension),
                                   i_alt_value       => g_svd_val_tab_epis_tumors(i_tumor_num).flg_unknown_dimension,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_unknown_dimension,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_num)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD PRIMARY TUMOR SIZE - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).num_dimension,
                                   i_alt_value       => NULL,
                                   i_desc_value      => CASE
                                                            WHEN g_svd_val_tab_epis_tumors(i_tumor_num).num_dimension IS NOT NULL THEN
                                                             g_svd_val_tab_epis_tumors(i_tumor_num)
                                                             .num_dimension || ' ' ||
                                                              pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                                                   i_prof         => i_prof,
                                                                                                   i_unit_measure => get_prim_tum_unit_meas(i_prof => i_prof))
                                                            ELSE
                                                             NULL
                                                        END,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_desc)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD PRIMARY TUMOR SIZE - ' || i_internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).desc_dimension,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).desc_dimension,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
        ELSIF i_internal_name IN (g_dsc_cancer_addit_path_info)
              AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
        THEN
            g_error := 'ADD ADDITIONAL PATH INFO';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                   i_internal_name   => i_internal_name,
                                   i_tumor_num       => i_tumor_num,
                                   i_value           => g_svd_val_tab_epis_tumors(i_tumor_num).additional_pathol_info,
                                   i_alt_value       => NULL,
                                   i_desc_value      => g_svd_val_tab_epis_tumors(i_tumor_num).additional_pathol_info,
                                   i_is_saved_value  => TRUE,
                                   io_tbl_sections   => io_tbl_sections,
                                   io_tbl_def_events => io_tbl_def_events,
                                   io_data_values    => io_data_values);
            --END SECTION PRIMARY TUMOR
            ----------------------------------------------------------
        ELSIF pk_diagnosis_core.get_staging_basis_rank(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_staging_basis => i_selected_staging_basis) >=
              pk_diagnosis_core.get_staging_basis_rank(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_staging_basis => g_svd_val_rec_epis_stag.id_staging_basis)
        THEN
            --BEGIN SECTION STAGING
            IF i_internal_name IN (g_dsc_cancer_staging_basis)
            THEN
                IF i_flg_edit_mode != pk_diagnosis_core.g_diag_edit_mode_retreatment
                THEN
                    g_error := 'ADD STAGING BASIS';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                           i_internal_name   => i_internal_name,
                                           i_tumor_num       => i_tumor_num,
                                           i_value           => g_svd_val_rec_epis_stag.id_staging_basis,
                                           i_alt_value       => NULL,
                                           i_desc_value      => g_svd_val_rec_epis_stag.desc_staging_basis,
                                           i_is_saved_value  => TRUE,
                                           io_tbl_sections   => io_tbl_sections,
                                           io_tbl_def_events => io_tbl_def_events,
                                           io_data_values    => io_data_values);
                END IF;
            ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_tnm_tnm)
            THEN
                g_error := 'ADD TNM - ' || i_internal_name;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.desc_tnm,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_tnm,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_tnm_t)
            THEN
                g_error := 'ADD TNM - ' || i_internal_name;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_tnm_t,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_tnm_t,
                                       i_xml_value       => get_tnm_additional_info(i_code_staging => g_svd_val_rec_epis_stag.code_tnm_t,
                                                                                    i_concept_code => g_svd_val_rec_epis_stag.concept_code_t,
                                                                                    i_tnm_type     => l_tnm_type_t),
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_tnm_n)
            THEN
                g_error := 'ADD TNM - ' || i_internal_name;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_tnm_n,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_tnm_n,
                                       i_xml_value       => get_tnm_additional_info(i_code_staging => g_svd_val_rec_epis_stag.code_tnm_n,
                                                                                    i_concept_code => g_svd_val_rec_epis_stag.concept_code_n,
                                                                                    i_tnm_type     => l_tnm_type_n),
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (pk_diagnosis_form.g_dsc_cancer_tnm_m)
            THEN
                g_error := 'ADD TNM - ' || i_internal_name;
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_tnm_m,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_tnm_m,
                                       i_xml_value       => get_tnm_additional_info(i_code_staging => g_svd_val_rec_epis_stag.code_tnm_m,
                                                                                    i_concept_code => g_svd_val_rec_epis_stag.concept_code_m,
                                                                                    i_tnm_type     => l_tnm_type_m),
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_metast_sites)
            THEN
                g_error := 'ADD METASTATIC SITES';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_metastatic_sites,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_metastatic_sites,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_progn_factors)
            THEN
                IF g_svd_val_tab_diag_factors IS NOT NULL
                   AND g_svd_val_tab_diag_factors.count > 0
                THEN
                    FOR i IN g_svd_val_tab_diag_factors.first .. g_svd_val_tab_diag_factors.last
                    LOOP
                        r_diag_factor := g_svd_val_tab_diag_factors(i);
                    
                        g_error := 'ADD PROGNOSTIC FACTORS - ' || i_internal_name || '_' || r_diag_factor.id_field;
                        pk_alertlog.log_debug(text            => g_error,
                                              object_name     => g_package,
                                              sub_object_name => l_func_name);
                        add_to_data_values_obj(i_ds_cmpt_mkt_rel => g_prognostic_factor_uk || CASE
                                                                        WHEN r_diag_factor.id_value IS NOT NULL THEN
                                                                         1
                                                                        ELSE
                                                                         2
                                                                    END || r_diag_factor.id_field,
                                               i_internal_name   => CASE
                                                                        WHEN r_diag_factor.id_value IS NOT NULL THEN
                                                                         pk_diagnosis_form.g_dsc_cancer_progn_factors_req
                                                                        ELSE
                                                                         pk_diagnosis_form.g_dsc_cancer_progn_factors_cli
                                                                    END,
                                               i_tumor_num       => i_tumor_num,
                                               i_value           => r_diag_factor.id_value,
                                               i_alt_value       => NULL,
                                               i_desc_value      => CASE
                                                                        WHEN r_diag_factor.id_value IS NOT NULL THEN
                                                                         r_diag_factor.desc_value_field
                                                                        ELSE
                                                                         r_diag_factor.desc_value
                                                                    END,
                                               i_xml_value       => get_prog_fact_addit_info(i_field => r_diag_factor.id_field),
                                               i_is_saved_value  => TRUE,
                                               io_tbl_sections   => io_tbl_sections,
                                               io_tbl_def_events => io_tbl_def_events,
                                               io_data_values    => io_data_values);
                    END LOOP;
                END IF;
            ELSIF i_internal_name IN (g_dsc_cancer_stage_grp)
            THEN
                g_error := 'ADD STAGE GROUP';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_staging_group,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_group,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_stage)
            THEN
                g_error := 'ADD STAGE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.desc_staging,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_staging,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_residual_tum)
            THEN
                g_error := 'ADD RESIDUAL TUMOR';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_residual_tumor,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_residual_tumor,
                                       i_xml_value       => get_residual_tumor_addit_info(i_residual_tumor => g_svd_val_rec_epis_stag.id_residual_tumor),
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_surg_margins)
            THEN
                g_error := 'ADD SURGICAL MARGINS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_surgical_margins,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_surgical_margins,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_lymp_vasc_inv)
            THEN
                g_error := 'ADD LYMPH VASCULAR INVASION';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_lymph_vasc_inv,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_lymph_vasc_inv,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
            ELSIF i_internal_name IN (g_dsc_cancer_ostaging_sys)
            THEN
                g_error := 'ADD OTHER STAGING SYSTEM';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                add_to_data_values_obj(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                                       i_internal_name   => i_internal_name,
                                       i_tumor_num       => i_tumor_num,
                                       i_value           => g_svd_val_rec_epis_stag.id_other_staging_sys,
                                       i_alt_value       => NULL,
                                       i_desc_value      => g_svd_val_rec_epis_stag.desc_other_staging_sys,
                                       i_is_saved_value  => TRUE,
                                       io_tbl_sections   => io_tbl_sections,
                                       io_tbl_def_events => io_tbl_def_events,
                                       io_data_values    => io_data_values);
                --END SECTION STAGING
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_saved_values;

    /**
    * Add default or saved data to the output XML data field of DS function GET_SECTION_DATA
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_episode                   Episode id
    * @param   i_internal_name             Component internal name
    * @param   i_tumor_num                 Tumor number
    * @param   i_selected_staging_basis    Selected staging basis id
    * @param   i_epis_diagnosis            Epis diagnosis id
    * @param   i_epis_diagnosis_hist       Epis diagnosis hist id (This value is passed only in cancer diags and when editing the a past staging)
    * @param   i_flg_edit_mode             Edit mode
    * @param   io_data_values              Saved data values
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   17-01-2012
    */
    FUNCTION add_data_val
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_ds_cmpt_mkt_rel        IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_internal_name          IN ds_component.internal_name%TYPE,
        i_tumor_num              IN epis_diag_tumors.tumor_num%TYPE,
        i_selected_staging_basis IN epis_diag_stag.id_staging_basis%TYPE,
        i_epis_diagnosis         IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist    IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_flg_edit_mode          IN VARCHAR2,
        io_tbl_sections          IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events        IN OUT NOCOPY t_table_ds_def_events,
        io_data_values           IN OUT NOCOPY xmltype,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'ADD_DATA_VAL';
        --
        l_exception EXCEPTION;
    BEGIN
        IF i_epis_diagnosis IS NULL
           AND i_epis_diagnosis_hist IS NULL
        THEN
            g_error := 'CALL ADD_DEFAULT_VALUES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            add_default_values(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_patient         => i_patient,
                               i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel,
                               i_internal_name   => i_internal_name,
                               i_tumor_num       => i_tumor_num,
                               io_tbl_sections   => io_tbl_sections,
                               io_tbl_def_events => io_tbl_def_events,
                               io_data_values    => io_data_values);
        ELSE
            g_error := 'CALL ADD_SAVED_VALUES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT add_saved_values(i_lang                   => i_lang,
                                    i_prof                   => i_prof,
                                    i_episode                => i_episode,
                                    i_ds_cmpt_mkt_rel        => i_ds_cmpt_mkt_rel,
                                    i_internal_name          => i_internal_name,
                                    i_tumor_num              => i_tumor_num,
                                    i_selected_staging_basis => i_selected_staging_basis,
                                    i_epis_diagnosis         => i_epis_diagnosis,
                                    i_epis_diagnosis_hist    => i_epis_diagnosis_hist,
                                    i_flg_edit_mode          => i_flg_edit_mode,
                                    io_tbl_sections          => io_tbl_sections,
                                    io_tbl_def_events        => io_tbl_def_events,
                                    io_data_values           => io_data_values,
                                    o_error                  => o_error)
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END add_data_val;

    PROCEDURE define_default_value
    (
        i_flg_default       IN VARCHAR2,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        io_item_value       IN OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'DEFINE_DEFAULT_VALUE';
    BEGIN
        IF nvl(i_flg_default, pk_alert_constant.g_no) = pk_alert_constant.g_yes
        THEN
            io_item_value := io_tbl_items_values(io_tbl_items_values.last);
        
            g_error := 'DEFAULT VALUE OF - "' || io_item_value.internal_name || '" IS ' || '"' ||
                       nvl(io_item_value.item_value, io_item_value.item_alt_value) || '"';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        END IF;
    END define_default_value;

    PROCEDURE add_basis_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component      IN ds_component.id_ds_component%TYPE,
        i_internal_name     IN ds_component.internal_name%TYPE,
        i_basis_diag        IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_BASIS_DIAG';
    BEGIN
        g_error := 'ADD ITEMS - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_basis_diag IN pk_diagnosis_form.c_basis_diag(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_basis_diag => i_basis_diag)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => pk_dynamic_screen.c_leaf_component,
                         i_item_desc          => r_basis_diag.desc_basis_diag,
                         i_item_value         => r_basis_diag.id_basis_diag,
                         i_item_xml_value     => r_basis_diag.addit_info.getclobval(),
                         i_item_rank          => r_basis_diag.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_basis_diag.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_basis_diag;

    PROCEDURE add_topography
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_diagnosis          IN diagnosis_ea.id_concept_version%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TOPOGRAPHY';
        --
        l_any_cancer_diagnosis diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_cancer_diagnosis := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_cancer_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_topog IN pk_diagnosis_form.c_topographies(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_diagnosis     => i_diagnosis,
                                                        i_any_diagnosis => l_any_cancer_diagnosis,
                                                        i_topography    => i_topography)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_topog.desc_topography,
                         i_item_value         => r_topog.id_topography,
                         i_item_xml_value     => r_topog.addit_info.getclobval(),
                         i_item_rank          => r_topog.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_topog.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_topography;

    PROCEDURE add_staging_basis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_edit_mode      IN VARCHAR2,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_staging_basis      IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_STAGING_BASIS';
        --
        l_flg_available VARCHAR2(1 CHAR);
        l_addit_info    xmltype;
        -- staging records
        l_tab_epis_diag_staging pk_edis_types.tab_epis_diag_staging;
    BEGIN
        g_error := 'GET STAGING INFO';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_tab_epis_diag_staging := pk_diagnosis_core.get_epis_diag_stagings(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_episode        => i_episode,
                                                                            i_flg_call       => pk_diagnosis_core.g_diag_call_viewer,
                                                                            i_epis_diag      => i_epis_diagnosis,
                                                                            i_epis_diag_hist => NULL,
                                                                            i_flg_ret_type   => pk_diagnosis_core.g_stage_ret_only_ids);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_staging_basis IN pk_diagnosis_form.c_staging_basis(i_lang          => i_lang,
                                                                 i_prof          => i_prof,
                                                                 i_flg_edit_mode => i_flg_edit_mode,
                                                                 i_staging_basis => pk_diagnosis_core.get_term_diagnosis_id(i_staging_basis,
                                                                                                                            i_prof.institution,
                                                                                                                            i_prof.software))
        LOOP
            l_flg_available := pk_diagnosis_core.check_staging_basis_avail(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_staging_basis => r_staging_basis.id_staging_basis,
                                                                           i_epis_st_basis => l_tab_epis_diag_staging,
                                                                           i_flg_edit_mode => i_flg_edit_mode);
        
            SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default, t.flg_available))
              INTO l_addit_info
              FROM (SELECT r_staging_basis.flg_default flg_default, l_flg_available flg_available
                      FROM dual) t;
        
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_staging_basis.desc_staging_basis,
                         i_item_value         => r_staging_basis.id_staging_basis,
                         i_item_xml_value     => l_addit_info.getclobval(),
                         i_item_rank          => r_staging_basis.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_staging_basis.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_staging_basis;

    PROCEDURE add_residual_tumor
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_residual_tumor     IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_RESIDUAL_TUMOR';
    BEGIN
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_res_tumor IN pk_diagnosis_form.c_residual_tumor(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_residual_tumor => i_residual_tumor)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_res_tumor.desc_residual_tumor,
                         i_item_value         => r_res_tumor.id_residual_tumor,
                         i_item_xml_value     => r_res_tumor.addit_info.getclobval(),
                         i_item_rank          => r_res_tumor.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_res_tumor.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_residual_tumor;

    PROCEDURE add_surgical_margins
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_surgical_margins   IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_SURGICAL_MARGINS';
    BEGIN
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_surg_margins IN pk_diagnosis_form.c_surgical_margins(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_surgical_margins => i_surgical_margins)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_surg_margins.desc_surgical_margin,
                         i_item_value         => r_surg_margins.id_surgical_margin,
                         i_item_xml_value     => r_surg_margins.addit_info.getclobval(),
                         i_item_rank          => r_surg_margins.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_surg_margins.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_surgical_margins;

    PROCEDURE set_um_prim_tumor_size_num
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        io_tbl_sections IN OUT NOCOPY t_table_ds_sections
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'SET_UM_PRIM_TUMOR_SIZE_NUM';
        --
        l_id_unit_meas     unit_measure.id_unit_measure%TYPE;
        l_unit_meas_abbrev pk_translation.t_desc_translation;
        l_additonal_info   xmltype;
    BEGIN
        g_error := 'CALL GET_PRIM_TUM_UNIT_MEAS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_id_unit_meas := get_prim_tum_unit_meas(i_prof => i_prof);
    
        g_error := 'CALL PK_UNIT_MEASURE.GET_UOM_ABBREVIATION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_unit_meas_abbrev := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_unit_measure => l_id_unit_meas);
    
        SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.id_unit_measure, t.unit_meas_abbrev)) addit_info
          INTO l_additonal_info
          FROM (SELECT l_id_unit_meas id_unit_measure, l_unit_meas_abbrev unit_meas_abbrev
                  FROM dual) t;
    
        IF io_tbl_sections.exists(1)
        THEN
            FOR i IN io_tbl_sections.first .. io_tbl_sections.last
            LOOP
                IF io_tbl_sections(i).internal_name = pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_num
                THEN
                    io_tbl_sections(i).component_desc := REPLACE(io_tbl_sections(i).component_desc,
                                                                 '@1',
                                                                 l_unit_meas_abbrev);
                    io_tbl_sections(i).addit_info_xml_value := l_additonal_info.getclobval();
                END IF;
            END LOOP;
        END IF;
    END set_um_prim_tumor_size_num;

    /*********************************************************************************
    *********************************************************************************/
    PROCEDURE set_rank_max_min_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN epis_diagnosis.id_episode%TYPE,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_edit_mode     IN VARCHAR2,
        i_flg_type          IN epis_diagnosis.flg_type%TYPE,
        i_tbl_index         IN NUMBER,
        io_tbl_sections     IN OUT NOCOPY t_table_ds_sections
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'SET_RANK_MAX_MIN_VALUE';
        --
    
        FUNCTION get_epis_diagnosis_rank RETURN epis_diagnosis.rank%TYPE IS
            l_rank epis_diagnosis.rank%TYPE;
        BEGIN
            SELECT MAX(ed.rank)
              INTO l_rank
              FROM epis_diagnosis ed
             WHERE ed.id_episode = i_id_episode
               AND ed.flg_status NOT IN
                   (pk_diagnosis.g_ed_flg_status_ca, pk_diagnosis.g_ed_flg_status_r, pk_diagnosis.g_ed_flg_status_b)
               AND ed.flg_type = pk_diagnosis.g_diag_type_d;
        
            RETURN l_rank;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN NULL;
        END;
    
    BEGIN
        IF io_tbl_sections.exists(i_tbl_index)
        THEN
            IF io_tbl_sections(i_tbl_index).internal_name = pk_diagnosis_form.g_dsc_general_rank
                AND i_flg_type = pk_diagnosis.g_diag_type_d -- Dischage diagnosis
            THEN
                IF i_flg_edit_mode IN (pk_diagnosis_core.g_diag_edit_mode_retreatment,
                                       pk_diagnosis_core.g_diag_edit_mode_edit,
                                       pk_diagnosis_core.g_diag_edit_mode_status,
                                       pk_diagnosis_core.g_diag_edit_mode_type,
                                       pk_diagnosis_core.g_diag_cancel_diag) -- edit/cancel diagnosis
                THEN
                    -- if we are editing the diagnosis the rank must be <= l_max_rank
                    io_tbl_sections(i_tbl_index).max_value := get_epis_diagnosis_rank();
                END IF;
            
                io_tbl_sections(i_tbl_index).min_value := 1;
                io_tbl_sections(i_tbl_index).slg_internal_name := 'i_id_episode: ' || i_id_episode ||
                                                                  ', i_flg_edit_mode: ' || i_flg_edit_mode ||
                                                                  ', i_flg_type: ' || i_flg_type;
            END IF;
        END IF;
    END set_rank_max_min_value;

    PROCEDURE add_tnm_def_events
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_internal_name   IN ds_component.internal_name%TYPE,
        io_tbl_def_events IN OUT NOCOPY t_table_ds_def_events
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TNM_DEF_EVENTS';
        --
        l_rec_def_event t_rec_ds_def_events;
    BEGIN
        g_error := 'CALL PK_DYNAMIC_SCREEN.TF_DS_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        SELECT VALUE(t)
          INTO l_rec_def_event
          FROM TABLE(pk_dynamic_screen.tf_ds_def_events(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_component_name => i_internal_name,
                                                        i_component_type => pk_dynamic_screen.c_leaf_component)) t
         WHERE t.id_ds_cmpt_mkt_rel NOT IN (SELECT b.id_ds_cmpt_mkt_rel
                                              FROM TABLE(io_tbl_def_events) b);
    
        g_error := 'ADD DEF_EVENT - ' || i_internal_name || ' - ' || l_rec_def_event.id_def_event;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        io_tbl_def_events.extend;
        io_tbl_def_events(io_tbl_def_events.count) := l_rec_def_event;
    EXCEPTION
        WHEN no_data_found THEN
            NULL;
    END add_tnm_def_events;

    PROCEDURE add_tnm_t
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_diagnosis    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist    IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component      IN ds_component.id_ds_component%TYPE,
        i_internal_name     IN ds_component.internal_name%TYPE,
        i_topography        IN diagnosis_ea.id_concept_term%TYPE,
        i_morph             IN epis_diag_tumors.id_morphology%TYPE,
        i_staging_basis     IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_def_events   IN OUT NOCOPY t_table_ds_def_events,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TNM_T';
        --
        l_any_topography      diagnosis.id_diagnosis%TYPE;
        l_any_morphology      diagnosis.id_diagnosis%TYPE;
        l_any_staging_basis   diagnosis.id_diagnosis%TYPE;
        l_any_treatment_group diagnosis.id_diagnosis%TYPE;
    
        l_id_diag_topography    diagnosis.id_diagnosis%TYPE;
        l_id_diag_morphology    diagnosis.id_diagnosis%TYPE;
        l_id_diag_staging_basis diagnosis.id_diagnosis%TYPE;
        l_code_staging_basis    diagnosis.code_icd%TYPE;
    
        l_epis_tnm_t   epis_diag_stag.id_tnm_t%TYPE;
        l_code_stage_t epis_diag_stag.code_tnm_t%TYPE;
    
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
        l_any_morphology      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_morphology_type);
        l_any_staging_basis   := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_stage_base_type);
        l_any_treatment_group := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_treatment_group);
    
        l_id_diag_topography    := pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_id_diag_morphology    := pk_diagnosis_core.get_term_diagnosis_id(i_morph, i_prof.institution, i_prof.software);
        l_id_diag_staging_basis := pk_diagnosis_core.get_term_diagnosis_id(i_staging_basis,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_code_staging_basis    := pk_diagnosis_core.get_diagnosis_code(l_id_diag_staging_basis,
                                                                        i_prof.institution,
                                                                        i_prof.software);
    
        g_error := 'CALL GET_TREAMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_treatment_group := get_treament_group(i_prof            => i_prof,
                                                i_topography      => l_id_diag_topography,
                                                i_any_topography  => l_any_topography,
                                                i_topography_term => i_topography,
                                                i_morphology      => l_id_diag_morphology,
                                                i_any_morphology  => l_any_morphology);
    
        g_error := 'GET EPISODE TNM  - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        BEGIN
            SELECT *
              INTO l_epis_tnm_t, l_code_stage_t
              FROM (SELECT eg.id_tnm_t, eg.code_tnm_t
                      FROM epis_diag_stag eg
                     WHERE eg.id_epis_diagnosis = i_epis_diagnosis
                       AND i_epis_diag_hist IS NULL
                    
                    UNION ALL
                    
                    SELECT egh.id_tnm_t, egh.code_tnm_t
                      FROM epis_diag_stag_hist egh
                     WHERE egh.id_epis_diagnosis_hist = i_epis_diag_hist);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'ADD ITEMS - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_tnm_t IN pk_diagnosis_form.c_tnm_t(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_topography          => l_id_diag_topography,
                                                 i_any_topography      => l_any_topography,
                                                 i_morphology          => l_id_diag_morphology,
                                                 i_any_morphology      => l_any_morphology,
                                                 i_treatment_group     => l_treatment_group,
                                                 i_any_treatment_group => l_any_treatment_group,
                                                 i_staging_basis       => l_id_diag_staging_basis,
                                                 i_code_stage_basis    => l_code_staging_basis,
                                                 i_any_staging_basis   => l_any_staging_basis,
                                                 i_epis_tnm_t          => l_epis_tnm_t,
                                                 i_code_tnm_t          => l_code_stage_t)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => pk_dynamic_screen.c_leaf_component,
                         i_item_desc          => r_tnm_t.desc_tnm_t,
                         i_item_value         => r_tnm_t.id_tnm_t,
                         i_item_xml_value     => r_tnm_t.addit_info.getclobval(),
                         i_item_rank          => r_tnm_t.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_tnm_t.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    
        g_error := 'CALL ADD_TNM_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_tnm_def_events(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_internal_name   => i_internal_name,
                           io_tbl_def_events => io_tbl_def_events);
    END add_tnm_t;

    PROCEDURE add_tnm_n
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_diagnosis    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist    IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component      IN ds_component.id_ds_component%TYPE,
        i_internal_name     IN ds_component.internal_name%TYPE,
        i_topography        IN diagnosis_ea.id_concept_term%TYPE,
        i_morph             IN epis_diag_tumors.id_morphology%TYPE,
        i_staging_basis     IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_def_events   IN OUT NOCOPY t_table_ds_def_events,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TNM_N';
        --
        l_any_topography      diagnosis.id_diagnosis%TYPE;
        l_any_morphology      diagnosis.id_diagnosis%TYPE;
        l_any_staging_basis   diagnosis.id_diagnosis%TYPE;
        l_any_treatment_group diagnosis.id_diagnosis%TYPE;
    
        l_id_diag_topography    diagnosis.id_diagnosis%TYPE;
        l_id_diag_morphology    diagnosis.id_diagnosis%TYPE;
        l_id_diag_staging_basis diagnosis.id_diagnosis%TYPE;
        l_code_staging_basis    diagnosis.code_icd%TYPE;
    
        l_epis_tnm_n   epis_diag_stag.id_tnm_n%TYPE;
        l_code_stage_n epis_diag_stag.code_tnm_n%TYPE;
    
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
        l_any_morphology      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_morphology_type);
        l_any_staging_basis   := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_stage_base_type);
        l_any_treatment_group := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_treatment_group);
    
        l_id_diag_topography    := pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_id_diag_morphology    := pk_diagnosis_core.get_term_diagnosis_id(i_morph, i_prof.institution, i_prof.software);
        l_id_diag_staging_basis := pk_diagnosis_core.get_term_diagnosis_id(i_staging_basis,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_code_staging_basis    := pk_diagnosis_core.get_diagnosis_code(l_id_diag_staging_basis,
                                                                        i_prof.institution,
                                                                        i_prof.software);
    
        g_error := 'CALL GET_TREAMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_treatment_group := get_treament_group(i_prof            => i_prof,
                                                i_topography      => l_id_diag_topography,
                                                i_any_topography  => l_any_topography,
                                                i_topography_term => i_topography,
                                                i_morphology      => l_id_diag_morphology,
                                                i_any_morphology  => l_any_morphology);
    
        g_error := 'GET EPISODE TNM  - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        BEGIN
            SELECT *
              INTO l_epis_tnm_n, l_code_stage_n
              FROM (SELECT eg.id_tnm_n, eg.code_tnm_n
                      FROM epis_diag_stag eg
                     WHERE eg.id_epis_diagnosis = i_epis_diagnosis
                       AND i_epis_diag_hist IS NULL
                    
                    UNION ALL
                    
                    SELECT egh.id_tnm_n, egh.code_tnm_n
                      FROM epis_diag_stag_hist egh
                     WHERE egh.id_epis_diagnosis_hist = i_epis_diag_hist);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'ADD ITEMS - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_tnm_n IN pk_diagnosis_form.c_tnm_n(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_topography          => l_id_diag_topography,
                                                 i_any_topography      => l_any_topography,
                                                 i_morphology          => l_id_diag_morphology,
                                                 i_any_morphology      => l_any_morphology,
                                                 i_treatment_group     => l_treatment_group,
                                                 i_any_treatment_group => l_any_treatment_group,
                                                 i_staging_basis       => l_id_diag_staging_basis,
                                                 i_code_stage_basis    => l_code_staging_basis,
                                                 i_any_staging_basis   => l_any_staging_basis,
                                                 i_epis_tnm_n          => l_epis_tnm_n,
                                                 i_code_tnm_n          => l_code_stage_n)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => pk_dynamic_screen.c_leaf_component,
                         i_item_desc          => r_tnm_n.desc_tnm_n,
                         i_item_value         => r_tnm_n.id_tnm_n,
                         i_item_xml_value     => r_tnm_n.addit_info.getclobval(),
                         i_item_rank          => r_tnm_n.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_tnm_n.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    
        g_error := 'CALL ADD_TNM_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_tnm_def_events(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_internal_name   => i_internal_name,
                           io_tbl_def_events => io_tbl_def_events);
    END add_tnm_n;

    PROCEDURE add_tnm_m
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_diagnosis    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist    IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component      IN ds_component.id_ds_component%TYPE,
        i_internal_name     IN ds_component.internal_name%TYPE,
        i_topography        IN diagnosis_ea.id_concept_term%TYPE,
        i_morph             IN epis_diag_tumors.id_morphology%TYPE,
        i_staging_basis     IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_def_events   IN OUT NOCOPY t_table_ds_def_events,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_TNM_M';
        --
        l_any_topography      diagnosis.id_diagnosis%TYPE;
        l_any_morphology      diagnosis.id_diagnosis%TYPE;
        l_any_staging_basis   diagnosis.id_diagnosis%TYPE;
        l_any_treatment_group diagnosis.id_diagnosis%TYPE;
    
        l_id_diag_topography    diagnosis.id_diagnosis%TYPE;
        l_id_diag_morphology    diagnosis.id_diagnosis%TYPE;
        l_id_diag_staging_basis diagnosis.id_diagnosis%TYPE;
        l_code_staging_basis    diagnosis.code_icd%TYPE;
    
        l_epis_tnm_m   epis_diag_stag.id_tnm_m%TYPE;
        l_code_stage_m epis_diag_stag.code_tnm_m%TYPE;
    
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
        l_any_morphology      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_morphology_type);
        l_any_staging_basis   := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_stage_base_type);
        l_any_treatment_group := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_treatment_group);
    
        l_id_diag_topography    := pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_id_diag_morphology    := pk_diagnosis_core.get_term_diagnosis_id(i_morph, i_prof.institution, i_prof.software);
        l_id_diag_staging_basis := pk_diagnosis_core.get_term_diagnosis_id(i_staging_basis,
                                                                           i_prof.institution,
                                                                           i_prof.software);
        l_code_staging_basis    := pk_diagnosis_core.get_diagnosis_code(l_id_diag_staging_basis,
                                                                        i_prof.institution,
                                                                        i_prof.software);
    
        g_error := 'CALL GET_TREAMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_treatment_group := get_treament_group(i_prof            => i_prof,
                                                i_topography      => l_id_diag_topography,
                                                i_any_topography  => l_any_topography,
                                                i_topography_term => i_topography,
                                                i_morphology      => l_id_diag_morphology,
                                                i_any_morphology  => l_any_morphology);
    
        g_error := 'GET EPISODE TNM  - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        BEGIN
            SELECT *
              INTO l_epis_tnm_m, l_code_stage_m
              FROM (SELECT eg.id_tnm_m, eg.code_tnm_m
                      FROM epis_diag_stag eg
                     WHERE eg.id_epis_diagnosis = i_epis_diagnosis
                       AND i_epis_diag_hist IS NULL
                    
                    UNION ALL
                    
                    SELECT egh.id_tnm_m, egh.code_tnm_m
                      FROM epis_diag_stag_hist egh
                     WHERE egh.id_epis_diagnosis_hist = i_epis_diag_hist);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'ADD ITEMS - ' || i_internal_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_tnm_m IN pk_diagnosis_form.c_tnm_m(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_topography          => l_id_diag_topography,
                                                 i_any_topography      => l_any_topography,
                                                 i_morphology          => l_id_diag_morphology,
                                                 i_any_morphology      => l_any_morphology,
                                                 i_treatment_group     => l_treatment_group,
                                                 i_any_treatment_group => l_any_treatment_group,
                                                 i_staging_basis       => l_id_diag_staging_basis,
                                                 i_code_stage_basis    => l_code_staging_basis,
                                                 i_any_staging_basis   => l_any_staging_basis,
                                                 i_epis_tnm_m          => l_epis_tnm_m,
                                                 i_code_tnm_m          => l_code_stage_m)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => pk_dynamic_screen.c_leaf_component,
                         i_item_desc          => r_tnm_m.desc_tnm_m,
                         i_item_value         => r_tnm_m.id_tnm_m,
                         i_item_xml_value     => r_tnm_m.addit_info.getclobval(),
                         i_item_rank          => r_tnm_m.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_tnm_m.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    
        g_error := 'CALL ADD_TNM_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_tnm_def_events(i_lang            => i_lang,
                           i_prof            => i_prof,
                           i_internal_name   => i_internal_name,
                           io_tbl_def_events => io_tbl_def_events);
    END add_tnm_m;

    PROCEDURE add_prognostic_factors
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ds_cmpt_mkt_rel   IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component      IN ds_component.id_ds_component%TYPE,
        i_topography        IN diagnosis_ea.id_concept_term%TYPE,
        i_morphology        IN epis_diag_tumors.id_morphology%TYPE,
        i_tbl_pfactor_val   IN table_number_idx,
        io_tbl_sections     IN OUT NOCOPY t_table_ds_sections,
        io_tbl_def_events   IN OUT NOCOPY t_table_ds_def_events,
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT table_prog_factor_fld_val
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_PROGNOSTIC_FACTORS';
        --
        l_code_msg_req_factors CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M017'; -- Required factors for staging
        l_code_msg_clin_sign   CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M018'; -- Clinically significant factors
        --
        l_rank PLS_INTEGER;
        --
        l_id_diag_topography diagnosis.id_diagnosis%TYPE;
        l_id_diag_morphology diagnosis.id_diagnosis%TYPE;
    
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    
        l_any_topography      diagnosis.id_diagnosis%TYPE;
        l_any_morphology      diagnosis.id_diagnosis%TYPE;
        l_any_treatment_group diagnosis.id_diagnosis%TYPE;
        --
        l_aux_item_value t_rec_ds_items_values;
        --
        l_pfactor_val NUMBER;
    BEGIN
        l_rank := g_default_rank;
    
        l_any_topography      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
        l_any_morphology      := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_morphology_type);
        l_any_treatment_group := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_treatment_group);
    
        l_id_diag_topography := pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                        i_prof.institution,
                                                                        i_prof.software);
        l_id_diag_morphology := pk_diagnosis_core.get_term_diagnosis_id(i_morphology,
                                                                        i_prof.institution,
                                                                        i_prof.software);
    
        g_error := 'CALL GET_TREAMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_treatment_group := get_treament_group(i_prof            => i_prof,
                                                i_topography      => l_id_diag_topography,
                                                i_any_topography  => l_any_topography,
                                                i_topography_term => i_topography,
                                                i_morphology      => l_id_diag_morphology,
                                                i_any_morphology  => l_any_morphology);
    
        g_error := 'ADD NODE SECTION - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_req;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_new_section(i_ds_cmpt_mkt_rel     => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 1,
                        i_ds_component_parent => i_ds_component,
                        i_ds_component        => i_ds_component || g_prognostic_factor_uk || 1,
                        i_component_desc      => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => l_code_msg_req_factors),
                        i_internal_name       => pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                        i_flg_component_type  => pk_dynamic_screen.c_node_component,
                        i_flg_data_type       => NULL,
                        i_rank                => l_rank,
                        io_tbl_sections       => io_tbl_sections);
    
        g_error := 'ADD DEFAULT EVENT - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_req;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 1,
                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 1,
                          i_flg_event_type  => pk_alert_constant.g_active,
                          io_tbl_def_events => io_tbl_def_events);
    
        o_item_value := table_prog_factor_fld_val();
    
        FOR r_field IN c_pfactors_staging_fields(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_topography          => l_id_diag_topography,
                                                 i_any_topography      => l_any_topography,
                                                 i_morphology          => l_id_diag_morphology,
                                                 i_any_morphology      => l_any_morphology,
                                                 i_treatment_group     => l_treatment_group,
                                                 i_any_treatment_group => l_any_treatment_group)
        LOOP
            g_error := 'ADD LEAF SECTION - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_req || ': ' ||
                       r_field.id_field;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_new_section(i_ds_cmpt_mkt_rel      => g_prognostic_factor_uk || 1 || r_field.id_field,
                            i_ds_component_parent  => i_ds_component || g_prognostic_factor_uk || 1,
                            i_ds_component         => g_prognostic_factor_uk || 1 || r_field.id_field,
                            i_component_desc       => r_field.field_label,
                            i_internal_name        => pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                            i_flg_component_type   => pk_dynamic_screen.c_leaf_component,
                            i_flg_data_type        => pk_dynamic_screen.c_data_type_ms,
                            i_addit_info_xml_value => r_field.addit_info.getclobval(),
                            i_rank                 => r_field.rank,
                            io_tbl_sections        => io_tbl_sections);
        
            g_error := 'ADD DEFAULT EVENT - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_req || ': ' ||
                       r_field.internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_new_def_event(i_pk              => g_prognostic_factor_uk || 1 || r_field.id_field,
                              i_ds_cmpt_mkt_rel => g_prognostic_factor_uk || 1 || r_field.id_field,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        
            g_error := 'GET PFACTOR_VAL';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            BEGIN
                l_pfactor_val := i_tbl_pfactor_val(r_field.id_field);
            EXCEPTION
                WHEN no_data_found THEN
                    l_pfactor_val := NULL;
            END;
        
            g_error := 'ADD ITEMS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            FOR r_value IN c_pfactors_staging_values(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_pfactor_staging_field => pk_diagnosis_core.get_term_diagnosis_id(r_field.id_field,
                                                                                                                        i_prof.institution,
                                                                                                                        i_prof.software),
                                                     i_pfactor_staging_value => l_pfactor_val)
            LOOP
                add_new_item(i_ds_cmpt_mkt_rel    => g_prognostic_factor_uk || 1 || r_field.id_field,
                             i_ds_component       => g_prognostic_factor_uk || 1 || r_field.id_field,
                             i_internal_name      => pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                             i_flg_component_type => pk_dynamic_screen.c_leaf_component,
                             i_item_desc          => r_value.desc_value,
                             i_item_value         => r_value.id_value,
                             i_item_xml_value     => r_value.addit_info.getclobval(),
                             i_item_rank          => r_value.rank,
                             io_tbl_items_values  => io_tbl_items_values);
            
                define_default_value(i_flg_default       => r_value.flg_default,
                                     io_tbl_items_values => io_tbl_items_values,
                                     io_item_value       => l_aux_item_value);
            END LOOP;
        
            o_item_value.extend;
            o_item_value(o_item_value.count).id_field := r_field.id_field;
            o_item_value(o_item_value.count).item_value := l_aux_item_value;
        END LOOP;
    
        l_rank := l_rank + g_default_rank;
    
        g_error := 'ADD NODE SECTION - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_cli;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_new_section(i_ds_cmpt_mkt_rel     => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 2,
                        i_ds_component_parent => i_ds_component,
                        i_ds_component        => i_ds_component || g_prognostic_factor_uk || 2,
                        i_component_desc      => pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => l_code_msg_clin_sign),
                        i_internal_name       => pk_diagnosis_form.g_dsc_cancer_progn_factors_cli,
                        i_flg_component_type  => pk_dynamic_screen.c_node_component,
                        i_flg_data_type       => NULL,
                        i_rank                => l_rank,
                        io_tbl_sections       => io_tbl_sections);
    
        g_error := 'ADD DEFAULT EVENT - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_cli;
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        add_new_def_event(i_pk              => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 2,
                          i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel || g_prognostic_factor_uk || 2,
                          i_flg_event_type  => pk_alert_constant.g_active,
                          io_tbl_def_events => io_tbl_def_events);
    
        FOR r_field IN c_pfactors_clin_signif_fields(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_topography     => l_id_diag_topography,
                                                     i_any_topography => l_any_topography)
        LOOP
            g_error := 'ADD LEAF SECTION - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_cli || ': ' ||
                       r_field.id_field;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_new_section(i_ds_cmpt_mkt_rel      => g_prognostic_factor_uk || 2 || r_field.id_field,
                            i_ds_component_parent  => i_ds_component || g_prognostic_factor_uk || 2,
                            i_ds_component         => g_prognostic_factor_uk || 2 || r_field.id_field,
                            i_component_desc       => r_field.field_label,
                            i_internal_name        => pk_diagnosis_form.g_dsc_cancer_progn_factors_cli,
                            i_flg_component_type   => pk_dynamic_screen.c_leaf_component,
                            i_flg_data_type        => pk_dynamic_screen.c_data_type_ft,
                            i_addit_info_xml_value => r_field.addit_info.getclobval(),
                            i_rank                 => r_field.rank,
                            io_tbl_sections        => io_tbl_sections);
        
            g_error := 'ADD DEFAULT EVENT - ' || pk_diagnosis_form.g_dsc_cancer_progn_factors_cli || ': ' ||
                       r_field.internal_name;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            add_new_def_event(i_pk              => g_prognostic_factor_uk || 2 || r_field.id_field,
                              i_ds_cmpt_mkt_rel => g_prognostic_factor_uk || 2 || r_field.id_field,
                              i_flg_event_type  => pk_alert_constant.g_active,
                              io_tbl_def_events => io_tbl_def_events);
        END LOOP;
    END add_prognostic_factors;

    PROCEDURE add_laterality
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        i_laterality         IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_LATERALITY';
        --
        l_any_topography diagnosis.id_diagnosis%TYPE;
    BEGIN
    
        l_any_topography := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_lat IN c_lateralities(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_topography     => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                i_prof.institution,
                                                                                                i_prof.software),
                                    i_any_topography => l_any_topography,
                                    i_laterality     => i_laterality)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_lat.desc_laterality,
                         i_item_value         => r_lat.id_laterality,
                         i_item_xml_value     => r_lat.addit_info.getclobval(),
                         i_item_rank          => r_lat.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_lat.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_laterality;

    PROCEDURE add_morphology
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        i_basis_diag         IN diagnosis_ea.id_concept_term%TYPE,
        i_morphology         IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_MORPHOLOGY';
        --
        l_any_topography diagnosis.id_diagnosis%TYPE;
        l_any_basis_diag diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
        l_any_basis_diag := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_diag_basis_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_hist IN c_histologies(i_lang           => i_lang,
                                    i_prof           => i_prof,
                                    i_topography     => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                i_prof.institution,
                                                                                                i_prof.software),
                                    i_any_topography => l_any_topography,
                                    i_basis_diag     => pk_diagnosis_core.get_term_diagnosis_id(i_basis_diag,
                                                                                                i_prof.institution,
                                                                                                i_prof.software),
                                    i_any_basis_diag => l_any_basis_diag,
                                    i_morphology     => i_morphology)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_hist.desc_morphology,
                         i_item_value         => r_hist.id_morphology,
                         i_item_xml_value     => r_hist.addit_info.getclobval(),
                         i_item_rank          => r_hist.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_hist.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_morphology;

    PROCEDURE add_behavior
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_morphology         IN diagnosis_ea.id_concept_term%TYPE,
        i_behavior           IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_BEHAVIOR';
    BEGIN
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_behav IN c_behaviours(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_morphology => pk_diagnosis_core.get_term_diagnosis_id(i_morphology,
                                                                                            i_prof.institution,
                                                                                            i_prof.software),
                                    i_behavior   => i_behavior)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_behav.desc_behavior,
                         i_item_value         => r_behav.id_behavior,
                         i_item_xml_value     => r_behav.addit_info.getclobval(),
                         i_item_rank          => r_behav.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_behav.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_behavior;

    PROCEDURE add_histological_grade
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        i_histological_grade IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_HISTOLOGICAL_GRADE';
    BEGIN
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_hist_grade IN pk_diagnosis_form.c_histological_grade(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_topography         => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                                                   i_prof.institution,
                                                                                                                                   i_prof.software),
                                                                   i_histological_grade => i_histological_grade)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_hist_grade.desc_histological_grade,
                         i_item_value         => r_hist_grade.id_histological_grade,
                         i_item_xml_value     => r_hist_grade.addit_info.getclobval(),
                         i_item_rank          => r_hist_grade.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_hist_grade.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_histological_grade;

    PROCEDURE add_other_grading_sys
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        i_morphology         IN diagnosis_ea.id_concept_term%TYPE,
        i_other_grading_sys  IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_OTHER_GRADING_SYS';
        --
        l_any_topography      diagnosis.id_diagnosis%TYPE;
        l_any_morphology      diagnosis.id_diagnosis%TYPE;
        l_any_treatment_group diagnosis.id_diagnosis%TYPE;
    
        l_id_diag_topography diagnosis.id_diagnosis%TYPE;
        l_id_diag_morphology diagnosis.id_diagnosis%TYPE;
    
        l_treatment_group diagnosis.id_diagnosis%TYPE;
    BEGIN
        g_error := 'GET_CONCEPT_VALIDATION_ANY - ';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_any_topography      := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_topography_type);
        l_any_morphology      := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_morphology_type);
        l_any_treatment_group := pk_api_pfh_diagnosis_in.get_concept_validation_any(pk_diagnosis_form.g_treatment_group);
    
        l_id_diag_topography := pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                        i_prof.institution,
                                                                        i_prof.software);
        l_id_diag_morphology := pk_diagnosis_core.get_term_diagnosis_id(i_morphology,
                                                                        i_prof.institution,
                                                                        i_prof.software);
    
        g_error := 'CALL GET_TREAMENT_GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        l_treatment_group := get_treament_group(i_prof            => i_prof,
                                                i_topography      => l_id_diag_topography,
                                                i_any_topography  => l_any_topography,
                                                i_topography_term => i_topography,
                                                i_morphology      => l_id_diag_morphology,
                                                i_any_morphology  => l_any_morphology);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_ograd IN c_other_grading_sys(i_lang                => i_lang,
                                           i_prof                => i_prof,
                                           i_topography          => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                            i_prof.institution,
                                                                                                            i_prof.software),
                                           i_any_topography      => l_any_topography,
                                           i_morphology          => pk_diagnosis_core.get_term_diagnosis_id(i_morphology,
                                                                                                            i_prof.institution,
                                                                                                            i_prof.software),
                                           i_any_morphology      => l_any_morphology,
                                           i_treatment_group     => l_treatment_group,
                                           i_any_treatment_group => l_any_treatment_group,
                                           i_other_grading_sys   => i_other_grading_sys)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_ograd.desc_other_grading_sys,
                         i_item_value         => r_ograd.id_other_grading_sys,
                         i_item_xml_value     => r_ograd.addit_info.getclobval(),
                         i_item_rank          => r_ograd.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_ograd.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_other_grading_sys;

    PROCEDURE add_other_staging_sys
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_topography         IN diagnosis_ea.id_concept_term%TYPE,
        i_other_staging_sys  IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_OTHER_STAGING_SYS';
        --
        l_any_topography diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_ostag IN c_other_staging_sys(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_topography        => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                          i_prof.institution,
                                                                                                          i_prof.software),
                                           i_any_topography    => l_any_topography,
                                           i_other_staging_sys => i_other_staging_sys)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_ostag.desc_other_staging_sys,
                         i_item_value         => r_ostag.id_other_staging_sys,
                         i_item_xml_value     => r_ostag.addit_info.getclobval(),
                         i_item_rank          => r_ostag.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_ostag.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_other_staging_sys;

    PROCEDURE add_metastatic_sites
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_tnm_m              IN diagnosis_ea.id_concept_term%TYPE,
        i_metastatic_sites   IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_METASTATIC_SITES';
        --
        l_any_tnm_m diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_tnm_m := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_tnm_m_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_meta IN c_metastatic_sites(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_tnm_m            => pk_diagnosis_core.get_term_diagnosis_id(i_tnm_m,
                                                                                                       i_prof.institution,
                                                                                                       i_prof.software),
                                         i_any_tnm_m        => l_any_tnm_m,
                                         i_metastatic_sites => i_metastatic_sites)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_meta.desc_metastatic_sites,
                         i_item_value         => r_meta.id_metastatic_sites,
                         i_item_xml_value     => r_meta.addit_info.getclobval(),
                         i_item_rank          => r_meta.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_meta.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_metastatic_sites;

    PROCEDURE add_lymph_vascular_invasion
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_ds_cmpt_mkt_rel         IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component            IN ds_component.id_ds_component%TYPE,
        i_internal_name           IN ds_component.internal_name%TYPE,
        i_flg_component_type      IN ds_component.flg_component_type%TYPE,
        i_topography              IN diagnosis_ea.id_concept_term%TYPE,
        i_lymph_vascular_invasion IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values       IN OUT NOCOPY t_table_ds_items_values,
        o_item_value              OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_LYMPH_VASCULAR_INVASION';
        --
        l_any_topography diagnosis.id_diagnosis%TYPE;
    BEGIN
        l_any_topography := pk_api_pfh_diagnosis_in.get_concept_validation_any(g_topography_type);
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_lymph IN c_lymph_vascular_invasion(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_topography              => pk_diagnosis_core.get_term_diagnosis_id(i_topography,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                 i_any_topography          => l_any_topography,
                                                 i_lymph_vascular_invasion => i_lymph_vascular_invasion)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_lymph.desc_lymph_vascular_invasion,
                         i_item_value         => r_lymph.id_lymph_vascular_invasion,
                         i_item_xml_value     => r_lymph.addit_info.getclobval(),
                         i_item_rank          => r_lymph.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_lymph.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
        END LOOP;
    END add_lymph_vascular_invasion;

    PROCEDURE set_last_item_as_default
    (
        io_tbl_items_values IN OUT NOCOPY t_table_ds_items_values,
        o_item_value        OUT t_rec_ds_items_values
    ) IS
    BEGIN
        SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(t.flg_default)).getclobval()
          INTO io_tbl_items_values(io_tbl_items_values.count).item_xml_value
          FROM (SELECT pk_alert_constant.g_yes flg_default
                  FROM dual) t;
    
        o_item_value := io_tbl_items_values(io_tbl_items_values.count);
    END set_last_item_as_default;

    PROCEDURE inactivate_leaf
    (
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        io_def_events     IN OUT t_table_ds_def_events
    ) IS
    BEGIN
        IF io_def_events.exists(1)
        THEN
            FOR i IN io_def_events.first .. io_def_events.last
            LOOP
                IF io_def_events(i).id_ds_cmpt_mkt_rel = i_ds_cmpt_mkt_rel
                THEN
                    io_def_events(i).flg_event_type := pk_alert_constant.g_inactive;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    END inactivate_leaf;

    PROCEDURE handle_acc_emergency_diag
    (
        i_total_items                IN PLS_INTEGER,
        i_ds_cmpt_mkt_rel            IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_flg_edit_mode              IN VARCHAR2,
        i_is_to_fill_with_saved_data IN VARCHAR2,
        io_def_events                IN OUT NOCOPY t_table_ds_def_events,
        io_events                    IN OUT NOCOPY t_table_ds_events,
        io_tbl_items_values          IN OUT NOCOPY t_table_ds_items_values,
        o_item_value                 OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'HANDLE_ACC_EMERGENCY_DIAG';
        --
        l_tbl_evts_to_remove t_table_ds_events;
    BEGIN
        IF i_total_items = 1
        THEN
            --There is only one item for the current multicoice so it must be selected by default
            g_error := 'CALL SET_LAST_ITEM_AS_DEFAULT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            set_last_item_as_default(io_tbl_items_values => io_tbl_items_values, o_item_value => o_item_value);
        END IF;
    
        IF i_total_items <= 1
           OR i_flg_edit_mode = pk_diagnosis_core.g_diag_edit_mode_edit
           OR (i_flg_edit_mode = pk_diagnosis_core.g_diag_create_mode AND
           i_is_to_fill_with_saved_data = pk_alert_constant.g_yes)
        THEN
            g_error := 'GET EVENTS TO BE REMOVED';
            --Due to the rules of cancer diagnosis form when a parent field is inactive all it's childs are inactive.
            --Ex: When topography is inactive it makes no sense that histology is active, so flash inactivates the histology field.
            --Flash knows these dependencies through events.
            --In AE diagnosis form this shouldn't happen because there are situations when we have no sub analysis.
            --To overcome this I will remove the events of the field that has no data to display
            --With no dependencies flash will activate the child fields
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            SELECT t_rec_ds_events(id_ds_event    => e.id_ds_event,
                                   origin         => e.origin,
                                   VALUE          => e.value,
                                   target         => e.target,
                                   flg_event_type => e.flg_event_type)
              BULK COLLECT
              INTO l_tbl_evts_to_remove
              FROM TABLE(io_events) e
             WHERE e.origin = i_ds_cmpt_mkt_rel;
        
            g_error := 'CALL REMOVE_SECTION_EVENTS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            remove_section_events(io_tbl_all_events => io_events, i_tbl_evts_to_remove => l_tbl_evts_to_remove);
        
            g_error := 'CALL INACTIVATE_LEAF';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
            inactivate_leaf(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel, io_def_events => io_def_events);
        END IF;
    END handle_acc_emergency_diag;

    PROCEDURE add_sub_analysis
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_ds_cmpt_mkt_rel            IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component               IN ds_component.id_ds_component%TYPE,
        i_internal_name              IN ds_component.internal_name%TYPE,
        i_flg_component_type         IN ds_component.flg_component_type%TYPE,
        i_diagnosis                  IN diagnosis_ea.id_concept_version%TYPE,
        i_alert_diagnosis            IN diagnosis_ea.id_concept_term%TYPE,
        i_sub_analysis               IN diagnosis_ea.id_concept_term%TYPE,
        i_flg_edit_mode              IN VARCHAR2,
        i_is_to_fill_with_saved_data IN VARCHAR2,
        io_def_events                IN OUT NOCOPY t_table_ds_def_events,
        io_events                    IN OUT NOCOPY t_table_ds_events,
        io_tbl_items_values          IN OUT NOCOPY t_table_ds_items_values,
        o_item_value                 OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_SUB_ANALYSIS';
        --
        l_count PLS_INTEGER := 0;
        --
        l_diagnosis diagnosis_ea.id_concept_version%TYPE;
        l_diag_type diagnosis.concept_type_int_name%TYPE;
    BEGIN
        SELECT d.concept_type_int_name
          INTO l_diag_type
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diagnosis;
    
        IF l_diag_type = g_ae_diagnosis_type
        THEN
            --validate if ae_diagnosis has sub_analysis if it does return them, if not try to get sub analysis form it's parent
            --the diagnosis_condition
            SELECT COUNT(1)
              INTO l_count
              FROM diagnosis_relations_ea dr
              JOIN diagnosis_ea d
                ON d.id_concept_version = dr.id_concept_version_2
               AND d.id_institution = dr.id_institution
               AND d.id_software = dr.id_software
             WHERE dr.id_concept_version_1 = i_diagnosis
               AND dr.concept_type_int_name1 = pk_diagnosis_form.g_ae_diagnosis_type
               AND dr.cncpt_rel_type_int_name = pk_diagnosis_form.g_rel_is_a
               AND dr.concept_type_int_name2 = pk_diagnosis_form.g_sub_analysis_type
               AND dr.id_institution = i_prof.institution
               AND dr.id_software = i_prof.software;
        
            IF l_count = 0
            THEN
                l_diagnosis := pk_diagnosis_core.get_id_diag_condition(i_prof => i_prof, i_diagnosis => i_diagnosis);
                l_diag_type := pk_diagnosis_form.g_diag_condition_type;
            ELSE
                l_diagnosis := i_diagnosis;
            END IF;
        
            --reset l_count
            l_count := 0;
        ELSE
            l_diagnosis := i_diagnosis;
        END IF;
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_sub_analysis IN pk_diagnosis_form.c_sub_analysis(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_diagnosis       => l_diagnosis,
                                                               i_alert_diagnosis => i_alert_diagnosis,
                                                               i_diag_type       => l_diag_type,
                                                               i_sub_analysis    => i_sub_analysis)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_sub_analysis.desc_sub_analysis,
                         i_item_value         => r_sub_analysis.id_sub_analysis,
                         i_item_xml_value     => r_sub_analysis.addit_info.getclobval(),
                         i_item_rank          => r_sub_analysis.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'CALL HANDLE_ACC_EMERGENCY_DIAG';
        handle_acc_emergency_diag(i_total_items                => l_count,
                                  i_ds_cmpt_mkt_rel            => i_ds_cmpt_mkt_rel,
                                  i_flg_edit_mode              => i_flg_edit_mode,
                                  i_is_to_fill_with_saved_data => i_is_to_fill_with_saved_data,
                                  io_def_events                => io_def_events,
                                  io_events                    => io_events,
                                  io_tbl_items_values          => io_tbl_items_values,
                                  o_item_value                 => o_item_value);
    END add_sub_analysis;

    PROCEDURE add_anatomical_area
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_ds_cmpt_mkt_rel            IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component               IN ds_component.id_ds_component%TYPE,
        i_internal_name              IN ds_component.internal_name%TYPE,
        i_flg_component_type         IN ds_component.flg_component_type%TYPE,
        i_diagnosis                  IN diagnosis_ea.id_concept_version%TYPE,
        i_sub_analysis               IN diagnosis_ea.id_concept_term%TYPE,
        i_anatomical_area            IN diagnosis_ea.id_concept_term%TYPE,
        i_flg_edit_mode              IN VARCHAR2,
        i_is_to_fill_with_saved_data IN VARCHAR2,
        io_def_events                IN OUT NOCOPY t_table_ds_def_events,
        io_events                    IN OUT NOCOPY t_table_ds_events,
        io_tbl_items_values          IN OUT NOCOPY t_table_ds_items_values,
        o_item_value                 OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_ANATOMICAL_AREA';
        --
        l_count PLS_INTEGER := 0;
        --
        l_diagnosis      diagnosis_ea.id_concept_version%TYPE;
        l_diag_condition diagnosis_ea.id_concept_version%TYPE;
        l_sub_analysis   diagnosis_ea.id_concept_version%TYPE;
        l_diag_type      diagnosis.concept_type_int_name%TYPE;
        --
        l_sub_analysis_concept diagnosis_ea.id_concept_version%TYPE;
        --
        FUNCTION get_total_anat_areas
        (
            i_cv        IN diagnosis_ea.id_concept_version%TYPE,
            i_diag_type IN diagnosis.concept_type_int_name%TYPE
        ) RETURN PLS_INTEGER IS
            l_ret PLS_INTEGER;
        BEGIN
            SELECT COUNT(1)
              INTO l_ret
              FROM diagnosis_relations_ea dr
              JOIN diagnosis_ea d
                ON d.id_concept_version = dr.id_concept_version_2
               AND d.id_institution = dr.id_institution
               AND d.id_software = dr.id_software
             WHERE dr.id_concept_version_1 = i_cv
               AND dr.concept_type_int_name1 = i_diag_type
               AND dr.cncpt_rel_type_int_name = pk_diagnosis_form.g_rel_finding_site
               AND dr.concept_type_int_name2 = pk_diagnosis_form.g_anatomical_area_type
               AND dr.id_institution = i_prof.institution
               AND dr.id_software = i_prof.software;
        
            RETURN l_ret;
        END get_total_anat_areas;
    BEGIN
        g_error := 'GET DIAG TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        SELECT d.concept_type_int_name
          INTO l_diag_type
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diagnosis;
    
        --validate if ae_diagnosis has anatomical_areas if it does return them, 
        IF get_total_anat_areas(i_cv => i_diagnosis, i_diag_type => l_diag_type) != 0
        THEN
            l_diagnosis := i_diagnosis;
        ELSE
            IF i_sub_analysis IS NULL
               AND l_diag_type = g_ae_diagnosis_type
            THEN
                l_sub_analysis := pk_diagnosis_core.get_id_sub_analysis(i_prof => i_prof, i_diagnosis => i_diagnosis);
            
                IF l_sub_analysis IS NOT NULL
                THEN
                    --if not try to get sub analysis and validate if it has areas
                    IF get_total_anat_areas(i_cv        => l_sub_analysis,
                                            i_diag_type => pk_diagnosis_form.g_sub_analysis_type) = 0
                    THEN
                        l_diag_condition := pk_diagnosis_core.get_id_diag_condition(i_prof      => i_prof,
                                                                                    i_diagnosis => l_sub_analysis);
                    
                        l_diagnosis := l_diag_condition;
                        l_diag_type := pk_diagnosis_form.g_diag_condition_type;
                    ELSE
                        l_diagnosis := l_sub_analysis;
                        l_diag_type := pk_diagnosis_form.g_sub_analysis_type;
                    END IF;
                ELSE
                    l_diag_condition := pk_diagnosis_core.get_id_diag_condition(i_prof      => i_prof,
                                                                                i_diagnosis => i_diagnosis);
                
                    l_diagnosis := l_diag_condition;
                    l_diag_type := pk_diagnosis_form.g_diag_condition_type;
                END IF;
            ELSIF i_sub_analysis IS NOT NULL
            THEN
                l_sub_analysis := i_sub_analysis;
            
                IF get_total_anat_areas(i_cv => l_sub_analysis, i_diag_type => pk_diagnosis_form.g_sub_analysis_type) = 0
                THEN
                    l_diag_condition := pk_diagnosis_core.get_id_diag_condition(i_prof      => i_prof,
                                                                                i_diagnosis => l_sub_analysis);
                
                    l_diagnosis := l_diag_condition;
                    l_diag_type := pk_diagnosis_form.g_diag_condition_type;
                ELSE
                    l_diagnosis := l_sub_analysis;
                    l_diag_type := pk_diagnosis_form.g_sub_analysis_type;
                END IF;
            ELSE
                l_diag_condition := pk_diagnosis_core.get_id_diag_condition(i_prof      => i_prof,
                                                                            i_diagnosis => i_diagnosis);
            
                l_diagnosis := l_diag_condition;
                l_diag_type := pk_diagnosis_form.g_diag_condition_type;
            END IF;
        END IF;
    
        g_error := 'GET SUB_ANALYSIS CONCEPT_VERSION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        BEGIN
            SELECT ad.id_diagnosis
              INTO l_sub_analysis_concept
              FROM alert_diagnosis ad
             WHERE ad.id_alert_diagnosis = i_sub_analysis;
        EXCEPTION
            WHEN no_data_found THEN
                l_sub_analysis_concept := NULL;
        END;
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_anatomical_area IN pk_diagnosis_form.c_anatomical_area(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_diagnosis       => l_diagnosis,
                                                                     i_diag_type       => l_diag_type,
                                                                     i_sub_analysis    => nvl(l_sub_analysis_concept,
                                                                                              l_sub_analysis),
                                                                     i_anatomical_area => i_anatomical_area)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_anatomical_area.desc_anatomical_area,
                         i_item_value         => r_anatomical_area.id_anatomical_area,
                         i_item_xml_value     => r_anatomical_area.addit_info.getclobval(),
                         i_item_rank          => r_anatomical_area.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'CALL HANDLE_ACC_EMERGENCY_DIAG';
        handle_acc_emergency_diag(i_total_items                => l_count,
                                  i_ds_cmpt_mkt_rel            => i_ds_cmpt_mkt_rel,
                                  i_flg_edit_mode              => i_flg_edit_mode,
                                  i_is_to_fill_with_saved_data => i_is_to_fill_with_saved_data,
                                  io_def_events                => io_def_events,
                                  io_events                    => io_events,
                                  io_tbl_items_values          => io_tbl_items_values,
                                  o_item_value                 => o_item_value);
    END add_anatomical_area;

    PROCEDURE add_anatomical_side
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_ds_cmpt_mkt_rel            IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component               IN ds_component.id_ds_component%TYPE,
        i_internal_name              IN ds_component.internal_name%TYPE,
        i_flg_component_type         IN ds_component.flg_component_type%TYPE,
        i_diagnosis                  IN diagnosis_ea.id_concept_version%TYPE,
        i_anatomical_area            IN diagnosis_ea.id_concept_term%TYPE,
        i_anatomical_side            IN diagnosis_ea.id_concept_term%TYPE,
        i_flg_edit_mode              IN VARCHAR2,
        i_is_to_fill_with_saved_data IN VARCHAR2,
        io_def_events                IN OUT NOCOPY t_table_ds_def_events,
        io_events                    IN OUT NOCOPY t_table_ds_events,
        io_tbl_items_values          IN OUT NOCOPY t_table_ds_items_values,
        o_item_value                 OUT t_rec_ds_items_values
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_ANATOMICAL_SIDE';
        --
        l_count PLS_INTEGER := 0;
        --
        l_diag_type diagnosis.concept_type_int_name%TYPE;
        --
        l_anatomical_area_concept diagnosis_ea.id_concept_version%TYPE;
    BEGIN
        g_error := 'GET DIAG TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        SELECT d.concept_type_int_name
          INTO l_diag_type
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diagnosis;
    
        g_error := 'GET ANATOMICAL_AREA CONCEPT_VERSION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        BEGIN
            SELECT ad.id_diagnosis
              INTO l_anatomical_area_concept
              FROM alert_diagnosis ad
             WHERE ad.id_alert_diagnosis = i_anatomical_area;
        EXCEPTION
            WHEN no_data_found THEN
                l_anatomical_area_concept := NULL;
        END;
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_anatomical_side IN pk_diagnosis_form.c_anatomical_side(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_diagnosis       => i_diagnosis,
                                                                     i_diag_type       => l_diag_type,
                                                                     i_anatomical_area => l_anatomical_area_concept,
                                                                     i_anatomical_side => i_anatomical_side)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_anatomical_side.desc_anatomical_side,
                         i_item_value         => r_anatomical_side.id_anatomical_side,
                         i_item_xml_value     => r_anatomical_side.addit_info.getclobval(),
                         i_item_rank          => r_anatomical_side.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            l_count := l_count + 1;
        END LOOP;
    
        g_error := 'CALL HANDLE_ACC_EMERGENCY_DIAG';
        handle_acc_emergency_diag(i_total_items                => l_count,
                                  i_ds_cmpt_mkt_rel            => i_ds_cmpt_mkt_rel,
                                  i_flg_edit_mode              => i_flg_edit_mode,
                                  i_is_to_fill_with_saved_data => i_is_to_fill_with_saved_data,
                                  io_def_events                => io_def_events,
                                  io_events                    => io_events,
                                  io_tbl_items_values          => io_tbl_items_values,
                                  o_item_value                 => o_item_value);
    END add_anatomical_side;

    PROCEDURE add_lesion_location
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_diagnosis          IN diagnosis_ea.id_concept_term%TYPE,
        i_lesion_location    IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values,
        io_def_events        IN OUT NOCOPY t_table_ds_def_events
        
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_LESION_LOCATION';
        l_diag_type diagnosis.concept_type_int_name%TYPE;
        l_count     NUMBER := 0;
    BEGIN
    
        --   IF pk_diagnosis_core.check_diag_trauma(i_lang => i_lang, i_prof => i_prof, i_diagnosis => i_diagnosis) =
        --      pk_alert_constant.g_yes
        --    THEN
        g_error := 'GET DIAG TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        SELECT d.concept_type_int_name
          INTO l_diag_type
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diagnosis;
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_loc IN c_lesion_location(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_diagnosis          => i_diagnosis,
                                       i_diag_type          => l_diag_type,
                                       i_id_lesion_location => i_lesion_location)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_loc.desc_lesion_location,
                         i_item_value         => r_loc.id_lesion_location,
                         i_item_xml_value     => r_loc.addit_info.getclobval(),
                         i_item_rank          => r_loc.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_loc.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
            l_count := l_count + 1;
        END LOOP;
        --      END IF;
    
        IF l_count = 0
        THEN
            inactivate_leaf(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel, io_def_events => io_def_events);
        END IF;
    
    END add_lesion_location;

    PROCEDURE add_lesion_type
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
        i_ds_component       IN ds_component.id_ds_component%TYPE,
        i_internal_name      IN ds_component.internal_name%TYPE,
        i_flg_component_type IN ds_component.flg_component_type%TYPE,
        i_diagnosis          IN diagnosis_ea.id_concept_term%TYPE,
        i_id_lesion_type     IN diagnosis_ea.id_concept_term%TYPE,
        io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values,
        o_item_value         OUT t_rec_ds_items_values,
        io_def_events        IN OUT NOCOPY t_table_ds_def_events
        
    ) IS
        l_proc_name CONSTANT VARCHAR2(30) := 'ADD_LESION_TYPE';
        --
        --      l_any_topography diagnosis.id_diagnosis%TYPE;
        l_diag_type diagnosis.concept_type_int_name%TYPE;
        l_count     NUMBER := 0;
    BEGIN
    
        --       IF pk_diagnosis_core.check_diag_trauma(i_lang => i_lang, i_prof => i_prof, i_diagnosis => i_diagnosis) =
        --          pk_alert_constant.g_yes
        --       THEN
        g_error := 'GET DIAG TYPE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        SELECT d.concept_type_int_name
          INTO l_diag_type
          FROM diagnosis d
         WHERE d.id_diagnosis = i_diagnosis;
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_proc_name);
        FOR r_int IN c_lesion_type(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_diagnosis      => i_diagnosis,
                                   i_diag_type      => l_diag_type,
                                   i_id_lesion_type => i_id_lesion_type)
        LOOP
            add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                         i_ds_component       => i_ds_component,
                         i_internal_name      => i_internal_name,
                         i_flg_component_type => i_flg_component_type,
                         i_item_desc          => r_int.desc_lesion_type,
                         i_item_value         => r_int.id_lesion_type,
                         i_item_xml_value     => r_int.addit_info.getclobval(),
                         i_item_rank          => r_int.rank,
                         io_tbl_items_values  => io_tbl_items_values);
        
            define_default_value(i_flg_default       => r_int.flg_default,
                                 io_tbl_items_values => io_tbl_items_values,
                                 io_item_value       => o_item_value);
            l_count := l_count + 1;
        END LOOP;
        --       END IF;
        IF l_count = 0
        THEN
            inactivate_leaf(i_ds_cmpt_mkt_rel => i_ds_cmpt_mkt_rel, io_def_events => io_def_events);
        END IF;
    END add_lesion_type;
    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    See rec_section_data_param record for more detail
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_flg_type                  P - Differencial
    *                                      D - Final
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN pk_edis_types.rec_diag_section_data_param,
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
        l_tumor_num    epis_diag_tumors.tumor_num%TYPE;
    
        --OUTPUT CURSORS
        l_final_tbl_sections t_table_ds_sections := t_table_ds_sections(); -- o_section cursor 
        l_tbl_events         t_table_ds_events; --o_events cursor
        l_tbl_def_events     t_table_ds_def_events; --o_def_events cursor
        l_tbl_items_values   t_table_ds_items_values; --o_items_values
    
        l_aux_data_val xmltype := NULL; --auxiliar var used to keep default data or previous saved data
        --
        --DIAGNOSES STATUS OPTIONS VARS
        l_diag_stat_already_called BOOLEAN := FALSE;
        l_tbl_status               pk_edis_types.table_status;
        l_tbl_assoc_prob           pk_edis_types.table_assoc_prob;
        --
        --ACCIDENT AND EMERGENCY FIELDS
        l_sub_analysis    t_rec_ds_items_values;
        l_anatomical_area t_rec_ds_items_values;
        l_anatomical_side t_rec_ds_items_values;
        --Trauma fields MX
        l_location       t_rec_ds_items_values;
        l_intentionality t_rec_ds_items_values;
        --
        l_tbl_prog_fact_fld_vals table_prog_factor_fld_val;
        l_tbl_leafs_default      table_leaf_def_data;
        --
        --LOCAL EXCEPTIONS
        l_exception EXCEPTION;
        --
        --DISCHARGE DIAGNOSIS MANAGE BY RANK OR PRINCIPAL
        g_manage_principal CONSTANT VARCHAR2(1 CHAR) := 'P';
        g_manage_rank      CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_diag_manage_type VARCHAR2(100 CHAR) := nvl(pk_sysconfig.get_config('DISCHARGE_DIAGNOSIS_MANAGE_BY_RANK_OR_PRINCIPAL',
                                                                             i_prof),
                                                     g_manage_principal);
        --                                           
        --INNER PROCS/FUNCS
        PROCEDURE get_diag_status_new_lst IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INVESTIGATION_STATUS';
            --
            c_status     pk_edis_types.cursor_status;
            c_assoc_prob pk_edis_types.cursor_assoc_prob;
        BEGIN
            IF NOT l_diag_stat_already_called
            THEN
                g_error := 'CALL PK_DIAGNOSIS.GET_EPIS_DIAG_STAT_NEW_LIST';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                IF NOT pk_diagnosis.get_epis_diag_stat_new_list(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_flg_type   => i_params.flg_type,
                                                                o_status     => c_status,
                                                                o_assoc_prob => c_assoc_prob,
                                                                o_error      => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                FETCH c_status BULK COLLECT
                    INTO l_tbl_status;
                CLOSE c_status;
            
                FETCH c_assoc_prob BULK COLLECT
                    INTO l_tbl_assoc_prob;
                CLOSE c_assoc_prob;
            
                l_diag_stat_already_called := TRUE;
            END IF;
        END get_diag_status_new_lst;
    
        PROCEDURE add_investigation_status
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_INVESTIGATION_STATUS';
            --
            r_status    pk_edis_types.rec_status;
            l_xml_value xmltype;
            l_rank      PLS_INTEGER;
        BEGIN
            g_error := 'CALL GET_DIAG_STATUS_NEW_LST';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
            get_diag_status_new_lst();
        
            IF l_tbl_status IS NOT NULL
               AND l_tbl_status.count > 0
            THEN
                l_rank := g_default_rank;
            
                g_error := 'ADD ALL INVESTIGATION STATUS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                FOR i IN l_tbl_status.first .. l_tbl_status.last
                LOOP
                    r_status := l_tbl_status(i);
                
                    SELECT xmlelement("ADDITIONAL_INFO",
                                      xmlattributes(a.img_name, --
                                                    a.flg_default))
                      INTO l_xml_value
                      FROM (SELECT r_status.img_name, r_status.flg_default
                              FROM dual) a;
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => r_status.desc_val,
                                 i_item_alt_value     => r_status.val,
                                 i_item_xml_value     => l_xml_value.getclobval(),
                                 i_item_rank          => l_rank,
                                 io_tbl_items_values  => io_tbl_items_values);
                
                    l_rank := l_rank + g_default_rank;
                END LOOP;
            END IF;
        END add_investigation_status;
    
        PROCEDURE add_to_problems
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_TO_PROBLEMS';
            --
            r_assoc_prob pk_edis_types.rec_assoc_prob;
            l_xml_value  xmltype;
            l_rank       PLS_INTEGER;
        BEGIN
            g_error := 'CALL GET_DIAG_STATUS_NEW_LST';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
            get_diag_status_new_lst();
        
            IF l_tbl_assoc_prob IS NOT NULL
               AND l_tbl_assoc_prob.count > 0
            THEN
                l_rank := g_default_rank;
            
                g_error := 'ADD ALL ASSOC PROB';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                FOR i IN l_tbl_assoc_prob.first .. l_tbl_assoc_prob.last
                LOOP
                    r_assoc_prob := l_tbl_assoc_prob(i);
                
                    SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(a.flg_default))
                      INTO l_xml_value
                      FROM (SELECT r_assoc_prob.flg_default
                              FROM dual) a;
                
                    add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                                 i_ds_component       => i_ds_component,
                                 i_internal_name      => i_internal_name,
                                 i_flg_component_type => i_flg_component_type,
                                 i_item_desc          => r_assoc_prob.label,
                                 i_item_alt_value     => r_assoc_prob.data,
                                 i_item_xml_value     => l_xml_value.getclobval(),
                                 i_item_rank          => l_rank,
                                 io_tbl_items_values  => io_tbl_items_values);
                
                    l_rank := l_rank + g_default_rank;
                END LOOP;
            END IF;
        END add_to_problems;
    
        PROCEDURE add_final_type
        (
            i_ds_cmpt_mkt_rel    IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE,
            i_ds_component       IN ds_component.id_ds_component%TYPE,
            i_internal_name      IN ds_component.internal_name%TYPE,
            i_flg_component_type IN ds_component.flg_component_type%TYPE,
            io_tbl_items_values  IN OUT NOCOPY t_table_ds_items_values
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'ADD_FINAL_TYPE';
            --
            r_final_type t_rec_values_domain_mkt;
            l_xml_value  xmltype;
        BEGIN
            g_error := 'LOOP THROUGH ALL DIAGNOSES TYPES';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
            FOR r_final_type IN (SELECT *
                                   FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang          => i_lang,
                                                                                       i_prof          => i_prof,
                                                                                       i_code_dom      => pk_diagnosis.g_epis_diag_type_d,
                                                                                       i_dep_clin_serv => NULL)))
            LOOP
                SELECT xmlelement("ADDITIONAL_INFO", xmlattributes(a.img_name, a.flg_default))
                  INTO l_xml_value
                  FROM (SELECT r_final_type.img_name,
                               decode(i_params.flg_type,
                                      pk_diagnosis.g_diag_type_d,
                                      decode(r_final_type.val,
                                             pk_diagnosis.g_flg_final_type_p,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) flg_default
                          FROM dual) a;
            
                add_new_item(i_ds_cmpt_mkt_rel    => i_ds_cmpt_mkt_rel,
                             i_ds_component       => i_ds_component,
                             i_internal_name      => i_internal_name,
                             i_flg_component_type => i_flg_component_type,
                             i_item_desc          => r_final_type.desc_val,
                             i_item_alt_value     => r_final_type.val,
                             i_item_xml_value     => l_xml_value.getclobval(),
                             i_item_rank          => r_final_type.rank,
                             io_tbl_items_values  => io_tbl_items_values);
            END LOOP;
        END add_final_type;
    BEGIN
        IF i_params.tbl_sections.exists(1)
        THEN
            l_tbl_sections     := i_params.tbl_sections;
            l_tbl_def_events   := t_table_ds_def_events();
            l_tbl_events       := t_table_ds_events();
            l_tbl_items_values := t_table_ds_items_values();
        ELSE
            g_error := 'CALL PK_DYNAMIC_SCREEN.GET_DS_SECTION_COMPLETE_STRUCT';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT pk_dynamic_screen.get_ds_section_complete_struct(i_lang           => i_lang,
                                                                    i_prof           => i_prof,
                                                                    i_component_name => i_params.ds_component_name,
                                                                    i_component_type => i_params.ds_component_type,
                                                                    o_section        => l_tbl_sections,
                                                                    o_def_events     => l_tbl_def_events,
                                                                    o_events         => l_tbl_events,
                                                                    o_items_values   => l_tbl_items_values,
                                                                    o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL HANDLE_TUMORS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT handle_tumors(i_lang                => i_lang,
                                 i_prof                => i_prof,
                                 i_episode             => i_params.id_episode,
                                 i_epis_diagnosis      => i_params.id_epis_diagnosis,
                                 i_epis_diagnosis_hist => i_params.id_epis_diagnosis_hist,
                                 i_flg_call_orig       => g_handle_tumor_sect_data,
                                 i_current_section     => i_params.ds_component_name,
                                 i_tumor_num           => i_params.tumor_num,
                                 io_tab_sections       => l_tbl_sections,
                                 io_tab_def_events     => l_tbl_def_events,
                                 io_tab_events         => l_tbl_events,
                                 io_tab_items_values   => l_tbl_items_values,
                                 o_error               => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF l_tbl_sections IS NOT NULL
           AND l_tbl_sections.count > 0
        THEN
            g_error := 'LOOP THROUGH DS SECTIONS';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            --l_tbl_sections - has all triage form fields
            FOR i IN l_tbl_sections.first .. l_tbl_sections.last
            LOOP
                IF l_tbl_sections(i) IS OF(t_rec_ds_tumor_sections)
                THEN
                    l_tumor_num := treat(l_tbl_sections(i) AS t_rec_ds_tumor_sections).tumor_num;
                    r_section   := l_tbl_sections(i);
                ELSE
                    l_tumor_num := i_params.tumor_num;
                
                    IF l_tumor_num IS NULL
                    THEN
                        r_section := l_tbl_sections(i);
                    ELSE
                        r_section := t_rec_ds_tumor_sections(ds_section     => l_tbl_sections(i),
                                                             tumor_num      => l_tumor_num,
                                                             display_number => l_tumor_num);
                    END IF;
                END IF;
            
                g_error := 'ADD CURRENT SECTION TO FINAL TBL_SECTION';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                l_final_tbl_sections.extend();
                l_final_tbl_sections(l_final_tbl_sections.count) := r_section;
            
                --I only want multichoice fields and only a restrite group of them
                --For instance, multichoice fields based on sys_list come automatically filled 
                --from the pk_dynamic_screen.get_ds_section_complete_struct function call
                IF r_section.flg_data_type = pk_dynamic_screen.c_data_type_fr
                THEN
                    CASE r_section.internal_name
                        WHEN g_dsc_cancer_progn_factors THEN
                            g_error := 'ADD SECTIONS AND ITEMS_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            DECLARE
                                l_tbl_aux table_number_idx;
                            BEGIN
                                add_prognostic_factors(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_ds_cmpt_mkt_rel   => r_section.id_ds_cmpt_mkt_rel,
                                                       i_ds_component      => r_section.id_ds_component,
                                                       i_topography        => i_params.id_topography,
                                                       i_morphology        => CASE
                                                                                  WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                                   l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                                  ELSE
                                                                                   i_params.morphology.morphology
                                                                              END,
                                                       i_tbl_pfactor_val   => l_tbl_aux, --Currently we don't receive the prog factors data
                                                       io_tbl_sections     => l_final_tbl_sections,
                                                       io_tbl_def_events   => l_tbl_def_events,
                                                       io_tbl_items_values => l_tbl_items_values,
                                                       o_item_value        => l_tbl_prog_fact_fld_vals);
                            END;
                        ELSE
                            NULL;
                    END CASE;
                ELSIF r_section.flg_data_type IN (pk_dynamic_screen.c_data_type_ms, pk_dynamic_screen.c_data_type_mm)
                THEN
                    CASE
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_cancer_princ_diag THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_final_type(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type,
                                           io_tbl_items_values  => l_tbl_items_values);
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_general_princ_diag THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            -- only initialize PRINCIPAL_DIAG if the management is defined as principal diagnosis (not RANK)
                            IF l_diag_manage_type = g_manage_principal
                            THEN
                                add_final_type(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                               i_ds_component       => r_section.id_ds_component,
                                               i_internal_name      => r_section.internal_name,
                                               i_flg_component_type => r_section.flg_component_type,
                                               io_tbl_items_values  => l_tbl_items_values);
                            END IF;
                        WHEN r_section.internal_name IN (g_dsc_general_invest_stat, g_dsc_cancer_invest_stat) THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_investigation_status(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                     i_ds_component       => r_section.id_ds_component,
                                                     i_internal_name      => r_section.internal_name,
                                                     i_flg_component_type => r_section.flg_component_type,
                                                     io_tbl_items_values  => l_tbl_items_values);
                        WHEN r_section.internal_name IN (g_dsc_general_add_problem, g_dsc_cancer_add_problem) THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_to_problems(i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                            i_ds_component       => r_section.id_ds_component,
                                            i_internal_name      => r_section.internal_name,
                                            i_flg_component_type => r_section.flg_component_type,
                                            io_tbl_items_values  => l_tbl_items_values);
                        WHEN r_section.internal_name = g_dsc_cancer_topography THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_topography(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type,
                                           i_diagnosis          => i_params.id_diagnosis,
                                           i_topography         => i_params.id_topography,
                                           io_tbl_items_values  => l_tbl_items_values,
                                           o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_staging_basis THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_staging_basis(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_episode            => i_params.id_episode,
                                              i_epis_diagnosis     => i_params.id_epis_diagnosis,
                                              i_flg_edit_mode      => i_params.flg_edit_mode,
                                              i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                              i_ds_component       => r_section.id_ds_component,
                                              i_internal_name      => r_section.internal_name,
                                              i_flg_component_type => r_section.flg_component_type,
                                              i_staging_basis      => i_params.id_staging_basis,
                                              io_tbl_items_values  => l_tbl_items_values,
                                              o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_residual_tum THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_residual_tumor(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                               i_ds_component       => r_section.id_ds_component,
                                               i_internal_name      => r_section.internal_name,
                                               i_flg_component_type => r_section.flg_component_type,
                                               i_residual_tumor     => NULL, --Currently we don't receive this data from the user
                                               io_tbl_items_values  => l_tbl_items_values,
                                               o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_surg_margins THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_surgical_margins(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                 i_ds_component       => r_section.id_ds_component,
                                                 i_internal_name      => r_section.internal_name,
                                                 i_flg_component_type => r_section.flg_component_type,
                                                 i_surgical_margins   => NULL, --Currently we don't receive this data from the user
                                                 io_tbl_items_values  => l_tbl_items_values,
                                                 o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_laterality THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_laterality(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type,
                                           i_topography         => CASE
                                                                       WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                        l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                       ELSE
                                                                        i_params.id_topography
                                                                   END,
                                           i_laterality         => NULL, --Currently we don't receive this data from the user
                                           io_tbl_items_values  => l_tbl_items_values,
                                           o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_histology THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_morphology(i_lang               => i_lang,
                                           i_prof               => i_prof,
                                           i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component       => r_section.id_ds_component,
                                           i_internal_name      => r_section.internal_name,
                                           i_flg_component_type => r_section.flg_component_type,
                                           i_topography         => CASE
                                                                       WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                        l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                       ELSE
                                                                        i_params.id_topography
                                                                   END,
                                           i_basis_diag         => CASE
                                                                       WHEN l_tbl_leafs_default.exists(g_dsc_cancer_basis_diag_ms) THEN
                                                                        l_tbl_leafs_default(g_dsc_cancer_basis_diag_ms).item_value
                                                                       ELSE
                                                                        i_params.id_basis_diag
                                                                   END,
                                           i_morphology         => i_params.morphology.morphology,
                                           io_tbl_items_values  => l_tbl_items_values,
                                           o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_behavior THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_behavior(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                         i_ds_component       => r_section.id_ds_component,
                                         i_internal_name      => r_section.internal_name,
                                         i_flg_component_type => r_section.flg_component_type,
                                         i_morphology         => CASE
                                                                     WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                      l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                     ELSE
                                                                      i_params.morphology.morphology
                                                                 END,
                                         i_behavior           => i_params.morphology.behavior,
                                         io_tbl_items_values  => l_tbl_items_values,
                                         o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_hist_grade THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_histological_grade(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                   i_ds_component       => r_section.id_ds_component,
                                                   i_internal_name      => r_section.internal_name,
                                                   i_flg_component_type => r_section.flg_component_type,
                                                   i_topography         => CASE
                                                                               WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                                l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                               ELSE
                                                                                i_params.id_topography
                                                                           END,
                                                   i_histological_grade => i_params.morphology.grade,
                                                   io_tbl_items_values  => l_tbl_items_values,
                                                   o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_ograd_system THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_other_grading_sys(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                  i_ds_component       => r_section.id_ds_component,
                                                  i_internal_name      => r_section.internal_name,
                                                  i_flg_component_type => r_section.flg_component_type,
                                                  i_topography         => CASE
                                                                              WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                               l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                              ELSE
                                                                               i_params.id_topography
                                                                          END,
                                                  i_morphology         => CASE
                                                                              WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                               l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                              ELSE
                                                                               i_params.morphology.morphology
                                                                          END,
                                                  i_other_grading_sys  => NULL, --Currently we don't receive this data from the user
                                                  io_tbl_items_values  => l_tbl_items_values,
                                                  o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_ostaging_sys THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_other_staging_sys(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                  i_ds_component       => r_section.id_ds_component,
                                                  i_internal_name      => r_section.internal_name,
                                                  i_flg_component_type => r_section.flg_component_type,
                                                  i_topography         => CASE
                                                                              WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                               l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                              ELSE
                                                                               i_params.id_topography
                                                                          END,
                                                  i_other_staging_sys  => NULL, --Currently we don't receive this data from the user
                                                  io_tbl_items_values  => l_tbl_items_values,
                                                  o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_metast_sites THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_metastatic_sites(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                 i_ds_component       => r_section.id_ds_component,
                                                 i_internal_name      => r_section.internal_name,
                                                 i_flg_component_type => r_section.flg_component_type,
                                                 i_tnm_m              => CASE
                                                                             WHEN l_tbl_leafs_default.exists(g_dsc_cancer_tnm_m) THEN
                                                                              l_tbl_leafs_default(g_dsc_cancer_tnm_m).item_value
                                                                             ELSE
                                                                              i_params.tnm.m
                                                                         END,
                                                 i_metastatic_sites   => NULL, --Currently we don't receive this data from the user
                                                 io_tbl_items_values  => l_tbl_items_values,
                                                 o_item_value         => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = g_dsc_cancer_lymp_vasc_inv THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_lymph_vascular_invasion(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_ds_cmpt_mkt_rel         => r_section.id_ds_cmpt_mkt_rel,
                                                        i_ds_component            => r_section.id_ds_component,
                                                        i_internal_name           => r_section.internal_name,
                                                        i_flg_component_type      => r_section.flg_component_type,
                                                        i_topography              => CASE
                                                                                         WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                                          l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                                         ELSE
                                                                                          i_params.id_topography
                                                                                     END,
                                                        i_lymph_vascular_invasion => NULL, --Currently we don't receive this data from the user
                                                        io_tbl_items_values       => l_tbl_items_values,
                                                        o_item_value              => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_acc_emer_sub_analysis THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_sub_analysis(i_lang                       => i_lang,
                                             i_prof                       => i_prof,
                                             i_ds_cmpt_mkt_rel            => r_section.id_ds_cmpt_mkt_rel,
                                             i_ds_component               => r_section.id_ds_component,
                                             i_internal_name              => r_section.internal_name,
                                             i_flg_component_type         => r_section.flg_component_type,
                                             i_diagnosis                  => i_params.id_diagnosis,
                                             i_alert_diagnosis            => i_params.id_alert_diagnosis,
                                             i_sub_analysis               => i_params.id_sub_analysis,
                                             i_flg_edit_mode              => i_params.flg_edit_mode,
                                             i_is_to_fill_with_saved_data => i_params.is_to_fill_with_saved_data,
                                             io_def_events                => l_tbl_def_events,
                                             io_events                    => l_tbl_events,
                                             io_tbl_items_values          => l_tbl_items_values,
                                             o_item_value                 => l_sub_analysis);
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_acc_emer_anat_area THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_anatomical_area(i_lang                       => i_lang,
                                                i_prof                       => i_prof,
                                                i_ds_cmpt_mkt_rel            => r_section.id_ds_cmpt_mkt_rel,
                                                i_ds_component               => r_section.id_ds_component,
                                                i_internal_name              => r_section.internal_name,
                                                i_flg_component_type         => r_section.flg_component_type,
                                                i_diagnosis                  => i_params.id_diagnosis,
                                                i_sub_analysis               => CASE
                                                                                    WHEN i_params.id_epis_diagnosis IS NULL
                                                                                         AND i_params.id_epis_diagnosis_hist IS NULL THEN
                                                                                     nvl(i_params.id_sub_analysis, l_sub_analysis.item_value)
                                                                                    ELSE
                                                                                     i_params.id_sub_analysis
                                                                                END,
                                                i_anatomical_area            => i_params.id_anatomical_area,
                                                i_flg_edit_mode              => i_params.flg_edit_mode,
                                                i_is_to_fill_with_saved_data => i_params.is_to_fill_with_saved_data,
                                                io_tbl_items_values          => l_tbl_items_values,
                                                io_def_events                => l_tbl_def_events,
                                                io_events                    => l_tbl_events,
                                                o_item_value                 => l_anatomical_area);
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_acc_emer_anat_side THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_anatomical_side(i_lang                       => i_lang,
                                                i_prof                       => i_prof,
                                                i_ds_cmpt_mkt_rel            => r_section.id_ds_cmpt_mkt_rel,
                                                i_ds_component               => r_section.id_ds_component,
                                                i_internal_name              => r_section.internal_name,
                                                i_flg_component_type         => r_section.flg_component_type,
                                                i_diagnosis                  => i_params.id_diagnosis,
                                                i_anatomical_area            => CASE
                                                                                    WHEN i_params.id_epis_diagnosis IS NULL
                                                                                         AND i_params.id_epis_diagnosis_hist IS NULL THEN
                                                                                     nvl(i_params.id_anatomical_area,
                                                                                         l_anatomical_area.item_value)
                                                                                    ELSE
                                                                                     i_params.id_anatomical_area
                                                                                END,
                                                i_anatomical_side            => i_params.id_anatomical_side,
                                                i_flg_edit_mode              => i_params.flg_edit_mode,
                                                i_is_to_fill_with_saved_data => i_params.is_to_fill_with_saved_data,
                                                io_def_events                => l_tbl_def_events,
                                                io_events                    => l_tbl_events,
                                                io_tbl_items_values          => l_tbl_items_values,
                                                o_item_value                 => l_anatomical_side);
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_cancer_basis_diag_ms THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_basis_diag(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_ds_cmpt_mkt_rel   => r_section.id_ds_cmpt_mkt_rel,
                                           i_ds_component      => r_section.id_ds_component,
                                           i_internal_name     => r_section.internal_name,
                                           i_basis_diag        => i_params.id_basis_diag,
                                           io_tbl_items_values => l_tbl_items_values,
                                           o_item_value        => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_cancer_tnm_t THEN
                            g_error := 'ADD SECTIONS AND ITEMS_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_tnm_t(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_epis_diagnosis    => i_params.id_epis_diagnosis,
                                      i_epis_diag_hist    => i_params.id_epis_diagnosis_hist,
                                      i_ds_cmpt_mkt_rel   => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component      => r_section.id_ds_component,
                                      i_internal_name     => r_section.internal_name,
                                      i_topography        => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                 ELSE
                                                                  i_params.id_topography
                                                             END,
                                      i_morph             => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                 ELSE
                                                                  i_params.morphology.morphology
                                                             END,
                                      i_staging_basis     => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_staging_basis) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_staging_basis).item_value
                                                                 ELSE
                                                                  i_params.id_staging_basis
                                                             END,
                                      io_tbl_def_events   => l_tbl_def_events,
                                      io_tbl_items_values => l_tbl_items_values,
                                      o_item_value        => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_cancer_tnm_n THEN
                            g_error := 'ADD SECTIONS AND ITEMS_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_tnm_n(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_epis_diagnosis    => i_params.id_epis_diagnosis,
                                      i_epis_diag_hist    => i_params.id_epis_diagnosis_hist,
                                      i_ds_cmpt_mkt_rel   => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component      => r_section.id_ds_component,
                                      i_internal_name     => r_section.internal_name,
                                      i_topography        => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                 ELSE
                                                                  i_params.id_topography
                                                             END,
                                      i_morph             => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                 ELSE
                                                                  i_params.morphology.morphology
                                                             END,
                                      i_staging_basis     => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_staging_basis) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_staging_basis).item_value
                                                                 ELSE
                                                                  i_params.id_staging_basis
                                                             END,
                                      io_tbl_def_events   => l_tbl_def_events,
                                      io_tbl_items_values => l_tbl_items_values,
                                      o_item_value        => l_tbl_leafs_default(r_section.internal_name));
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_cancer_tnm_m THEN
                            g_error := 'ADD SECTIONS AND ITEMS_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_tnm_m(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_epis_diagnosis    => i_params.id_epis_diagnosis,
                                      i_epis_diag_hist    => i_params.id_epis_diagnosis_hist,
                                      i_ds_cmpt_mkt_rel   => r_section.id_ds_cmpt_mkt_rel,
                                      i_ds_component      => r_section.id_ds_component,
                                      i_internal_name     => r_section.internal_name,
                                      i_topography        => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_topography) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_topography).item_value
                                                                 ELSE
                                                                  i_params.id_topography
                                                             END,
                                      i_morph             => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_histology) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_histology).item_value
                                                                 ELSE
                                                                  i_params.morphology.morphology
                                                             END,
                                      i_staging_basis     => CASE
                                                                 WHEN l_tbl_leafs_default.exists(g_dsc_cancer_staging_basis) THEN
                                                                  l_tbl_leafs_default(g_dsc_cancer_staging_basis).item_value
                                                                 ELSE
                                                                  i_params.id_staging_basis
                                                             END,
                                      io_tbl_def_events   => l_tbl_def_events,
                                      io_tbl_items_values => l_tbl_items_values,
                                      o_item_value        => l_tbl_leafs_default(r_section.internal_name));
                        
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_lesion_type THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_lesion_type(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                            i_ds_component       => r_section.id_ds_component,
                                            i_internal_name      => r_section.internal_name,
                                            i_flg_component_type => r_section.flg_component_type,
                                            i_diagnosis          => i_params.id_diagnosis,
                                            i_id_lesion_type     => i_params.id_lesion_type,
                                            io_tbl_items_values  => l_tbl_items_values,
                                            o_item_value         => l_location,
                                            io_def_events        => l_tbl_def_events);
                        
                        WHEN r_section.internal_name = pk_diagnosis_form.g_dsc_lesion_location THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            add_lesion_location(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_ds_cmpt_mkt_rel    => r_section.id_ds_cmpt_mkt_rel,
                                                i_ds_component       => r_section.id_ds_component,
                                                i_internal_name      => r_section.internal_name,
                                                i_flg_component_type => r_section.flg_component_type,
                                                i_diagnosis          => i_params.id_diagnosis,
                                                i_lesion_location    => i_params.id_lesion_location,
                                                io_tbl_items_values  => l_tbl_items_values,
                                                o_item_value         => l_location,
                                                io_def_events        => l_tbl_def_events);
                        ELSE
                            NULL;
                    END CASE;
                ELSIF r_section.flg_data_type = pk_dynamic_screen.c_data_type_n
                THEN
                    CASE r_section.internal_name
                        WHEN pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_num THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            set_um_prim_tumor_size_num(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       io_tbl_sections => l_final_tbl_sections);
                        WHEN pk_diagnosis_form.g_dsc_general_rank THEN
                            g_error := 'ADD ITEM_VALUES FOR: ' || r_section.internal_name;
                            pk_alertlog.log_debug(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => l_func_name);
                            set_rank_max_min_value(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_episode        => i_params.id_episode,
                                                   i_id_epis_diagnosis => i_params.id_epis_diagnosis,
                                                   i_flg_edit_mode     => i_params.flg_edit_mode,
                                                   i_flg_type          => i_params.flg_type,
                                                   i_tbl_index         => l_final_tbl_sections.count,
                                                   io_tbl_sections     => l_final_tbl_sections);
                        ELSE
                            NULL;
                    END CASE;
                END IF;
            
                g_error := 'CALL ADD_DEF_EVENTS';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                IF NOT add_def_events(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_ds_cmpt_mkt_rel => r_section.id_ds_cmpt_mkt_rel,
                                      i_internal_name   => r_section.internal_name,
                                      i_diagnosis_type  => i_params.flg_type, --diagnosis.flg_type: P - Working diag.; D - Final diag.
                                      i_edt_mode        => i_params.flg_edit_mode,
                                      io_tbl_def_events => l_tbl_def_events,
                                      o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF i_params.is_to_fill_with_saved_data = pk_alert_constant.g_yes
                THEN
                    g_error := 'CALL ADD_SAVED_VALUES';
                    pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                    IF NOT add_data_val(i_lang                   => i_lang,
                                        i_prof                   => i_prof,
                                        i_patient                => i_params.id_patient,
                                        i_episode                => i_params.id_episode,
                                        i_ds_cmpt_mkt_rel        => r_section.id_ds_cmpt_mkt_rel,
                                        i_internal_name          => r_section.internal_name,
                                        i_tumor_num              => l_tumor_num,
                                        i_selected_staging_basis => i_params.id_staging_basis,
                                        i_epis_diagnosis         => i_params.id_epis_diagnosis,
                                        i_epis_diagnosis_hist    => i_params.id_epis_diagnosis_hist,
                                        i_flg_edit_mode          => i_params.flg_edit_mode,
                                        io_tbl_sections          => l_final_tbl_sections,
                                        io_tbl_def_events        => l_tbl_def_events,
                                        io_data_values           => l_aux_data_val,
                                        o_error                  => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            END LOOP;
        
            g_error := 'CALL handle_events';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            IF NOT handle_events(i_lang                 => i_lang,
                            i_flg_edit_mode        => i_params.flg_edit_mode,
                            i_tab_sections         => l_final_tbl_sections,
                            i_is_stag_basis_filled => CASE
                                                          WHEN i_params.id_staging_basis IS NULL THEN
                                                           FALSE
                                                          ELSE
                                                           TRUE
                                                      END,
                            io_tab_def_events      => l_tbl_def_events,
                            io_tab_events          => l_tbl_events,
                            o_error                => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF i_params.tbl_sections IS NOT NULL
           AND i_params.tbl_sections.count > 0
        THEN
            --When the origin of this function call is a user action then don't send the events
            l_tbl_events := t_table_ds_events();
        END IF;
    
        o_section    := l_final_tbl_sections;
        o_events     := l_tbl_events;
        o_def_events := l_tbl_def_events;
    
        --o_items_values - This table has all multichoice options for all multichoice fields
        o_items_values := l_tbl_items_values;
    
        o_data_val := l_aux_data_val;
    
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            o_data_val := NULL;
            RETURN FALSE;
    END get_section_data_int;

    -- Parse xml, validate input params and fill missing data of section data xml parameter
    FUNCTION parse_val_fill_sect_param
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT pk_edis_types.rec_diag_section_data_param,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'PARSE_VAL_FILL_SECT_PARAM';
        --
        r_section        t_rec_ds_sections;
        l_tumor_num      PLS_INTEGER := NULL;
        l_prev_tumor_num PLS_INTEGER := NULL;
        --
        l_exception EXCEPTION;
        --
        CURSOR c_parameters IS(
            SELECT a.id_episode,
                   a.id_patient,
                   a.flg_edit_mode,
                   a.id_diagnosis,
                   a.id_alert_diagnosis,
                   (SELECT decode(d.flg_other, pk_alert_constant.g_yes, a.desc_diagnosis, NULL)
                      FROM diagnosis d
                     WHERE d.id_diagnosis = a.id_diagnosis) desc_diagnosis,
                   a.flg_type,
                   nvl(a.flg_reuse_past_diag, pk_alert_constant.g_no) flg_reuse_past_diag,
                   a.id_epis_diagnosis,
                   a.id_epis_diagnosis_hist,
                   a.ds_component_name,
                   a.tumor_num,
                   a.display_number,
                   a.ds_component_type,
                   a.id_topography,
                   a.morphology,
                   a.behavior,
                   a.grade,
                   a.tnm_t,
                   a.tnm_m,
                   a.tnm_n,
                   a.id_staging_basis,
                   a.id_basis_diag,
                   a.id_sub_analysis,
                   a.id_anatomical_area,
                   a.id_anatomical_side,
                   extract(b.params, '/PARAMETERS/DS_COMPONENTS') ds_components
              FROM (SELECT VALUE(p) params
                      FROM TABLE(xmlsequence(extract(xmltype(i_params), '/PARAMETERS'))) p) b,
                   xmltable('/PARAMETERS' passing b.params columns --
                            "ID_EPISODE" NUMBER(24) path '@ID_EPISODE', --
                            "ID_PATIENT" NUMBER(24) path '@ID_PATIENT', --
                            "FLG_EDIT_MODE" VARCHAR2(1 CHAR) path '@FLG_EDIT_MODE', --
                            "ID_DIAGNOSIS" NUMBER(24) path 'DIAGNOSIS/@ID_DIAGNOSIS', --
                            "ID_ALERT_DIAGNOSIS" NUMBER(24) path 'DIAGNOSIS/@ID_ALERT_DIAG', --
                            "DESC_DIAGNOSIS" VARCHAR2(1000 CHAR) path 'DIAGNOSIS/@DESC_DIAGNOSIS', --
                            "FLG_TYPE" VARCHAR2(1 CHAR) path 'DIAGNOSIS/@FLG_TYPE', --
                            "FLG_REUSE_PAST_DIAG" VARCHAR2(1 CHAR) path 'DIAGNOSIS/@FLG_REUSE_PAST_DIAG', --
                            "ID_EPIS_DIAGNOSIS" NUMBER(24) path 'EPIS_DIAGNOSIS/@ID_EPIS_DIAGNOSIS', --
                            "ID_EPIS_DIAGNOSIS_HIST" NUMBER(24) path 'EPIS_DIAGNOSIS/@ID_EPIS_DIAGNOSIS_HIST', --
                            "DS_COMPONENT_NAME" VARCHAR2(200 CHAR) path 'DS_COMPONENT/@INTERNAL_NAME', --
                            "TUMOR_NUM" NUMBER(24) path 'DS_COMPONENT/@TUMOR_NUM', --
                            "DISPLAY_NUMBER" NUMBER(24) path 'DS_COMPONENT/@DISPLAY_NUMBER', --
                            "DS_COMPONENT_TYPE" VARCHAR2(1 CHAR) path 'DS_COMPONENT/@FLG_COMPONENT_TYPE', --
                            "ID_TOPOGRAPHY" NUMBER(24) path 'TOPOGRAPHY/@ID', --
                            "MORPHOLOGY" NUMBER(24) path 'MORPHOLOGY/@HISTOLOGY', --Histology is the name used in the diagnosis form, but we are refering to the id_morphology
                            "BEHAVIOR" NUMBER(24) path 'MORPHOLOGY/@BEHAVIOR', --
                            "GRADE" NUMBER(24) path 'MORPHOLOGY/@GRADE', --
                            "TNM_T" NUMBER(24) path 'TNM/@T', --
                            "TNM_N" NUMBER(24) path 'TNM/@N', --
                            "TNM_M" NUMBER(24) path 'TNM/@M', --
                            "ID_STAGING_BASIS" NUMBER(24) path 'STAGING_BASIS/@ID', --
                            "ID_BASIS_DIAG" NUMBER(24) path 'BASIS_DIAG/@ID', --
                            "ID_SUB_ANALYSIS" NUMBER(24) path 'ACCIDENT_EMERGENCY/@ID_SUB_ANALYSIS', --
                            "ID_ANATOMICAL_AREA" NUMBER(24) path 'ACCIDENT_EMERGENCY/@ID_ANATOMICAL_AREA', --
                            "ID_ANATOMICAL_SIDE" NUMBER(24) path 'ACCIDENT_EMERGENCY/@ID_ANATOMICAL_SIDE' --
                            ) a);
    
        FUNCTION get_table_sections(i_ds_components IN xmltype) RETURN t_table_ds_sections IS
            l_table_sections       t_table_ds_sections;
            l_table_tumor_sections t_table_ds_sections;
        
            FUNCTION get_ds_sections(i_get_tumor_components IN VARCHAR2) RETURN t_table_ds_sections IS
                l_ret t_table_ds_sections;
            BEGIN
                WITH tbl_components AS
                 (SELECT id_ds_cmpt_mkt_rel,
                         id_ds_component_parent,
                         id_ds_component,
                         component_desc,
                         internal_name,
                         tumor_num,
                         display_number,
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
                                  "TUMOR_NUM" NUMBER(24) path '@TUMOR_NUM', --
                                  "DISPLAY_NUMBER" NUMBER(24) path '@DISPLAY_NUMBER', --
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
                SELECT decode(i_get_tumor_components,
                              pk_alert_constant.g_no,
                              t_rec_ds_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
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
                                                component_values       => NULL),
                              t_rec_ds_tumor_sections(id_ds_cmpt_mkt_rel     => a.id_ds_cmpt_mkt_rel,
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
                                                      component_values       => NULL,
                                                      tumor_num              => a.tumor_num,
                                                      display_number         => a.display_number))
                  BULK COLLECT
                  INTO l_ret
                  FROM tbl_components a
                 WHERE ((i_get_tumor_components = pk_alert_constant.g_no AND a.tumor_num IS NULL AND
                       a.display_number IS NULL) OR (i_get_tumor_components = pk_alert_constant.g_yes AND
                       (a.tumor_num IS NOT NULL OR a.display_number IS NOT NULL)));
            
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
                l_table_sections       := get_ds_sections(i_get_tumor_components => pk_alert_constant.g_no);
                l_table_tumor_sections := get_ds_sections(i_get_tumor_components => pk_alert_constant.g_yes);
            
                l_table_sections := l_table_sections MULTISET UNION ALL l_table_tumor_sections;
            ELSE
                l_table_sections := t_table_ds_sections();
            END IF;
        
            add_child_sections(io_tbl_sections => l_table_sections);
        
            RETURN l_table_sections;
        END get_table_sections;
        --
        FUNCTION get_parameters RETURN pk_edis_types.rec_diag_section_data_param IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_PARAMETERS';
            --
            r_parameter   c_parameters%ROWTYPE;
            l_tbl_section t_table_ds_sections;
            l_ret         pk_edis_types.rec_diag_section_data_param;
        BEGIN
            IF i_params IS NOT NULL
            THEN
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error := 'OPEN INPUT PARAMETERS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                OPEN c_parameters;
            
                g_error := 'FETCH DATA';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                FETCH c_parameters
                    INTO r_parameter;
            
                IF c_parameters%NOTFOUND
                THEN
                    g_error := 'MISSING INPUT PARAMETERS';
                    pk_alertlog.log_error(object_name     => g_package,
                                          sub_object_name => l_inner_func_name,
                                          text            => g_error);
                    RAISE l_exception;
                END IF;
            
                g_error := 'CLOSE CURSOR';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                CLOSE c_parameters;
            
                g_error := 'CALL GET_TABLE_SECTIONS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                l_tbl_section := get_table_sections(i_ds_components => r_parameter.ds_components);
            
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error := 'FILL RETURN VALUE';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                l_ret.id_patient    := r_parameter.id_patient;
                l_ret.id_episode    := r_parameter.id_episode;
                l_ret.flg_edit_mode := r_parameter.flg_edit_mode;
            
                IF l_tbl_section.exists(1)
                THEN
                    l_ret.is_to_fill_with_saved_data := pk_alert_constant.g_no;
                ELSIF r_parameter.id_epis_diagnosis IS NULL
                      AND pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_concept_type => NULL,
                                                          i_diagnosis    => r_parameter.id_diagnosis) =
                      pk_diagnosis_core.g_diag_type_acc_emerg
                THEN
                    l_ret.is_to_fill_with_saved_data := pk_alert_constant.g_no;
                ELSE
                    l_ret.is_to_fill_with_saved_data := pk_alert_constant.g_yes;
                END IF;
            
                l_ret.id_diagnosis           := r_parameter.id_diagnosis;
                l_ret.id_alert_diagnosis     := r_parameter.id_alert_diagnosis;
                l_ret.desc_diagnosis         := r_parameter.desc_diagnosis;
                l_ret.flg_type               := r_parameter.flg_type;
                l_ret.flg_reuse_past_diag    := r_parameter.flg_reuse_past_diag;
                l_ret.id_epis_diagnosis      := r_parameter.id_epis_diagnosis;
                l_ret.id_epis_diagnosis_hist := r_parameter.id_epis_diagnosis_hist;
                l_ret.ds_component_name      := r_parameter.ds_component_name;
                l_ret.tumor_num              := r_parameter.tumor_num;
                l_ret.display_number         := r_parameter.display_number;
                l_ret.ds_component_type      := r_parameter.ds_component_type;
                l_ret.id_topography          := r_parameter.id_topography;
                l_ret.morphology.morphology  := r_parameter.morphology;
                l_ret.morphology.behavior    := r_parameter.behavior;
                l_ret.morphology.grade       := r_parameter.grade;
                l_ret.tnm.t                  := r_parameter.tnm_t;
                l_ret.tnm.m                  := r_parameter.tnm_m;
                l_ret.tnm.n                  := r_parameter.tnm_n;
                l_ret.id_staging_basis       := r_parameter.id_staging_basis;
                l_ret.id_basis_diag          := r_parameter.id_basis_diag;
                l_ret.id_sub_analysis        := r_parameter.id_sub_analysis;
                l_ret.id_anatomical_area     := r_parameter.id_anatomical_area;
                l_ret.id_anatomical_side     := r_parameter.id_anatomical_side;
                l_ret.tbl_sections           := l_tbl_section;
            END IF;
        
            RETURN l_ret;
        END get_parameters;
        --
        PROCEDURE fill_params_with_saved_data
        (
            i_tumor_num IN PLS_INTEGER,
            io_params   IN OUT pk_edis_types.rec_diag_section_data_param
        ) IS
            l_inner_proc_name CONSTANT VARCHAR2(30) := 'FILL_PARAMS_WITH_SAVED_DATA';
            --
            l_curr_area_ed         epis_diagnosis.id_epis_diagnosis%TYPE;
            l_curr_area_ed_status  epis_diagnosis.flg_status%TYPE;
            l_other_area_ed        epis_diagnosis.id_epis_diagnosis%TYPE;
            l_other_area_ed_status epis_diagnosis.flg_status%TYPE;
        BEGIN
            --verify if id_diagnosis/id_alert_diagnosis has been already registered in the current patient
            --if so, get the most recent epis_diagnosis id and fill the form with it's data
            IF io_params.id_epis_diagnosis IS NULL
               AND io_params.id_epis_diagnosis_hist IS NULL
               AND pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                   i_prof         => i_prof,
                                                   i_concept_type => NULL,
                                                   i_diagnosis    => io_params.id_diagnosis) !=
               pk_diagnosis_core.g_diag_type_acc_emerg
            THEN
                BEGIN
                    SELECT ed.id_epis_diagnosis, ed.flg_status
                      INTO l_curr_area_ed, l_curr_area_ed_status
                      FROM epis_diagnosis ed
                     WHERE ed.id_epis_diagnosis =
                           pk_diagnosis_core.get_existing_epis_diag(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_episode   => io_params.id_episode,
                                                                    i_diagnosis => io_params.id_diagnosis,
                                                                    i_desc_diag => io_params.desc_diagnosis,
                                                                    i_flg_type  => io_params.flg_type);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_curr_area_ed        := NULL;
                        l_curr_area_ed_status := NULL;
                END;
            
                IF l_curr_area_ed IS NULL
                   OR l_curr_area_ed_status = pk_diagnosis.g_ed_flg_status_ca
                THEN
                    --Diagnosis wasn't registered in the current area, verify if it was in the other (working or final diagnosis area)
                    BEGIN
                        SELECT ed.id_epis_diagnosis, ed.flg_status
                          INTO l_other_area_ed, l_other_area_ed_status
                          FROM epis_diagnosis ed
                         WHERE ed.id_epis_diagnosis =
                               pk_diagnosis_core.get_existing_epis_diag(i_lang      => i_lang,
                                                                        i_prof      => i_prof,
                                                                        i_episode   => io_params.id_episode,
                                                                        i_diagnosis => io_params.id_diagnosis,
                                                                        i_desc_diag => io_params.desc_diagnosis,
                                                                        i_flg_type  => CASE io_params.flg_type
                                                                                           WHEN pk_diagnosis.g_diag_type_d THEN
                                                                                            pk_diagnosis.g_diag_type_p
                                                                                           ELSE
                                                                                            pk_diagnosis.g_diag_type_d
                                                                                       END);
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_other_area_ed        := NULL;
                            l_other_area_ed_status := NULL;
                    END;
                END IF;
            
                IF l_curr_area_ed_status != pk_diagnosis.g_ed_flg_status_ca
                THEN
                    io_params.id_epis_diagnosis := l_curr_area_ed;
                ELSIF l_other_area_ed_status != pk_diagnosis.g_ed_flg_status_ca
                THEN
                    io_params.id_epis_diagnosis := l_other_area_ed;
                END IF;
            
                IF io_params.flg_edit_mode = pk_diagnosis_core.g_diag_create_mode
                   AND io_params.id_epis_diagnosis IS NOT NULL
                THEN
                    --The user is trying to create a diagnosis that already exists in the episode and in the same area (working/final diagnosis)
                    io_params.flg_edit_mode := pk_diagnosis_core.g_diag_edit_mode_edit;
                END IF;
            
                --It was already checked in CHECK_DIAG_ALREADY_REG function if the diagnosis is a cancer diag, so the value of flg_reuse_past_diag takes this into consideration
                IF io_params.flg_reuse_past_diag = pk_alert_constant.g_yes --Means that is a cancer diag and the user wants to import the last registered data
                   AND io_params.id_epis_diagnosis IS NULL
                THEN
                    g_error := 'CALL PK_DIAGNOSIS_FORM.get_cancer_diag_already_reg';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    io_params.id_epis_diagnosis := pk_diagnosis_form.get_cancer_diag_already_reg(i_lang            => i_lang,
                                                                                                 i_prof            => i_prof,
                                                                                                 i_patient         => io_params.id_patient,
                                                                                                 i_episode         => io_params.id_episode,
                                                                                                 i_diagnosis       => io_params.id_diagnosis,
                                                                                                 i_alert_diagnosis => io_params.id_alert_diagnosis);
                ELSIF io_params.flg_edit_mode = pk_diagnosis_core.g_diag_create_mode
                      AND io_params.flg_reuse_past_diag = pk_alert_constant.g_no
                      AND io_params.id_epis_diagnosis IS NULL
                      AND pk_diagnosis_core.check_diag_cancer(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_concept_type => NULL,
                                                              i_diagnosis    => io_params.id_diagnosis) =
                      pk_alert_constant.g_yes
                THEN
                    --After the first call to the function GET_SECTION_DATA the parameter FLG_REUSE_PAST_DIAG value is always 'N' 
                    --so we must verify if it was already registered to change the FLG_EDIT_MODE. 
                    g_error := 'CALL PK_DIAGNOSIS_FORM.GET_CANCER_DIAG_ALREADY_REG';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    IF pk_diagnosis_form.get_cancer_diag_already_reg(i_lang            => i_lang,
                                                                     i_prof            => i_prof,
                                                                     i_patient         => io_params.id_patient,
                                                                     i_episode         => io_params.id_episode,
                                                                     i_diagnosis       => io_params.id_diagnosis,
                                                                     i_alert_diagnosis => io_params.id_alert_diagnosis) IS NOT NULL
                    THEN
                        io_params.flg_edit_mode := pk_diagnosis_core.g_diag_edit_mode_retreatment;
                    END IF;
                END IF;
            END IF;
        
            IF io_params.is_to_fill_with_saved_data = pk_alert_constant.g_yes
               AND (io_params.id_epis_diagnosis IS NOT NULL OR io_params.id_epis_diagnosis_hist IS NOT NULL)
            THEN
                g_error := 'FILL OBJECTS WITH SAVED DATA BY CALLING GET_EPIS_DIAG_REC';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_inner_proc_name);
                IF NOT get_epis_diag_rec(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_episode             => io_params.id_episode,
                                         i_epis_diagnosis      => io_params.id_epis_diagnosis,
                                         i_epis_diagnosis_hist => io_params.id_epis_diagnosis_hist,
                                         i_flg_edit_mode       => io_params.flg_edit_mode,
                                         o_error               => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                IF g_svd_val_rec_epis_diag.flg_status = pk_diagnosis.g_ed_flg_status_ca
                THEN
                    g_svd_val_rec_epis_diag.flg_status  := pk_diagnosis.g_ed_flg_status_d;
                    g_svd_val_rec_epis_diag.desc_status := pk_sysdomain.get_domain(i_code_dom => pk_diagnosis.g_epis_diag_status,
                                                                                   i_val      => g_svd_val_rec_epis_diag.flg_status,
                                                                                   i_lang     => i_lang);
                END IF;
            
                IF io_params.id_diagnosis IS NULL
                THEN
                    io_params.id_diagnosis := g_svd_val_rec_epis_diag.id_diagnosis;
                END IF;
            
                IF io_params.id_alert_diagnosis IS NULL
                THEN
                    io_params.id_alert_diagnosis := g_svd_val_rec_epis_diag.id_alert_diagnosis;
                END IF;
            
                IF io_params.flg_type IS NULL
                THEN
                    io_params.flg_type := g_svd_val_rec_epis_diag.flg_type;
                END IF;
            
                IF io_params.flg_type != pk_diagnosis.g_diag_type_d
                THEN
                    g_svd_val_rec_epis_diag.flg_final_type  := NULL;
                    g_svd_val_rec_epis_diag.desc_final_type := NULL;
                END IF;
            
                IF io_params.tnm.t IS NULL
                THEN
                    io_params.tnm.t := g_svd_val_rec_epis_stag.id_tnm_t;
                END IF;
            
                IF io_params.tnm.m IS NULL
                THEN
                    io_params.tnm.m := g_svd_val_rec_epis_stag.id_tnm_m;
                END IF;
            
                IF io_params.tnm.n IS NULL
                THEN
                    io_params.tnm.n := g_svd_val_rec_epis_stag.id_tnm_n;
                END IF;
            
                IF io_params.id_staging_basis IS NULL
                THEN
                    io_params.id_staging_basis := g_svd_val_rec_epis_stag.id_staging_basis;
                END IF;
            
                IF io_params.id_basis_diag IS NULL
                THEN
                    io_params.id_basis_diag := g_svd_val_rec_epis_diag.id_diag_basis;
                END IF;
            
                IF i_tumor_num IS NOT NULL
                   AND g_svd_val_tab_epis_tumors.exists(i_tumor_num)
                THEN
                    IF io_params.id_topography IS NULL
                    THEN
                        io_params.id_topography := g_svd_val_tab_epis_tumors(i_tumor_num).id_topography;
                    END IF;
                
                    IF io_params.morphology.morphology IS NULL
                    THEN
                        io_params.morphology.morphology := g_svd_val_tab_epis_tumors(i_tumor_num).id_morphology;
                    END IF;
                
                    IF io_params.morphology.behavior IS NULL
                    THEN
                        io_params.morphology.behavior := g_svd_val_tab_epis_tumors(i_tumor_num).id_behavior;
                    END IF;
                
                    IF io_params.morphology.grade IS NULL
                    THEN
                        io_params.morphology.grade := g_svd_val_tab_epis_tumors(i_tumor_num).id_histological_grade;
                    END IF;
                END IF;
            
                IF io_params.id_sub_analysis IS NULL
                   AND g_svd_val_rec_epis_diag.id_sub_analysis IS NOT NULL
                THEN
                    io_params.id_sub_analysis := g_svd_val_rec_epis_diag.id_sub_analysis;
                END IF;
            
                IF io_params.id_anatomical_area IS NULL
                   AND g_svd_val_rec_epis_diag.id_anatomical_area IS NOT NULL
                THEN
                    io_params.id_anatomical_area := g_svd_val_rec_epis_diag.id_anatomical_area;
                END IF;
            
                IF io_params.id_anatomical_side IS NULL
                   AND g_svd_val_rec_epis_diag.id_anatomical_side IS NOT NULL
                THEN
                    io_params.id_anatomical_side := g_svd_val_rec_epis_diag.id_anatomical_side;
                END IF;
            END IF;
        END fill_params_with_saved_data;
    BEGIN
        g_error := 'EXTRACT PARAMETERS FROM I_PARAMS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        o_params := get_parameters();
    
        g_error := 'PARAMETER VALIDATION';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF (o_params.id_diagnosis IS NOT NULL AND o_params.flg_type IS NULL)
           OR (o_params.id_diagnosis IS NULL AND o_params.flg_type IS NOT NULL)
        THEN
            raise_application_error(-20010,
                                    'When ID_DIAGNOSIS or FLG_TYPE is not null the other field must also be sent.');
        ELSIF o_params.id_diagnosis IS NULL
              AND o_params.flg_type IS NULL
              AND o_params.id_epis_diagnosis IS NULL
              AND (o_params.tbl_sections IS NULL OR o_params.tbl_sections.count = 0)
        THEN
            raise_application_error(-20012,
                                    'All of the following fields ID_DIAGNOSIS, FLG_TYPE, ID_EPIS_DIAGNOSIS and TBL_SECTIONS are empty.');
        END IF;
    
        --I need to be sure that in the current call we are going only to treat one tumor, for intance, because of the input parameter with the selected topography
        --If the patient has multiple tumors then a call to this function must be made for each tumor 
        IF o_params.tbl_sections.exists(1)
        THEN
            FOR i IN o_params.tbl_sections.first .. o_params.tbl_sections.last
            LOOP
                r_section := o_params.tbl_sections(i);
            
                IF r_section IS OF(t_rec_ds_tumor_sections)
                THEN
                    l_tumor_num := treat(r_section AS t_rec_ds_tumor_sections).tumor_num;
                END IF;
            
                IF l_prev_tumor_num IS NULL
                   AND l_tumor_num IS NOT NULL
                THEN
                    l_prev_tumor_num := l_tumor_num;
                ELSIF l_prev_tumor_num IS NOT NULL
                      AND l_tumor_num IS NOT NULL
                      AND l_prev_tumor_num != l_tumor_num
                THEN
                    raise_application_error(-20013, 'Only one tumor section can be treated at a time.');
                END IF;
            END LOOP;
        END IF;
    
        l_tumor_num := o_params.tumor_num;
    
        IF l_prev_tumor_num IS NOT NULL
           AND l_tumor_num IS NOT NULL
           AND l_prev_tumor_num != l_tumor_num
        THEN
            raise_application_error(-20014, 'Only one tumor section can be treated at a time.');
        END IF;
    
        IF l_tumor_num IS NULL
        THEN
            l_tumor_num := 1;
        END IF;
    
        g_error := 'FILL PARAMETERS WITH SAVED DATA';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        fill_params_with_saved_data(i_tumor_num => l_tumor_num, io_params => o_params);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END parse_val_fill_sect_param;

    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_params       IN pk_edis_types.rec_diag_section_data_param,
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
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT get_section_data_int(i_lang         => i_lang,
                                    i_prof         => i_prof,
                                    i_params       => i_params,
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_section_data_db;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *          <PARAMETERS ID_EPISODE="" ID_PATIENT="" FLG_EDIT_MODE="">
    *              <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_TYPE="" FLG_REUSE_PAST_DIAG="" /> <!-- This information is available just when creating a new diagnosis -->
    *              <!-- FLG_REUSE_PAST_DIAG - if is to reuse epis_diagnosis data from a past diagnosis -->
    *              <!-- ID_EPIS_DIAGNOSIS is only needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *                   ID_EPIS_DIAGNOSIS_HIST is only needed for cancer diagnosis when editing a past staging diagnosis  -->
    *              <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" /> <!-- This information is available just when editing a existing diagnosis -->
    *              <DS_COMPONENT INTERNAL_NAME="" FLG_COMPONENT_TYPE="" /> <!-- Used to get information of form sections, etc...; NAME = I_COMPONENT_NAME; TYPE = I_COMPONENT_TYPE -->
    *              <TOPOGRAPHY ID="" /> <!-- Selected user option -->
    *              <MORPHOLOGY HISTOLOGY="" BEHAVIOR="" GRADE="" />  <!-- Selected user option -->
    *              <TNM T="" N="" M="" />  <!-- Selected user option -->
    *              <STAGING_BASIS ID="" />  <!-- Selected user option -->
    *              <BASIS_DIAG ID="" /> <!-- Selected user option -->
    *              <DS_COMPONENTS> 
    *                  <!-- Used to get information of MS, MM, FR fields that depend on user selection -->
    *                  <!-- Set of fields whose values we want to get -->
    *                  <DS_COMPONENT ID_DS_CMPT_MKT_REL=""  ID_DS_COMPONENT_PARENT="" ID_DS_COMPONENT="" COMPONENT_DESC="" INTERNAL_NAME="" FLG_COMPONENT_TYPE="" FLG_DATA_TYPE="" SLG_INTERNAL_NAME="" RANK="" />
    *              </DS_COMPONENTS>
    *          </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data_db
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
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
        l_parameter pk_edis_types.rec_diag_section_data_param;
        --   
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PARSE_VAL_FILL_SECT_PARAM';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT parse_val_fill_sect_param(i_lang   => i_lang,
                                         i_prof   => i_prof,
                                         i_params => i_params,
                                         o_params => l_parameter,
                                         o_error  => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL GET_SECTION_DATA_DB';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT get_section_data_db(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_params       => l_parameter,
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_section_data_db;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_section                   Section cursor
    * @param   o_def_events                Default events cursor
    * @param   o_events                    Events cursor
    * @param   o_items_values              Item values for multichoices of single choice
    * @param   o_data_val                  Default data or previous saved data
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *          <PARAMETERS ID_EPISODE="" ID_PATIENT="" FLG_EDIT_MODE="">
    *              <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_TYPE="" FLG_REUSE_PAST_DIAG="" /> <!-- This information is available just when creating a new diagnosis -->
    *              <!-- FLG_REUSE_PAST_DIAG - if is to reuse epis_diagnosis data from a past diagnosis -->
    *              <!-- ID_EPIS_DIAGNOSIS is only needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *                   ID_EPIS_DIAGNOSIS_HIST is only needed for cancer diagnosis when editing a past staging diagnosis  -->
    *              <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" /> <!-- This information is available just when editing a existing diagnosis -->
    *              <DS_COMPONENT INTERNAL_NAME="" FLG_COMPONENT_TYPE="" /> <!-- Used to get information of form sections, etc...; NAME = I_COMPONENT_NAME; TYPE = I_COMPONENT_TYPE -->
    *              <TOPOGRAPHY ID="" /> <!-- Selected user option -->
    *              <MORPHOLOGY HISTOLOGY="" BEHAVIOR="" GRADE="" />  <!-- Selected user option -->
    *              <TNM T="" N="" M="" />  <!-- Selected user option -->
    *              <STAGING_BASIS ID="" />  <!-- Selected user option -->
    *              <BASIS_DIAG ID="" /> <!-- Selected user option -->
    *              <DS_COMPONENTS> 
    *                  <!-- Used to get information of MS, MM, FR fields that depend on user selection -->
    *                  <!-- Set of fields whose values we want to get -->
    *                  <DS_COMPONENT ID_DS_CMPT_MKT_REL=""  ID_DS_COMPONENT_PARENT="" ID_DS_COMPONENT="" COMPONENT_DESC="" INTERNAL_NAME="" FLG_COMPONENT_TYPE="" FLG_DATA_TYPE="" SLG_INTERNAL_NAME="" RANK="" />
    *              </DS_COMPONENTS>
    *          </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
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
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT get_section_data_db(i_lang         => i_lang,
                                   i_prof         => i_prof,
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
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
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
                   max_value,
                   node_name,
                   tumor_num,
                   display_number
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
                           b.max_value,
                           --Remove prefix
                           REPLACE(REPLACE(REPLACE(b.internal_name, 'ACC_EMER_DIAGNOSES_', ''), 'CANCER_DIAGNOSES_', ''),
                                   'GENERAL_DIAGNOSES_',
                                   '') node_name,
                           --tumor fields
                           b.tumor_num,
                           b.display_number
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
                                   c.max_value,
                                   NULL                     tumor_num,
                                   NULL                     display_number
                              FROM TABLE(l_tbl_section) c
                             WHERE VALUE(c) IS NOT OF TYPE(t_rec_ds_tumor_sections)
                            UNION ALL
                            SELECT c.id_ds_cmpt_mkt_rel,
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
                                   c.max_value,
                                   treat                   (VALUE(c) AS t_rec_ds_tumor_sections).tumor_num                    tumor_num,
                                   treat                   (VALUE(c) AS t_rec_ds_tumor_sections).display_number                    display_number
                              FROM TABLE(l_tbl_section) c
                             WHERE VALUE(c) IS OF TYPE(t_rec_ds_tumor_sections)) b) a
             ORDER BY a.rank;
    
        g_error := 'OPEN O_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_events FOR
            SELECT *
              FROM TABLE(l_tbl_events);
    
        g_error := 'OPEN O_DEF_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_def_events FOR
            SELECT *
              FROM TABLE(l_tbl_def_events);
    
        g_error := 'OPEN O_ITEMS_VALUES';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
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
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(i_cursor => o_section);
            pk_types.open_my_cursor(i_cursor => o_def_events);
            pk_types.open_my_cursor(i_cursor => o_events);
            pk_types.open_my_cursor(i_cursor => o_items_values);
            o_data_val := NULL;
            RETURN FALSE;
    END get_section_data;

    /**
    * Get dynamic screen sections and events list
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_stage_info                Stage information
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS>
    *   <CHARACTERIZATION NUM_PRIM_TUMORS_MS_YN="" NUM_PRIM_TUMORS_NUM="" />
    *   <STAGING STAGING_BASIS="" TNM_T="" CODE_STAGE_T="" TNM_N="" CODE_STAGE_N="" TNM_M="" CODE_STAGE_M="">
    *     <PROG_FACTORS>
    *       <PROG_FACTOR ID_LABEL="" ID_VALUE="" />
    *     </PROG_FACTORS>
    *   </STAGING>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   17-01-2012
    */
    FUNCTION get_calculate_fields_values
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_params     IN CLOB,
        o_stage_info OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_CALCULATE_FIELDS_VALUES';
        --
        l_code_tnm_considered_crit CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M032'; --TNM Considered criteria
        l_separator                CONSTANT VARCHAR2(3) := ' - ';
        --
        l_staging_group           pk_edis_types.rec_diag_staging_group;
        l_desc_tnm                pk_translation.t_desc_translation;
        l_desc_stage_info         pk_translation.t_desc_translation;
        l_flg_mult_tumors         epis_diagnosis.flg_mult_tumors%TYPE;
        l_num_prim_tumors         epis_diagnosis.num_primary_tumors%TYPE;
        l_pfactor_considered_crit VARCHAR2(1000 CHAR);
        --
        l_params pk_edis_types.rec_in_diag_staging;
        --
        FUNCTION get_parameters RETURN pk_edis_types.rec_in_diag_staging IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_PARAMETERS';
            --
            CURSOR c_diag_staging IS(
                SELECT a.id_staging_basis,
                       a.tnm_t,
                       a.code_stage_t,
                       a.tnm_n,
                       a.code_stage_n,
                       a.tnm_m,
                       a.code_stage_m,
                       a.flg_mult_tumors,
                       a.num_primary_tumors,
                       extract(b.diag_staging, 'PARAMETERS/STAGING/PROG_FACTORS') prog_factors
                  FROM (SELECT VALUE(p) diag_staging
                          FROM TABLE(xmlsequence(extract(xmltype(i_params), '/PARAMETERS'))) p) b,
                       xmltable('/PARAMETERS' passing b.diag_staging columns --
                                "ID_STAGING_BASIS" NUMBER(24) path 'STAGING/@STAGING_BASIS', --
                                "TNM_T" NUMBER(24) path 'STAGING/@TNM_T', --
                                "CODE_STAGE_T" VARCHAR2(100 CHAR) path 'STAGING/@CODE_STAGE_T', --
                                "TNM_N" NUMBER(24) path 'STAGING/@TNM_N', --
                                "CODE_STAGE_N" VARCHAR2(100 CHAR) path 'STAGING/@CODE_STAGE_N', --
                                "TNM_M" NUMBER(24) path 'STAGING/@TNM_M', --
                                "CODE_STAGE_M" VARCHAR2(100 CHAR) path 'STAGING/@CODE_STAGE_M', --
                                "FLG_MULT_TUMORS" VARCHAR2(1 CHAR) path 'CHARACTERIZATION/@NUM_PRIM_TUMORS_MS_YN', --
                                "NUM_PRIMARY_TUMORS" NUMBER(6) path 'CHARACTERIZATION/@NUM_PRIM_TUMORS_NUM' --
                                ) a);
        
            r_diag_staging c_diag_staging%ROWTYPE;
        
            CURSOR c_prog_factors(i_prog_factors IN xmltype) IS(
                SELECT a.id_field, a.id_value
                  FROM (SELECT VALUE(p) prog_factors
                          FROM TABLE(xmlsequence(extract(i_prog_factors, '/PROG_FACTORS/PROG_FACTOR'))) p) b,
                       xmltable('/PROG_FACTOR' passing b.prog_factors columns --
                                "ID_FIELD" NUMBER(24) path '@ID_LABEL', --
                                "ID_VALUE" NUMBER(24) path '@ID_VALUE') a);
        
            r_prog_factor c_prog_factors%ROWTYPE;
        
            l_diag_staging     pk_edis_types.rec_in_diag_staging;
            l_tbl_prog_factors pk_edis_types.table_in_prog_factor;
            l_prog_factor      pk_edis_types.rec_in_prog_factor;
        BEGIN
            g_sysdate_tstz := current_timestamp;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
            g_error := 'OPEN C_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            OPEN c_diag_staging;
        
            g_error := 'FETCH DATA INTO R_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            FETCH c_diag_staging
                INTO r_diag_staging;
        
            g_error := 'CLOSE CURSOR C_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            CLOSE c_diag_staging;
        
            l_flg_mult_tumors := r_diag_staging.flg_mult_tumors;
            l_num_prim_tumors := r_diag_staging.num_primary_tumors;
        
            g_error := 'SET STAGING PARAMS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            l_diag_staging.id_staging_basis := pk_diagnosis_core.get_term_diagnosis_id(r_diag_staging.id_staging_basis,
                                                                                       i_prof.institution,
                                                                                       i_prof.software);
            l_diag_staging.tnm.t            := pk_diagnosis_core.get_term_diagnosis_id(r_diag_staging.tnm_t,
                                                                                       i_prof.institution,
                                                                                       i_prof.software);
            l_diag_staging.tnm.code_stage_t := r_diag_staging.code_stage_t;
            l_diag_staging.tnm.n            := pk_diagnosis_core.get_term_diagnosis_id(r_diag_staging.tnm_n,
                                                                                       i_prof.institution,
                                                                                       i_prof.software);
            l_diag_staging.tnm.code_stage_n := r_diag_staging.code_stage_n;
            l_diag_staging.tnm.m            := pk_diagnosis_core.get_term_diagnosis_id(r_diag_staging.tnm_m,
                                                                                       i_prof.institution,
                                                                                       i_prof.software);
            l_diag_staging.tnm.code_stage_m := r_diag_staging.code_stage_m;
        
            l_tbl_prog_factors := pk_edis_types.table_in_prog_factor();
        
            g_error := 'SET PROG_FACTORS PARAMS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            FOR r_prog_factor IN c_prog_factors(i_prog_factors => r_diag_staging.prog_factors)
            LOOP
                l_prog_factor.id_field := pk_diagnosis_core.get_term_diagnosis_id(r_prog_factor.id_field,
                                                                                  i_prof.institution,
                                                                                  i_prof.software);
                l_prog_factor.id_value := pk_diagnosis_core.get_term_diagnosis_id(r_prog_factor.id_value,
                                                                                  i_prof.institution,
                                                                                  i_prof.software);
            
                IF l_prog_factor.id_value IS NOT NULL
                THEN
                    l_pfactor_considered_crit := l_pfactor_considered_crit || '; ' ||
                                                 pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                            i_prof               => i_prof,
                                                                            i_id_alert_diagnosis => r_prog_factor.id_field, --ATTENTION: This must be the term of the label shown to the user
                                                                            i_code               => NULL,
                                                                            i_flg_other          => pk_alert_constant.g_no,
                                                                            i_flg_std_diag       => pk_alert_constant.g_yes);
                END IF;
            
                l_tbl_prog_factors.extend;
                l_tbl_prog_factors(l_tbl_prog_factors.count) := l_prog_factor;
            END LOOP;
        
            l_diag_staging.tbl_prog_factors := l_tbl_prog_factors;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
            RETURN l_diag_staging;
        END get_parameters;
    BEGIN
        g_error := 'PARSE XML TO OBJECT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_params := get_parameters();
    
        g_error := 'GET STAGE GROUP';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_staging_group := pk_diagnosis_core.get_desc_staging_group(i_lang                      => i_lang,
                                                                    i_prof                      => i_prof,
                                                                    i_pfactors                  => l_params.tbl_prog_factors,
                                                                    i_tnm                       => l_params.tnm,
                                                                    i_show_sgroup_not_avail_msg => TRUE);
    
        g_error := 'GET TNM';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_desc_tnm := pk_diagnosis_core.get_desc_tnm(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_tnm             => l_params.tnm,
                                                     i_flg_mult_tumors => l_flg_mult_tumors,
                                                     i_num_prim_tumors => l_num_prim_tumors);
    
        g_error := 'GET STAGE INFO';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_desc_stage_info := pk_diagnosis_core.get_desc_staging_info(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_staging_basis      => l_params.id_staging_basis,
                                                                     i_desc_tnm           => l_desc_tnm,
                                                                     i_desc_staging_group => NULL);
    
        OPEN o_stage_info FOR
            SELECT l_staging_group.id_staging_group id_staging_group,
                   nvl2(l_staging_group.code_staging_group,
                        l_staging_group.code_staging_group || l_separator ||
                        pk_message.get_message(i_lang, i_prof, l_code_tnm_considered_crit) || l_pfactor_considered_crit,
                        l_staging_group.desc_staging_group || l_separator ||
                        pk_message.get_message(i_lang, i_prof, l_code_tnm_considered_crit) || l_pfactor_considered_crit) desc_stage_group,
                   l_desc_stage_info desc_stage
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            pk_types.open_cursor_if_closed(o_stage_info);
            RETURN FALSE;
    END get_calculate_fields_values;

    /**
    * Get the resulting ICDO diagnosis description to be placed in the form
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_diag_icdo                 Diagnosis description
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS BEHAVIOR="" HISTOLOGY="" TOPOGRAPHY="" HISTOLOGIC_GRADE=""/>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_calculate_diag_icdo
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_params    IN CLOB,
        o_diag_icdo OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_CALCULATE_DIAG_ICDO';
        --
        TYPE t_diag_parameters IS RECORD(
            id_diag_behavior   diagnosis.id_diagnosis%TYPE,
            id_behavior        alert_diagnosis.id_alert_diagnosis%TYPE,
            id_diag_morphology diagnosis.id_diagnosis%TYPE,
            id_morphology      alert_diagnosis.id_alert_diagnosis%TYPE,
            id_diag_topography diagnosis.id_diagnosis%TYPE,
            id_topography      alert_diagnosis.id_alert_diagnosis%TYPE,
            id_diag_hist_grade diagnosis.id_diagnosis%TYPE,
            id_hist_grade      alert_diagnosis.id_alert_diagnosis%TYPE);
    
        l_parameters t_diag_parameters;
        --
        PROCEDURE get_parameters IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_PARAMETERS';
            --
            CURSOR c_diag_icdo IS(
                SELECT pk_diagnosis_core.get_term_diagnosis_id(a.id_behavior, i_prof.institution, i_prof.software) id_diag_behavior,
                       a.id_behavior,
                       pk_diagnosis_core.get_term_diagnosis_id(a.id_morphology, i_prof.institution, i_prof.software) id_diag_morphology,
                       a.id_morphology,
                       pk_diagnosis_core.get_term_diagnosis_id(a.id_topography, i_prof.institution, i_prof.software) id_diag_topography,
                       a.id_topography,
                       pk_diagnosis_core.get_term_diagnosis_id(a.id_hist_grade, i_prof.institution, i_prof.software) id_diag_hist_grade,
                       a.id_hist_grade
                  FROM (SELECT VALUE(p) diag_icdo
                          FROM TABLE(xmlsequence(extract(xmltype(i_params), '/PARAMETERS'))) p) b,
                       xmltable('/PARAMETERS' passing b.diag_icdo columns --
                                "ID_BEHAVIOR" NUMBER(24) path '@BEHAVIOR', --
                                "ID_MORPHOLOGY" NUMBER(24) path '@HISTOLOGY', --
                                "ID_TOPOGRAPHY" NUMBER(24) path '@TOPOGRAPHY', --
                                "ID_HIST_GRADE" NUMBER(24) path '@HISTOLOGIC_GRADE' --
                                ) a);
        
        BEGIN
            g_sysdate_tstz := current_timestamp;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
            g_error := 'OPEN C_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            OPEN c_diag_icdo;
        
            g_error := 'FETCH DATA INTO R_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            FETCH c_diag_icdo
                INTO l_parameters;
        
            g_error := 'CLOSE CURSOR C_DIAG_STAGING';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            CLOSE c_diag_icdo;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
        END get_parameters;
    BEGIN
        g_error := 'PARSE XML TO OBJECT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        get_parameters;
    
        g_error := 'GET DIAGNOSIS DESCRIPTION';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        o_diag_icdo := pk_diagnosis_core.get_desc_diag_icdo(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_code_topography => pk_diagnosis_core.get_diagnosis_code(l_parameters.id_diag_topography,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                            i_code_histology  => pk_diagnosis_core.get_code_histology(i_lang,
                                                                                                                      i_prof,
                                                                                                                      l_parameters.id_diag_morphology),
                                                            i_code_behaviour  => pk_diagnosis_core.get_diagnosis_code(l_parameters.id_diag_behavior,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                            i_code_hist_grade => pk_diagnosis_core.get_diagnosis_code(l_parameters.id_diag_hist_grade,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                            i_desc_morphology => pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                                            i_prof               => i_prof,
                                                                                                            i_id_alert_diagnosis => l_parameters.id_morphology,
                                                                                                            i_code               => NULL,
                                                                                                            i_flg_other          => pk_alert_constant.g_no,
                                                                                                            i_flg_std_diag       => pk_alert_constant.g_yes),
                                                            i_desc_topography => pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                                                            i_prof               => i_prof,
                                                                                                            i_id_alert_diagnosis => l_parameters.id_topography,
                                                                                                            i_code               => NULL,
                                                                                                            i_flg_other          => pk_alert_constant.g_no,
                                                                                                            i_flg_std_diag       => pk_alert_constant.g_yes));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_calculate_diag_icdo;

    /**
    * Parse XML parameter to database pl/sql record types
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_rec_in_epis_diagnoses Save parameters
    * @param   o_error                 Error information
    *
    * @example i_params                See the example of set_epis_diagnosis function
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   19/03/2012
    */
    FUNCTION get_save_parameters
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_params                IN CLOB,
        o_rec_in_epis_diagnoses OUT pk_edis_types.rec_in_epis_diagnoses,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_SAVE_PARAMETERS';
        --
        TYPE rec_ms_item IS RECORD(
            item_value NUMBER(24),
            alt_value  VARCHAR2(200 CHAR),
            --TNM fields
            code_staging      VARCHAR2(200 CHAR),
            desc_complication VARCHAR2(200 CHAR));
    
        TYPE table_ms_items IS TABLE OF rec_ms_item;
    
        TYPE rec_leaf IS RECORD(
            leaf_value VARCHAR2(3000 CHAR),
            --Prognostic factors fields
            id_field   epis_diag_stag_pfact.id_field%TYPE,
            field_rank epis_diag_stag_pfact.field_rank%TYPE,
            --Multichoice values
            tbl_ms_items table_ms_items);
    
        TYPE table_leafs IS TABLE OF rec_leaf INDEX BY VARCHAR2(200 CHAR); --Form fields/leafs indexed by INTERNAL_NAME, Prognostic Factors are indexed by ID_FIELD
    
        TYPE rec_form_section IS RECORD(
            internal_name ds_component.internal_name%TYPE,
            tumor_num     NUMBER(24),
            tbl_leafs     table_leafs);
    
        TYPE table_form_sections IS TABLE OF rec_form_section;
        --
        l_node_epis_diag CONSTANT pk_translation.t_desc_translation := 'EPIS_DIAGNOSES';
    
        CURSOR c_epis_diagnoses(i_epis_diags IN xmltype) IS(
            SELECT a.id_patient,
                   a.id_episode,
                   a.prof_cat_type,
                   a.flg_type,
                   a.flg_edit_mode,
                   a.id_cdr_call,
                   --EPIS_DIAGNOSIS
                   a.id_epis_diagnosis,
                   a.id_epis_diagnosis_hist,
                   a.flg_transf_final,
                   a.id_cancel_reason,
                   a.cancel_notes,
                   a.flg_cancel_diff_diag,
                   --DIAGNOSIS
                   extract(b.diag_records, '/EPIS_DIAGNOSES/EPIS_DIAGNOSIS/DIAGNOSIS') diagnosis,
                   -- GENERAL_NOTES
                   a.id_epis_diagnosis_notes,
                   a.general_notes,
                   a.id_cancel_reason_notes
              FROM (SELECT VALUE(p) diag_records
                      FROM TABLE(xmlsequence(extract(i_epis_diags, '/EPIS_DIAGNOSES'))) p) b,
                   xmltable('/EPIS_DIAGNOSES' passing b.diag_records columns --
                            "ID_PATIENT" NUMBER(24) path '@ID_PATIENT', --
                            "ID_EPISODE" NUMBER(24) path '@ID_EPISODE', --
                            "PROF_CAT_TYPE" VARCHAR2(1 CHAR) path '@PROF_CAT_TYPE', --
                            "FLG_TYPE" VARCHAR2(1 CHAR) path '@FLG_TYPE', --
                            "FLG_EDIT_MODE" VARCHAR2(1 CHAR) path '@FLG_EDIT_MODE', --
                            "ID_CDR_CALL" NUMBER(24) path '@ID_CDR_CALL', --
                            -- EPIS_DIAGNOSIS
                            "ID_EPIS_DIAGNOSIS" NUMBER(24) path 'EPIS_DIAGNOSIS/@ID_EPIS_DIAGNOSIS', --
                            "ID_EPIS_DIAGNOSIS_HIST" NUMBER(24) path 'EPIS_DIAGNOSIS/@ID_EPIS_DIAGNOSIS_HIST', --
                            "FLG_TRANSF_FINAL" VARCHAR2(1 CHAR) path 'EPIS_DIAGNOSIS/@FLG_TRANSF_FINAL', --
                            "ID_CANCEL_REASON" NUMBER(24) path 'EPIS_DIAGNOSIS/CANCEL_REASON/@ID_CANCEL_REASON', --
                            "CANCEL_NOTES" VARCHAR2(1000 CHAR) path 'EPIS_DIAGNOSIS/CANCEL_REASON/.', --
                            "FLG_CANCEL_DIFF_DIAG" VARCHAR2(1 CHAR) path
                            'EPIS_DIAGNOSIS/CANCEL_REASON/@FLG_CANCEL_DIFF_DIAG', --
                            -- GENERAL_NOTES
                            "ID_EPIS_DIAGNOSIS_NOTES" NUMBER(24) path 'GENERAL_NOTES/@ID', --
                            "GENERAL_NOTES" VARCHAR2(1000 CHAR) path 'GENERAL_NOTES/.', --
                            "ID_CANCEL_REASON_NOTES" NUMBER(24) path 'GENERAL_NOTES/@ID_CANCEL_REASON' --
                            ) a);
    
        CURSOR c_diagnosis(i_diagnosis IN xmltype) IS(
            SELECT a.id_diagnosis, a.id_alert_diagnosis, a.desc_diagnosis, extract(b.diags, '/DIAGNOSIS') sections
              FROM (SELECT VALUE(p) diags
                      FROM TABLE(xmlsequence(extract(i_diagnosis, '/DIAGNOSIS'))) p) b,
                   xmltable('/DIAGNOSIS' passing b.diags columns --
                            "ID_DIAGNOSIS" NUMBER(24) path '@ID_DIAGNOSIS', --
                            "ID_ALERT_DIAGNOSIS" NUMBER(24) path '@ID_ALERT_DIAG', --
                            "DESC_DIAGNOSIS" VARCHAR2(1000 CHAR) path 'DESC_DIAGNOSIS/.' --
                            ) a);
        --
        l_tbl_diags        pk_edis_types.table_in_diagnosis;
        l_tbl_tumors       pk_edis_types.table_in_tumors;
        l_tbl_diag_staging pk_edis_types.table_in_diag_staging;
        l_tbl_prog_factors pk_edis_types.table_in_prog_factor;
        l_diag             pk_edis_types.rec_in_diagnosis;
        l_tumor            pk_edis_types.rec_in_tumor;
        l_diag_staging     pk_edis_types.rec_in_diag_staging;
        l_prog_factor      pk_edis_types.rec_in_prog_factor;
        r_epis_diagnoses   c_epis_diagnoses%ROWTYPE;
        --
        l_tbl_form_sect_caract   table_form_sections; --CANCER_DIAGNOSES_CARACTERIZATION or GENERAL_DIAGNOSES_CARACTERIZATION or ACC_EMER_DIAGNOSES_CARACTERIZATION sections
        l_tbl_form_sect_tumors   table_form_sections; --CANCER_DIAGNOSES_PRIMARY_TUMOR sections
        l_tbl_form_sect_staging  table_form_sections; --CANCER_DIAGNOSES_STAGING sections
        l_tbl_form_sect_add_info table_form_sections; --CANCER_DIAGNOSES_ADDITIONAL_INFO or GENERAL_DIAGNOSES_ADDITIONAL_INFO or ACC_EMER_DIAGNOSES_ADDITIONAL_INFO sections
        l_tbl_prog_factor_leafs  table_leafs;
        l_tbl_aux_leafs          table_leafs;
        l_tbl_aux_ms_items       table_ms_items;
        l_complication           pk_edis_types.rec_in_complication;
        --
        PROCEDURE initialize_form_table(i_sections IN xmltype) IS
            CURSOR c_form_sections IS(
                SELECT a.section_internal_name, a.tumor_num, extract(b.section, '/SECTION') leafs
                  FROM (SELECT VALUE(p) section
                          FROM TABLE(xmlsequence(extract(i_sections, '/DIAGNOSIS/SECTION'))) p) b,
                       xmltable('/SECTION' passing b.section columns --
                                "SECTION_INTERNAL_NAME" VARCHAR2(200 CHAR) path '@INTERNAL_NAME', --
                                "TUMOR_NUM" NUMBER(24) path '@TUMOR_NUM' --
                                ) a);
        
            r_form_section c_form_sections%ROWTYPE;
            --
            CURSOR c_section_leafs(i_form_section IN xmltype) IS(
                SELECT a.leaf_internal_name,
                       a.leaf_value,
                       a.id_field,
                       nvl(a.field_rank, rownum) field_rank,
                       extract(b.form_section, '/LEAF') selected_items
                  FROM (SELECT VALUE(p) form_section
                          FROM TABLE(xmlsequence(extract(i_form_section, '/SECTION/LEAF'))) p) b,
                       xmltable('/LEAF' passing b.form_section columns --
                                "LEAF_INTERNAL_NAME" VARCHAR2(200 CHAR) path '@INTERNAL_NAME', --
                                "LEAF_VALUE" VARCHAR2(3000 CHAR) path '/.', --
                                "ID_FIELD" NUMBER(24) path 'ADDITIONAL_INFO/@ID_FIELD', --
                                "FIELD_RANK" NUMBER(24) path 'ADDITIONAL_INFO/@RANK' --
                                ) a);
        
            r_section_leaf c_section_leafs%ROWTYPE;
            --
            CURSOR c_selected_items(i_selected_items IN xmltype) IS(
                SELECT a.item_value, a.alt_value, a.code_staging, a.item_desc
                  FROM (SELECT VALUE(p) selected_items
                          FROM TABLE(xmlsequence(extract(i_selected_items, '/LEAF/SELECTED_ITEM'))) p) b,
                       xmltable('/SELECTED_ITEM' passing b.selected_items columns --
                                "ITEM_VALUE" NUMBER(24) path '@VALUE', --
                                "ALT_VALUE" VARCHAR2(200 CHAR) path '@ALT_VALUE', --
                                "CODE_STAGING" VARCHAR2(200 CHAR) path 'ADDITIONAL_INFO/@CODE_STAGING', --
                                "ITEM_DESC" VARCHAR2(200 CHAR) path '/.') a);
        
            r_selected_item c_selected_items%ROWTYPE;
            --
            l_aux_tbl_ms_items table_ms_items;
            --
            l_tbl_leafs table_leafs;
            --
            l_tumor_section_found BOOLEAN;
            --
            FUNCTION get_new_table RETURN table_leafs IS
                l_ret table_leafs;
            BEGIN
                RETURN l_ret;
            END get_new_table;
        
            FUNCTION merge_tables
            (
                i_tbl1 IN table_leafs,
                i_tbl2 IN table_leafs
            ) RETURN table_leafs IS
                l_tbl_merge table_leafs;
                l_key       VARCHAR2(200 CHAR);
            BEGIN
                IF i_tbl1.count = 0
                   AND i_tbl2.count != 0
                THEN
                    l_tbl_merge := i_tbl2;
                ELSIF i_tbl1.count != 0
                      AND i_tbl2.count = 0
                THEN
                    l_tbl_merge := i_tbl1;
                ELSIF i_tbl1.count != 0
                      AND i_tbl2.count != 0
                THEN
                    l_tbl_merge := i_tbl1;
                
                    l_key := i_tbl2.first;
                    WHILE l_key IS NOT NULL
                    LOOP
                        l_tbl_merge(l_key) := i_tbl2(l_key);
                    
                        l_key := i_tbl2.next(l_key);
                    END LOOP;
                END IF;
            
                RETURN l_tbl_merge;
            END merge_tables;
        BEGIN
            l_tbl_form_sect_caract := table_form_sections();
            l_tbl_form_sect_caract.extend;
            l_tbl_form_sect_tumors  := table_form_sections();
            l_tbl_form_sect_staging := table_form_sections();
            l_tbl_form_sect_staging.extend;
            l_tbl_form_sect_add_info := table_form_sections();
            l_tbl_form_sect_add_info.extend;
        
            FOR r_form_section IN c_form_sections
            LOOP
                l_tbl_leafs := get_new_table;
            
                FOR r_section_leaf IN c_section_leafs(i_form_section => r_form_section.leafs)
                LOOP
                    l_aux_tbl_ms_items := table_ms_items();
                
                    FOR r_selected_item IN c_selected_items(i_selected_items => r_section_leaf.selected_items)
                    LOOP
                        l_aux_tbl_ms_items.extend;
                        l_aux_tbl_ms_items(l_aux_tbl_ms_items.count).item_value := r_selected_item.item_value;
                        l_aux_tbl_ms_items(l_aux_tbl_ms_items.count).alt_value := r_selected_item.alt_value;
                        l_aux_tbl_ms_items(l_aux_tbl_ms_items.count).code_staging := r_selected_item.code_staging;
                        l_aux_tbl_ms_items(l_aux_tbl_ms_items.count).desc_complication := r_selected_item.item_desc;
                    END LOOP;
                
                    IF r_section_leaf.leaf_internal_name IN
                       (pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                        pk_diagnosis_form.g_dsc_cancer_progn_factors_cli)
                    THEN
                        l_tbl_prog_factor_leafs(r_section_leaf.id_field).leaf_value := r_section_leaf.leaf_value;
                        l_tbl_prog_factor_leafs(r_section_leaf.id_field).id_field := r_section_leaf.id_field;
                        l_tbl_prog_factor_leafs(r_section_leaf.id_field).field_rank := r_section_leaf.field_rank;
                        l_tbl_prog_factor_leafs(r_section_leaf.id_field).tbl_ms_items := l_aux_tbl_ms_items;
                    ELSE
                        l_tbl_leafs(r_section_leaf.leaf_internal_name).leaf_value := r_section_leaf.leaf_value;
                        l_tbl_leafs(r_section_leaf.leaf_internal_name).id_field := r_section_leaf.id_field;
                        l_tbl_leafs(r_section_leaf.leaf_internal_name).field_rank := r_section_leaf.field_rank;
                        l_tbl_leafs(r_section_leaf.leaf_internal_name).tbl_ms_items := l_aux_tbl_ms_items;
                    END IF;
                END LOOP;
            
                --Internal name isn't used, if it was we would have a problem because we only have a name for a group of sections
                CASE
                --CARACTERIZATION SECTION
                    WHEN r_form_section.section_internal_name IN
                         (pk_diagnosis_form.g_dsc_cancer_caracterization,
                          pk_diagnosis_form.g_dsc_general_caracterization,
                          pk_diagnosis_form.g_dsc_acc_emerg_caract,
                          pk_diagnosis_form.g_dsc_cancer_basis_diag,
                          pk_diagnosis_form.g_dsc_cancer_num_prim_tum) THEN
                        l_tbl_form_sect_caract(l_tbl_form_sect_caract.count).internal_name := r_form_section.section_internal_name;
                        l_tbl_form_sect_caract(l_tbl_form_sect_caract.count).tbl_leafs := merge_tables(i_tbl1 => l_tbl_form_sect_caract(l_tbl_form_sect_caract.count)
                                                                                                                 .tbl_leafs,
                                                                                                       i_tbl2 => l_tbl_leafs);
                        --TUMOR's SECTION
                    WHEN r_form_section.section_internal_name IN
                         (pk_diagnosis_form.g_dsc_cancer_prim_tum, pk_diagnosis_form.g_dsc_cancer_prim_tum_siz) THEN
                        IF NOT l_tbl_form_sect_tumors.exists(1)
                        THEN
                            l_tbl_form_sect_tumors.extend;
                            l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).internal_name := r_form_section.section_internal_name;
                            l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).tumor_num := r_form_section.tumor_num;
                            l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).tbl_leafs := l_tbl_leafs;
                        ELSE
                            l_tumor_section_found := FALSE;
                        
                            FOR i IN l_tbl_form_sect_tumors.first .. l_tbl_form_sect_tumors.last
                            LOOP
                                IF l_tbl_form_sect_tumors(i).tumor_num = r_form_section.tumor_num
                                THEN
                                    l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).tbl_leafs := merge_tables(i_tbl1 => l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count)
                                                                                                                             .tbl_leafs,
                                                                                                                   i_tbl2 => l_tbl_leafs);
                                    l_tumor_section_found := TRUE;
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            IF NOT l_tumor_section_found
                            THEN
                                l_tbl_form_sect_tumors.extend;
                                l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).internal_name := r_form_section.section_internal_name;
                                l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).tumor_num := r_form_section.tumor_num;
                                l_tbl_form_sect_tumors(l_tbl_form_sect_tumors.count).tbl_leafs := l_tbl_leafs;
                            END IF;
                        END IF;
                        --STAGING BASIS SECTION
                    WHEN r_form_section.section_internal_name IN
                         (pk_diagnosis_form.g_dsc_cancer_staging,
                          pk_diagnosis_form.g_dsc_cancer_tnm,
                          pk_diagnosis_form.g_dsc_cancer_progn_factors,
                          pk_diagnosis_form.g_dsc_cancer_progn_factors_req,
                          pk_diagnosis_form.g_dsc_cancer_progn_factors_cli) THEN
                        l_tbl_form_sect_staging(l_tbl_form_sect_staging.count).internal_name := r_form_section.section_internal_name;
                        l_tbl_form_sect_staging(l_tbl_form_sect_staging.count).tbl_leafs := merge_tables(i_tbl1 => l_tbl_form_sect_staging(l_tbl_form_sect_staging.count)
                                                                                                                   .tbl_leafs,
                                                                                                         i_tbl2 => l_tbl_leafs);
                        --ADDITIONAL_INFO SECTION
                    WHEN r_form_section.section_internal_name IN
                         (pk_diagnosis_form.g_dsc_cancer_additional_info,
                          pk_diagnosis_form.g_dsc_general_additional_info,
                          pk_diagnosis_form.g_dsc_acc_emerg_add_info) THEN
                        l_tbl_form_sect_add_info(l_tbl_form_sect_add_info.count).internal_name := r_form_section.section_internal_name;
                        l_tbl_form_sect_add_info(l_tbl_form_sect_add_info.count).tbl_leafs := merge_tables(i_tbl1 => l_tbl_form_sect_add_info(l_tbl_form_sect_add_info.count)
                                                                                                                     .tbl_leafs,
                                                                                                           i_tbl2 => l_tbl_leafs);
                    ELSE
                        NULL;
                END CASE;
            END LOOP;
        END initialize_form_table;
    
        FUNCTION get_dsc_leaf_int_name
        (
            i_diag_type     IN VARCHAR2,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN ds_component.internal_name%TYPE IS
            l_ret ds_component.internal_name%TYPE;
        BEGIN
            CASE i_diag_type
                WHEN pk_diagnosis_core.g_diag_type_acc_emerg THEN
                    CASE i_db_field_name
                        WHEN pk_diagnosis_form.g_db_fld_add_to_problems THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_add_problem;
                        WHEN pk_diagnosis_form.g_db_fld_age_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_age_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_anatomical_area THEN
                            l_ret := pk_diagnosis_form.g_dsc_acc_emer_anat_area;
                        WHEN pk_diagnosis_form.g_db_fld_anatomical_side THEN
                            l_ret := pk_diagnosis_form.g_dsc_acc_emer_anat_side;
                        WHEN pk_diagnosis_form.g_db_fld_dt_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_dt_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_investigation_status THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_invest_stat;
                        WHEN pk_diagnosis_form.g_db_fld_notes THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_notes;
                        WHEN pk_diagnosis_form.g_db_fld_principal_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_princ_diag;
                        WHEN pk_diagnosis_form.g_db_fld_recurrence THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_recur;
                        WHEN pk_diagnosis_form.g_db_fld_sub_analysis THEN
                            l_ret := pk_diagnosis_form.g_dsc_acc_emer_sub_analysis;
                        ELSE
                            l_ret := NULL;
                    END CASE;
                WHEN pk_diagnosis_core.g_diag_type_cancer THEN
                    CASE i_db_field_name
                        WHEN pk_diagnosis_form.g_db_fld_additional_path_info THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_addit_path_info;
                        WHEN pk_diagnosis_form.g_db_fld_add_to_problems THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_add_problem;
                        WHEN pk_diagnosis_form.g_db_fld_age_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_age_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_basis_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_basis_diag;
                        WHEN pk_diagnosis_form.g_db_fld_basis_diag_ms THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_basis_diag_ms;
                        WHEN pk_diagnosis_form.g_db_fld_basis_diag_spec THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_basis_diag_spec;
                        WHEN pk_diagnosis_form.g_db_fld_behavior THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_behavior;
                        WHEN pk_diagnosis_form.g_db_fld_dt_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_dt_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_histologic_grade THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_hist_grade;
                        WHEN pk_diagnosis_form.g_db_fld_histology THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_histology;
                        WHEN pk_diagnosis_form.g_db_fld_investigation_status THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_invest_stat;
                        WHEN pk_diagnosis_form.g_db_fld_laterality THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_laterality;
                        WHEN pk_diagnosis_form.g_db_fld_lymph_vasc_invasion THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_lymp_vasc_inv;
                        WHEN pk_diagnosis_form.g_db_fld_metastatic_sites THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_metast_sites;
                        WHEN pk_diagnosis_form.g_db_fld_notes THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_notes;
                        WHEN pk_diagnosis_form.g_db_fld_num_prim_tumors THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_num_prim_tum;
                        WHEN pk_diagnosis_form.g_db_fld_num_prim_tumors_ms_yn THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_nprim_tum_ms_yn;
                        WHEN pk_diagnosis_form.g_db_fld_num_prim_tumors_num THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_nprim_tum_num;
                        WHEN pk_diagnosis_form.g_db_fld_other_grading_system THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_ograd_system;
                        WHEN pk_diagnosis_form.g_db_fld_other_staging_system THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_ostaging_sys;
                        WHEN pk_diagnosis_form.g_db_fld_ptumor_size THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_prim_tum_siz;
                        WHEN pk_diagnosis_form.g_db_fld_ptumor_size_desc THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_desc;
                        WHEN pk_diagnosis_form.g_db_fld_ptumor_size_numeric THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_num;
                        WHEN pk_diagnosis_form.g_db_fld_ptumor_size_unknown THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_prim_tum_siz_unk;
                        WHEN pk_diagnosis_form.g_db_fld_principal_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_princ_diag;
                        WHEN pk_diagnosis_form.g_db_fld_prognostic_factors THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_progn_factors;
                        WHEN pk_diagnosis_form.g_db_fld_recurrence THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_recur;
                        WHEN pk_diagnosis_form.g_db_fld_residual_tumor THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_residual_tum;
                        WHEN pk_diagnosis_form.g_db_fld_stage THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_stage;
                        WHEN pk_diagnosis_form.g_db_fld_stage_group THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_stage_grp;
                        WHEN pk_diagnosis_form.g_db_fld_staging_basis THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_staging_basis;
                        WHEN pk_diagnosis_form.g_db_fld_surgical_margins THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_surg_margins;
                        WHEN pk_diagnosis_form.g_db_fld_tnm THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_tnm;
                        WHEN pk_diagnosis_form.g_db_fld_tnm_m THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_tnm_m;
                        WHEN pk_diagnosis_form.g_db_fld_tnm_n THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_tnm_n;
                        WHEN pk_diagnosis_form.g_db_fld_tnm_t THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_tnm_t;
                        WHEN pk_diagnosis_form.g_db_fld_tnm_tnm THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_tnm_tnm;
                        WHEN pk_diagnosis_form.g_db_fld_topography THEN
                            l_ret := pk_diagnosis_form.g_dsc_cancer_topography;
                        ELSE
                            l_ret := NULL;
                    END CASE;
                WHEN pk_diagnosis_core.g_diag_type_diag THEN
                    CASE i_db_field_name
                        WHEN pk_diagnosis_form.g_db_fld_add_to_problems THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_add_problem;
                        WHEN pk_diagnosis_form.g_db_fld_age_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_age_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_dt_init_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_dt_init_diag;
                        WHEN pk_diagnosis_form.g_db_fld_investigation_status THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_invest_stat;
                        WHEN pk_diagnosis_form.g_db_fld_notes THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_notes;
                        WHEN pk_diagnosis_form.g_db_fld_principal_diag THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_princ_diag;
                        WHEN pk_diagnosis_form.g_db_fld_recurrence THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_recur;
                        WHEN pk_diagnosis_form.g_db_lesion_location THEN
                            l_ret := pk_diagnosis_form.g_dsc_lesion_location;
                        WHEN pk_diagnosis_form.g_db_lesion_type THEN
                            l_ret := pk_diagnosis_form.g_dsc_lesion_type;
                        WHEN pk_diagnosis_form.g_db_complications THEN
                            l_ret := pk_diagnosis_form.g_dsc_complications;
                        WHEN pk_diagnosis_form.g_db_fld_rank THEN
                            l_ret := pk_diagnosis_form.g_dsc_general_rank;
                        ELSE
                            l_ret := NULL;
                    END CASE;
                ELSE
                    l_ret := NULL;
            END CASE;
        
            RETURN l_ret;
        END get_dsc_leaf_int_name;
    
        FUNCTION get_leaf_value
        (
            i_diag_type     IN VARCHAR2,
            i_tbl_leafs     IN table_leafs,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN VARCHAR2 IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_LEAF_VALUE';
            --
            l_internal_name ds_component.internal_name%TYPE;
            --
            l_ret VARCHAR2(3000 CHAR) := NULL;
        BEGIN
            g_error := 'CALL GET_DSC_LEAF_INT_NAME - DIAG_TYPE: ' || i_diag_type || '; DB_FIELD_NAME: ' ||
                       i_db_field_name;
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            l_internal_name := get_dsc_leaf_int_name(i_diag_type => i_diag_type, i_db_field_name => i_db_field_name);
        
            IF l_internal_name IS NOT NULL
            THEN
                BEGIN
                    l_ret := i_tbl_leafs(l_internal_name).leaf_value;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ret := NULL;
                END;
            END IF;
        
            RETURN l_ret;
        END get_leaf_value;
    
        FUNCTION get_leaf_value_num
        (
            i_diag_type     IN VARCHAR2,
            i_tbl_leafs     IN table_leafs,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN NUMBER IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_LEAF_VALUE_NUM';
            --
            e_invalid_number EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_invalid_number, -01722);
            --
            l_leaf_value VARCHAR2(1000 CHAR);
            l_ret        NUMBER(24);
        BEGIN
            g_error := 'CALL GET_LEAF_VALUE';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            l_leaf_value := TRIM(get_leaf_value(i_diag_type     => i_diag_type,
                                                i_tbl_leafs     => i_tbl_leafs,
                                                i_db_field_name => i_db_field_name));
        
            IF l_leaf_value IS NOT NULL
            THEN
                g_error := 'CONVERT "' || l_leaf_value || '" TO NUMBER';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                l_ret := to_number(l_leaf_value);
            ELSE
                l_ret := NULL;
            END IF;
        
            RETURN l_ret;
        EXCEPTION
            WHEN e_invalid_number THEN
                raise_application_error(-20010,
                                        'ERROR CONVERTING "' || i_db_field_name || '" FIELD WITH VALUE "' ||
                                        l_leaf_value || '" TO NUMBER');
        END get_leaf_value_num;
    
        FUNCTION get_leaf_value_dt
        (
            i_diag_type     IN VARCHAR2,
            i_tbl_leafs     IN table_leafs,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN TIMESTAMP
            WITH TIME ZONE IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_LEAF_VALUE_DT';
            --
            l_leaf_value VARCHAR2(1000 CHAR);
            l_ret        TIMESTAMP WITH TIME ZONE;
        BEGIN
            g_error := 'CALL GET_LEAF_VALUE';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
            l_leaf_value := TRIM(get_leaf_value(i_diag_type     => i_diag_type,
                                                i_tbl_leafs     => i_tbl_leafs,
                                                i_db_field_name => i_db_field_name));
        
            IF l_leaf_value IS NOT NULL
            THEN
                g_error := 'CONVERT "' || l_leaf_value || '" TO TSTZ';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                l_ret := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_timestamp => l_leaf_value,
                                                       i_timezone  => NULL);
            ELSE
                l_ret := NULL;
            END IF;
        
            IF l_ret IS NULL
               AND l_leaf_value IS NOT NULL
            THEN
                raise_application_error(-20011,
                                        'ERROR CONVERTING "' || i_db_field_name || '" FIELD WITH VALUE "' ||
                                        l_leaf_value || '" TO TSTZ');
            END IF;
        
            RETURN l_ret;
        END get_leaf_value_dt;
    
        FUNCTION get_leaf_ms_item
        (
            i_diag_type     IN VARCHAR2,
            i_tbl_leafs     IN table_leafs,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN rec_ms_item IS
            l_internal_name ds_component.internal_name%TYPE;
            l_rec_leaf      rec_leaf;
            l_tbl_ms_items  table_ms_items;
            l_aux_item      rec_ms_item;
        BEGIN
            l_internal_name := get_dsc_leaf_int_name(i_diag_type => i_diag_type, i_db_field_name => i_db_field_name);
        
            IF l_internal_name IS NOT NULL
            THEN
                BEGIN
                    l_rec_leaf     := i_tbl_leafs(l_internal_name);
                    l_tbl_ms_items := l_rec_leaf.tbl_ms_items;
                
                    IF l_tbl_ms_items.exists(1)
                    THEN
                        l_aux_item := l_tbl_ms_items(1);
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            RETURN l_aux_item;
        END get_leaf_ms_item;
    
        -----------------------------------
        -- return multiple items instead of a single one
        FUNCTION get_leaf_ms_items
        (
            i_diag_type     IN VARCHAR2,
            i_tbl_leafs     IN table_leafs,
            i_db_field_name IN ds_component.internal_name%TYPE
        ) RETURN table_ms_items IS
            -- rec_ms_item
            l_internal_name ds_component.internal_name%TYPE;
            l_rec_leaf      rec_leaf;
            l_tbl_ms_items  table_ms_items;
            l_aux_items     table_ms_items;
        BEGIN
            l_internal_name := get_dsc_leaf_int_name(i_diag_type => i_diag_type, i_db_field_name => i_db_field_name);
        
            IF l_internal_name IS NOT NULL
            THEN
                BEGIN
                    l_rec_leaf     := i_tbl_leafs(l_internal_name);
                    l_tbl_ms_items := l_rec_leaf.tbl_ms_items;
                
                    IF l_tbl_ms_items.exists(1)
                    THEN
                        l_aux_items := l_tbl_ms_items;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            RETURN l_aux_items;
        END get_leaf_ms_items;
    
    BEGIN
        IF i_params IS NOT NULL
           AND instr(i_params, l_node_epis_diag) != 0
        THEN
            g_sysdate_tstz := current_timestamp;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
            g_error := 'OPEN C_EPIS_DIAGNOSES';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            OPEN c_epis_diagnoses(i_epis_diags => xmltype(i_params));
        
            g_error := 'FETCH DATA INTO R_EPIS_DIAGNOSES';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            FETCH c_epis_diagnoses
                INTO r_epis_diagnoses;
        
            g_error := 'CLOSE CURSOR';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            CLOSE c_epis_diagnoses;
        
            o_rec_in_epis_diagnoses.epis_diagnosis.id_epis_diagnosis      := r_epis_diagnoses.id_epis_diagnosis;
            o_rec_in_epis_diagnoses.epis_diagnosis.id_epis_diagnosis_hist := r_epis_diagnoses.id_epis_diagnosis_hist;
            o_rec_in_epis_diagnoses.epis_diagnosis.id_patient             := r_epis_diagnoses.id_patient;
            o_rec_in_epis_diagnoses.epis_diagnosis.id_episode             := r_epis_diagnoses.id_episode;
            o_rec_in_epis_diagnoses.epis_diagnosis.prof_cat_type          := r_epis_diagnoses.prof_cat_type;
            o_rec_in_epis_diagnoses.epis_diagnosis.flg_type               := r_epis_diagnoses.flg_type;
            o_rec_in_epis_diagnoses.epis_diagnosis.flg_edit_mode          := r_epis_diagnoses.flg_edit_mode;
            o_rec_in_epis_diagnoses.epis_diagnosis.flg_transf_final       := r_epis_diagnoses.flg_transf_final;
            o_rec_in_epis_diagnoses.epis_diagnosis.id_cdr_call            := r_epis_diagnoses.id_cdr_call;
        
            IF r_epis_diagnoses.flg_edit_mode IN
               (pk_diagnosis_core.g_diag_cancel_diag,
                --When flash start sending the staging data this flag can be removed
                pk_diagnosis_core.g_diag_cancel_staging)
            THEN
                o_rec_in_epis_diagnoses.epis_diagnosis.id_cancel_reason := r_epis_diagnoses.id_cancel_reason;
                o_rec_in_epis_diagnoses.epis_diagnosis.cancel_notes     := r_epis_diagnoses.cancel_notes;
            END IF;
        
            o_rec_in_epis_diagnoses.epis_diagnosis.flg_cancel_diff_diag     := r_epis_diagnoses.flg_cancel_diff_diag;
            o_rec_in_epis_diagnoses.epis_diagnosis.flg_val_single_prim_diag := nvl(pk_sysconfig.get_config(i_code_cf => pk_diagnosis_core.g_cfg_single_prim_diag,
                                                                                                           i_prof    => i_prof),
                                                                                   pk_alert_constant.g_yes);
        
            l_tbl_diags        := pk_edis_types.table_in_diagnosis();
            l_tbl_aux_ms_items := table_ms_items();
        
            FOR r_diagnosis IN c_diagnosis(i_diagnosis => r_epis_diagnoses.diagnosis)
            LOOP
                l_diag.id_diagnosis       := r_diagnosis.id_diagnosis;
                l_diag.id_alert_diagnosis := r_diagnosis.id_alert_diagnosis;
                l_diag.desc_diagnosis     := r_diagnosis.desc_diagnosis;
                l_diag.tbl_complications  := pk_edis_types.table_in_complications();
            
                --SET DIAG TYPE - This var is used to map the db field with the ds leaf
                g_error := 'CALL PK_DIAGNOSIS_CORE.GET_DIAG_TYPE - ID_DIAG: ' || l_diag.id_diagnosis;
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                l_diag.flg_diag_type := pk_diagnosis_core.get_diag_type(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_concept_type => NULL,
                                                                        i_diagnosis    => l_diag.id_diagnosis);
            
                g_error := 'CALL INITIALIZE_FORM_TABLE';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                initialize_form_table(i_sections => r_diagnosis.sections);
            
                --ADDITIONAL_INFO
                IF l_tbl_form_sect_add_info.exists(1)
                THEN
                    --Additional info only has one section
                    l_tbl_aux_leafs := l_tbl_form_sect_add_info(1).tbl_leafs;
                
                    l_diag.flg_final_type := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_principal_diag)
                                             .alt_value;
                    l_diag.flg_status     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_investigation_status)
                                             .alt_value;
                
                    l_diag.rank := get_leaf_value_num(l_diag.flg_diag_type,
                                                      l_tbl_aux_leafs,
                                                      pk_diagnosis_form.g_db_fld_rank);
                    -----------------------------------------
                    -- COMPLICATIONS processing
                    -- determine if LEAF COMPLICATIONS exists
                    IF l_tbl_aux_leafs.exists(get_dsc_leaf_int_name(i_diag_type     => l_diag.flg_diag_type,
                                                                    i_db_field_name => pk_diagnosis_form.g_db_complications))
                    THEN
                        l_tbl_aux_ms_items := get_leaf_ms_items(l_diag.flg_diag_type,
                                                                l_tbl_aux_leafs,
                                                                pk_diagnosis_form.g_db_complications);
                        IF l_tbl_aux_ms_items.exists(1)
                        THEN
                            FOR i IN l_tbl_aux_ms_items.first .. l_tbl_aux_ms_items.last
                            LOOP
                                l_complication.id_complication       := l_tbl_aux_ms_items(i).item_value;
                                l_complication.id_alert_complication := to_number(l_tbl_aux_ms_items(i).alt_value);
                                l_complication.desc_complication     := l_tbl_aux_ms_items(i).desc_complication;
                            
                                l_diag.tbl_complications.extend;
                                l_diag.tbl_complications(l_diag.tbl_complications.last) := l_complication;
                            END LOOP;
                        ELSE
                            -- if COMPLICATION LEAF exists, but no information regarding SELECTED_ITEM (list of complications is empty)
                            -- then create empty record to indicate existing complications must be inactivated
                            l_complication.id_complication       := NULL;
                            l_complication.id_alert_complication := NULL;
                            l_complication.desc_complication     := NULL;
                        
                            l_diag.tbl_complications.extend;
                            l_diag.tbl_complications(l_diag.tbl_complications.last) := l_complication;
                        END IF;
                    END IF;
                    -----------------------------------------
                
                    l_diag.flg_add_problem    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_add_to_problems)
                                                 .alt_value;
                    l_diag.id_lesion_location := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_lesion_location)
                                                 .item_value;
                    l_diag.id_lesion_type     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_lesion_type)
                                                 .item_value;
                    l_diag.notes              := get_leaf_value(l_diag.flg_diag_type,
                                                                l_tbl_aux_leafs,
                                                                pk_diagnosis_form.g_db_fld_notes);
                END IF;
            
                --CHARACTERIZATION - ACCIDENT_EMERGENCY
                IF l_tbl_form_sect_caract.exists(1)
                THEN
                    --Characterization only has one section
                    l_tbl_aux_leafs := l_tbl_form_sect_caract(1).tbl_leafs;
                
                    l_diag.id_diagnosis_condition := pk_diagnosis_core.get_id_diag_condition(i_prof      => i_prof,
                                                                                             i_diagnosis => l_diag.id_diagnosis);
                
                    l_diag.id_sub_analysis    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_sub_analysis)
                                                 .item_value;
                    l_diag.id_anatomical_area := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_anatomical_area)
                                                 .item_value;
                    l_diag.id_anatomical_side := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_anatomical_side)
                                                 .item_value;
                    --CHARACTERIZATION
                    l_diag.dt_initial_diag    := get_leaf_value_dt(l_diag.flg_diag_type,
                                                                   l_tbl_aux_leafs,
                                                                   pk_diagnosis_form.g_db_fld_dt_init_diag);
                    l_diag.id_diag_basis      := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_basis_diag_ms)
                                                 .item_value;
                    l_diag.diag_basis_spec    := get_leaf_value(l_diag.flg_diag_type,
                                                                l_tbl_aux_leafs,
                                                                pk_diagnosis_form.g_db_fld_basis_diag_spec);
                    l_diag.flg_recurrence     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_recurrence)
                                                 .alt_value;
                    l_diag.flg_mult_tumors    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_num_prim_tumors_ms_yn)
                                                 .alt_value;
                    l_diag.num_primary_tumors := get_leaf_value_num(l_diag.flg_diag_type,
                                                                    l_tbl_aux_leafs,
                                                                    pk_diagnosis_form.g_db_fld_num_prim_tumors_num);
                END IF;
            
                --TUMORS
                l_tbl_tumors := pk_edis_types.table_in_tumors();
            
                IF l_tbl_form_sect_tumors.exists(1)
                THEN
                    FOR i IN l_tbl_form_sect_tumors.first .. l_tbl_form_sect_tumors.last
                    LOOP
                        l_tumor.tumor_num              := l_tbl_form_sect_tumors(i).tumor_num;
                        l_tumor.id_topography          := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_topography)
                                                          .item_value;
                        l_tumor.id_laterality          := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_laterality)
                                                          .item_value;
                        l_tumor.morphology.morphology  := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_histology)
                                                          .item_value;
                        l_tumor.morphology.behavior    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_behavior)
                                                          .item_value;
                        l_tumor.morphology.grade       := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_histologic_grade)
                                                          .item_value;
                        l_tumor.id_other_grading_sys   := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_other_grading_system)
                                                          .item_value;
                        l_tumor.flg_unknown_dimension  := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_form_sect_tumors(i).tbl_leafs, pk_diagnosis_form.g_db_fld_ptumor_size_unknown)
                                                          .alt_value;
                        l_tumor.num_dimension          := get_leaf_value_num(l_diag.flg_diag_type,
                                                                             l_tbl_form_sect_tumors(i).tbl_leafs,
                                                                             pk_diagnosis_form.g_db_fld_ptumor_size_numeric);
                        l_tumor.desc_dimension         := get_leaf_value(l_diag.flg_diag_type,
                                                                         l_tbl_form_sect_tumors(i).tbl_leafs,
                                                                         pk_diagnosis_form.g_db_fld_ptumor_size_desc);
                        l_tumor.additional_pathol_info := get_leaf_value(l_diag.flg_diag_type,
                                                                         l_tbl_form_sect_tumors(i).tbl_leafs,
                                                                         pk_diagnosis_form.g_db_fld_additional_path_info);
                    
                        l_tbl_tumors.extend;
                        l_tbl_tumors(l_tbl_tumors.count) := l_tumor;
                    END LOOP;
                END IF;
            
                --STAGING
                l_tbl_diag_staging := pk_edis_types.table_in_diag_staging();
            
                IF l_tbl_form_sect_caract.exists(1)
                THEN
                    --Staging only has one section
                    l_tbl_aux_leafs := l_tbl_form_sect_staging(1).tbl_leafs;
                
                    l_diag_staging.id_staging_basis     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_staging_basis)
                                                           .item_value;
                    l_diag_staging.num_staging_basis    := pk_diagnosis_core.get_staging_basis_rank(i_lang          => i_lang,
                                                                                                    i_prof          => i_prof,
                                                                                                    i_staging_basis => l_diag_staging.id_staging_basis);
                    l_diag_staging.tnm.t                := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_t)
                                                           .item_value;
                    l_diag_staging.tnm.code_stage_t     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_t)
                                                           .code_staging;
                    l_diag_staging.tnm.n                := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_n)
                                                           .item_value;
                    l_diag_staging.tnm.code_stage_n     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_n)
                                                           .code_staging;
                    l_diag_staging.tnm.m                := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_m)
                                                           .item_value;
                    l_diag_staging.tnm.code_stage_m     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_tnm_m)
                                                           .code_staging;
                    l_diag_staging.id_metastatic_sites  := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_metastatic_sites)
                                                           .item_value;
                    l_diag_staging.id_staging_group     := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_stage_group)
                                                           .item_value;
                    l_diag_staging.id_residual_tumor    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_residual_tumor)
                                                           .item_value;
                    l_diag_staging.id_surgical_margins  := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_surgical_margins)
                                                           .item_value;
                    l_diag_staging.id_lymph_vasc_inv    := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_lymph_vasc_invasion)
                                                           .item_value;
                    l_diag_staging.id_other_staging_sys := get_leaf_ms_item(l_diag.flg_diag_type, l_tbl_aux_leafs, pk_diagnosis_form.g_db_fld_other_staging_system)
                                                           .item_value;
                END IF;
            
                IF r_epis_diagnoses.flg_edit_mode = pk_diagnosis_core.g_diag_cancel_staging
                THEN
                    --For now this code will never be run, because flash doesn't send staging info when canceling the staging
                    --However I will kept this code, we never know when they will start sending it
                    l_diag_staging.id_cancel_reason := r_epis_diagnoses.id_cancel_reason;
                    l_diag_staging.cancel_notes     := r_epis_diagnoses.cancel_notes;
                END IF;
            
                l_tbl_prog_factors := pk_edis_types.table_in_prog_factor();
            
                IF l_tbl_prog_factor_leafs.count > 0
                THEN
                    DECLARE
                        l_field VARCHAR2(200 CHAR);
                    BEGIN
                        l_field := l_tbl_prog_factor_leafs.first();
                    
                        WHILE l_field IS NOT NULL
                        LOOP
                            l_prog_factor.id_field   := l_tbl_prog_factor_leafs(l_field).id_field;
                            l_prog_factor.field_rank := l_tbl_prog_factor_leafs(l_field).field_rank;
                        
                            IF l_tbl_prog_factor_leafs(l_field).tbl_ms_items.exists(1)
                            THEN
                                l_prog_factor.id_value   := l_tbl_prog_factor_leafs(l_field).tbl_ms_items(1).item_value;
                                l_prog_factor.desc_value := NULL;
                            ELSE
                                l_prog_factor.id_value   := NULL;
                                l_prog_factor.desc_value := l_tbl_prog_factor_leafs(l_field).leaf_value;
                            END IF;
                        
                            l_tbl_prog_factors.extend;
                            l_tbl_prog_factors(l_tbl_prog_factors.count) := l_prog_factor;
                        
                            l_field := l_tbl_prog_factor_leafs.next(l_field);
                        END LOOP;
                    END;
                END IF;
            
                IF l_diag_staging.id_staging_basis IS NOT NULL
                THEN
                    l_diag_staging.tbl_prog_factors := l_tbl_prog_factors;
                    l_tbl_diag_staging.extend;
                    l_tbl_diag_staging(l_tbl_diag_staging.count) := l_diag_staging;
                END IF;
            
                l_diag.tbl_tumors       := l_tbl_tumors;
                l_diag.tbl_diag_staging := l_tbl_diag_staging;
            
                l_tbl_diags.extend;
                l_tbl_diags(l_tbl_diags.count) := l_diag;
            END LOOP;
        
            o_rec_in_epis_diagnoses.epis_diagnosis.tbl_diagnosis := l_tbl_diags;
        
            o_rec_in_epis_diagnoses.general_notes.id_epis_diagnosis_notes := r_epis_diagnoses.id_epis_diagnosis_notes;
            o_rec_in_epis_diagnoses.general_notes.id_episode              := r_epis_diagnoses.id_episode;
            o_rec_in_epis_diagnoses.general_notes.notes                   := r_epis_diagnoses.general_notes;
            o_rec_in_epis_diagnoses.general_notes.id_cancel_reason        := r_epis_diagnoses.id_cancel_reason_notes;
            o_rec_in_epis_diagnoses.general_notes.id_prof_create          := i_prof.id;
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_save_parameters;
    --
    /**
    * Parse database pl/sql record type to XML
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_out_params            Onput parameter object
    * @param   o_out_params            XML output parameters
    * @param   o_error                 Error information
    *
    * @example o_out_params            See the example of set_epis_diagnosis function
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   19/03/2012
    */
    FUNCTION get_out_parameters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_out_params IN pk_edis_types.table_out_epis_diags,
        o_out_params OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_OUT_PARAMETERS';
        --
        doc                xmldom.domdocument;
        main_node          xmldom.domnode;
        root_node          xmldom.domnode;
        param_node         xmldom.domnode;
        tumors_node        xmldom.domnode;
        tumor_node         xmldom.domnode;
        stagings_node      xmldom.domnode;
        staging_node       xmldom.domnode;
        complications_node xmldom.domnode;
        complication_node  xmldom.domnode;
        pfactors_node      xmldom.domnode;
        pfactor_node       xmldom.domnode;
        item_elmt          xmldom.domelement;
    BEGIN
        g_error := 'VERIFY IF THERE IS SOMETHING TO PARSE';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF i_out_params IS NOT NULL
           AND i_out_params.count > 0
        THEN
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        
            g_error := 'ADD ROOT ELEMENT';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            doc       := xmldom.newdomdocument;
            main_node := xmldom.makenode(doc);
            item_elmt := xmldom.createelement(doc, 'OUT_PARAMS');
        
            root_node := xmldom.appendchild(main_node, xmldom.makenode(item_elmt));
        
            FOR i IN i_out_params.first .. i_out_params.last
            LOOP
                item_elmt := xmldom.createelement(doc, 'OUT_PARAM');
            
                IF i_out_params(i).id_epis_diagnosis IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt, 'ID_EPIS_DIAGNOSIS', to_char(i_out_params(i).id_epis_diagnosis));
                END IF;
            
                IF i_out_params(i).id_epis_diagnosis_hist IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt,
                                        'ID_EPIS_DIAGNOSIS_HIST',
                                        to_char(i_out_params(i).id_epis_diagnosis_hist));
                END IF;
            
                IF i_out_params(i).dt_record IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt,
                                        'DATE_RECORD',
                                        pk_date_utils.dt_chr_tsz(i_lang => i_lang,
                                                                 i_date => i_out_params(i).dt_record,
                                                                 i_prof => i_prof));
                    xmldom.setattribute(item_elmt,
                                        'HOUR_RECORD',
                                        pk_date_utils.date_char_hour_tsz(i_lang => i_lang,
                                                                         i_date => i_out_params(i).dt_record,
                                                                         i_inst => i_prof.institution,
                                                                         i_soft => i_prof.software));
                END IF;
            
                IF i_out_params(i).id_professional IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt, 'ID_PROFESSIONAL', i_out_params(i).id_professional);
                END IF;
            
                IF i_out_params(i).prof_name IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt, 'PROF_NAME', i_out_params(i).prof_name);
                END IF;
            
                IF i_out_params(i).prof_spec IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt, 'PROF_SPEC', i_out_params(i).prof_spec);
                END IF;
            
                IF i_out_params(i).problem_flg_show IS NOT NULL
                THEN
                    xmldom.setattribute(item_elmt, 'PROBLEM_MSG', i_out_params(i).problem_msg);
                    xmldom.setattribute(item_elmt, 'PROBLEM_MSG_TITLE', i_out_params(i).problem_msg_title);
                    xmldom.setattribute(item_elmt, 'PROBLEM_FLG_SHOW', i_out_params(i).problem_flg_show);
                    xmldom.setattribute(item_elmt, 'PROBLEM_BUTTON', i_out_params(i).problem_button);
                END IF;
            
                g_error := 'ADD OUT_PARAMETER';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                param_node := xmldom.appendchild(root_node, xmldom.makenode(item_elmt));
            
                IF i_out_params(i).tbl_tumors IS NOT NULL
                    AND i_out_params(i).tbl_tumors.count > 0
                THEN
                    g_error := 'ADD TUMOR ROOT NODE';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    item_elmt := xmldom.createelement(doc, 'TUMORS');
                
                    tumors_node := xmldom.appendchild(param_node, xmldom.makenode(item_elmt));
                
                    FOR j IN i_out_params(i).tbl_tumors.first .. i_out_params(i).tbl_tumors.last
                    LOOP
                        item_elmt := xmldom.createelement(doc, 'TUMOR');
                    
                        IF i_out_params(i).tbl_tumors(j).tumor_num IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'TUMOR_NUM',
                                                to_char(i_out_params(i).tbl_tumors(j).tumor_num));
                        END IF;
                    
                        IF i_out_params(i).tbl_tumors(j).tumor_num_directly_hist IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'TUMOR_NUMOR_DIRECTLY_HIST',
                                                to_char(i_out_params(i).tbl_tumors(j).tumor_num_directly_hist));
                        END IF;
                    
                        g_error := 'ADD TUMOR';
                        pk_alertlog.log_debug(object_name     => g_package,
                                              sub_object_name => l_func_name,
                                              text            => g_error);
                        tumor_node := xmldom.appendchild(tumors_node, xmldom.makenode(item_elmt));
                    END LOOP;
                END IF;
            
                ------------------------------------------------------------------------
                IF i_out_params(i).tbl_complications IS NOT NULL
                    AND i_out_params(i).tbl_complications.count > 0
                THEN
                    g_error := 'ADD COMPLICATION ROOT NODE';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    item_elmt := xmldom.createelement(doc, 'COMPLICATIONS');
                
                    complications_node := xmldom.appendchild(param_node, xmldom.makenode(item_elmt));
                
                    FOR j IN i_out_params(i).tbl_complications.first .. i_out_params(i).tbl_complications.last
                    LOOP
                        item_elmt := xmldom.createelement(doc, 'COMPLICATION');
                    
                        -----------------------
                        IF i_out_params(i).tbl_complications(j).id_complication IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'ID_COMPLICATION',
                                                to_char(i_out_params(i).tbl_complications(j).id_complication));
                        END IF;
                        -----------------------
                        IF i_out_params(i).tbl_complications(j).complication_description IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'COMPLICATION_DESCRIPTION',
                                                to_char(i_out_params(i).tbl_complications(j).complication_description));
                        END IF;
                        -----------------------
                        IF i_out_params(i).tbl_complications(j).complication_code IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'COMPLICATION_CODE',
                                                to_char(i_out_params(i).tbl_complications(j).complication_code));
                        END IF;
                        -----------------------
                        IF i_out_params(i).tbl_complications(j).rank IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt, 'RANK', to_char(i_out_params(i).tbl_complications(j).rank));
                        END IF;
                    
                        g_error := 'ADD COMPLICATION';
                        pk_alertlog.log_debug(object_name     => g_package,
                                              sub_object_name => l_func_name,
                                              text            => g_error);
                        complication_node := xmldom.appendchild(complications_node, xmldom.makenode(item_elmt));
                    END LOOP;
                END IF;
            
                ------------------------------------------------------------------------
                IF i_out_params(i).tbl_stagings IS NOT NULL
                    AND i_out_params(i).tbl_stagings.count > 0
                THEN
                    g_error := 'ADD STAGING ROOT NODE';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    item_elmt := xmldom.createelement(doc, 'STAGINGS');
                
                    stagings_node := xmldom.appendchild(param_node, xmldom.makenode(item_elmt));
                
                    FOR j IN i_out_params(i).tbl_stagings.first .. i_out_params(i).tbl_stagings.last
                    LOOP
                        item_elmt := xmldom.createelement(doc, 'STAGING');
                    
                        IF i_out_params(i).tbl_stagings(j).diag_staging IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'DIAG_STAGING',
                                                to_char(i_out_params(i).tbl_stagings(j).diag_staging));
                        END IF;
                    
                        IF i_out_params(i).tbl_stagings(j).diag_staging_directly_hist IS NOT NULL
                        THEN
                            xmldom.setattribute(item_elmt,
                                                'DIAG_STAGING_DIRECTLY_HIST',
                                                to_char(i_out_params(i).tbl_stagings(j).diag_staging_directly_hist));
                        END IF;
                    
                        g_error := 'ADD STAGING';
                        pk_alertlog.log_debug(object_name     => g_package,
                                              sub_object_name => l_func_name,
                                              text            => g_error);
                        staging_node := xmldom.appendchild(stagings_node, xmldom.makenode(item_elmt));
                    
                        IF i_out_params(i).tbl_stagings(j)
                         .tbl_prog_factors IS NOT NULL
                            AND i_out_params(i).tbl_stagings(j).tbl_prog_factors.count > 0
                        THEN
                            g_error := 'ADD PROG_FACTOR ROOT NODE';
                            pk_alertlog.log_debug(object_name     => g_package,
                                                  sub_object_name => l_func_name,
                                                  text            => g_error);
                            item_elmt := xmldom.createelement(doc, 'PROG_FACTORS');
                        
                            pfactors_node := xmldom.appendchild(staging_node, xmldom.makenode(item_elmt));
                        
                            FOR k IN i_out_params(i).tbl_stagings(j).tbl_prog_factors.first .. i_out_params(i).tbl_stagings(j)
                                                                                               .tbl_prog_factors.last
                            LOOP
                                item_elmt := xmldom.createelement(doc, 'PROG_FACTOR');
                            
                                IF i_out_params(i).tbl_stagings(j).tbl_prog_factors(k).prog_factor IS NOT NULL
                                THEN
                                    xmldom.setattribute(item_elmt,
                                                        'PROG_FACTOR',
                                                        to_char(i_out_params(i).tbl_stagings(j).tbl_prog_factors(k)
                                                                .prog_factor));
                                END IF;
                            
                                IF i_out_params(i).tbl_stagings(j).tbl_prog_factors(k)
                                 .prog_factor_directly_hist IS NOT NULL
                                THEN
                                    xmldom.setattribute(item_elmt,
                                                        'PROG_FACTOR_DIRECTLY_HIST',
                                                        to_char(i_out_params(i).tbl_stagings(j).tbl_prog_factors(k)
                                                                .prog_factor_directly_hist));
                                END IF;
                            
                                g_error := 'ADD PROG_FACTOR';
                                pk_alertlog.log_debug(object_name     => g_package,
                                                      sub_object_name => l_func_name,
                                                      text            => g_error);
                                pfactor_node := xmldom.appendchild(pfactors_node, xmldom.makenode(item_elmt));
                            END LOOP;
                        END IF;
                    
                    END LOOP;
                END IF;
            END LOOP;
        
            g_error := 'WRITE XML DOC TO CLOB';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            dbms_lob.createtemporary(o_out_params, TRUE);
            xmldom.writetoclob(doc, o_out_params);
            xmldom.freedocument(doc);
        
            g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
            pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
            set_nls_numeric_characters(i_prof => i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_out_parameters;

    /**
    * Encapsulates the logic of saving (create or update) a announced arrival patient
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_params                XML with all output parameters
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    *
    * <EPIS_DIAGNOSES ID_PATIENT="" ID_EPISODE="" PROF_CAT_TYPE="" FLG_TYPE="" FLG_EDIT_MODE="" ID_CDR_CALL="">
    *   <!-- 
    *   FLG_TYPE: P - Working diag; D - Final diag
    *   FLG_EDIT_MODE: Flag to diferentiate which fields are being updated
    *       S - Diagnosis Status edit
    *       T - Diagnosis Type edit
    *       N - Diagnosis screen edition (multiple values editable)
    *   --> 
    *   <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST=""  FLG_TRANSF_FINAL="" ID_CANCEL_REASON="" CANCEL_NOTES="" FLG_CANCEL_DIFF_DIAG="" >
    *     <!-- 
    *     ID_EPIS_DIAGNOSIS OR ID_EPIS_DIAGNOSIS_HIST mandatory when editing
    *     ID_EPIS_DIAGNOSIS is needed when editing the current episode diagnosis, in the case of cancer diagnosis also means editing the current staging diagnosis
    *     ID_EPIS_DIAGNOSIS_HIST is needed for cancer diagnosis when editing a past staging diagnosis
    *     --> 
    *     <!-- 
    *        In case of association only ID is needed for diagnosis
    *     --> 
    *     
    *     <DIAGNOSIS ID="" ID_ALERT_DIAG="" DESC_DIAGNOSIS="" FLG_FINAL_TYPE="" FLG_STATUS="" FLG_ADD_PROBLEM="" NOTES="" >
    *       <CHARACTERIZATION DT_INIT_DIAG="" BASIS_DIAG_MS="" BASIS_DIAG_SPEC= "" NUM_PRIM_TUMORS_MS_YN="" NUM_PRIM_TUMORS_NUM="" RECURRENCE="" />
    *       <!-- 
    *       DESC_DIAGNOSIS only available when creating a new diagnosis
    *       ID_ALERT_DIAG only necessary when creating
    *       -->
    *       <TUMORS>
    *         <TUMOR NUM="" TOPOGRAPHY="" LATERALITY="" HISTOLOGY="" BEHAVIOR="" HISTOLOGIC_GRADE="" OTHER_GRADING_SYSTEM=""
    *              PRIMARY_TUMOR_SIZE_UNKNOWN="" PRIMARY_TUMOR_SIZE_NUMERIC="" PRIMARY_TUMOR_SIZE_DESCRIPTIVE="" ADDITIONAL_PATH_INFO="" />
    *       </TUMORS>
    *       <STAGING NUM_STAGING_BASIS="" STAGING_BASIS="" TNM_T="" CODE_STAGE_T="" TNM_N="" CODE_STAGE_N="" TNM_M="" CODE_STAGE_M="" METASTATIC_SITES="" STAGE_GROUP="" RESIDUAL_TUMOR="" SURGICAL_MARGINS="" LYMPH_VASCULAR_INVASION="" OTHER_STAGING_SYSTEM="">
    *         <PROG_FACTORS>
    *           <PROG_FACTOR ID_LABEL="" LABEL_RANK="" ID_VALUE="" FT=""  />
    *         </PROG_FACTORS>
    *       </STAGING>
    *     </DIAGNOSIS>
    *     <!--
    *     FLG_CANCEL_DIFF_DIAG: Flag that indicates if differencial diagnoses should also be cancelled (This flag is only necessary when cancelling a final diagnosis)
    *     -->
    *   </EPIS_DIAGNOSIS>
    *   <GENERAL_NOTES ID="" VALUE="" ID_CANCEL_REASON="" />
    *   <!--
    *   ID: is equal to ID_EPIS_DIAGNOSIS_NOTES, this is only used when editing the general note
    *   ID_CANCEL_REASON: Only mandatory when cancelling the general notes
    *   -->
    * </EPIS_DIAGNOSES>
    *
    * @example o_params                Example of the possible XML passed in this variable
    *
    * <OUT_PARAMS>
    *   <OUT_PARAM ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" DATE_RECORD="" HOUR_RECORD="" PROBLEM_MSG="" PROBLEM_MSG_TITLE="" PROBLEM_FLG_SHOW="" PROBLEM_BUTTON="">
    *   <TUMORS>
    *     <TUMOR TUMOR_NUM="" TUMOR_NUMOR_DIRECTLY_HIST="" />
    *   </TUMORS>
    *   <STAGINGS>
    *     <STAGING DIAG_STAGING="" DIAG_STAGING_DIRECTLY_HIST="">
    *       <PROG_FACTORS>
    *         <PROG_FACTOR PROG_FACTOR="" PROG_FACTOR_DIRECTLY_HIST="" />
    *       </PROG_FACTORS>
    *     </STAGING>
    *   </STAGINGS>
    *   </OUT_PARAM>
    * </OUT_PARAMS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Sergio Dias
    * @version 1.0
    * @since   14/Fev/2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_params OUT CLOB,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_EPIS_DIAGNOSIS';
        --
        l_epis_diagnoses pk_edis_types.rec_in_epis_diagnoses;
        l_out_params     pk_edis_types.table_out_epis_diags;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_PARAMETERS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_params,
                                                     o_rec_in_epis_diagnoses => l_epis_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL PK_DIAGNOSIS_CORE.SET_EPIS_DIAGNOSIS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => l_epis_diagnoses,
                                                    o_params         => l_out_params,
                                                    o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'TRANSFORM OUT_PARAMS INTO XML FORMAT';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_diagnosis_form.get_out_parameters(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_out_params => l_out_params,
                                                    o_out_params => o_params,
                                                    o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_diagnosis;

    /********************************************************************************
    ********************************************************************************/
    FUNCTION set_confirmed_epis_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_params            IN CLOB,
        o_id_epis_diagnosis OUT table_number,
        o_id_diagnosis      OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_CONFIRMED_EPIS_DIAGNOSIS';
        --
        l_epis_diagnoses     pk_edis_types.rec_in_epis_diagnoses;
        l_out_params         pk_edis_types.table_out_epis_diags;
        l_rec_epis_diagnosis pk_edis_types.rec_epis_diagnosis;
        --
        l_exception EXCEPTION;
    BEGIN
        o_id_epis_diagnosis := table_number();
        o_id_diagnosis      := table_number();
    
        -----------------------------------------------------
        g_error := 'CALL GET_PARAMETERS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_diagnosis_form.get_save_parameters(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_params                => i_params,
                                                     o_rec_in_epis_diagnoses => l_epis_diagnoses,
                                                     o_error                 => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -- set diagnosis to "F" = confirmed
        FOR i IN l_epis_diagnoses.epis_diagnosis.tbl_diagnosis.first .. l_epis_diagnoses.epis_diagnosis.tbl_diagnosis.last
        LOOP
            l_epis_diagnoses.epis_diagnosis.tbl_diagnosis(i).flg_status := 'F';
        END LOOP;
    
        -----------------------------------------------------    
        g_error := 'CALL PK_DIAGNOSIS_CORE.SET_EPIS_DIAGNOSIS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_epis_diagnoses => l_epis_diagnoses,
                                                    o_params         => l_out_params,
                                                    o_error          => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -----------------------------------------------------
        IF l_out_params.exists(1)
        THEN
            FOR i IN l_out_params.first .. l_out_params.last
            LOOP
                l_rec_epis_diagnosis := pk_diagnosis_core.get_epis_diag(i_lang           => i_lang,
                                                                        i_prof           => i_prof,
                                                                        i_episode        => l_epis_diagnoses.general_notes.id_episode,
                                                                        i_epis_diag      => l_out_params(i).id_epis_diagnosis,
                                                                        i_epis_diag_hist => l_out_params(i).id_epis_diagnosis_hist);
            
                o_id_epis_diagnosis.extend;
                o_id_epis_diagnosis(o_id_epis_diagnosis.last) := l_out_params(i).id_epis_diagnosis;
            
                o_id_diagnosis.extend;
                o_id_diagnosis(o_id_diagnosis.last) := l_rec_epis_diagnosis.id_diagnosis;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_confirmed_epis_diagnosis;

    --
    /**
    * Gets the patient age on the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_when                      Date on which you want to know the patient's age
    *
    * @return  Patient age on the given date
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_when    IN patient.dt_deceased%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PAT_AGE';
        --
        l_dates_diff PLS_INTEGER;
        l_pat_age    PLS_INTEGER;
        --
        l_pat_age_chr VARCHAR2(50 CHAR);
    BEGIN
        g_error := 'GET PATIENT AGE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_pat_age := pk_patient.get_pat_age(i_lang => i_lang, i_dt_birth => NULL, i_age => NULL, i_patient => i_patient);
    
        IF i_when IS NOT NULL
           AND l_pat_age IS NOT NULL
        THEN
            g_error := 'CALCULATE YEARS DIFF';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            l_dates_diff := trunc(months_between(current_timestamp, i_when) / 12);
        
            l_pat_age_chr := l_pat_age - l_dates_diff;
        ELSE
            l_pat_age_chr := NULL;
        END IF;
    
        RETURN l_pat_age_chr;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_age;
    --
    /**
    * Gets the patient age on the given date
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient id
    * @param   i_when                      Date on which you want to know the patient's age
    * @param   o_pat_age                   Patient age on the given date
    * @param   o_error                     Error information
    *
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.2.1
    * @since   28-03-2012
    */
    FUNCTION get_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_when    IN VARCHAR2,
        o_pat_age OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PAT_AGE';
    BEGIN
        o_pat_age := get_pat_age(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_patient => i_patient,
                                 i_when    => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                            i_prof      => i_prof,
                                                                            i_timestamp => i_when,
                                                                            i_timezone  => NULL));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_age;
    --
    /**
    * Check if any of the selected diagnoses were registered in a past episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_params                    Group of parameters
    * @param   o_title                     Confirmation title
    * @param   o_msg                       Confirmation message
    * @param   o_diags                     Diagnoses info
    * @param   o_error                     Error information
    *
    * @example i_params                    Example of the XML passed in this variable
    *
    * <PARAMETERS ID_PATIENT="" ID_EPISODE="">
    *   <DIAGNOSIS ID_DIAGNOSIS="" ID_ALERT_DIAGNOSIS=""/>
    * </PARAMETERS>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   26-06-2012
    */
    FUNCTION check_diag_already_reg
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN CLOB,
        o_title  OUT VARCHAR2,
        o_msg    OUT VARCHAR2,
        o_diags  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_DIAG_ALREADY_REG';
        --
        l_code_title CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M041';
        l_code_msg   CONSTANT sys_message.code_message%TYPE := 'DIAGNOSIS_M042';
        --
        l_parameter      pk_edis_types.rec_chk_diag_alredy_reg;
        l_diag           pk_edis_types.rec_diagnosis;
        l_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
        --
        l_tbl_diag       table_number := table_number();
        l_tbl_alert_diag table_number := table_number();
        l_tbl_flg_show   table_varchar := table_varchar();
        --
        l_exception EXCEPTION;
        --
        FUNCTION get_parameters RETURN pk_edis_types.rec_chk_diag_alredy_reg IS
            l_inner_func_name CONSTANT VARCHAR2(30) := 'GET_PARAMETERS';
            --
            CURSOR c_parameters IS(
                SELECT a.id_patient, a.id_episode, extract(b.params, '/PARAMETERS/DIAGNOSIS') diagnosis
                  FROM (SELECT VALUE(p) params
                          FROM TABLE(xmlsequence(extract(xmltype(i_params), '/PARAMETERS'))) p) b,
                       xmltable('/PARAMETERS' passing b.params columns --
                                "ID_EPISODE" NUMBER(24) path '@ID_EPISODE', --
                                "ID_PATIENT" NUMBER(24) path '@ID_PATIENT') a);
        
            CURSOR c_diagnosis(i_diagnosis IN xmltype) IS(
                SELECT a.id_diagnosis, a.id_alert_diagnosis
                  FROM (SELECT VALUE(p) diagnosis
                          FROM TABLE(xmlsequence(extract(i_diagnosis, '/DIAGNOSIS'))) p) b,
                       xmltable('/DIAGNOSIS' passing b.diagnosis columns --
                                "ID_DIAGNOSIS" NUMBER(24) path '@ID_DIAGNOSIS', --
                                "ID_ALERT_DIAGNOSIS" NUMBER(24) path '@ID_ALERT_DIAG' --
                                ) a);
            --
            r_parameter c_parameters%ROWTYPE;
            l_ret       pk_edis_types.rec_chk_diag_alredy_reg;
        BEGIN
            IF i_params IS NOT NULL
            THEN
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error := 'OPEN INPUT PARAMETERS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                OPEN c_parameters;
            
                g_error := 'FETCH DATA';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                FETCH c_parameters
                    INTO r_parameter;
            
                IF c_parameters%NOTFOUND
                THEN
                    g_error := 'MISSING INPUT PARAMETERS';
                    pk_alertlog.log_error(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    RAISE l_exception;
                END IF;
            
                g_error := 'CLOSE CURSOR';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                CLOSE c_parameters;
            
                g_error := 'OPEN INPUT PARAMETERS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                OPEN c_diagnosis(i_diagnosis => r_parameter.diagnosis);
            
                g_error := 'EXTRACT DS_COMPONENTS';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                FETCH c_diagnosis BULK COLLECT
                    INTO l_ret.tbl_diagnoses;
            
                g_error := 'CLOSE CURSOR';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                CLOSE c_diagnosis;
            
                g_error := 'CALL SET_NLS_NUMERIC_CHARACTERS TO RESET';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                set_nls_numeric_characters(i_prof => i_prof);
            
                g_error := 'FILL RETURN VALUE';
                pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_inner_func_name, text => g_error);
                l_ret.id_patient := r_parameter.id_patient;
                l_ret.id_episode := r_parameter.id_episode;
            END IF;
        
            RETURN l_ret;
        END get_parameters;
    BEGIN
        g_error := 'EXTRACT PARAMETERS FROM I_PARAMS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        l_parameter := get_parameters();
    
        g_error := 'ADD ITEMS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF l_parameter.tbl_diagnoses IS NOT NULL
           AND l_parameter.tbl_diagnoses.count > 0
        THEN
            FOR i IN l_parameter.tbl_diagnoses.first .. l_parameter.tbl_diagnoses.last
            LOOP
                l_diag := l_parameter.tbl_diagnoses(i);
            
                g_error := 'CALL PK_DIAGNOSIS_CORE.CHECK_DIAG_CANCER';
                pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
                IF pk_diagnosis_core.check_diag_cancer(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_concept_type => NULL,
                                                       i_diagnosis    => l_diag.id_diagnosis) = pk_alert_constant.g_yes
                THEN
                    g_error := 'CALL PK_DIAGNOSIS_FORM.GET_CANCER_DIAG_ALREADY_REG';
                    pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
                    l_epis_diagnosis := pk_diagnosis_form.get_cancer_diag_already_reg(i_lang            => i_lang,
                                                                                      i_prof            => i_prof,
                                                                                      i_patient         => l_parameter.id_patient,
                                                                                      i_episode         => l_parameter.id_episode,
                                                                                      i_diagnosis       => l_diag.id_diagnosis,
                                                                                      i_alert_diagnosis => l_diag.id_alert_diagnosis);
                ELSE
                    l_epis_diagnosis := NULL;
                END IF;
            
                l_tbl_diag.extend;
                l_tbl_diag(l_tbl_diag.count) := l_diag.id_diagnosis;
            
                l_tbl_alert_diag.extend;
                l_tbl_alert_diag(l_tbl_alert_diag.count) := l_diag.id_alert_diagnosis;
            
                l_tbl_flg_show.extend;
                IF l_epis_diagnosis IS NOT NULL
                THEN
                    l_tbl_flg_show(l_tbl_flg_show.count) := pk_alert_constant.g_yes;
                ELSE
                    l_tbl_flg_show(l_tbl_flg_show.count) := pk_alert_constant.g_no;
                END IF;
            END LOOP;
        END IF;
    
        OPEN o_diags FOR
            SELECT d.id_diagnosis,
                   ad.id_alert_diagnosis,
                   fs.flg_show,
                   (SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => adg.id_alert_diagnosis,
                                                      i_id_diagnosis        => dg.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => dg.code_icd,
                                                      i_flg_other           => dg.flg_other,
                                                      i_flg_std_diag        => adg.flg_icd9,
                                                      i_epis_diag           => ed.id_epis_diagnosis,
                                                      i_show_aditional_info => pk_alert_constant.g_no)
                      FROM diagnosis dg
                      JOIN alert_diagnosis adg
                        ON adg.id_diagnosis = dg.id_diagnosis
                      LEFT JOIN epis_diagnosis ed
                        ON ed.id_epis_diagnosis = l_epis_diagnosis
                       AND ed.id_diagnosis = dg.id_diagnosis
                       AND ed.id_alert_diagnosis = adg.id_alert_diagnosis
                     WHERE dg.id_diagnosis = d.id_diagnosis
                       AND adg.id_alert_diagnosis = ad.id_alert_diagnosis) desc_diagnosis
              FROM (SELECT column_value id_diagnosis, rownum num
                      FROM TABLE(l_tbl_diag)) d
              JOIN (SELECT column_value id_alert_diagnosis, rownum num
                      FROM TABLE(l_tbl_alert_diag)) ad
                ON ad.num = d.num
              JOIN (SELECT column_value flg_show, rownum num
                      FROM TABLE(l_tbl_flg_show)) fs
                ON fs.num = ad.num;
    
        o_title := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_title);
    
        o_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_cursor_if_closed(o_diags);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(o_diags);
            RETURN FALSE;
    END check_diag_already_reg;
    --
    /**
    * Get cancer diagnosis already registered in a past episode
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_patient                   Patient ID
    * @param   i_episode                   Episode ID
    * @param   i_diagnosis                 Diagnosis ID
    * @param   i_alert_diagnosis           Alert Diagnoses ID
    *
    * @return  id_epis_diagnosis of the past episode
    *
    * @author  Alexandre Santos
    * @version v2.6
    * @since   10-07-2012
    */
    FUNCTION get_cancer_diag_already_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_epis_diagnosis%TYPE IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_CANCER_DIAG_ALREADY_REG';
        --
        l_cancer_epis_diag_alr_reg epis_diagnosis.id_epis_diagnosis%TYPE := NULL; -- Cancer diagnosis that was already register in a previous episode
    BEGIN
        g_error := 'OPEN PK_DIAGNOSIS_FORM.C_CANCER_DIAG_ALREADY_REG';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        OPEN pk_diagnosis_form.c_cancer_diag_already_reg(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_patient         => i_patient,
                                                         i_episode         => i_episode,
                                                         i_diagnosis       => i_diagnosis,
                                                         i_alert_diagnosis => i_alert_diagnosis);
    
        g_error := 'FETCH CURSOR INTO L_EPIS_DIAGNOSIS';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        FETCH pk_diagnosis_form.c_cancer_diag_already_reg
            INTO l_cancer_epis_diag_alr_reg;
    
        g_error := 'CLOSE CURSOR';
        pk_alertlog.log_debug(object_name => g_package, sub_object_name => l_func_name, text => g_error);
        CLOSE pk_diagnosis_form.c_cancer_diag_already_reg;
    
        RETURN l_cancer_epis_diag_alr_reg;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_owner,
                                                  g_package,
                                                  l_func_name,
                                                  l_error);
            END;
        
            RETURN NULL;
    END get_cancer_diag_already_reg;

    /********************************************************************************************
    * Function that returns the the place of occurence of the diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Diagnosis ID
    * @param i_diag_type              Concept type DEFAULT DIAGNOSIS
    * @param i_id_location            Place of occurence ID
    * @param i_show_code              if the code Should be shown (Default Y)
     *
    * @return                         diagnosis general info
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          16/11/2016
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_diag_type   IN diagnosis.concept_type_int_name%TYPE DEFAULT g_cncpt_type_diag,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        i_show_code   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_location FOR
            SELECT t.id_location, t.desc_location, t.flg_default, t.rank
              FROM (SELECT id_concept_term id_location,
                           htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => id_concept_term,
                                                                    i_id_diagnosis       => id_concept_version,
                                                                    i_code_diagnosis     => code_diagnosis,
                                                                    i_diagnosis_language => id_language,
                                                                    i_code               => NULL,
                                                                    i_flg_other          => flg_other,
                                                                    i_flg_std_diag       => flg_icd9,
                                                                    i_flg_search_mode    => pk_alert_constant.g_yes)) desc_location,
                           rank,
                           CASE
                                WHEN i_id_location IS NULL THEN
                                 flg_default
                                ELSE
                                 decode(i_id_location, id_concept_term, pk_alert_constant.g_yes, pk_alert_constant.g_no)
                            END flg_default
                      FROM (SELECT DISTINCT d.id_concept_term,
                                            d.id_concept_version,
                                            d.code_diagnosis,
                                            d.id_language,
                                            d.concept_code,
                                            d.flg_other,
                                            d.flg_icd9,
                                            dr.rank,
                                            dr.flg_default
                              FROM diagnosis_relations_ea dr
                              JOIN diagnosis_ea d
                                ON d.id_concept_version = dr.id_concept_version_1
                             WHERE dr.concept_type_int_name1 = g_lesion_location_type
                               AND dr.id_concept_version_2 = i_diagnosis
                               AND dr.cncpt_rel_type_int_name = g_rel_depends_on
                               AND dr.concept_type_int_name2 = i_diag_type
                               AND dr.id_institution = i_prof.institution
                               AND dr.id_software = i_prof.software
                               AND d.id_institution = i_prof.institution
                               AND d.id_software = i_prof.software)) t
             ORDER BY t.rank, t.desc_location;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PLACE_OF_OCCURENCE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_location);
            RETURN FALSE;
        
    END get_place_of_occurence;

    /********************************************************************************************
    * Function that returns the the places of occurence of the diagnoses
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Collection of diagnoses IDs
    * @param i_id_location            Collection of places of occurence (IDs already registered)
    *
    * @return                         Places of occurence
    *
    * Note: This function will return the locations that are common to all the input diagnoses.
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_diag_type   IN diagnosis.concept_type_int_name%TYPE DEFAULT g_cncpt_type_diag,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diangosis_count NUMBER := 0;
    
    BEGIN
    
        l_diangosis_count := i_diagnosis.count();
    
        OPEN o_location FOR
            SELECT t.id_location, t.desc_location, t.flg_default, t.rank
              FROM (SELECT id_concept_term id_location,
                           htf.escape_sc(pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                                    i_prof               => i_prof,
                                                                    i_id_alert_diagnosis => id_concept_term,
                                                                    i_id_diagnosis       => id_concept_version,
                                                                    i_code_diagnosis     => code_diagnosis,
                                                                    i_diagnosis_language => id_language,
                                                                    i_code               => NULL,
                                                                    i_flg_other          => flg_other,
                                                                    i_flg_std_diag       => flg_icd9,
                                                                    i_flg_search_mode    => pk_alert_constant.g_yes)) desc_location,
                           rank,
                           CASE
                                WHEN id_alert_diagnosis IS NULL THEN
                                 flg_default
                                ELSE
                                 decode(id_alert_diagnosis,
                                        id_concept_term,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_no)
                            END flg_default
                      FROM (SELECT DISTINCT d.id_concept_term,
                                            d.id_concept_version,
                                            d.code_diagnosis,
                                            d.id_language,
                                            d.concept_code,
                                            d.flg_other,
                                            d.flg_icd9,
                                            dr.rank,
                                            dr.flg_default,
                                            tl.column_value AS id_alert_diagnosis
                              FROM diagnosis_relations_ea dr
                              JOIN (SELECT dr_1.id_concept_version_1, MIN(dr_1.rank) AS rank
                                     FROM diagnosis_relations_ea dr_1
                                    WHERE dr_1.id_concept_version_2 IN
                                          (SELECT /*+opt_estimate(table td rows=1)*/
                                            *
                                             FROM TABLE(i_diagnosis) td)
                                      AND dr_1.concept_type_int_name1 = g_lesion_location_type
                                      AND dr_1.cncpt_rel_type_int_name = g_rel_depends_on
                                      AND dr_1.concept_type_int_name2 = i_diag_type
                                      AND dr_1.id_institution = i_prof.institution
                                      AND dr_1.id_software = i_prof.software
                                      AND EXISTS (SELECT 1
                                             FROM diagnosis_ea d
                                            WHERE d.id_concept_version = dr_1.id_concept_version_1
                                              AND d.id_institution = i_prof.institution
                                              AND d.id_software = i_prof.software)
                                      AND EXISTS (SELECT dr_2.id_concept_version_1, COUNT(1)
                                             FROM diagnosis_relations_ea dr_2
                                            WHERE dr_2.id_concept_version_1 = dr_1.id_concept_version_1
                                              AND dr_2.id_concept_version_2 IN
                                                  (SELECT /*+opt_estimate(table td rows=1)*/
                                                    *
                                                     FROM TABLE(i_diagnosis) td)
                                              AND dr_2.concept_type_int_name1 = dr_1.concept_type_int_name1
                                              AND dr_2.cncpt_rel_type_int_name = dr_1.cncpt_rel_type_int_name
                                              AND dr_2.concept_type_int_name2 = dr_1.concept_type_int_name2
                                              AND dr_2.id_institution = dr_1.id_institution
                                              AND dr_2.id_software = dr_1.id_software
                                            GROUP BY dr_2.id_concept_version_1
                                           HAVING COUNT(1) > = l_diangosis_count)
                                    GROUP BY dr_1.id_concept_version_1) dr_t
                                ON dr_t.id_concept_version_1 = dr.id_concept_version_1
                               AND dr_t.rank = dr.rank
                              JOIN diagnosis_ea d
                                ON d.id_concept_version = dr.id_concept_version_1
                              LEFT JOIN TABLE(i_id_location) tl
                                ON tl.column_value = d.id_concept_term
                             WHERE dr.concept_type_int_name1 = g_lesion_location_type
                               AND dr.cncpt_rel_type_int_name = g_rel_depends_on
                               AND dr.concept_type_int_name2 = i_diag_type
                               AND dr.id_institution = i_prof.institution
                               AND dr.id_software = i_prof.software
                               AND d.id_institution = i_prof.institution
                               AND d.id_software = i_prof.software)) t
             ORDER BY t.rank, t.desc_location;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PLACE_OF_OCCURENCE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_location);
            RETURN FALSE;
        
    END get_place_of_occurence;

    /********************************************************************************************
    * Function that returns the list of mandatory components of the selected diagnoses
    * (used for multiple selection)
    *    
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_patient             Patient ID
    * @param i_id_episode             Episode ID
    * @param i_id_diagnosis           List of diagnoses IDs
    * @param i_id_alert_diagnosis     List of alert diagnoses IDs
    * @param i_desc_diagnosis         List of diagnoses descriptions
    * @param i_flg_type               List of type of each diagnosis (P-Working diagnosis/D-Discharge diagnosis)
    *
    * @return                         List of mandatory sections of the selected diagnoses
    *
    *
    * @author                         Diogo Oliveira
    * @version                        2.7.4.0
    * @since                          14/05/2018
    **********************************************************************************************/
    FUNCTION get_mandatory_sections
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        i_desc_diagnosis     IN table_varchar,
        i_flg_type           IN table_varchar,
        o_mandatory_sections OUT t_tbl_diag_mandatory_sections,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'GET_MANDATORY_SECTIONS';
    
        l_parameter              CLOB := '';
        l_tbl_parameters         table_clob := table_clob();
        l_parsed_parameter       pk_edis_types.rec_diag_section_data_param;
        l_section                t_table_ds_sections;
        l_def_events             t_table_ds_def_events;
        l_events                 t_table_ds_events;
        l_items_values           t_table_ds_items_values;
        l_data_val               xmltype;
        l_tbl_mandatory_sections t_tbl_diag_mandatory_sections := t_tbl_diag_mandatory_sections();
        l_mandatory_sections     sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'MANDATORY_DIAGNOSIS_COMPONENTS',
                                                                                  i_prof    => i_prof);
        l_tbl_mandatory_section  table_varchar;
    
        l_exception EXCEPTION;
    
        PROCEDURE construct_xml
        (
            i_id_episode         IN episode.id_episode%TYPE,
            i_id_patient         IN patient.id_patient%TYPE,
            i_internal_name      IN VARCHAR2,
            i_flg_component_type IN VARCHAR2,
            i_flg_type           IN VARCHAR2,
            i_id_diagnosis       IN diagnosis_ea.id_concept_version%TYPE,
            i_id_alert_diagnosis IN diagnosis_ea.id_concept_term%TYPE,
            i_desc_diagnosis     IN VARCHAR2,
            o_param              OUT CLOB
        ) IS
        BEGIN
            o_param := '<PARAMETERS FLG_EDIT_MODE="D" ID_EPISODE="' || i_id_episode || '" ID_PATIENT="' || i_id_patient || '">
                          <DS_COMPONENT FLG_COMPONENT_TYPE="' || i_flg_component_type ||
                       '" INTERNAL_NAME="' || i_internal_name ||
                       '" />
                          <DIAGNOSIS FLG_REUSE_PAST_DIAG="N" DESC_DIAGNOSIS="' ||
                       i_desc_diagnosis || '" ID_ALERT_DIAG="' || i_id_alert_diagnosis || '" FLG_TYPE="' || i_flg_type ||
                       '" ID_DIAGNOSIS="' || i_id_diagnosis || '" />
                        </PARAMETERS>';
        END construct_xml;
    
    BEGIN
        --OBTAIN THE LIST OF COMPONENTS TO BE CHECKED (SYS_CONFIG: MANDATORY_DIAGNOSIS_COMPONENTS)
        l_tbl_mandatory_section := pk_string_utils.str_split(i_list => l_mandatory_sections, i_delim => '|');
    
        IF l_tbl_mandatory_section.exists(1)
        THEN
            IF l_tbl_mandatory_section(1) IS NOT NULL
            THEN
                IF i_id_alert_diagnosis.exists(1)
                THEN
                    --CHECK IF THE GIVEN DIAGNOSES PRESENT THE COMPONENTS FROM THE SYS_CONFIG
                    FOR i IN i_id_alert_diagnosis.first .. i_id_alert_diagnosis.last
                    LOOP
                        DECLARE
                            l_ds_component     ds_component.internal_name%TYPE;
                            l_ds_comp_type     ds_component.flg_component_type%TYPE;
                            l_tbl_ds_component table_varchar := table_varchar();
                            l_tbl_ds_comp_type table_varchar := table_varchar();
                        BEGIN
                            IF NOT get_root_ds_comp(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_diagnosis    => i_id_diagnosis(i),
                                                    o_ds_component => l_ds_component,
                                                    o_ds_comp_type => l_ds_comp_type,
                                                    o_error        => o_error)
                            THEN
                                CONTINUE;
                            END IF;
                        
                            SELECT a.internal_name, a.flg_component_type
                              BULK COLLECT
                              INTO l_tbl_ds_component, l_tbl_ds_comp_type
                              FROM TABLE(pk_dynamic_screen.tf_ds_sections(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_component_name => l_ds_component,
                                                                          i_component_type => l_ds_comp_type,
                                                                          i_component_list => 'N',
                                                                          i_patient        => i_id_patient)) a
                             WHERE a.internal_name IN (SELECT /*+opt_estimate(table t1 rows=1)*/
                                                        t1.column_value
                                                         FROM TABLE(l_tbl_mandatory_section) t1);
                        
                            --IF THE COMPONENT IS PRESENT ON THE DIAGNOSIS => CONSTRUCT THE XML
                            IF l_tbl_ds_component.count > 0
                            THEN
                                FOR j IN l_tbl_ds_component.first .. l_tbl_ds_component.last
                                LOOP
                                    construct_xml(i_id_episode         => i_id_episode,
                                                  i_id_patient         => i_id_patient,
                                                  i_internal_name      => l_tbl_ds_component(j),
                                                  i_flg_component_type => l_tbl_ds_comp_type(j),
                                                  i_flg_type           => i_flg_type(i),
                                                  i_id_diagnosis       => i_id_diagnosis(i),
                                                  i_id_alert_diagnosis => i_id_alert_diagnosis(i),
                                                  i_desc_diagnosis     => i_desc_diagnosis(i),
                                                  o_param              => l_parameter);
                                
                                    l_tbl_parameters.extend();
                                    l_tbl_parameters(l_tbl_parameters.count) := l_parameter;
                                    l_parameter := '';
                                END LOOP;
                            END IF;
                        EXCEPTION
                            WHEN no_data_found THEN
                                CONTINUE;
                        END;
                    END LOOP;
                    --CHECK IF THOSE COMPONENTS ARE CONFIGURED AS MANDATORY            
                    IF l_tbl_parameters.exists(1)
                    THEN
                        FOR i IN l_tbl_parameters.first .. l_tbl_parameters.last
                        LOOP
                            l_parameter := l_tbl_parameters(i);
                            IF NOT pk_diagnosis_form.parse_val_fill_sect_param(i_lang   => i_lang,
                                                                               i_prof   => i_prof,
                                                                               i_params => l_parameter,
                                                                               o_params => l_parsed_parameter,
                                                                               o_error  => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            IF NOT pk_diagnosis_form.get_section_data_db(i_lang         => i_lang,
                                                                         i_prof         => i_prof,
                                                                         i_params       => l_parsed_parameter,
                                                                         o_section      => l_section,
                                                                         o_def_events   => l_def_events,
                                                                         o_events       => l_events,
                                                                         o_items_values => l_items_values,
                                                                         o_data_val     => l_data_val,
                                                                         o_error        => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            IF l_def_events.exists(1)
                            THEN
                                FOR j IN l_def_events.first .. l_def_events.last
                                LOOP
                                    IF l_def_events(j).flg_event_type = 'M'
                                    THEN
                                        l_tbl_mandatory_sections.extend;
                                        l_tbl_mandatory_sections(l_tbl_mandatory_sections.count) := t_ds_diag_mandatory_section(l_parsed_parameter.id_diagnosis,
                                                                                                                                l_parsed_parameter.id_alert_diagnosis,
                                                                                                                                l_def_events(j)
                                                                                                                                .id_ds_cmpt_mkt_rel);
                                    
                                    END IF;
                                END LOOP;
                            END IF;
                        END LOOP;
                    
                        o_mandatory_sections := l_tbl_mandatory_sections;
                    
                        RETURN TRUE;
                    END IF;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_mandatory_sections;

BEGIN
    -- Initialization
    g_sysdate_tstz := current_timestamp;

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_diagnosis_form;
/
