/*-- Last Change Revision: $Rev: 1877820 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2018-11-14 12:21:09 +0000 (qua, 14 nov 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_documentation AS

    /**************************************************************************
    * Updates documentation values associated with an area (doc_area)            *
    * of a template (doc_template).                                           *
    * Allows for new, edit and agree epis documentation.                      *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_flg_show                   Flag to show warn message           *
    * @param o_msg                        Message to be displayde in popup    *
    * @param o_msg_title                  Title do message window             *
    * @param o_button                     Type of button on popup msg         *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/09/07                              *
    **************************************************************************/
    FUNCTION manage_epis_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_epis_oris     IN episode.id_episode%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        i_flg_val_group IN sr_surgery_validation.flg_group%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE r_val_rec IS RECORD(
            internal_name sr_surgery_validation.internal_name%TYPE,
            VALUE         sr_surgery_validation.value%TYPE,
            target_table  sr_surgery_validation.target_table%TYPE,
            target_column sr_surgery_validation.target_column%TYPE,
            where_clause  sr_surgery_validation.where_clause%TYPE,
            id_doc_area   sr_surgery_validation.id_doc_area%TYPE);
    
        TYPE r_val_tab IS TABLE OF r_val_rec INDEX BY sr_surgery_validation.internal_name%TYPE;
        TYPE r_doc_area_tab IS TABLE OF table_varchar INDEX BY PLS_INTEGER;
    
        l_val_tab            r_val_tab;
        l_val_rec            r_val_rec;
        l_doc_area_tab       r_doc_area_tab;
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_element_values     pk_types.cursor_type;
        l_internal_names     pk_types.cursor_type;
        r_doc                pk_touch_option.t_coll_last_elem_val;
    
        l_export_in   table_varchar := table_varchar();
        l_sql_instr   VARCHAR2(32767);
        l_rows_out    table_varchar := table_varchar();
        l_aux_msg     VARCHAR2(32767);
        l_aux_tv      table_varchar;
        l_str_value   VARCHAR(30);
        l_count       NUMBER := 1;
        l_doc_count   NUMBER := 1;
        l_finish_proc BOOLEAN := FALSE;
    
        l_aux_ide doc_element.id_doc_element%TYPE;
        l_aux_in  VARCHAR2(32767);
        l_aux_ft  doc_element.flg_type%TYPE;
        l_aux_de  pk_translation.t_desc_translation;
        l_aux_dev pk_translation.t_desc_translation;
        l_aux_v   epis_documentation_det.value%TYPE;
        l_aux_vp  epis_documentation_det.value_properties%TYPE;
        l_aux_fv  VARCHAR2(32767);
    
        CURSOR c_crit IS
            SELECT internal_name, VALUE, target_table, target_column, where_clause, flg_type, id_doc_area
              FROM (SELECT sv.internal_name,
                           sv.value,
                           sv.target_table,
                           sv.target_column,
                           sv.where_clause,
                           sv.flg_type,
                           sv.id_doc_area,
                           rank() over(PARTITION BY sv.internal_name ORDER BY sv.id_institution DESC, sv.id_software DESC) origin_rank
                      FROM sr_surgery_validation sv
                     WHERE sv.flg_group = i_flg_val_group
                       AND sv.flg_available = pk_alert_constant.g_yes
                       AND sv.id_institution IN (0, i_prof.institution)
                       AND sv.id_software IN (0, i_prof.software)
                       AND (instr(sv.flg_type, g_flg_type_exp) > 0 OR instr(sv.flg_type, g_flg_type_chk) > 0))
             WHERE origin_rank = 1;
    
        FUNCTION remove_value
        (
            i_aux_in  IN doc_element.internal_name%TYPE,
            i_val_tab IN OUT r_val_tab
        ) RETURN table_varchar IS
            l_return table_varchar := table_varchar();
            l_val_1  r_val_rec;
            l_val_2  r_val_rec;
            l_i_key  sr_surgery_validation.internal_name%TYPE;
        BEGIN
            l_i_key := i_val_tab.first;
            l_val_2 := i_val_tab(i_aux_in);
            WHILE l_i_key IS NOT NULL
            LOOP
                l_val_1 := i_val_tab(l_i_key);
                IF (l_i_key != i_aux_in AND
                   l_val_1.target_table || l_val_1.target_column != l_val_2.target_table || l_val_2.target_column)
                THEN
                    l_return.extend;
                    l_return(l_return.count) := l_i_key;
                ELSIF l_i_key != i_aux_in
                THEN
                    i_val_tab.delete(l_i_key);
                END IF;
                l_i_key := i_val_tab.next(l_i_key);
            END LOOP;
        
            RETURN l_return;
        END remove_value;
    
        PROCEDURE init_vars
        (
            i_aux_ide IN OUT doc_element.id_doc_element%TYPE,
            i_aux_in  IN OUT doc_element.internal_name%TYPE,
            i_aux_ft  IN OUT doc_element.flg_type%TYPE,
            i_aux_de  IN OUT pk_translation.t_desc_translation,
            i_aux_dev IN OUT pk_translation.t_desc_translation,
            i_aux_v   IN OUT epis_documentation_det.value%TYPE,
            i_aux_vp  IN OUT epis_documentation_det.value_properties%TYPE,
            i_aux_fv  IN OUT VARCHAR2
        ) IS
        BEGIN
            i_aux_ide := NULL;
            i_aux_in  := NULL;
            i_aux_ft  := NULL;
            i_aux_de  := NULL;
            i_aux_dev := NULL;
            i_aux_v   := NULL;
            i_aux_vp  := NULL;
            i_aux_fv  := NULL;
        END init_vars;
    
    BEGIN
    
        g_error := 'Process c_crit';
        pk_alertlog.log_debug(g_error);
        FOR r_crit IN c_crit
        LOOP
            IF (instr(r_crit.flg_type, g_flg_type_exp) > 0)
            THEN
                l_val_rec               := NULL;
                l_val_rec.internal_name := r_crit.internal_name;
                l_val_rec.value         := r_crit.value;
                l_val_rec.target_table  := r_crit.target_table;
                l_val_rec.target_column := r_crit.target_column;
                l_val_rec.where_clause  := r_crit.where_clause;
                l_val_rec.id_doc_area   := r_crit.id_doc_area;
            
                l_export_in.extend;
                l_export_in(l_export_in.count) := l_val_rec.internal_name;
            
                IF (l_doc_area_tab.exists(r_crit.id_doc_area))
                THEN
                    l_aux_tv := l_doc_area_tab(r_crit.id_doc_area);
                    l_aux_tv.extend;
                    l_aux_tv(l_aux_tv.count) := r_crit.internal_name;
                    l_doc_area_tab(r_crit.id_doc_area) := l_aux_tv;
                ELSE
                    l_aux_tv := table_varchar(1);
                    l_aux_tv(l_aux_tv.count) := r_crit.internal_name;
                    l_doc_area_tab(r_crit.id_doc_area) := l_aux_tv;
                END IF;
            
                l_val_tab(r_crit.internal_name) := l_val_rec;
            END IF;
            IF (instr(r_crit.flg_type, g_flg_type_chk) > 0)
            THEN
                g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_DOC_AREA_ELEM_VALUES FOR ID_EPISODE: ' || i_epis;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_touch_option.get_last_doc_area_elem_values(i_lang               => i_lang,
                                                                     i_prof               => i_prof,
                                                                     i_episode            => i_epis,
                                                                     i_doc_area           => r_crit.id_doc_area,
                                                                     i_doc_template       => NULL,
                                                                     i_table_element_keys => table_varchar(r_crit.internal_name),
                                                                     i_key_type           => 'N',
                                                                     o_last_epis_doc      => l_last_epis_doc,
                                                                     o_last_date_epis_doc => l_last_date_epis_doc,
                                                                     o_element_values     => l_element_values,
                                                                     o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        IF l_last_epis_doc IS NOT NULL
        THEN
            g_error := 'FETCH CURSOR l_element_values';
            FETCH l_element_values BULK COLLECT
                INTO r_doc;
            CLOSE l_element_values;
        
            g_error := 'ACCESSING COLLECTION';
            IF r_doc.exists(1)
            THEN
                l_aux_in := r_doc(1).internal_name;
            ELSE
                l_aux_in := NULL;
            END IF;
        
            IF (i_test = pk_alert_constant.g_yes AND l_aux_in IS NOT NULL)
            THEN
                l_aux_in := NULL;
                pk_alertlog.log_debug(text            => 'Call to pk_sr_planning.check_surgery_type for episode: ' ||
                                                         i_epis || ' - episode oris: ' || i_epis_oris,
                                      object_name     => 'PK_SR_DOCUMENTATION',
                                      sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
                g_error := 'Call to pk_sr_planning.check_surgery_type';
                IF pk_sr_planning.check_surgery_type(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_flg_group      => g_flg_group_amb,
                                                     i_episode        => nvl(i_epis_oris, i_epis),
                                                     o_flg_show       => o_flg_show,
                                                     o_internal_names => l_internal_names,
                                                     o_error          => o_error)
                THEN
                    IF o_flg_show = pk_alert_constant.g_yes
                    THEN
                        o_msg     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SR_SPDETAIL_M001');
                        l_aux_msg := '';
                        LOOP
                            FETCH l_internal_names
                                INTO l_aux_in;
                            EXIT WHEN l_internal_names%NOTFOUND;
                            l_aux_msg := l_aux_msg || l_aux_in || chr(10);
                        END LOOP;
                        o_msg       := REPLACE(o_msg, '@1', l_aux_msg);
                        o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T013');
                        o_button    := 'C';
                        RETURN TRUE;
                    END IF;
                ELSE
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        pk_alertlog.log_debug(text            => 'Call to pk_touch_option.get_last_doc_area_elem_values for l_export_in: ' ||
                                                 pk_utils.to_string(l_export_in),
                              object_name     => 'PK_SR_DOCUMENTATION',
                              sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
        g_error := 'Call to pk_touch_option.get_last_doc_area_elem_values';
    
        BEGIN
            l_aux_tv := l_doc_area_tab(i_doc_area);
        EXCEPTION
            WHEN no_data_found THEN
                l_aux_tv := table_varchar();
        END;
    
        IF (l_aux_tv.count > 0)
        THEN
            g_error := 'CALL PK_TOUCH_OPTION.GET_LAST_DOC_AREA_ELEM_VALUES FOR ID_EPISODE: ' || i_epis;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.get_last_doc_area_elem_values(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_episode            => i_epis,
                                                                 i_doc_area           => i_doc_area,
                                                                 i_doc_template       => i_doc_template,
                                                                 i_table_element_keys => l_aux_tv,
                                                                 i_key_type           => 'N',
                                                                 o_last_epis_doc      => l_last_epis_doc,
                                                                 o_last_date_epis_doc => l_last_date_epis_doc,
                                                                 o_element_values     => l_element_values,
                                                                 o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'START PROCESSING EXPORT DATA FOR INTERNAL NAMES';
            pk_alertlog.log_debug(g_error);
        
            FETCH l_element_values BULK COLLECT
                INTO r_doc;
            CLOSE l_element_values;
        
            LOOP
                IF l_last_epis_doc IS NOT NULL
                   AND NOT l_finish_proc
                THEN
                    IF r_doc.exists(l_doc_count)
                    THEN
                        l_aux_in    := r_doc(l_doc_count).internal_name;
                        l_str_value := l_val_tab(l_aux_in).value;
                        l_aux_tv    := remove_value(l_aux_in, l_val_tab);
                    ELSE
                        l_aux_in      := NULL;
                        l_finish_proc := TRUE;
                    END IF;
                ELSE
                    l_finish_proc := TRUE;
                END IF;
            
                IF l_finish_proc
                THEN
                    EXIT WHEN l_count > l_aux_tv.count;
                    l_aux_in    := l_aux_tv(l_count);
                    l_str_value := NULL;
                    l_count     := l_count + 1;
                    l_aux_tv    := remove_value(l_aux_in, l_val_tab);
                END IF;
            
                pk_alertlog.log_debug(text            => 'Processing value ''' || nvl(l_str_value, 'NULL') ||
                                                         ''' for internal_name : ' || l_aux_in || ' - ' ||
                                                         pk_utils.to_string(l_aux_tv),
                                      object_name     => 'PK_SR_DOCUMENTATION',
                                      sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
            
                l_sql_instr := 'begin ' || chr(10);
                l_sql_instr := l_sql_instr || l_val_tab(l_aux_in).target_table || '.upd(';
                l_sql_instr := l_sql_instr || l_val_tab(l_aux_in).target_column || '_in => :1, ' || chr(10);
                l_sql_instr := l_sql_instr || l_val_tab(l_aux_in).target_column || '_nin => false, ' || chr(10);
                l_sql_instr := l_sql_instr || 'where_in => :2, ' || chr(10);
                l_sql_instr := l_sql_instr || 'rows_out => :3);' || chr(10) || 'end;';
            
                pk_alertlog.log_debug(text            => l_val_tab(l_aux_in)
                                                         .value || ' - ' ||
                                                          REPLACE(l_val_tab(l_aux_in).where_clause,
                                                                  '@1',
                                                                  nvl(i_epis_oris, i_epis)),
                                      object_name     => 'PK_SR_DOCUMENTATION',
                                      sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
                pk_alertlog.log_debug(text            => l_sql_instr,
                                      object_name     => 'PK_SR_DOCUMENTATION',
                                      sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
            
                g_error := 'Executing generated instructions';
                EXECUTE IMMEDIATE l_sql_instr
                    USING IN l_str_value, IN REPLACE(l_val_tab(l_aux_in).where_clause, '@1', nvl(i_epis_oris, i_epis)), IN OUT l_rows_out;
            
                pk_alertlog.log_debug(text            => l_rows_out.count || ' rows updated: ' ||
                                                         pk_utils.to_string(l_rows_out),
                                      object_name     => 'PK_SR_DOCUMENTATION',
                                      sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
            
                l_rows_out := table_varchar();
                l_val_tab.delete(l_aux_in);
            
                init_vars(i_aux_ide => l_aux_ide,
                          i_aux_in  => l_aux_in,
                          i_aux_ft  => l_aux_ft,
                          i_aux_de  => l_aux_de,
                          i_aux_dev => l_aux_dev,
                          i_aux_v   => l_aux_v,
                          i_aux_vp  => l_aux_vp,
                          i_aux_fv  => l_aux_fv);
            
                l_doc_count := l_doc_count + 1;
            END LOOP;
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
                                              'MANAGE_EPIS_DOCUMENTATION',
                                              o_error);
        
            RETURN FALSE;
    END manage_epis_documentation;

    /**************************************************************************
    * Sets documentation values associated with an area (doc_area)            *
    * of a template (doc_template).                                           *
    * Allows for new, edit and agree epis documentation.                      *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_prof_cat_type              professional category               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_flg_type                   A Agree, E edit, N - new            *
    * @param i_id_documentation           array with id documentation,        *
    * @param i_id_doc_element             array with doc elements             *
    * @param i_id_doc_element_crit        array with doc elements crit        *
    * @param i_value                      array with values                   *
    * @param i_notes                      note                                *
    * @param i_id_doc_element_qualif      array with doc elements qualif      *
    * @param i_epis_context               context id (Ex:id_interv_presc_det, *
    *                                     id_exam...)                         *
    * @param i_summary_and_notes          template summary to be included on  *
    *                                     clinical notes                      *
    * @param i_episode_context            context episode id  used in         *
    *                                     preoperative ORIS area by OUTP, INP,*
    *                                     EDIS                                *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_flg_show                   Flag to show warn message           *
    * @param o_msg                        Message to be displayde in popup    *
    * @param o_msg_title                  Title do message window             *
    * @param o_button                     Type of button on popup msg         *
    * @param o_epis_documentation         Created epis documentation id       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/09/07                              *
    **************************************************************************/
    FUNCTION set_sr_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE,
        i_flg_val_group         IN sr_surgery_validation.flg_group%TYPE,
        i_test                  IN VARCHAR2,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_status IS
            SELECT flg_pat_status
              FROM sr_pat_status
             WHERE id_episode = i_episode_context;
    
        l_pat_status        sr_pat_status.flg_pat_status%TYPE;
        l_rcv_status        VARCHAR2(1);
        l_rcv_manual        VARCHAR2(1);
        l_rcv_unverif_items pk_types.cursor_type;
        l_aux               VARCHAR2(1024);
        internal_error_exception EXCEPTION;
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        pk_alertlog.log_debug(text            => 'Call to pk_touch_option.set_epis_document_internal for episode: ' ||
                                                 i_epis,
                              object_name     => 'PK_SR_DOCUMENTATION',
                              sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
        g_error := 'Call to pk_touch_option.set_epis_document_internal';
    
        IF i_vs_element_list IS NULL
           OR i_vs_element_list.count = 0
        THEN
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => i_prof_cat_type,
                                                              i_epis                  => i_epis,
                                                              i_doc_area              => i_doc_area,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => i_epis_documentation,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => i_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_notes,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_epis_context,
                                                              i_episode_context       => i_episode_context,
                                                              o_epis_documentation    => o_epis_documentation,
                                                              o_error                 => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        ELSE
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_prof_cat_type         => i_prof_cat_type,
                                                              i_epis                  => i_epis,
                                                              i_doc_area              => i_doc_area,
                                                              i_doc_template          => i_doc_template,
                                                              i_epis_documentation    => i_epis_documentation,
                                                              i_flg_type              => i_flg_type,
                                                              i_id_documentation      => i_id_documentation,
                                                              i_id_doc_element        => i_id_doc_element,
                                                              i_id_doc_element_crit   => i_id_doc_element_crit,
                                                              i_value                 => i_value,
                                                              i_notes                 => i_notes,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                              i_epis_context          => i_epis_context,
                                                              i_episode_context       => i_episode_context,
                                                              --i_flg_table_origin      => ,
                                                              --i_flg_status            => ,
                                                              --i_dt_creation           => ,
                                                              i_vs_element_list    => i_vs_element_list,
                                                              i_vs_save_mode_list  => i_vs_save_mode_list,
                                                              i_vs_list            => i_vs_list,
                                                              i_vs_value_list      => i_vs_value_list,
                                                              i_vs_uom_list        => i_vs_uom_list,
                                                              i_vs_scales_list     => i_vs_scales_list,
                                                              i_vs_date_list       => i_vs_date_list,
                                                              i_vs_read_list       => i_vs_read_list,
                                                              i_id_edit_reason     => i_id_edit_reason,
                                                              i_notes_edit         => i_notes_edit,
                                                              o_epis_documentation => o_epis_documentation,
                                                              o_error              => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        END IF;
        IF i_flg_val_group IS NOT NULL
        THEN
            pk_alertlog.log_debug(text            => 'Call to manage_epis_documentation for epis_documentation: ' ||
                                                     o_epis_documentation,
                                  object_name     => 'PK_SR_DOCUMENTATION',
                                  sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
            g_error := 'Call to manage_epis_documentation';
            IF NOT manage_epis_documentation(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_epis          => i_epis,
                                             i_epis_oris     => i_episode_context,
                                             i_doc_area      => i_doc_area,
                                             i_doc_template  => i_doc_template,
                                             i_flg_val_group => i_flg_val_group,
                                             i_test          => i_test,
                                             o_flg_show      => o_flg_show,
                                             o_msg           => o_msg,
                                             o_msg_title     => o_msg_title,
                                             o_button        => o_button,
                                             o_error         => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        END IF;
        IF o_flg_show = pk_alert_constant.g_yes
        THEN
            o_epis_documentation := NULL;
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        IF i_doc_area = g_doc_area_pre_op_assessment
        THEN
            pk_alertlog.log_debug(text            => 'Call to pk_sr_procedures.update_receive for id_episode: ' ||
                                                     i_episode_context,
                                  object_name     => 'PK_SR_DOCUMENTATION',
                                  sub_object_name => 'SET_SR_EPIS_DOCUMENTATION');
            IF NOT pk_sr_procedures.update_receive(i_lang           => i_lang,
                                                   i_episode        => i_episode_context,
                                                   i_prof           => i_prof,
                                                   i_doc_template   => i_doc_template,
                                                   i_transaction_id => l_transaction_id,
                                                   o_status         => l_rcv_status,
                                                   o_manual         => l_rcv_manual,
                                                   o_unverif_items  => l_rcv_unverif_items,
                                                   o_title          => l_aux,
                                                   o_button         => l_aux,
                                                   o_error          => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            IF l_rcv_status = 'Y'
            THEN
                --Same logic used in pk_sr_procedures.update_receive
                OPEN c_pat_status;
                FETCH c_pat_status
                    INTO l_pat_status;
                CLOSE c_pat_status;
            
                IF nvl(l_pat_status, pk_sr_procedures.g_pat_status_a) IN
                   (pk_sr_procedures.g_pat_status_a,
                    pk_sr_procedures.g_pat_status_w,
                    pk_sr_procedures.g_pat_status_l,
                    pk_sr_procedures.g_pat_status_t)
                THEN
                
                    -- Updates Patient status to V-Admitted
                    g_error := 'SET PAT STATUS';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => i_episode_context,
                                                          i_flg_status_new => pk_sr_procedures.g_pat_status_v,
                                                          i_flg_status_old => l_pat_status,
                                                          i_test           => 'N',
                                                          i_transaction_id => l_transaction_id,
                                                          o_flg_show       => l_aux,
                                                          o_msg_title      => l_aux,
                                                          o_msg_text       => l_aux,
                                                          o_button         => l_aux,
                                                          o_error          => o_error)
                    THEN
                        RAISE internal_error_exception;
                    END IF;
                END IF;
            END IF;
        END IF;
    
/*        g_error := 'Call to pk_clinical_notes.set_clinical_notes_doc_area for id_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_clinical_notes.set_clinical_notes_doc_area(i_lang,
                                                             i_prof,
                                                             i_episode_context,
                                                             i_doc_area,
                                                             i_summary_and_notes,
                                                             o_error)
        THEN
            RAISE internal_error_exception;
        END IF;*/
    
        g_error := 'Call to pk_sr_approval.check_status_for_approval for i_episode_context: ' || i_episode_context;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_episode_context,
                                                        o_error   => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'CALL  PK_SCHEDULE_API_UPSTREAM.DO_COMMIT FOR ID_TRANSACTION' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_EPIS_DOCUMENTATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_EPIS_DOCUMENTATION',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_sr_epis_documentation;

    /**************************************************************************
    * Cancels an episode documentation                                        *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_notes                      notes                               *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_flg_show                   Flag to show warn message           *
    * @param o_msg_title                  Title do message window             *
    * @param o_msg_text                   Message to be displayde in popup    *
    * @param o_button                     Type of button on popup msg         *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/09/15                              *
    **************************************************************************/
    FUNCTION cancel_sr_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_flg_val_group      IN sr_surgery_validation.flg_group%TYPE,
        i_notes              IN VARCHAR2,
        i_test               IN VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Call pk_touch_option.cancel_epis_doc_no_commit for id_epis_documentation: ' || i_epis_documentation;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.cancel_epis_doc_no_commit(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_id_epis_doc => i_epis_documentation,
                                                         i_notes       => i_notes,
                                                         i_test        => pk_alert_constant.g_no,
                                                         o_flg_show    => o_flg_show,
                                                         o_msg_title   => o_msg_title,
                                                         o_msg_text    => o_msg_text,
                                                         o_button      => o_button,
                                                         o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        g_error := 'Call to manage_epis_documentation for id_episode: ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT manage_epis_documentation(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_epis          => i_epis,
                                         i_epis_oris     => NULL,
                                         i_doc_area      => i_doc_area,
                                         i_doc_template  => i_doc_template,
                                         i_flg_val_group => i_flg_val_group,
                                         i_test          => i_test,
                                         o_flg_show      => o_flg_show,
                                         o_msg           => o_msg_text,
                                         o_msg_title     => o_msg_title,
                                         o_button        => o_button,
                                         o_error         => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        IF i_test = pk_alert_constant.g_yes
           AND (o_flg_show IS NULL OR o_flg_show = pk_alert_constant.g_no)
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'DOCUMENTATION_T006');
            o_msg_text  := pk_message.get_message(i_lang, 'DOCUMENTATION_M013');
            o_button    := 'NC';
            pk_utils.undo_changes;
            RETURN TRUE;
        ELSIF i_test = pk_alert_constant.g_yes
              AND o_flg_show = pk_alert_constant.g_yes
        THEN
            pk_utils.undo_changes;
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL PK_SR_APPROVAL.CHECK_STATUS_FOR_APPROVAL ' || i_epis;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_approval.check_status_for_approval(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => i_epis,
                                                        o_error   => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_EPIS_DOCUMENTATION',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_sr_epis_documentation;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_sr_documentation;
/
