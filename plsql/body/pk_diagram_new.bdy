/*-- Last Change Revision: $Rev: 2044926 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-09-05 11:34:11 +0100 (seg, 05 set 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_diagram_new IS

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang,
                                          NULL,
                                          pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_package_name || '.' ||
                                          i_func_proc_name,
                                          NULL,
                                          g_package_owner,
                                          g_package_name,
                                          'error_handling',
                                          o_error);
    
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
        RETURN FALSE;
    END error_handling;

    FUNCTION find_diff_eddn
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_edd      IN epis_diagram_detail.id_epis_diagram_detail%TYPE,
        o_symbols     OUT VARCHAR2,
        o_recent_note OUT VARCHAR2,
        o_old_notes   OUT VARCHAR2,
        o_cancelled   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- SELECT ALL THE NOTES FROM THE LAYOUT BELOGING TO THE SYMBOL GIVEN BY I_ID_EDD
    
        CURSOR c_symbol_notes IS
            SELECT eddn.*
              FROM epis_diagram_detail_notes eddn, epis_diagram_detail edd
             WHERE eddn.id_epis_diagram_detail = edd.id_epis_diagram_detail
               AND edd.id_epis_diagram_detail = i_id_edd
             ORDER BY eddn.dt_notes_tstz DESC;
    
        l_eddn_row          epis_diagram_detail_notes%ROWTYPE;
        l_eddn_previous_row epis_diagram_detail_notes%ROWTYPE;
        l_symbol            VARCHAR2(50);
    
        l_value              NUMBER;
        l_doc_name           VARCHAR2(100);
        l_doc_name_cancelled VARCHAR2(100);
        l_tag_outdated_info  VARCHAR2(50);
        l_tag_cancelled      VARCHAR2(50);
        l_flg_status_edd     VARCHAR(1);
        l_flg_status_edl     VARCHAR(1);
        l_date_cancelled     TIMESTAMP WITH TIME ZONE;
        l_cancel_notes       VARCHAR2(200);
        l_layout_order       epis_diagram_layout.layout_order%TYPE;
    
    BEGIN
    
        l_tag_outdated_info := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T018');
        l_tag_cancelled     := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T017');
    
        -- selecting the layout order within the diagram
        g_error := 'SELECT EPIS_DIAGRAM_LAYOUT.LAYOUT_ORDER';
        SELECT edl.layout_order
          INTO l_layout_order
          FROM epis_diagram_layout edl, epis_diagram_detail edd
         WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout
           AND edl.flg_status <> g_diag_lay_removed
           AND edd.id_epis_diagram_detail = i_id_edd;
    
        -- selecting the symbol identifier (example: c1)
        g_error := 'SELECT EPIS_DIAGRAM_DETAIL.VALUE';
        BEGIN
            SELECT edd.value
              INTO l_value
              FROM epis_diagram_detail edd
             WHERE edd.id_epis_diagram_detail = i_id_edd;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        g_error := 'SELECT DIAGRAM_TOOLS_GROUP.CODE_ACRONYM_GROUP';
        BEGIN
            SELECT pk_translation.get_translation(i_lang, dtg.code_acronym_group)
              INTO l_symbol
              FROM epis_diagram_detail edd, diagram_tools dt, diagram_tools_group dtg
            
             WHERE edd.id_diagram_tools = dt.id_diagram_tools
               AND dt.id_diagram_tools_group = dtg.id_diagram_tools_group
               AND edd.id_epis_diagram_detail = i_id_edd;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- filling in the symbols buffer
        IF l_symbol IS NULL
        THEN
            o_symbols := l_layout_order || '*' || l_value || ':';
        ELSE
            o_symbols := l_layout_order || '*' || l_symbol || l_value || ':';
        END IF;
    
        -- getting the flag_status ( if is equal to 'c', then the layout is cancelled and therefore the note is also cancelled)
        g_error := 'SELECT FLAG_STATUS';
        BEGIN
            SELECT edl.flg_status
              INTO l_flg_status_edl
              FROM epis_diagram_layout edl, epis_diagram_detail edd
             WHERE edd.id_epis_diagram_detail = i_id_edd
               AND edd.flg_status <> g_diag_lay_removed
               AND edd.id_epis_diagram_layout = edl.id_epis_diagram_layout;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- or the detail may have been cancelled    
        BEGIN
            SELECT edd.flg_status
              INTO l_flg_status_edd
              FROM epis_diagram_detail edd
             WHERE edd.id_epis_diagram_detail = i_id_edd;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        -- fetching : professional who cancelled, cancelation date and cancelation notes
        IF l_flg_status_edd = 'C'
        THEN
        
            SELECT pk_tools.get_prof_description(i_lang, i_prof, epd.id_prof_cancel, epd.dt_cancel_tstz, NULL) doc_name_cancelled,
                   epd.dt_cancel_tstz date_cancelled,
                   epd.notes_cancel
              INTO l_doc_name_cancelled, l_date_cancelled, l_cancel_notes
              FROM epis_diagram_detail epd
             WHERE epd.id_epis_diagram_detail = i_id_edd;
        
        END IF;
    
        -- for each symbol in the cursor, find the differences in the notes
        g_error := 'CURSOR c_symbol_notes';
        OPEN c_symbol_notes;
        FETCH c_symbol_notes -- first line (most recent update)
            INTO l_eddn_row;
    
        l_doc_name := pk_tools.get_prof_description(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => l_eddn_row.id_professional,
                                                    i_date    => l_eddn_row.dt_notes_tstz,
                                                    i_episode => NULL);
        IF l_eddn_row.notes <> ' '
        THEN
        
            o_recent_note := l_eddn_row.notes || '|||' || l_doc_name || ' / ' ||
                             pk_date_utils.date_time_chr_tsz(i_lang, l_eddn_row.dt_notes_tstz, i_prof) || '|||';
        
        ELSE
            o_recent_note := '|||' || l_doc_name || ' / ' ||
                             pk_date_utils.date_time_chr_tsz(i_lang, l_eddn_row.dt_notes_tstz, i_prof) || '|||';
        END IF;
    
        -- other lines (older updates)    
        -- initially, the previous row is equal to the first one
        l_eddn_previous_row := l_eddn_row;
    
        LOOP
            FETCH c_symbol_notes
                INTO l_eddn_row;
            EXIT WHEN c_symbol_notes%NOTFOUND;
        
            l_doc_name := pk_tools.get_prof_description(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_prof_id => l_eddn_row.id_professional,
                                                        i_date    => l_eddn_row.dt_notes_tstz,
                                                        i_episode => NULL);
        
            IF l_eddn_row.notes IS NOT NULL
               AND l_eddn_row.notes <> l_eddn_previous_row.notes
            THEN
                o_old_notes := o_old_notes || l_eddn_row.notes || '|||' || l_doc_name || ' / ' ||
                               pk_date_utils.date_time_chr_tsz(i_lang, l_eddn_row.dt_notes_tstz, i_prof) || '|||';
            
                l_eddn_previous_row := l_eddn_row;
            END IF;
        END LOOP;
    
        CLOSE c_symbol_notes;
    
        IF o_old_notes IS NOT NULL
        THEN
            o_old_notes := l_tag_outdated_info || '|||' || o_old_notes;
        END IF;
    
        IF l_flg_status_edd = 'C'
        THEN
            o_cancelled   := l_tag_cancelled || '|||' || l_cancel_notes || '|||' || l_doc_name_cancelled || ' ' || '/' || ' ' ||
                             pk_date_utils.date_time_chr_tsz(i_lang, l_date_cancelled, i_prof) || '|||' ||
                             o_recent_note || o_old_notes;
            o_recent_note := NULL;
            o_old_notes   := NULL;
        ELSE
            IF l_flg_status_edl = 'C'
            THEN
                o_cancelled   := l_tag_cancelled || '|||' || l_doc_name_cancelled || '|||' || o_recent_note || '|||' ||
                                 o_old_notes;
                o_recent_note := NULL;
                o_old_notes   := NULL;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'find_diff_eddn',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END find_diff_eddn;

    FUNCTION find_differences_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_edl_row       IN epis_diagram_layout%ROWTYPE,
        io_symbols      IN OUT table_varchar,
        io_recent_notes IN OUT table_varchar,
        io_old_notes    IN OUT table_varchar,
        io_cancelled    IN OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- select all the symbols from the layout belonging to diagram i_id_diag and with layout_order= i_layout_number    
        CURSOR c_layout_symbols IS
            SELECT edd.*
              FROM epis_diagram_detail edd
             WHERE edd.id_epis_diagram_layout = i_edl_row.id_epis_diagram_layout
             ORDER BY (SELECT MAX(eddn.dt_notes_tstz)
                         FROM epis_diagram_detail_notes eddn
                        WHERE eddn.id_epis_diagram_detail = edd.id_epis_diagram_detail) DESC;
    
        l_edd_row     epis_diagram_detail%ROWTYPE;
        l_index       NUMBER;
        l_symbols     VARCHAR2(2000);
        l_recent_note VARCHAR2(2000);
        l_old_notes   VARCHAR2(2000);
        l_cancelled   VARCHAR2(2000);
        l_error       t_error_out;
        l_boolean     BOOLEAN;
    
    BEGIN
    
        l_index := io_symbols.count;
    
        -- for each symbol in the cursor, find the differences in the notes
        g_error := 'OPEN C_LAYOUT_SYMBOLS';
        OPEN c_layout_symbols;
        LOOP
            FETCH c_layout_symbols
                INTO l_edd_row;
            EXIT WHEN c_layout_symbols%NOTFOUND;
        
            l_index   := l_index + 1;
            l_boolean := find_diff_eddn(i_lang,
                                        i_prof,
                                        l_edd_row.id_epis_diagram_detail,
                                        l_symbols,
                                        l_recent_note,
                                        l_old_notes,
                                        l_cancelled,
                                        l_error);
        
            io_symbols.extend;
            io_symbols(l_index) := l_symbols;
        
            io_recent_notes.extend;
            io_recent_notes(l_index) := l_recent_note;
        
            io_old_notes.extend;
            io_old_notes(l_index) := l_old_notes;
        
            io_cancelled.extend;
            io_cancelled(l_index) := l_cancelled;
        
        END LOOP;
        CLOSE c_layout_symbols;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'find_differences_notes',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END find_differences_notes;

    FUNCTION find_figures_info
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_edl_row                 IN epis_diagram_layout%ROWTYPE,
        io_figures                IN OUT table_varchar,
        io_figures_info           IN OUT table_varchar,
        io_figures_info_cancelled IN OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_index NUMBER;
    
        l_doc_name           VARCHAR2(100);
        l_doc_name_cancelled VARCHAR2(100);
        l_tag_cancelled      VARCHAR2(50);
        l_tag_created_by     VARCHAR2(50);
        l_lay_desc           VARCHAR2(200);
        l_code_diag_lay      VARCHAR2(100);
    
    BEGIN
    
        l_index := io_figures.count + 1;
    
        l_tag_cancelled := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T017');
    
        l_tag_created_by := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T030');
    
        l_doc_name := pk_tools.get_prof_description(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => i_edl_row.id_professional,
                                                    i_date    => i_edl_row.dt_creation_tstz,
                                                    i_episode => NULL);
    
        SELECT dl.code_diagram_layout
          INTO l_code_diag_lay
          FROM diagram_layout dl, epis_diagram_layout edl
         WHERE edl.id_diagram_layout = dl.id_diagram_layout
           AND edl.id_epis_diagram_layout = i_edl_row.id_epis_diagram_layout
           AND edl.flg_status <> g_diag_lay_removed;
    
        l_lay_desc := pk_translation.get_translation(i_lang, l_code_diag_lay);
    
        IF i_edl_row.id_prof_cancel IS NOT NULL
        THEN
            l_doc_name_cancelled := pk_tools.get_prof_description(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_prof_id => i_edl_row.id_prof_cancel,
                                                                  i_date    => i_edl_row.dt_cancel_tstz,
                                                                  i_episode => NULL);
        END IF;
    
        io_figures.extend;
        io_figures(l_index) := i_edl_row.layout_order || '*' ||
                               REPLACE(pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T011'),
                                       '@1',
                                       i_edl_row.layout_order);
    
        IF i_edl_row.flg_status = 'A'
        THEN
        
            io_figures_info.extend;
            io_figures_info(l_index) := l_lay_desc || '|||' || l_doc_name || ' / ' ||
                                        pk_date_utils.date_time_chr_tsz(i_lang, i_edl_row.dt_creation_tstz, i_prof) ||
                                        '|||';
        
            io_figures_info_cancelled.extend;
            io_figures_info_cancelled(l_index) := NULL;
        
        ELSE
        
            io_figures_info.extend;
        
            io_figures_info_cancelled.extend;
            io_figures_info(l_index) := NULL;
        
            -- this test is necessary because we only want the cancelation date and the name of the doctor who performed it, if they arent null values
            IF l_doc_name_cancelled IS NULL
               OR i_edl_row.dt_cancel_tstz IS NULL
            THEN
            
                io_figures_info_cancelled(l_index) := l_tag_cancelled || '|||' || l_lay_desc || '|||' ||
                                                      l_tag_created_by || ':' || '|||' || l_doc_name || ',' ||
                                                      pk_date_utils.date_time_chr_tsz(i_lang,
                                                                                      i_edl_row.dt_creation_tstz,
                                                                                      i_prof) || '|||';
            
            ELSE
            
                io_figures_info_cancelled(l_index) := l_tag_cancelled || '|||' || l_lay_desc || '|||' ||
                                                     
                                                      l_doc_name_cancelled || ' / ' ||
                                                      pk_date_utils.date_time_chr_tsz(i_lang,
                                                                                      i_edl_row.dt_cancel_tstz,
                                                                                      i_prof) || '|||' ||
                                                      l_tag_created_by || ':' || '|||' || l_doc_name || ',' ||
                                                      pk_date_utils.date_time_chr_tsz(i_lang,
                                                                                      i_edl_row.dt_creation_tstz,
                                                                                      i_prof) || '|||';
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'find_figures_info',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END find_figures_info;

    FUNCTION get_diag_lay_imag_image_url
    (
        i_prof          IN profissional,
        i_diagram_image IN diagram_image.id_diagram_image%TYPE
    ) RETURN VARCHAR2 IS
        l_url sys_config.value%TYPE;
    BEGIN
        g_error := 'GET ' || g_diagram_single_image_url || ' SYS_CONFIG';
        IF (g_url_image IS NULL)
        THEN
            g_url_image := pk_sysconfig.get_config(g_diagram_single_image_url, i_prof);
        END IF;
        g_error := 'REPLACE id_diagram_image';
        l_url   := REPLACE(g_url_image, '@1', i_diagram_image);
    
        RETURN l_url;
    
    END get_diag_lay_imag_image_url;

    FUNCTION get_diag_lay_image_url
    (
        i_prof           IN profissional,
        i_diagram_layout IN diagram_layout.id_diagram_layout%TYPE
    ) RETURN VARCHAR2 IS
    
        l_url sys_config.value%TYPE;
    
    BEGIN
    
        g_error := 'GET ' || g_diagram_full_image_url || ' SYS_CONFIG';
        IF (g_url_layout) IS NULL
        THEN
            g_url_layout := pk_sysconfig.get_config(g_diagram_full_image_url, i_prof);
        END IF;
        g_error := 'REPLACE id_diagram_layout';
        l_url   := REPLACE(g_url_layout, '@1', i_diagram_layout);
    
        RETURN l_url;
    
    END get_diag_lay_image_url;

    FUNCTION get_default_lay_sys_config
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_gender   IN VARCHAR2,
        i_age      IN NUMBER,
        i_flg_type IN diagram_layout.flg_type%TYPE
    ) RETURN NUMBER IS
        l_diagram_layout    diagram_layout.id_diagram_layout%TYPE := NULL;
        l_age               NUMBER;
        l_gender            VARCHAR2(1);
        l_sys_config_prefix pk_types.t_low_char;
    
        l_exception EXCEPTION;
    
        CURSOR c_int_names(age NUMBER) IS
            SELECT b.internal_name
              FROM body_diag_age_grp b
             WHERE (age >= (SELECT nvl(tb.min_age, bag.min_age)
                              FROM body_diag_age_grp bag
                              LEFT JOIN (SELECT *
                                          FROM bd_age_grp_soft_inst
                                         WHERE id_institution IN (i_prof.institution, 0)
                                           AND id_software IN (i_prof.software, 0)
                                         ORDER BY id_institution DESC, id_software DESC) tb
                                ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                             WHERE bag.id_body_diag_age_grp = b.id_body_diag_age_grp) AND
                   age <= (SELECT nvl(tb.max_age, bag.max_age)
                              FROM body_diag_age_grp bag
                              LEFT JOIN (SELECT *
                                          FROM bd_age_grp_soft_inst
                                         WHERE id_institution IN (i_prof.institution, 0)
                                           AND id_software IN (i_prof.software, 0)
                                         ORDER BY id_institution DESC, id_software DESC) tb
                                ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                             WHERE bag.id_body_diag_age_grp = b.id_body_diag_age_grp));
    BEGIN
    
        l_gender := nvl(i_gender, 'M');
        -- if the required diagram layout type id is 'N' (Neurological assessment)
        IF i_flg_type = g_flg_type_neur_assessm
        THEN
            l_sys_config_prefix := 'DEF_NEUR_ASSESSM_DIAG_LAYOUT';
            -- if the required diagram layout type id is 'D' (Drainage)            
        ELSIF i_flg_type = g_flg_type_drainage
        THEN
            l_sys_config_prefix := 'DEF_DRAIN_DIAG_LAYOUT';
        ELSE
            l_sys_config_prefix := 'DEFAULT_DIAGRAM_LAYOUT';
        END IF;
    
        IF i_age IS NULL
        THEN
            l_diagram_layout := pk_sysconfig.get_config(l_sys_config_prefix || '_' || l_gender,
                                                        i_prof.institution,
                                                        i_prof.software);
        ELSE
            l_age := i_age;
        
            IF l_age < 0
            THEN
                l_age := 0;
            ELSIF l_age > 999
            THEN
                l_age := 999;
            END IF;
        
            FOR int_name IN c_int_names(l_age)
            LOOP
                IF l_diagram_layout IS NULL
                THEN
                    l_diagram_layout := pk_sysconfig.get_config(l_sys_config_prefix || '_' || l_gender || '_' ||
                                                                int_name.internal_name,
                                                                i_prof.institution,
                                                                i_prof.software);
                
                END IF;
            END LOOP;
        
        END IF;
    
        IF l_diagram_layout IS NULL
        THEN
            l_diagram_layout := pk_sysconfig.get_config(l_sys_config_prefix || '_' || l_gender,
                                                        i_prof.institution,
                                                        i_prof.software);
        END IF;
    
        RETURN l_diagram_layout;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(name1_in => 'GET_DEFAULT_LAY_SYS_CONFIG', error_code_in => SQLCODE);
            RETURN NULL;
    END get_default_lay_sys_config;

    FUNCTION get_default_lay
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN diagram_layout.flg_type%TYPE,
        o_diagram_layout OUT diagram_layout.id_diagram_layout%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result            sys_config.value%TYPE;
        l_id_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_diagram_layout diagram_layout.id_diagram_layout%TYPE;
        l_gender            patient.gender%TYPE;
        l_age               patient.age%TYPE;
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(floor((SYSDATE - dt_birth) / 365), p.age) age
              FROM patient p
              JOIN episode e
                ON e.id_patient = p.id_patient
             WHERE e.id_episode = i_episode;
    
    BEGIN
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_gender, l_age;
        CLOSE c_pat;
    
        IF (l_age IS NULL)
        THEN
            -- qd a idade n??onhecida ?ecess?o atribuir uma idade por defeito para efeitos de configura?.
            -- optou-se por adulto
            l_age := 999;
        END IF;
    
        -- fetching the id_dep_clin_serv
        g_error  := 'GET DEFAULT_DIAGRAM_LAYOUT_STRATEGY SYS_CONFIG';
        l_result := pk_sysconfig.get_config('DEFAULT_DIAGRAM_LAYOUT_STRATEGY', i_prof.institution, i_prof.software);
    
        IF l_result = 'EPIS_INFO'
        THEN
            -- Episode is associated with a dep_clin_serv in EPIS_INFO
            -- applies to INPATIENT 
            g_error := 'GET FROM EPIS_INFO';
            SELECT epis_info.id_dep_clin_serv
              INTO l_id_dep_clin_serv
              FROM epis_info
             WHERE epis_info.id_episode = i_episode;
        
        ELSIF l_result = 'PROF_DEP_CLIN_SERVICE'
        THEN
            -- When the episode is not associated with a specific dep_clin_serv, 
            -- we use the preferred professional dep_clin_serv
            -- applies to ORIS 
            g_error := 'GET FROM PROF_DEP_CLIN_SERVICE';
            BEGIN
                SELECT pdcs.id_dep_clin_serv
                  INTO l_id_dep_clin_serv
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = i_prof.id
                   AND pdcs.flg_default = 'Y'
                   AND rownum = 1
                   AND pdcs.id_institution = i_prof.institution;
            
            EXCEPTION
                WHEN no_data_found THEN
                    -- professional has no default dep_clin_serv
                    -- lets use a default configured at sys_config
                    g_error            := ' GET SYS_CONFIG FOR PROF_DEP_CLIN_SERVICE';
                    l_id_dep_clin_serv := pk_sysconfig.get_config('SURGERY_DEP_CLIN_SERV',
                                                                  i_prof.institution,
                                                                  i_prof.software);
            END;
        
        ELSIF l_result = 'SCHEDULE'
        THEN
            -- Episode is associated with a dep_clin_serv in schedule
            -- applies to PCARE, OUTPATIENT, PRIVATE PRACTICE
            g_error := ' GET FROM EPIS_INFO';
            BEGIN
                SELECT id_dcs_requested
                  INTO l_id_dep_clin_serv
                  FROM epis_info
                 WHERE epis_info.id_episode = i_episode
                   AND epis_info.id_dcs_requested IS NOT NULL;
            
            EXCEPTION
                WHEN no_data_found THEN
                    -- professional has no default SCHEDULE
                    -- lets use a default configured at sys_config
                    g_error             := ' GET SYS_CONFIG FOR SCHEDULE';
                    l_id_diagram_layout := get_default_lay_sys_config(i_lang, i_prof, l_gender, l_age, i_flg_type);
            END;
        
        ELSIF l_result = 'SYS_CONFIG'
        THEN
            -- APPLIES TO EDIS
            g_error             := ' GET FROM SYS_CONFIG';
            l_id_diagram_layout := get_default_lay_sys_config(i_lang, i_prof, l_gender, l_age, i_flg_type);
        
        END IF;
    
        -- check if a dep_clin_serv or diagram_alyout was found, if not send an error
        IF l_id_dep_clin_serv IS NULL
           AND l_id_diagram_layout IS NULL
        THEN
            g_error := 'dep_clin_serv';
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              REPLACE(pk_message.get_message(i_lang, i_prof, 'COMMON_M039'),
                                                      '@1',
                                                      g_error) || chr(10) ||
                                              'PK_DIAGRAM_NEW.GET_DEFAULT_DIAGRAM_LAYOUT',
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'get_default_lay',
                                              o_error);
        
            RETURN FALSE;
        END IF;
    
        IF l_id_diagram_layout IS NULL
        THEN
            -- FETCHING THE DEFAULT DIAGRAM LAYOUT 
            g_error := 'GET DEFAULT DIAGRAM_LAYOUT';
            BEGIN
                -- no caso de existirem diferentes configura?s diferentes para o layout por defeito, com sexo e sem sexo
                -- d?e prioridade ?onfigura? sem sexo
                SELECT id_diagram_layout
                  INTO l_id_diagram_layout
                  FROM (SELECT dldcs.id_diagram_layout, decode(dl.gender, NULL, 1, 0) rank, dldcs.id_software
                          FROM diag_lay_dep_clin_serv dldcs
                          JOIN diagram_layout dl
                            ON dl.id_diagram_layout = dldcs.id_diagram_layout
                         WHERE dldcs.id_dep_clin_serv = l_id_dep_clin_serv
                           AND dldcs.id_software IN (0, i_prof.software)
                           AND dldcs.flg_type = g_flg_type_default
                           AND (dl.gender IS NULL OR dl.gender = l_gender)
                           AND (dl.id_body_diag_age_grp IS NULL OR
                               (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                             FROM body_diag_age_grp bag
                                             LEFT JOIN (SELECT *
                                                         FROM bd_age_grp_soft_inst
                                                        WHERE id_institution IN (i_prof.institution, 0)
                                                          AND id_software IN (i_prof.software, 0)
                                                        ORDER BY id_institution DESC, id_software DESC) tb
                                               ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                            WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                               l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                             FROM body_diag_age_grp bag
                                             LEFT JOIN (SELECT *
                                                         FROM bd_age_grp_soft_inst
                                                        WHERE id_institution IN (i_prof.institution, 0)
                                                          AND id_software IN (i_prof.software, 0)
                                                        ORDER BY id_institution DESC, id_software DESC) tb
                                               ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                            WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                         ORDER BY id_software DESC, rank ASC)
                 WHERE rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL; -- validation is done is the next if
            END;
        END IF;
    
        -- check if a default diagram layout was found
        IF l_id_diagram_layout IS NULL
        THEN
            g_error := 'DIAGRAM_LAYOUT';
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              REPLACE(pk_message.get_message(i_lang, i_prof, 'COMMON_M039'),
                                                      '@1',
                                                      g_error) || chr(10) ||
                                              'PK_DIAGRAM_NEW.GET_DEFAULT_DIAGRAM_LAYOUT',
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'get_default_lay',
                                              o_error);
        
            RETURN FALSE;
        END IF;
    
        o_diagram_layout := l_id_diagram_layout;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_default_lay',
                                              o_error);
            RETURN FALSE;
    END get_default_lay;

    FUNCTION create_diag_internal
    (
        i_lang                language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_id_diagram_layout   IN diagram_layout.id_diagram_layout%TYPE,
        o_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error               OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_max_id_diagram_epis NUMBER := NULL;
        l_epis_diagram        epis_diagram.id_epis_diagram%TYPE;
        l_epis_diagram_layout epis_diagram_layout.id_epis_diagram_layout%TYPE;
        l_rowids              table_varchar;
    
        l_error t_error_out;
    
        t_ti_log_ins_exception EXCEPTION;
    
        CURSOR c_lock IS
            SELECT *
              FROM epis_diagram
             WHERE id_episode = i_epis
               FOR UPDATE;
    
        CURSOR c_max_id_diagram_epis IS
            SELECT MAX(diagram_order)
              FROM epis_diagram
             WHERE id_episode = i_epis;
    BEGIN
        g_error        := 'GET ID_EPIS_DIAGRAM';
        l_epis_diagram := ts_epis_diagram.next_key();
    
        g_error := 'CALC ID_DIAGRAM_EPIS';
        -- creating an entry in the epis_diagram table
        OPEN c_lock;
        CLOSE c_lock;
    
        OPEN c_max_id_diagram_epis;
        FETCH c_max_id_diagram_epis
            INTO l_max_id_diagram_epis;
        CLOSE c_max_id_diagram_epis;
    
        IF l_max_id_diagram_epis IS NULL
        THEN
            l_max_id_diagram_epis := 1;
        ELSE
            l_max_id_diagram_epis := l_max_id_diagram_epis + 1;
        END IF;
    
        g_error  := 'INSERT INTO EPIS_DIAGRAM';
        l_rowids := NULL;
        ts_epis_diagram.ins(id_epis_diagram_in  => l_epis_diagram,
                            flg_status_in       => g_flg_status_open,
                            dt_creation_tstz_in => current_timestamp,
                            id_episode_in       => i_epis,
                            id_patient_in       => pk_episode.get_id_patient(i_epis),
                            diagram_order_in    => l_max_id_diagram_epis,
                            rows_out            => l_rowids);
    
        --Process the events associated to an insert on epis_recomend
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIAGRAM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => i_epis,
                                i_flg_status => g_flg_status_open,
                                i_id_record  => l_epis_diagram,
                                i_flg_type   => g_bd_ti_log,
                                o_error      => l_error)
        THEN
            RAISE t_ti_log_ins_exception;
        END IF;
    
        IF i_id_diagram_layout IS NOT NULL
        THEN
            l_epis_diagram_layout := ts_epis_diagram_layout.next_key;
        
            g_error  := 'INSERT INTO EPIS_DIAGRAM_LAYOUT';
            l_rowids := NULL;
            ts_epis_diagram_layout.ins(id_epis_diagram_layout_in => l_epis_diagram_layout,
                                       id_epis_diagram_in        => l_epis_diagram,
                                       id_diagram_layout_in      => i_id_diagram_layout,
                                       layout_order_in           => 1, -- 1 : because the diagram is new and initially only contains the default layout
                                       flg_status_in             => g_flg_status_active,
                                       id_professional_in        => i_prof.id,
                                       dt_creation_tstz_in       => current_timestamp,
                                       rows_out                  => l_rowids);
        
            --Process the events associated to an insert on epis_recomend
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            o_epis_diagram_layout := l_epis_diagram_layout;
        
        END IF;
    
        o_epis_diagram := l_epis_diagram;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN t_ti_log_ins_exception THEN
            pk_utils.undo_changes;
            RETURN error_handling(i_lang, 'CREATE_DIAG_INTERNAL', g_error, SQLERRM, o_error);
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'create_diag_internal',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_diag_internal;

    FUNCTION get_new_diag_lay_imag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diagram_layout      IN diagram_layout.id_diagram_layout%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_diag_lay_img           OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_diag_lay_img FOR
            SELECT i_id_epis_diagram_layout id_epis_diagram_layout,
                   dli.id_diagram_lay_imag,
                   1 layout_order, -- default diagram will be first diagram
                   dli.id_diagram_image,
                   dli.id_diagram_layout,
                   dli.position_x,
                   dli.position_y,
                   get_diag_lay_imag_image_url(i_prof, di.id_diagram_image) url_diagram_image,
                   pk_translation.get_translation(i_lang, di.code_diagram_image) image_desc
              FROM diagram_layout dl
              JOIN diagram_lay_imag dli
                ON dl.id_diagram_layout = dli.id_diagram_layout
              JOIN diagram_image di
                ON di.id_diagram_image = dli.id_diagram_image
             WHERE dl.id_diagram_layout = i_id_diagram_layout
             ORDER BY dli.id_diagram_image;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_new_diag_lay_imag',
                                              o_error);
            RETURN FALSE;
    END get_new_diag_lay_imag;

    FUNCTION get_diag_tools
    (
        i_lang            IN language.id_language%TYPE,
        i_flg_family_tree IN VARCHAR2,
        o_diag_tools      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR O_DIAG_TOOLS';
        OPEN o_diag_tools FOR
            SELECT title,
                   id_diagram_tools_group,
                   id_diagram_tools,
                   ordena,
                   icon,
                   icon_color_image,
                   icon_color_tools,
                   icon_color_cancel,
                   acronym_group
              FROM (SELECT pk_translation.get_translation(i_lang, code_diagram_tools_group) title,
                           CASE
                                WHEN id_diagram_tools_group IN (11, 12)
                                     AND i_flg_family_tree = 'Y' THEN
                                 id_diagram_tools_group - 8
                                ELSE
                                 id_diagram_tools_group
                            END id_diagram_tools_group,
                           NULL id_diagram_tools,
                           0 ordena,
                           NULL icon,
                           NULL icon_color_image,
                           NULL icon_color_tools,
                           NULL icon_color_cancel,
                           pk_translation.get_translation(i_lang, code_acronym_group) acronym_group
                      FROM diagram_tools_group
                     WHERE flg_available = 'Y'
                       AND ((i_flg_family_tree = 'Y' AND id_diagram_tools_group NOT IN (3, 4)) OR
                           (i_flg_family_tree = 'N'))
                    UNION
                    SELECT NULL title,
                           dtg.id_diagram_tools_group,
                           CASE
                               WHEN dt.id_diagram_tools = 13
                                    AND i_flg_family_tree = 'Y' THEN
                                21
                               WHEN dt.id_diagram_tools = 14
                                    AND i_flg_family_tree = 'Y' THEN
                                22
                               ELSE
                                dt.id_diagram_tools
                           END id_diagram_tools,
                           dt.rank ordena,
                           CASE
                               WHEN dt.icon = 'ScarIcon'
                                    AND i_flg_family_tree = 'Y' THEN
                                'MaleSymbolDiagram'
                               WHEN dt.icon = 'FractureIcon'
                                    AND i_flg_family_tree = 'Y' THEN
                                'FemaleSymbolDiagram'
                               ELSE
                                dt.icon
                           END icon,
                           dt.icon_color_image,
                           dt.icon_color_tools,
                           dt.icon_color_cancel,
                           CASE
                               WHEN pk_translation.get_translation(i_lang, dtg.code_acronym_group) = 's' THEN
                                'm'
                               ELSE
                                pk_translation.get_translation(i_lang, dtg.code_acronym_group)
                           END acronym_group
                      FROM diagram_tools_group dtg, diagram_tools dt
                     WHERE dtg.id_diagram_tools_group = dt.id_diagram_tools_group
                       AND dtg.flg_available = 'Y')
             ORDER BY id_diagram_tools_group, ordena;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_tools);
            g_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_tools',
                                              o_error);
            RETURN FALSE;
    END get_diag_tools;

    FUNCTION get_diag_lay_imag_blob
    (
        i_diagram_image IN diagram_image.id_diagram_image%TYPE,
        i_prof          IN profissional,
        o_img           OUT BLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT di.image
          INTO o_img
          FROM diagram_image di
         WHERE di.id_diagram_image = i_diagram_image;
    
        o_img := pk_tech_utils.set_empty_blob(o_img);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              'GET DIAGRAM IMAGE',
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIAG_LAY_IMAG_BLOB',
                                              o_error);
            RETURN FALSE;
    END get_diag_lay_imag_blob;

    FUNCTION get_diag_lay_imag_blob_rep
    (
        i_diagram_image IN diagram_image.id_diagram_image%TYPE,
        i_prof          IN profissional,
        o_img           OUT BLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT di.reports_image
          INTO o_img
          FROM diagram_image di
         WHERE di.id_diagram_image = i_diagram_image;
    
        o_img := pk_tech_utils.set_empty_blob(o_img);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => NULL,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => 'GET REPORTS DIAGRAM IMAGE',
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DIAG_LAY_IMAG_BLOB_REP',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_diag_lay_imag_blob_rep;

    FUNCTION get_diag_lay_blob
    (
        i_diagram_layout IN diagram_layout.id_diagram_layout%TYPE,
        i_prof           IN profissional,
        o_img            OUT BLOB,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_lang sys_config.value%TYPE := pk_sysconfig.get_config('LANGUAGE', i_prof);
    
    BEGIN
    
        g_error := 'GET DIAGRAM IMAGE';
        SELECT dl.small_image
          INTO o_img
          FROM diagram_layout dl
         WHERE dl.id_diagram_layout = i_diagram_layout;
    
        o_img := pk_tech_utils.set_empty_blob(o_img);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(l_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(NULL,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_lay_blob',
                                              o_error);
            RETURN FALSE;
    END get_diag_lay_blob;

    FUNCTION remove_non_used_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_to_upd            table_number := table_number();
        l_diag_list              table_number := table_number();
        l_has_symbol             VARCHAR2(1 CHAR);
        l_max_diag_lay           epis_diagram_layout.id_epis_diagram_layout%TYPE;
        l_id_epis_diagram_layout table_number;
    
        l_rowids_edl table_varchar;
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            BEGIN
                SELECT ed.id_episode
                  BULK COLLECT
                  INTO l_epis_to_upd
                  FROM epis_diagram ed
                 WHERE ed.id_patient = i_patient;
            EXCEPTION
                WHEN no_data_found THEN
                    l_epis_to_upd := NULL;
            END;
        ELSE
            l_epis_to_upd.extend();
            l_epis_to_upd(1) := i_episode;
        END IF;
    
        FOR i IN 1 .. l_epis_to_upd.count
        LOOP
            --get the layouts for the episode
            BEGIN
                SELECT ed.id_epis_diagram
                  BULK COLLECT
                  INTO l_diag_list
                  FROM epis_diagram ed
                 WHERE ed.id_episode = l_epis_to_upd(i);
            EXCEPTION
                WHEN no_data_found THEN
                    l_diag_list := NULL;
            END;
        
            FOR j IN 1 .. l_diag_list.count
            LOOP
                --check if some layout with symbols exist
                BEGIN
                    SELECT pk_alert_constant.g_yes
                      INTO l_has_symbol
                      FROM epis_diagram_layout edl
                     WHERE edl.id_epis_diagram = l_diag_list(j)
                       AND EXISTS (SELECT 1
                              FROM epis_diagram_detail edd
                             WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout)
                       AND rownum <= 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_has_symbol := pk_alert_constant.g_no;
                END;
            
                IF l_has_symbol = pk_alert_constant.g_yes
                THEN
                    --if some layout with symbols exist we will update all
                    SELECT edl.id_epis_diagram_layout
                      BULK COLLECT
                      INTO l_id_epis_diagram_layout
                      FROM epis_diagram_layout edl
                     WHERE edl.id_epis_diagram = l_diag_list(j)
                       AND edl.flg_status = 'A'
                       AND NOT EXISTS (SELECT 1
                              FROM epis_diagram_detail edd
                             WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout);
                
                    l_rowids_edl := NULL;
                    FOR k IN 1 .. l_id_epis_diagram_layout.count
                    LOOP
                        g_error := 'UPDATE EPIS_DIAGRAM_LAYOUT';
                        ts_epis_diagram_layout.upd(id_epis_diagram_layout_in => l_id_epis_diagram_layout(k),
                                                   flg_status_in             => g_diag_lay_removed,
                                                   rows_out                  => l_rowids_edl);
                    END LOOP;
                    --Process the events associated to an insert on epis_recomend
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                                  i_rowids     => l_rowids_edl,
                                                  o_error      => o_error);
                
                ELSE
                    --if not we update all except the most recent
                    BEGIN
                        SELECT id_epis_diagram_layout
                          INTO l_max_diag_lay
                          FROM (SELECT edl.id_epis_diagram_layout
                                  FROM epis_diagram_layout edl
                                 WHERE edl.id_epis_diagram = l_diag_list(j)
                                   AND edl.flg_status = 'A'
                                 ORDER BY edl.dt_creation_tstz DESC)
                         WHERE rownum <= 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_max_diag_lay := NULL;
                    END;
                
                    SELECT edl.id_epis_diagram_layout
                      BULK COLLECT
                      INTO l_id_epis_diagram_layout
                      FROM epis_diagram_layout edl
                     WHERE edl.id_epis_diagram = l_diag_list(j)
                       AND edl.flg_status = 'A'
                       AND NOT EXISTS (SELECT 1
                              FROM epis_diagram_detail edd
                             WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout)
                       AND edl.id_epis_diagram_layout <> l_max_diag_lay
                       AND l_max_diag_lay IS NOT NULL;
                
                    l_rowids_edl := NULL;
                    FOR k IN 1 .. l_id_epis_diagram_layout.count
                    LOOP
                        g_error := 'UPDATE EPIS_DIAGRAM_LAYOUT';
                        ts_epis_diagram_layout.upd(id_epis_diagram_layout_in => l_id_epis_diagram_layout(k),
                                                   flg_status_in             => g_diag_lay_removed,
                                                   rows_out                  => l_rowids_edl);
                    END LOOP;
                    --Process the events associated to an insert on epis_recomend
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                                  i_rowids     => l_rowids_edl,
                                                  o_error      => o_error);
                
                END IF;
            END LOOP;
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
                                              'REMOVE_NON_USED_DIAG',
                                              o_error);
            RETURN FALSE;
    END remove_non_used_diag;

    FUNCTION get_diag_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis            IN episode.id_episode%TYPE,
        i_filter          IN VARCHAR2,
        i_flg_family_tree IN VARCHAR2,
        o_info            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit         visit.id_visit%TYPE;
        l_epis_type     episode.id_epis_type%TYPE;
        l_episode_visit table_number;
    
    BEGIN
    
        --if we are not in edition mode, then we must delete the images that have no simbols associated (MJG request)
        IF i_filter = pk_alert_constant.g_yes
        THEN
            --remove unused diagrams layouts
            IF NOT remove_non_used_diag(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => NULL,
                                        i_episode => i_epis,
                                        o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --we can now commit the changes already
            COMMIT;
        END IF;
    
        --get the id_visit of the current episode
        SELECT e.id_visit, e.id_epis_type
          INTO l_visit, l_epis_type
          FROM episode e
         WHERE e.id_episode = i_epis;
    
        --get the list of episodes of the current visit
        SELECT e.id_episode
          BULK COLLECT
          INTO l_episode_visit
          FROM episode e
         WHERE e.id_visit = l_visit;
    
        g_error := 'GET CURSOR O_INFO';
        OPEN o_info FOR
            SELECT
            -- Return description of the diagram with software where it was requested (if not actual software)
             decode(l_epis_type,
                    nvl(t_ti_log.get_epis_type(i_lang,
                                               i_prof,
                                               epi.id_epis_type,
                                               g_flg_status_close,
                                               ed.id_epis_diagram,
                                               g_bd_ti_log),
                        epi.id_epis_type),
                    pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order,
                    pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order || ' (' ||
                    pk_message.get_message(i_lang,
                                           profissional(i_prof.id,
                                                        i_prof.institution,
                                                        nvl(t_ti_log.get_epis_type_soft(i_lang,
                                                                                        i_prof,
                                                                                        epi.id_epis_type,
                                                                                        g_flg_status_close,
                                                                                        ed.id_epis_diagram,
                                                                                        g_bd_ti_log),
                                                            t_ti_log.get_epis_type_soft(i_lang,
                                                                                        i_prof,
                                                                                        epi.id_epis_type,
                                                                                        g_flg_status_open,
                                                                                        ed.id_epis_diagram,
                                                                                        g_bd_ti_log))),
                                           'IMAGE_T009') || ')') diagram_number,
             CASE
              -- 'Created'
                  WHEN ed.flg_status = g_flg_status_open
                       AND ed.dt_last_update_tstz IS NULL THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T002') || ': '
              -- 'Updated'
                  WHEN ed.flg_status = g_flg_status_open
                       AND ed.dt_last_update_tstz IS NOT NULL THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041') || ': '
              -- 'Closed'
                  WHEN ed.flg_status = g_flg_status_close THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T012') || ': '
              
              END last_update_tag,
             pk_date_utils.date_time_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) date_time,
             ed.id_epis_diagram,
             ed.flg_status
              FROM epis_diagram ed
              JOIN episode epi
                ON epi.id_episode = ed.id_episode
             WHERE ed.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      *
                                       FROM TABLE(l_episode_visit) t)
               AND EXISTS (SELECT 1
                      FROM epis_diagram_layout edl
                     WHERE edl.id_epis_diagram = ed.id_epis_diagram
                       AND edl.flg_status <> g_diag_lay_removed
                       AND ((i_flg_family_tree = 'Y' AND edl.id_diagram_layout = 3475) OR
                           (i_flg_family_tree = 'N' AND edl.id_diagram_layout != 3475)))
             ORDER BY ed.id_epis_diagram DESC, ed.diagram_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_epis',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_diag_epis;

    FUNCTION is_family_tree(i_id_epis_diagram IN NUMBER) RETURN VARCHAR2 IS
    
        l_count  NUMBER;
        l_return VARCHAR2(0050 CHAR);
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_diagram_layout edlt
         WHERE edlt.id_epis_diagram = i_id_epis_diagram
           AND edlt.id_diagram_layout = 3475;
    
        IF l_count > 0
        THEN
            l_return := 'Y';
        END IF;
    
        RETURN l_count;
    
    END is_family_tree;

    FUNCTION get_diag_epis_report
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN episode.id_episode%TYPE,
        i_filter IN VARCHAR2,
        o_info   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_visit         visit.id_visit%TYPE;
        l_epis_type     episode.id_epis_type%TYPE;
        l_episode_visit table_number;
    
    BEGIN
        --if we are not in edition mode, then we must delete the images that have no simbols associated (MJG request)
        IF i_filter = pk_alert_constant.g_yes
        THEN
            --remove unused diagrams layouts
            IF NOT remove_non_used_diag(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => NULL,
                                        i_episode => i_epis,
                                        o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --we can now commit the changes already
            COMMIT;
        END IF;
    
        --get the id_visit of the current episode
        SELECT e.id_visit, e.id_epis_type
          INTO l_visit, l_epis_type
          FROM episode e
         WHERE e.id_episode = i_epis;
    
        --get the list of episodes of the current visit
        SELECT e.id_episode
          BULK COLLECT
          INTO l_episode_visit
          FROM episode e
         WHERE e.id_visit = l_visit;
    
        g_error := 'GET CURSOR O_INFO';
        OPEN o_info FOR
            SELECT
            -- Return description of the diagram with software where it was requested (if not actual software)
             decode(l_epis_type,
                    nvl(t_ti_log.get_epis_type(i_lang,
                                               i_prof,
                                               epi.id_epis_type,
                                               g_flg_status_close,
                                               ed.id_epis_diagram,
                                               g_bd_ti_log),
                        epi.id_epis_type),
                    pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order,
                    pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order || ' (' ||
                    pk_message.get_message(i_lang,
                                           profissional(i_prof.id,
                                                        i_prof.institution,
                                                        nvl(t_ti_log.get_epis_type_soft(i_lang,
                                                                                        i_prof,
                                                                                        epi.id_epis_type,
                                                                                        g_flg_status_close,
                                                                                        ed.id_epis_diagram,
                                                                                        g_bd_ti_log),
                                                            t_ti_log.get_epis_type_soft(i_lang,
                                                                                        i_prof,
                                                                                        epi.id_epis_type,
                                                                                        g_flg_status_open,
                                                                                        ed.id_epis_diagram,
                                                                                        g_bd_ti_log))),
                                           'IMAGE_T009') || ')') diagram_number,
             CASE
              -- 'Created'
                  WHEN ed.flg_status = g_flg_status_open
                       AND ed.dt_last_update_tstz IS NULL THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T002') || ': '
              -- 'Updated'
                  WHEN ed.flg_status = g_flg_status_open
                       AND ed.dt_last_update_tstz IS NOT NULL THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041') || ': '
              -- 'Closed'
                  WHEN ed.flg_status = g_flg_status_close THEN
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T012') || ': '
              END last_update_tag,
             pk_date_utils.date_time_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) date_time,
             ed.id_epis_diagram,
             pk_diagram_new.is_family_tree(ed.id_epis_diagram) is_family_tree
              FROM epis_diagram ed
              JOIN episode epi
                ON epi.id_episode = ed.id_episode
             WHERE ed.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      *
                                       FROM TABLE(l_episode_visit))
               AND EXISTS (SELECT 1
                      FROM epis_diagram_layout edl
                      JOIN epis_diagram_detail edd
                        ON edd.id_epis_diagram_layout = edl.id_epis_diagram_layout
                     WHERE edl.id_epis_diagram = ed.id_epis_diagram)
             ORDER BY ed.id_epis_diagram DESC, ed.diagram_order DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_epis',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_diag_epis_report;

    FUNCTION get_new_diag_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diagram_order IN epis_diagram.diagram_order%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_desc     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET DIAG DESC CURSOR';
        OPEN o_diag_desc FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || i_diagram_order diag_desc,
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041') || ': ' diag_status,
                   pk_date_utils.date_time_chr_tsz(i_lang, current_timestamp, i_prof) diag_date,
                   i_flg_type flg_type
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_new_diag_desc',
                                              o_error);
            RETURN FALSE;
    END get_new_diag_desc;

    FUNCTION get_diag_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_family_tree IN VARCHAR2,
        o_diag_desc       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type     episode.id_epis_type%TYPE;
        l_ori_epis_type episode.id_epis_type%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_ori_epis_type
              FROM episode e
             WHERE e.id_episode IN (SELECT id_episode
                                      FROM epis_diagram
                                     WHERE id_epis_diagram = i_id_epis_diagram
                                       AND rownum <= 1);
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        g_error := 'GET DIAG DESC CURSOR';
        OPEN o_diag_desc FOR
            SELECT ed.id_epis_diagram,
                   decode(l_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     l_ori_epis_type,
                                                     g_flg_status_close,
                                                     ed.id_epis_diagram,
                                                     g_bd_ti_log),
                              l_ori_epis_type),
                          pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order,
                          pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order || ' (' ||
                          pk_message.get_message(i_lang,
                                                 profissional(i_prof.id,
                                                              i_prof.institution,
                                                              nvl(t_ti_log.get_epis_type_soft(i_lang,
                                                                                              i_prof,
                                                                                              l_ori_epis_type,
                                                                                              g_flg_status_close,
                                                                                              ed.id_epis_diagram,
                                                                                              g_bd_ti_log),
                                                                  t_ti_log.get_epis_type_soft(i_lang,
                                                                                              i_prof,
                                                                                              l_ori_epis_type,
                                                                                              g_flg_status_open,
                                                                                              ed.id_epis_diagram,
                                                                                              g_bd_ti_log))),
                                                 'IMAGE_T009') || ')') diag_desc,
                   CASE
                    -- 'Created'
                        WHEN ed.flg_status = g_flg_status_open
                             AND ed.dt_last_update_tstz IS NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T002') || ': '
                    -- 'Updated'
                        WHEN ed.flg_status = g_flg_status_open
                             AND ed.dt_last_update_tstz IS NOT NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041') || ': '
                    -- 'Closed'
                        WHEN ed.flg_status = g_flg_status_close THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T012') || ': '
                    
                    END diag_status,
                   pk_date_utils.date_time_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) diag_date,
                   decode(i_flg_family_tree, 'Y', 'F', dl.flg_type) flg_type
              FROM epis_diagram ed
              JOIN epis_diagram_layout edl
                ON ed.id_epis_diagram = edl.id_epis_diagram
              JOIN diagram_layout dl
                ON edl.id_diagram_layout = dl.id_diagram_layout
              LEFT JOIN epis_diagram_detail edd
                ON edl.id_epis_diagram_layout = edd.id_epis_diagram_layout
              LEFT JOIN epis_diagram_detail_notes eddn
                ON eddn.id_epis_diagram_detail = edd.id_epis_diagram_detail
             WHERE ed.id_epis_diagram = i_id_epis_diagram
               AND edl.flg_status <> g_diag_lay_removed
             GROUP BY ed.id_epis_diagram,
                      ed.flg_status,
                      ed.diagram_order,
                      ed.dt_creation_tstz,
                      ed.dt_last_update_tstz,
                      dl.flg_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_desc',
                                              o_error);
            RETURN FALSE;
    END get_diag_desc;

    FUNCTION get_diag_lay_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_epis_diagram        IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE DEFAULT NULL,
        i_report                 IN VARCHAR2,
        o_diag_lay_desc          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET DIAG LAY DESC CURSOR';
        OPEN o_diag_lay_desc FOR
            SELECT edl.id_epis_diagram_layout,
                   REPLACE(pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T011'), '@1', edl.layout_order) ||
                   decode(edl.flg_status,
                          'C',
                          ' ' || '(' || pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T017') || ')') diag_lay_desc,
                   edl.flg_status,
                   pk_sysdomain.get_domain(g_epis_diag_lay_flg_status_dmn, edl.flg_status, i_lang) diag_lay_status,
                   pk_translation.get_translation(i_lang, dl.code_diagram_layout) layout_desc,
                   get_diag_lay_image_url(i_prof, dl.id_diagram_layout) image_url
              FROM epis_diagram ed
              JOIN epis_diagram_layout edl
                ON edl.id_epis_diagram = ed.id_epis_diagram
              JOIN diagram_layout dl
                ON dl.id_diagram_layout = edl.id_diagram_layout
             WHERE ed.id_epis_diagram = i_id_epis_diagram
               AND edl.flg_status <> g_diag_lay_removed
               AND (EXISTS (SELECT 1
                              FROM epis_diagram_detail edd
                             WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout) OR
                    nvl(i_report, pk_alert_constant.g_no) = pk_alert_constant.g_no)
               AND nvl(i_id_epis_diagram_layout, edl.id_epis_diagram_layout) = edl.id_epis_diagram_layout
             ORDER BY edl.layout_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_lay_desc',
                                              o_error);
            RETURN FALSE;
    END get_diag_lay_desc;

    FUNCTION get_epis_diag_lay_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        o_diag_layout OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET DIAG LAY DESC CURSOR o_diag_layout';
        OPEN o_diag_layout FOR
            SELECT DISTINCT t.id_diagram_layout,
                            pk_translation.get_translation(i_lang, t.code_diagram_layout) desc_info,
                            t.id_episode,
                            t.dt_creation_tstz dt_creation,
                            pk_prof_utils.get_detail_signature(i_lang,
                                                               i_prof,
                                                               t.id_episode,
                                                               t.dt_creation_tstz,
                                                               t.id_professional) signature
              FROM (SELECT dl.id_diagram_layout,
                           dl.code_diagram_layout,
                           ed.id_episode,
                           ed.dt_creation_tstz,
                           edl.id_professional
                      FROM epis_diagram ed
                      JOIN epis_diagram_layout edl
                        ON edl.id_epis_diagram = ed.id_epis_diagram
                      JOIN diagram_layout dl
                        ON dl.id_diagram_layout = edl.id_diagram_layout
                     WHERE ed.id_episode IN (SELECT /*+opt_estimate(table, t, rows = 1)*/
                                              column_value
                                               FROM TABLE(i_tbl_episode) t)
                       AND edl.flg_status NOT IN (g_diag_lay_removed, g_diag_lay_cancelled)) t
             ORDER BY dt_creation DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_layout);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_diag_lay_desc',
                                              o_error);
            RETURN FALSE;
    END get_epis_diag_lay_desc;

    FUNCTION get_new_diag_lay_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diagram_layout      IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_diag_lay_desc          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DIAG LAY DESC CURSOR';
        OPEN o_diag_lay_desc FOR
            SELECT i_id_epis_diagram_layout id_epis_diagram_layout,
                   dl.id_diagram_layout,
                   g_flg_status_active flg_status,
                   pk_sysdomain.get_domain(g_epis_diag_lay_flg_status_dmn, g_flg_status_active, i_lang) diag_lay_status,
                   pk_translation.get_translation(i_lang, dl.code_diagram_layout) layout_desc,
                   pk_translation.get_translation(i_lang, dl.code_diagram_layout) diag_lay_desc,
                   get_diag_lay_image_url(i_prof, dl.id_diagram_layout) image_url
              FROM diagram_layout dl
             WHERE dl.id_diagram_layout = i_id_diagram_layout;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_new_diag_lay_desc',
                                              o_error);
            RETURN FALSE;
    END get_new_diag_lay_desc;

    FUNCTION get_diag_lay_imag
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagram    IN epis_diagram.id_epis_diagram%TYPE,
        i_report          IN VARCHAR2,
        i_flg_family_tree IN VARCHAR2,
        o_diag_lay_img    OUT pk_types.cursor_type,
        o_diag_desc       OUT pk_types.cursor_type,
        o_diag_lay_desc   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'call get_diag_lay_imag in REPORTS context';
        RETURN get_diag_lay_imag(i_lang                   => i_lang,
                                 i_prof                   => i_prof,
                                 i_episode                => i_episode,
                                 i_epis_diagram           => i_epis_diagram,
                                 i_id_epis_diagram_layout => NULL,
                                 i_report                 => i_report,
                                 i_flg_tmp_diag           => pk_alert_constant.g_no,
                                 i_flg_type               => g_flg_type_others,
                                 i_flg_family_tree        => i_flg_family_tree,
                                 o_diag_lay_img           => o_diag_lay_img,
                                 o_diag_desc              => o_diag_desc,
                                 o_diag_lay_desc          => o_diag_lay_desc,
                                 o_error                  => o_error);
    END get_diag_lay_imag;

    FUNCTION get_diag_lay_imag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_epis_diagram           IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_report                 IN VARCHAR2,
        i_flg_tmp_diag           IN pk_types.t_flg_char,
        i_flg_type               IN diagram_layout.flg_type%TYPE,
        i_flg_family_tree        IN VARCHAR2,
        o_diag_lay_img           OUT pk_types.cursor_type,
        o_diag_desc              OUT pk_types.cursor_type,
        o_diag_lay_desc          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_diagram        epis_diagram.id_epis_diagram%TYPE;
        l_id_diagram_layout      diagram_layout.id_diagram_layout%TYPE;
        l_curr_diag_rank         epis_diagram.diagram_order%TYPE;
        l_id_epis_diagram_layout table_number;
    
        l_internal_exception EXCEPTION;
        --*************************
        l_flg_type VARCHAR2(0010 CHAR);
        l_bool_flg BOOLEAN;
        l_flag     NUMBER;
    
    BEGIN
    
        l_bool_flg := i_flg_type IS NULL;
        IF l_bool_flg
        THEN
            l_flag     := 0;
            l_flg_type := 'D';
        ELSE
            l_flag     := 1;
            l_flg_type := i_flg_type;
        END IF;
    
        -- validate input parameters
        IF (i_episode IS NULL AND i_epis_diagram IS NULL)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              REPLACE(pk_message.get_message(i_lang, i_prof, 'COMMON_M038'),
                                                      '@1',
                                                      'PK_DIAGRAM_NEW.GET_DIAG_LAY_IMAG'),
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_lay_imag',
                                              o_error);
        
            RAISE l_internal_exception;
        END IF;
    
        -- get id_epis_diagram
        IF (i_epis_diagram IS NULL)
        THEN
        
            -- episode has any diagram?
            g_error := 'GET last episode diagram';
            BEGIN
                SELECT ed.id_epis_diagram, ed.diagram_order
                  INTO l_id_epis_diagram, l_curr_diag_rank
                  FROM epis_diagram ed
                 WHERE ed.id_episode = i_episode
                   AND ed.diagram_order = (SELECT MAX(ed.diagram_order)
                                             FROM epis_diagram ed
                                            WHERE ed.id_episode = i_episode);
            EXCEPTION
                WHEN no_data_found THEN
                    --if used in reports, theres nothing to show
                    IF i_report = pk_alert_constant.g_yes
                    THEN
                        pk_types.open_my_cursor(o_diag_lay_img);
                        pk_types.open_my_cursor(o_diag_desc);
                        pk_types.open_my_cursor(o_diag_lay_desc);
                    
                        RETURN TRUE;
                    ELSE
                        NULL; -- ok there is no diagram in episode
                    END IF;
            END;
        ELSE
            l_id_epis_diagram := i_epis_diagram;
        END IF;
    
        -- getting type of diagram
        IF l_id_epis_diagram IS NOT NULL
        THEN
            BEGIN
                SELECT e.id_diagram_layout
                  BULK COLLECT
                  INTO l_id_epis_diagram_layout
                  FROM epis_diagram_layout e
                  JOIN (SELECT ddd1.*
                          FROM diagram_layout ddd1
                         WHERE l_flag = 0
                           AND ddd1.flg_type != 'D'
                        UNION ALL
                        SELECT ddd2.*
                          FROM diagram_layout ddd2
                         WHERE l_flag = 1
                           AND ddd2.flg_type = i_flg_type) dl
                    ON dl.id_diagram_layout = e.id_diagram_layout
                 WHERE e.id_epis_diagram = l_id_epis_diagram;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_epis_diagram_layout := NULL;
            END;
        END IF;
    
        -- in case it is the family tree screen, it can only show the family tree
        IF l_id_epis_diagram_layout IS NOT NULL
        THEN
            FOR i IN 1 .. l_id_epis_diagram_layout.count
            LOOP
                IF i_flg_family_tree = 'Y'
                THEN
                
                    IF l_id_epis_diagram_layout(i) != 3475
                    THEN
                        l_id_epis_diagram := NULL;
                    END IF;
                    -- if it's not the family tree screen, cannot show the diagram
                ELSE
                    IF l_id_epis_diagram_layout(i) = 3475
                    THEN
                        l_id_epis_diagram := NULL;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        IF i_flg_tmp_diag = pk_alert_constant.g_yes
        THEN
            l_id_epis_diagram := NULL;
        END IF;
    
        -- get diagram layouts
        IF (l_id_epis_diagram IS NOT NULL)
        THEN
            -- episode already has a diagram, get diagram layouts
            g_error := 'GET CURSOR O_DIAG_LAY_IMG 1';
            OPEN o_diag_lay_img FOR
                SELECT edl.id_epis_diagram_layout,
                       dli.id_diagram_lay_imag,
                       edl.layout_order,
                       dli.id_diagram_image,
                       dli.id_diagram_layout,
                       dli.position_x,
                       dli.position_y,
                       get_diag_lay_imag_image_url(i_prof, di.id_diagram_image) url_diagram_image,
                       pk_translation.get_translation(i_lang, di.code_diagram_image) image_desc
                  FROM (SELECT ddd1.*
                          FROM diagram_layout ddd1
                         WHERE l_flag = 0
                           AND ddd1.flg_type != 'D'
                        UNION ALL
                        SELECT ddd2.*
                          FROM diagram_layout ddd2
                         WHERE l_flag = 1
                           AND ddd2.flg_type = i_flg_type) dl
                  JOIN diagram_lay_imag dli
                    ON dl.id_diagram_layout = dli.id_diagram_layout
                  JOIN diagram_image di
                    ON di.id_diagram_image = dli.id_diagram_image
                  JOIN epis_diagram_layout edl
                    ON edl.id_diagram_layout = dl.id_diagram_layout
                  JOIN epis_diagram ed
                    ON ed.id_epis_diagram = edl.id_epis_diagram
                 WHERE ed.id_epis_diagram = l_id_epis_diagram
                   AND edl.flg_status <> g_diag_lay_removed
                   AND (EXISTS (SELECT 1
                                  FROM epis_diagram_detail edd
                                 WHERE edd.id_epis_diagram_layout = edl.id_epis_diagram_layout) OR
                        nvl(i_report, pk_alert_constant.g_no) = pk_alert_constant.g_no)
                   AND nvl(i_id_epis_diagram_layout, edl.id_epis_diagram_layout) = edl.id_epis_diagram_layout
                 ORDER BY edl.layout_order, dli.id_diagram_image;
        
            -- get diagram description
            g_error := 'CALL get_diag_desc';
            IF (NOT get_diag_desc(i_lang, i_prof, l_id_epis_diagram, i_episode, i_flg_family_tree, o_diag_desc, o_error))
            THEN
                RAISE l_internal_exception; -- error on getting diagram description
            END IF;
        
            -- get figures descriptions
            g_error := 'CALL get_diag_lay_desc';
            IF (NOT get_diag_lay_desc(i_lang,
                                      i_prof,
                                      l_id_epis_diagram,
                                      i_id_epis_diagram_layout,
                                      nvl(i_report, pk_alert_constant.g_no),
                                      o_diag_lay_desc,
                                      o_error))
            THEN
                RAISE l_internal_exception; -- error on getting diagram layout descriptions
            END IF;
        
        ELSE
            IF i_flg_tmp_diag = pk_alert_constant.g_yes
            THEN
                l_curr_diag_rank := nvl(l_curr_diag_rank, 0) + 1;
            ELSE
                l_curr_diag_rank := 1; -- 1 is the diagram_order for an unexisting diagram
            END IF;
        
            -- get default diagram layout
            IF i_flg_family_tree = pk_alert_constant.g_no
            THEN
                IF NOT get_default_lay(i_lang, i_prof, i_episode, i_flg_type, l_id_diagram_layout, o_error)
                THEN
                    -- error on getting default diagram layout
                    NULL;
                END IF;
            ELSE
                l_id_diagram_layout := 3475; -- family tree diagram layout
            END IF;
        
            -- get diagram layout images from layout diagram        
            g_error := 'CALL get_new_diag_lay_imag';
            IF NOT get_new_diag_lay_imag(i_lang,
                                         i_prof,
                                         l_id_diagram_layout,
                                         i_id_epis_diagram_layout,
                                         o_diag_lay_img,
                                         o_error)
            THEN
                RAISE l_internal_exception;
            END IF;
        
            -- get diagram description
            g_error := 'CALL get_new_diag_desc';
            IF NOT get_new_diag_desc(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_diagram_order => l_curr_diag_rank,
                                     i_flg_type      => CASE i_flg_family_tree
                                                            WHEN pk_alert_constant.g_yes THEN
                                                             'F'
                                                            ELSE
                                                             i_flg_type
                                                        END,
                                     o_diag_desc     => o_diag_desc,
                                     o_error         => o_error)
            THEN
                RAISE l_internal_exception; -- error on getting default diagram layout
            END IF;
        
            -- get new figure description
            g_error := 'CALL get_new_diag_lay_desc';
            IF (NOT get_new_diag_lay_desc(i_lang,
                                          i_prof,
                                          l_id_diagram_layout,
                                          i_id_epis_diagram_layout,
                                          o_diag_lay_desc,
                                          o_error))
            THEN
                RAISE l_internal_exception; -- error on getting diagram layout descriptions
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_exception THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_desc);
            pk_types.open_my_cursor(o_diag_lay_desc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_desc);
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_lay_imag',
                                              o_error);
            RETURN FALSE;
    END get_diag_lay_imag;

    FUNCTION get_diag_det_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_diag  IN epis_diagram.id_epis_diagram%TYPE,
        o_diag_det OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_DIAG_DET';
        OPEN o_diag_det FOR
            SELECT pk_translation.get_translation(i_lang, dtg.code_acronym_group) acronym_group,
                   edd.value,
                   edd.id_epis_diagram_detail,
                   edd.id_professional prof_det,
                   pdd.nick_name name_prof_det,
                   pk_translation.get_translation(i_lang, sdd.code_speciality) desc_spec_det,
                   pk_date_utils.dt_chr_tsz(i_lang, edd.dt_diagram_detail_tstz, i_prof) date_target_det,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    edd.dt_diagram_detail_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target_det,
                   eddn.id_professional prof_notes,
                   p.nick_name name_prof_notes,
                   pk_translation.get_translation(i_lang, s.code_speciality) desc_spec_notes,
                   eddn.notes,
                   pk_date_utils.dt_chr_tsz(i_lang, eddn.dt_notes_tstz, i_prof) date_target_notes,
                   pk_date_utils.date_char_hour_tsz(i_lang, eddn.dt_notes_tstz, i_prof.institution, i_prof.software) hour_target_notes,
                   edd.notes_cancel,
                   edd.id_prof_cancel,
                   pc.nick_name name_prof_cancel,
                   pk_translation.get_translation(i_lang, sc.code_speciality) desc_spec_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang, edd.dt_cancel_tstz, i_prof) date_target_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, edd.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_target_cancel,
                   edd.flg_status status_det,
                   dt.icon
              FROM epis_diagram              ed,
                   epis_diagram_detail       edd,
                   epis_diagram_detail_notes eddn,
                   epis_diagram_layout       edl,
                   professional              p,
                   speciality                s,
                   professional              pc,
                   speciality                sc,
                   professional              pdd,
                   speciality                sdd,
                   diagram_tools             dt,
                   diagram_tools_group       dtg
             WHERE ed.id_epis_diagram = edl.id_epis_diagram
               AND edl.id_epis_diagram_layout(+) = edd.id_epis_diagram_layout
               AND edd.id_epis_diagram_detail = eddn.id_epis_diagram_detail(+)
               AND eddn.id_professional = p.id_professional(+)
               AND s.id_speciality(+) = p.id_speciality
               AND edd.id_prof_cancel = pc.id_professional(+)
               AND sc.id_speciality(+) = pc.id_speciality
               AND edd.id_professional = pdd.id_professional(+)
               AND sdd.id_speciality(+) = pdd.id_speciality
               AND edd.id_diagram_tools = dt.id_diagram_tools
               AND dt.id_diagram_tools_group = dtg.id_diagram_tools_group
               AND ed.id_epis_diagram = i_id_diag
               AND edl.flg_status <> g_diag_lay_removed
             ORDER BY pk_sysdomain.get_rank(i_lang, 'DIAGRAM.FLG_STATUS', edd.flg_status),
                      acronym_group,
                      edd.value,
                      date_target_det ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_det);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_det_notes',
                                              o_error);
            RETURN FALSE;
    END get_diag_det_notes;

    FUNCTION set_diag_lay_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_id_diag             IN epis_diagram.id_epis_diagram%TYPE,
        i_id_lay_type         IN table_varchar,
        i_id_layout           IN table_varchar,
        i_id_imag             IN table_varchar,
        i_id_diag_det         IN table_varchar,
        i_id_icon             IN table_varchar,
        i_val_icon            IN table_varchar,
        i_val_posx            IN table_varchar,
        i_val_posy            IN table_varchar,
        i_notes               IN table_varchar,
        i_coor_x              IN table_varchar,
        i_coor_y              IN table_varchar,
        i_color               IN table_varchar,
        o_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_next_det                   epis_diagram_detail.id_epis_diagram_detail%TYPE;
        l_next_det_n                 epis_diagram_detail_notes.id_diagram_detail_notes%TYPE;
        l_char                       VARCHAR2(1);
        l_dft_epis_diag_lay_not_crtd BOOLEAN := TRUE;
    
        l_id_epis_diagram_layout epis_diagram_layout.id_epis_diagram_layout%TYPE;
        l_def_layout_order       NUMBER;
    
        l_rowids     table_varchar;
        l_rowids_edl table_varchar;
    
        l_coordinates CLOB;
    
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis
               AND flg_status <> g_epis_cancel;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- Verificar se o episodio esta CANCELADO
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
    
        IF g_found
        THEN
            -- a new diagram is created when the i_id_diag is null, which means we are only registering the default layout        
            IF i_id_diag IS NULL
            THEN
                g_error := 'call create_diag_internal';
                IF NOT create_diag_internal(i_lang,
                                            i_prof,
                                            i_epis,
                                            i_id_lay_type(1), -- we may use the first value in the array because in this case we are setting only on default layout 
                                            o_epis_diagram,
                                            l_id_epis_diagram_layout,
                                            o_error)
                THEN
                    RETURN FALSE;
                ELSE
                    o_epis_diagram_layout        := l_id_epis_diagram_layout;
                    l_dft_epis_diag_lay_not_crtd := FALSE;
                END IF;
            END IF;
        
            FOR i IN 1 .. i_id_imag.count
            LOOP
                IF l_dft_epis_diag_lay_not_crtd
                   AND i_id_layout(i) IS NULL
                THEN
                    g_error                  := 'INSERT INTO EPIS_DIAGRAM_LAYOUT';
                    l_id_epis_diagram_layout := ts_epis_diagram_layout.next_key;
                
                    -- we need to know the layout in which the default diagram will be_ inserted                
                    SELECT (MAX(edl.layout_order) + 1)
                      INTO l_def_layout_order
                      FROM epis_diagram_layout edl
                     WHERE edl.id_epis_diagram = i_id_diag;
                
                    g_error      := 'INSERT INTO EPIS_DIAGRAM_LAYOUT';
                    l_rowids_edl := NULL;
                    ts_epis_diagram_layout.ins(id_epis_diagram_layout_in => l_id_epis_diagram_layout,
                                               id_epis_diagram_in        => i_id_diag,
                                               id_diagram_layout_in      => i_id_lay_type(i),
                                               layout_order_in           => l_def_layout_order,
                                               flg_status_in             => g_flg_status_active,
                                               id_professional_in        => i_prof.id,
                                               dt_creation_tstz_in       => g_sysdate_tstz,
                                               rows_out                  => l_rowids_edl);
                
                    --Process the events associated to an insert on epis_recomend
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                                  i_rowids     => l_rowids_edl,
                                                  o_error      => o_error);
                
                    l_dft_epis_diag_lay_not_crtd := FALSE;
                END IF;
            
                dbms_output.put_line('IMAGE ARRAY');
            
                IF i_id_diag_det(i) IS NULL
                THEN
                    -- new information to add                
                    g_error := 'GET SEQ_DIAGRAM_DETAIL.NEXTVAL';
                    SELECT seq_epis_diagram_detail.nextval
                      INTO l_next_det
                      FROM dual;
                
                    --construct the coordinates
                    IF length(i_coor_x(i)) > 0
                    THEN
                        l_coordinates := i_coor_x(i) || '|' || i_coor_y(i);
                    ELSE
                        l_coordinates := NULL;
                    END IF;
                
                    -- insert in the epis_diagram_detail table
                    g_error := 'INSERT IN THE EPIS_DIAGRAM_DETAIL TABLE)';
                    ts_epis_diagram_detail.ins(id_epis_diagram_detail_in => l_next_det,
                                               id_diagram_lay_imag_in    => i_id_imag(i),
                                               id_diagram_tools_in       => i_id_icon(i),
                                               position_x_in             => i_val_posx(i),
                                               position_y_in             => i_val_posy(i),
                                               value_in                  => i_val_icon(i),
                                               flg_status_in             => g_flg_status_det_a,
                                               id_professional_in        => i_prof.id,
                                               id_epis_diagram_layout_in => nvl(i_id_layout(i), l_id_epis_diagram_layout),
                                               dt_diagram_detail_tstz_in => g_sysdate_tstz,
                                               coordinates_in            => l_coordinates,
                                               color_in                  => i_color(i),
                                               rows_out                  => l_rowids);
                
                    --Process the events associated to an update on epis_recomend
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EPIS_DIAGRAM_DETAIL',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    -- Criar NOVO REGISTO DE NOTAS para a linha de detalhe do diagrama            
                    g_error := 'GET SEQ_DIAGRAM_DETAIL_NOTES.NEXTVAL';
                    SELECT seq_epis_diagram_detail_notes.nextval
                      INTO l_next_det_n
                      FROM dual;
                
                    g_error := ' INSERIR DIAGRAM_DETAIL_NOTES (1)';
                    dbms_output.put_line(g_error);
                
                    INSERT INTO epis_diagram_detail_notes
                        (id_diagram_detail_notes, id_epis_diagram_detail, notes, id_professional, dt_notes_tstz)
                    VALUES
                        (l_next_det_n, l_next_det, i_notes(i), i_prof.id, g_sysdate_tstz);
                
                ELSIF i_id_diag_det(i) IS NOT NULL
                THEN
                    -- ID_DETALHE já existe, será efectuada a inserção nas NOTAS 
                    g_error := 'GET SEQ_DIAGRAM_DETAIL_NOTES.NEXTVAL';
                    SELECT seq_epis_diagram_detail_notes.nextval
                      INTO l_next_det_n
                      FROM dual;
                
                    g_error := ' INSERIR DIAGRAM_DETAIL_NOTES (2)';
                    dbms_output.put_line(g_error);
                
                    INSERT INTO epis_diagram_detail_notes
                        (id_diagram_detail_notes, id_epis_diagram_detail, notes, id_professional, dt_notes_tstz)
                    VALUES
                        (l_next_det_n, i_id_diag_det(i), i_notes(i), i_prof.id, g_sysdate_tstz);
                
                END IF;
            END LOOP;
        
            IF i_id_diag IS NOT NULL
            THEN
                g_error := 'call upd_epis_diag_dt_last_update for i_id_diag: ' || i_id_diag;
                IF NOT upd_epis_diag_dt_last_update(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_id_epis_diagram => i_id_diag,
                                                    o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_epis,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            --change the status of do hhc request
            IF i_prof.software = pk_alert_constant.g_soft_home_care
            THEN
                g_error := 'CHANGE THE STATUS - PK_HHC_CORE.SET_REQ_STATUS_IE';
                --change the status
                IF NOT pk_hhc_core.set_req_status_ie(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_epis,
                                                     i_id_epis_hhc_req => NULL,
                                                     o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        ELSE
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              'THE EPISODE IS CANCELLED',
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'set_diag_lay_det',
                                              o_error);
            NULL;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_diag_lay_det',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_diag_lay_det;

    FUNCTION set_diag_lay_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_id_diag             IN epis_diagram.id_epis_diagram%TYPE,
        i_flg_action          IN table_varchar,
        i_id_lay_type         IN table_varchar,
        i_id_layout           IN table_varchar,
        i_id_imag             IN table_varchar,
        i_id_diag_det         IN table_varchar,
        i_id_icon             IN table_varchar,
        i_val_icon            IN table_varchar,
        i_val_posx            IN table_varchar,
        i_val_posy            IN table_varchar,
        i_notes               IN table_varchar,
        i_coor_x              IN table_varchar,
        i_coor_y              IN table_varchar,
        i_color               IN table_varchar,
        o_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Variables for setting a diagram
        l_id_lay_type     table_varchar := table_varchar();
        l_id_layout       table_varchar := table_varchar();
        l_id_imag         table_varchar := table_varchar();
        l_id_diag_det_add table_varchar := table_varchar();
        l_id_icon         table_varchar := table_varchar();
        l_val_icon        table_varchar := table_varchar();
        l_val_posx        table_varchar := table_varchar();
        l_val_posy        table_varchar := table_varchar();
        l_notes           table_varchar := table_varchar();
        l_coor_x          table_varchar := table_varchar();
        l_coor_y          table_varchar := table_varchar();
        l_color           table_varchar := table_varchar();
    
        --Variables for deleting a diagram        
        l_id_diag_det_remove table_varchar := table_varchar();
        l_cancel_reason      table_number := table_number();
        l_notes_cancel       table_varchar := table_varchar();
    
        l_index_add        NUMBER := 0;
        l_index_remove     NUMBER := 0;
        l_id_layout_remove NUMBER := NULL;
    
    BEGIN
    
        FOR i IN i_flg_action.first .. i_flg_action.last
        LOOP
        
            IF i_flg_action(i) = pk_prog_notes_constants.g_flg_add
            THEN
            
                l_index_add := l_index_add + 1;
            
                l_id_lay_type.extend();
                l_id_layout.extend();
                l_id_imag.extend();
                l_id_diag_det_add.extend();
                l_id_icon.extend();
                l_val_icon.extend();
                l_val_posx.extend();
                l_val_posy.extend();
                l_notes.extend();
                l_coor_x.extend();
                l_coor_y.extend();
                l_color.extend();
            
                l_id_lay_type(l_index_add) := i_id_lay_type(i);
                l_id_layout(l_index_add) := i_id_layout(i);
                l_id_imag(l_index_add) := i_id_imag(i);
                l_id_diag_det_add(l_index_add) := i_id_diag_det(i);
                l_id_icon(l_index_add) := i_id_icon(i);
                l_val_icon(l_index_add) := i_val_icon(i);
                l_val_posx(l_index_add) := i_val_posx(i);
                l_val_posy(l_index_add) := i_val_posy(i);
                l_notes(l_index_add) := i_notes(i);
                l_coor_x(l_index_add) := i_coor_x(i);
                l_coor_y(l_index_add) := i_coor_y(i);
                l_color(l_index_add) := i_color(i);
            
            ELSIF i_flg_action(i) = pk_prog_notes_constants.g_flg_remove
            THEN
            
                l_index_remove := l_index_remove + 1;
            
                l_id_diag_det_remove.extend();
            
                l_id_diag_det_remove(l_index_remove) := i_id_diag_det(i);
            
                l_id_layout_remove := i_id_layout(i);
            
            END IF;
        END LOOP;
    
        IF l_index_remove > 0
        THEN
            g_error := 'CALL CANCEL_DIAGRAM_SYMBOL';
            IF NOT cancel_diagram_symbol(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_episode             => i_epis,
                                         i_epis_diagram        => i_id_diag,
                                         i_epis_diagram_layout => l_id_layout_remove,
                                         i_epis_diagram_detail => l_id_diag_det_remove,
                                         i_cancel_reason       => NULL,
                                         i_notes_cancel        => NULL,
                                         o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        IF l_index_add > 0
        THEN
            g_error := 'CALL SET_DIAG_LAY_DET';
            IF NOT set_diag_lay_det(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_epis                => i_epis,
                                    i_id_diag             => i_id_diag,
                                    i_id_lay_type         => l_id_lay_type,
                                    i_id_layout           => l_id_layout,
                                    i_id_imag             => l_id_imag,
                                    i_id_diag_det         => l_id_diag_det_add,
                                    i_id_icon             => l_id_icon,
                                    i_val_icon            => l_val_icon,
                                    i_val_posx            => l_val_posx,
                                    i_val_posy            => l_val_posy,
                                    i_notes               => l_notes,
                                    i_coor_x              => l_coor_x,
                                    i_coor_y              => l_coor_y,
                                    i_color               => l_color,
                                    o_epis_diagram        => o_epis_diagram,
                                    o_epis_diagram_layout => o_epis_diagram_layout,
                                    o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_diag_lay_det',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_diag_lay_det;

    FUNCTION create_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_desc     OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_diagram_layout      diagram_layout.id_diagram_layout%TYPE;
        l_id_epis_diagram_layout epis_diagram_layout.id_epis_diagram_layout%TYPE;
        l_id_epis_diagram        epis_diagram.id_epis_diagram%TYPE;
        l_internal_exception EXCEPTION;
    
    BEGIN
        g_error := 'CALL get_default_lay';
        IF i_flg_type = 'F'
        THEN
            -- family tree
            l_id_diagram_layout := 3475;
        ELSE
            IF NOT get_default_lay(i_lang, i_prof, i_epis, i_flg_type, l_id_diagram_layout, o_error)
            THEN
                NULL;
            END IF;
        END IF;
    
        g_error := 'CALL create_diag_internal';
        IF NOT create_diag_internal(i_lang,
                                    i_prof,
                                    i_epis,
                                    l_id_diagram_layout,
                                    l_id_epis_diagram,
                                    l_id_epis_diagram_layout,
                                    o_error)
        THEN
            RAISE l_internal_exception;
        END IF;
    
        -- fetching all the info concerning the new diagram and returning it on a cursor
        -- get diagram layout images from layout diagram    
        g_error := 'CALL get_new_diag_lay_imag';
        IF NOT
            get_new_diag_lay_imag(i_lang, i_prof, l_id_diagram_layout, l_id_epis_diagram_layout, o_diag_lay_img, o_error)
        THEN
            RAISE l_internal_exception;
        END IF;
    
        -- get diagram layout description
        g_error := 'CALL get_new_diag_desc';
        IF (NOT get_new_diag_desc(i_lang, i_prof, 1, i_flg_type, o_diag_desc, o_error))
        THEN
            RAISE l_internal_exception; -- error on getting default diagram layout
        END IF;
    
        -- get new figure description
        g_error := 'CALL get_new_diag_lay_desc';
        IF (NOT get_new_diag_lay_desc(i_lang,
                                      i_prof,
                                      l_id_diagram_layout,
                                      l_id_epis_diagram_layout,
                                      o_diag_lay_desc,
                                      o_error))
        THEN
            RAISE l_internal_exception; -- error on getting diagram layout descriptions
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_exception THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_desc);
            pk_types.open_my_cursor(o_diag_lay_desc);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_desc);
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'create_diag',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_diag;

    FUNCTION get_diag_lay_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diag        IN epis_diagram.id_epis_diagram%TYPE,
        i_id_diag_lay    IN diagram_layout.id_diagram_layout%TYPE,
        o_diagram_layout OUT pk_types.cursor_type,
        o_title          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_DIAGRAM_LAY';
        -- fetching the diagram info
        OPEN o_diagram_layout FOR
            SELECT edd.id_epis_diagram_detail,
                   edd.id_diagram_lay_imag,
                   edd.id_diagram_tools,
                   edl.layout_order,
                   edl.id_diagram_layout,
                   edd.position_x,
                   edd.position_y,
                   pk_translation.get_translation(i_lang, dtg.code_acronym_group) acronym_group,
                   edd.value,
                   dt.icon,
                   decode(edd.notes_cancel, NULL, dt.icon_color_image, dt.icon_color_cancel) color_image,
                   decode(ddn.notes, NULL, NULL, ddn.notes) notes,
                   edl.flg_status,
                   ed.flg_status
              FROM epis_diagram              ed,
                   diagram_lay_imag          dli,
                   epis_diagram_detail       edd,
                   diagram_tools             dt,
                   diagram_tools_group       dtg,
                   epis_diagram_detail_notes ddn,
                   epis_diagram_layout       edl,
                   diagram_layout            dl
             WHERE edl.id_epis_diagram = ed.id_epis_diagram
               AND edl.id_diagram_layout = dl.id_diagram_layout
               AND edd.id_diagram_lay_imag = dli.id_diagram_lay_imag
               AND dli.id_diagram_layout = dl.id_diagram_layout
               AND dl.id_diagram_layout = i_id_diag_lay
               AND edd.id_diagram_tools = dt.id_diagram_tools
               AND dt.id_diagram_tools_group = dtg.id_diagram_tools_group
               AND ddn.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail
               AND edl.flg_status <> g_diag_lay_removed
               AND ((ddn.dt_notes_tstz =
                   (SELECT MAX(ddn1.dt_notes_tstz)
                        FROM epis_diagram_detail_notes ddn1
                       WHERE ddn1.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail) AND EXISTS
                    (SELECT '0'
                        FROM epis_diagram_detail_notes ddn2
                       WHERE ddn2.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail)) OR NOT EXISTS
                    (SELECT '0'
                       FROM epis_diagram_detail_notes ddn3
                      WHERE ddn3.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail));
    
        g_error := 'GET CURSOR O_TITLE';
        OPEN o_title FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') desc_diagram, --DIAGRAM
                   epis_diagram.diagram_order id_diagram_epis, --NUMBER
                   -- FIGURE @number
                   REPLACE(pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T011'),
                           '@1',
                           epis_diagram_layout.layout_order),
                   pk_translation.get_translation(i_lang, diagram_layout.code_diagram_layout) --LAYOUT DESCRIPTION            
              FROM epis_diagram, epis_diagram_layout, diagram_layout
             WHERE epis_diagram_layout.id_epis_diagram = epis_diagram.id_epis_diagram
               AND epis_diagram_layout.flg_status <> g_diag_lay_removed
               AND epis_diagram_layout.id_diagram_layout = i_id_diag_lay;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_lay_det',
                                              o_error);
            RETURN FALSE;
    END get_diag_lay_det;

    FUNCTION cancel_diag_lay
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diag_lay IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_diagram_new.cancel_diagram_layout(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_epis_diagram_layout => i_id_epis_diag_lay,
                                                    i_cancel_reason       => NULL,
                                                    i_cancel_notes        => NULL,
                                                    o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIAG_LAY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_diag_lay;

    FUNCTION cancel_diagram_layout
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_cancel_reason       IN epis_diagram_layout.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_diagram_layout.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_diagram epis_diagram.id_epis_diagram%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- to cancel a layout, all we have to do is set the flg_status to 'C' (cancelled)        
        g_error := 'UPDATE EPIS_DIAGRAM_LAYOUT';
        ts_epis_diagram_layout.upd(id_epis_diagram_layout_in => i_epis_diagram_layout,
                                   flg_status_in             => g_diag_lay_cancelled,
                                   id_prof_cancel_in         => i_prof.id,
                                   dt_cancel_tstz_in         => g_sysdate_tstz,
                                   id_cancel_reason_in       => i_cancel_reason,
                                   notes_cancel_in           => i_cancel_notes,
                                   rows_out                  => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'get epis_diagram_layout.id_epis_diagram';
        SELECT edl.id_epis_diagram
          INTO l_id_epis_diagram
          FROM epis_diagram_layout edl
         WHERE edl.id_epis_diagram_layout = i_epis_diagram_layout;
    
        g_error := 'call upd_epis_diag_dt_last_update for i_id_epis_diagram : ' || l_id_epis_diagram;
        IF NOT upd_epis_diag_dt_last_update(i_lang            => i_lang,
                                            i_prof            => i_prof,
                                            i_id_epis_diagram => l_id_epis_diagram,
                                            o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIAGRAM_LAYOUT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_diagram_layout;

    FUNCTION cancel_diagram_symbol
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagram        IN epis_diagram.id_epis_diagram%TYPE,
        i_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_epis_diagram_detail IN table_varchar,
        i_cancel_reason       IN epis_diagram_detail.id_cancel_reason%TYPE,
        i_notes_cancel        IN epis_diagram_detail.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char VARCHAR2(1);
    
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_episode
               AND flg_status <> g_epis_cancel;
    
        CURSOR c_layout IS
            SELECT 'X'
              FROM epis_diagram_layout
             WHERE id_epis_diagram_layout = i_epis_diagram_layout
               AND flg_status = 'A';
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        -- Check if the episode isnt cancelled
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
    
        IF g_found
        THEN
            -- Check if the layout isnt cancelled
            g_error := 'GET CURSOR C_LAYOUT';
            OPEN c_layout;
            FETCH c_layout
                INTO l_char;
            g_found := c_layout%FOUND;
            CLOSE c_layout;
        
            IF g_found
            THEN
                --layout exists and its open
                FOR i IN 1 .. i_epis_diagram_detail.count
                LOOP
                    g_error := 'CANCEL IN EPIS_DIAGRAM_DETAIL';
                    ts_epis_diagram_detail.upd(id_epis_diagram_detail_in => i_epis_diagram_detail(i),
                                               id_cancel_reason_in       => i_cancel_reason,
                                               notes_cancel_in           => i_notes_cancel,
                                               dt_cancel_tstz_in         => g_sysdate_tstz,
                                               id_prof_cancel_in         => i_prof.id,
                                               flg_status_in             => g_flg_status_det_c,
                                               rows_out                  => l_rows_out);
                END LOOP;
            
                --Process the events associated to an update on epis_recomend
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_DIAGRAM_DETAIL',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF i_epis_diagram IS NOT NULL
                THEN
                    g_error := 'call upd_epis_diag_dt_last_update for i_id_epis_diagram: ' || i_epis_diagram;
                    IF NOT upd_epis_diag_dt_last_update(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_epis_diagram => i_epis_diagram,
                                                        o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                COMMIT;
            
                RETURN TRUE;
            END IF;
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIAGRAM_SYMBOL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_diagram_symbol;

    FUNCTION add_diag_lay
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_epis                   IN episode.id_episode%TYPE,
        i_id_epis_diagram        IN epis_diagram.id_epis_diagram%TYPE,
        i_id_lay_type            IN diagram_layout.id_diagram_layout%TYPE,
        o_id_epis_diagram        OUT epis_diagram.id_epis_diagram%TYPE,
        o_id_epis_diagram_layout OUT epis_diagram_layout.id_epis_diagram_layout%TYPE,
        o_figure_tag_plus_number OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_edl_nextval  NUMBER;
        l_layout_order NUMBER;
        l_internal_exception EXCEPTION;
        l_rowids_edl table_varchar;
    
    BEGIN
    
        -- we might need to create a new diagram if a new layout is about to be added, but there's no epis_diagram, yet
        IF i_id_epis_diagram IS NULL
        THEN
            IF (NOT create_diag_internal(i_lang,
                                         i_prof,
                                         i_epis,
                                         i_id_lay_type,
                                         o_id_epis_diagram,
                                         o_id_epis_diagram_layout,
                                         o_error))
            THEN
                RAISE l_internal_exception;
            ELSE
                o_figure_tag_plus_number := REPLACE(pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T011'), '@1', 1);
                NULL; -- go until the end of the function
            
            END IF;
        ELSE
        
            l_edl_nextval := ts_epis_diagram_layout.next_key;
        
            g_error := 'GET LAYOUT ORDER IN DIAGRAM';
        
            --get the next diagram order while locking the row            
            SELECT (MAX(edl.layout_order) + 1)
              INTO l_layout_order
              FROM epis_diagram_layout edl
             WHERE edl.id_epis_diagram = i_id_epis_diagram;
        
            g_error      := 'INSERT INTO EPIS_DIAGRAM_LAYOUT';
            l_rowids_edl := NULL;
            ts_epis_diagram_layout.ins(id_epis_diagram_layout_in => l_edl_nextval,
                                       id_epis_diagram_in        => i_id_epis_diagram,
                                       id_diagram_layout_in      => i_id_lay_type,
                                       layout_order_in           => l_layout_order,
                                       flg_status_in             => g_flg_status_active,
                                       id_professional_in        => i_prof.id,
                                       dt_creation_tstz_in       => current_timestamp,
                                       rows_out                  => l_rowids_edl);
        
            --Process the events associated to an insert on epis_recomend
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIAGRAM_LAYOUT',
                                          i_rowids     => l_rowids_edl,
                                          o_error      => o_error);
        
            g_error := 'call upd_epis_diag_dt_last_update for i_id_epis_diagram: ' || i_id_epis_diagram;
            IF NOT upd_epis_diag_dt_last_update(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_epis_diagram => i_id_epis_diagram,
                                                o_error           => o_error)
            THEN
                RAISE l_internal_exception;
            END IF;
        
            o_figure_tag_plus_number := REPLACE(pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T011'),
                                                '@1',
                                                
                                                l_layout_order);
            o_id_epis_diagram        := i_id_epis_diagram;
            o_id_epis_diagram_layout := l_edl_nextval;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_internal_exception THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              'PK_DIAGRAM_NEW.ADD_DIAG_LAY / ' || g_error || ' / ' || SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'get_default_lay',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'add_diag_lay',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END add_diag_lay;

    FUNCTION get_most_freq_diag_lay_imag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_layouts(id_dcs IN dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT l.id_diagram_layout
              FROM (SELECT dldcs.id_diagram_layout,
                           row_number() over(PARTITION BY dldcs.id_diagram_layout ORDER BY dldcs.id_software DESC, dldcs.rank) rn
                      FROM diag_lay_dep_clin_serv dldcs
                     WHERE dldcs.id_institution = i_prof.institution
                       AND dldcs.id_software IN (0, i_prof.software)
                       AND dldcs.flg_type = g_flg_type_most_freq
                       AND dldcs.id_dep_clin_serv = id_dcs) l
             WHERE l.rn = 1;
    
        CURSOR c_layouts IS
            SELECT l.id_diagram_layout
              FROM (SELECT dldcs.id_diagram_layout,
                           row_number() over(PARTITION BY dldcs.id_diagram_layout ORDER BY dldcs.id_software DESC, dldcs.rank) rn
                      FROM diag_lay_dep_clin_serv dldcs
                      JOIN prof_dep_clin_serv pdcs
                        ON dldcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE dldcs.id_institution = i_prof.institution
                       AND dldcs.id_software IN (0, i_prof.software)
                       AND dldcs.flg_type = g_flg_type_most_freq
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.flg_status = 'S') l
             WHERE l.rn = 1;
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(floor((SYSDATE - p.dt_birth) / 365), p.age) age
              FROM patient p
             WHERE p.id_patient = i_patient;
    
        l_epis_dcs epis_info.id_dep_clin_serv%TYPE;
        l_gender   patient.gender%TYPE;
        l_age      patient.age%TYPE;
        l_layouts  table_number;
    BEGIN
    
        --Get episode dep_clin_serv
        SELECT ei.id_dep_clin_serv
          INTO l_epis_dcs
          FROM epis_info ei
         WHERE ei.id_episode = i_id_episode;
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_gender, l_age;
        CLOSE c_pat;
    
        --Get the diagrams
        IF l_epis_dcs IS NOT NULL
        THEN
            -- Based on epis dcs
            g_error := 'OPEN c_epis_layouts';
            OPEN c_epis_layouts(l_epis_dcs);
            FETCH c_epis_layouts BULK COLLECT
                INTO l_layouts;
            CLOSE c_epis_layouts;
        ELSE
            -- Based on user profile
            g_error := 'OPEN c_layouts';
            OPEN c_layouts;
            FETCH c_layouts BULK COLLECT
                INTO l_layouts;
            CLOSE c_layouts;
        END IF;
    
        IF l_age IS NULL
        THEN
            -- qd a idade não é desconhecida é necessário atribuir uma idade por defeito para efeitos de configuração.
            -- optou-se por adulto
            l_age := 999;
        END IF;
    
        g_error := 'GET CURSOR o_diag_lay_img';
        OPEN o_diag_lay_img FOR
            SELECT dli.id_diagram_lay_imag,
                   dli.id_diagram_image,
                   dl.id_diagram_layout,
                   dli.position_x,
                   dli.position_y,
                   get_diag_lay_imag_image_url(i_prof, di.id_diagram_image) url_diagram_image,
                   pk_translation.get_translation(i_lang, di.code_diagram_image) image_desc,
                   dldcs.rank
              FROM diagram_layout dl
              JOIN diagram_lay_imag dli
                ON dl.id_diagram_layout = dli.id_diagram_layout
              JOIN diagram_image di
                ON di.id_diagram_image = dli.id_diagram_image
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_diagram_layout, rownum rank
                      FROM TABLE(l_layouts) t) dldcs
                ON dl.id_diagram_layout = dldcs.id_diagram_layout
             WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                   l_gender = 'I')
               AND (dl.id_body_diag_age_grp IS NULL OR
                   (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                   l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
               AND dl.flg_available = 'Y'
               AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
             ORDER BY dldcs.rank, dl.id_diagram_layout, dli.id_diagram_image;
    
        g_error := 'GET CURSOR o_diag_lay_desc';
        OPEN o_diag_lay_desc FOR
            SELECT pk_translation.get_translation(i_lang, dl.code_diagram_layout) layout_desc,
                   dl.id_diagram_layout,
                   get_diag_lay_image_url(i_prof, dl.id_diagram_layout) url_image,
                   dldcs.rank
              FROM diagram_layout dl
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_diagram_layout, rownum rank
                      FROM TABLE(l_layouts) t) dldcs
                ON dl.id_diagram_layout = dldcs.id_diagram_layout
             WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                   l_gender = 'I')
               AND (dl.id_body_diag_age_grp IS NULL OR
                   (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                   l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
               AND dl.flg_available = 'Y'
               AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
             ORDER BY dldcs.rank, layout_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_most_freq_diag_lay_imag',
                                              o_error);
            RETURN FALSE;
    END get_most_freq_diag_lay_imag;

    FUNCTION get_all_diag_lay_imag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_diag_lay_img  OUT pk_types.cursor_type,
        o_diag_lay_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(floor((SYSDATE - p.dt_birth) / 365), p.age) age
              FROM patient p
             WHERE p.id_patient = i_patient;
    
        CURSOR c_layouts IS
            SELECT l.id_diagram_layout
              FROM (SELECT dldcs.id_diagram_layout,
                           row_number() over(PARTITION BY dldcs.id_diagram_layout ORDER BY dldcs.id_software DESC, dldcs.rank) rn
                      FROM diag_lay_dep_clin_serv dldcs
                      JOIN prof_dep_clin_serv pdcs
                        ON dldcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE dldcs.id_institution = i_prof.institution
                       AND dldcs.id_software IN (0, i_prof.software)
                       AND dldcs.flg_type = g_flg_type_searchable
                       AND pdcs.id_professional = i_prof.id) l
             WHERE l.rn = 1;
    
        l_age     patient.age%TYPE;
        l_gender  patient.gender%TYPE;
        l_layouts table_number;
    
    BEGIN
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_gender, l_age;
        CLOSE c_pat;
    
        IF l_age IS NULL
        THEN
            -- qd a idade não é desconhecida é necessário atribuir uma idade por defeito para efeitos de configuração.
            -- optou-se por adulto
            l_age := 999;
        END IF;
    
        g_error := 'OPEN c_layouts';
        OPEN c_layouts;
        FETCH c_layouts BULK COLLECT
            INTO l_layouts;
        CLOSE c_layouts;
    
        g_error := 'GET CURSOR o_diag_lay_img';
        OPEN o_diag_lay_img FOR
            SELECT dli.id_diagram_lay_imag,
                   dli.id_diagram_image,
                   dl.id_diagram_layout,
                   dli.position_x,
                   dli.position_y,
                   get_diag_lay_imag_image_url(i_prof, di.id_diagram_image) url_diagram_image,
                   pk_translation.get_translation(i_lang, di.code_diagram_image) image_desc,
                   dldcs.rank
              FROM diagram_layout dl
              JOIN diagram_lay_imag dli
                ON dl.id_diagram_layout = dli.id_diagram_layout
              JOIN diagram_image di
                ON di.id_diagram_image = dli.id_diagram_image
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_diagram_layout, rownum rank
                      FROM TABLE(l_layouts) t) dldcs
                ON dl.id_diagram_layout = dldcs.id_diagram_layout
             WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                   l_gender = 'I')
               AND (dl.id_body_diag_age_grp IS NULL OR
                   (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                   l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
               AND dl.flg_available = 'Y'
               AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
             ORDER BY dldcs.rank, dl.id_diagram_layout, dli.id_diagram_image;
    
        g_error := 'GET CURSOR o_diag_lay_desc';
        OPEN o_diag_lay_desc FOR
            SELECT pk_translation.get_translation(i_lang, dl.code_diagram_layout) layout_desc,
                   dl.id_diagram_layout,
                   get_diag_lay_image_url(i_prof, dl.id_diagram_layout) url_image,
                   dldcs.rank
              FROM diagram_layout dl
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_diagram_layout, rownum rank
                      FROM TABLE(l_layouts) t) dldcs
                ON dl.id_diagram_layout = dldcs.id_diagram_layout
             WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                   l_gender = 'I')
               AND (dl.id_body_diag_age_grp IS NULL OR
                   (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                   l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                 FROM body_diag_age_grp bag
                                 LEFT JOIN (SELECT *
                                             FROM bd_age_grp_soft_inst bagrsi
                                            WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                              AND bagrsi.id_software IN (i_prof.software, 0)
                                            ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                   ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
               AND dl.flg_available = 'Y'
               AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
             ORDER BY dldcs.rank, layout_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_diag_lay_img);
            pk_types.open_my_cursor(o_diag_lay_desc);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_all_diag_lay_imag',
                                              o_error);
            RETURN FALSE;
    END get_all_diag_lay_imag;

    FUNCTION get_diag_det_notes_hist
    
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diag                IN epis_diagram.id_epis_diagram%TYPE,
        o_symbols                OUT table_varchar,
        o_recent_notes           OUT table_varchar,
        o_old_notes              OUT table_varchar,
        o_cancelled              OUT table_varchar,
        o_figures                OUT table_varchar,
        o_figures_data           OUT table_varchar,
        o_figures_data_cancelled OUT table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_boolean BOOLEAN;
        l_edl_row epis_diagram_layout%ROWTYPE;
    
        CURSOR c_figures IS
            SELECT *
              FROM epis_diagram_layout
             WHERE id_epis_diagram = i_id_diag
             ORDER BY layout_order;
    
        l_symbols                table_varchar := table_varchar();
        l_recent_notes           table_varchar := table_varchar();
        l_old_notes              table_varchar := table_varchar();
        l_cancelled              table_varchar := table_varchar();
        l_figures                table_varchar := table_varchar();
        l_figures_data           table_varchar := table_varchar();
        l_figures_data_cancelled table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_FIGURES';
        OPEN c_figures;
        LOOP
            FETCH c_figures
                INTO l_edl_row;
            EXIT WHEN c_figures%NOTFOUND;
        
            l_boolean := find_figures_info(i_lang,
                                           i_prof,
                                           l_edl_row,
                                           l_figures,
                                           l_figures_data,
                                           l_figures_data_cancelled,
                                           o_error);
        END LOOP;
        CLOSE c_figures;
    
        g_error := 'OPEN CURSOR C_FIGURES (2))';
        OPEN c_figures;
        LOOP
            FETCH c_figures
                INTO l_edl_row;
            EXIT WHEN c_figures%NOTFOUND;
            l_boolean := find_differences_notes(i_lang,
                                                i_prof,
                                                l_edl_row,
                                                l_symbols,
                                                l_recent_notes,
                                                l_old_notes,
                                                l_cancelled,
                                                o_error);
        END LOOP;
        CLOSE c_figures;
    
        o_symbols                := l_symbols;
        o_recent_notes           := l_recent_notes;
        o_old_notes              := l_old_notes;
        o_cancelled              := l_cancelled;
        o_figures                := l_figures;
        o_figures_data           := l_figures_data;
        o_figures_data_cancelled := l_figures_data_cancelled;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_det_notes_hist',
                                              o_error);
            RETURN FALSE;
    END get_diag_det_notes_hist;

    FUNCTION get_all_available_figures
    
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_layer_values  IN table_varchar,
        i_layer_concept IN table_varchar,
        i_flg_type      IN diagram_layout.flg_type%TYPE,
        o_final_layer   OUT NUMBER,
        o_layers        OUT pk_types.cursor_type,
        o_layer_name    OUT VARCHAR2,
        o_layer_concept OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_layer_concept_last_element NUMBER;
        l_layer_values_last_element  NUMBER;
        l_count_body_part            NUMBER;
        l_count_null_body_side       NUMBER;
        l_choosen_side               NUMBER;
        l_layouts                    table_number;
        l_gender                     patient.gender%TYPE;
        l_age                        patient.age%TYPE;
    
        CURSOR c_pat IS
            SELECT p.gender, nvl(floor((SYSDATE - p.dt_birth) / 365), p.age) age
              FROM patient p
             WHERE p.id_patient = i_patient;
    
        CURSOR c_layouts IS
            SELECT l.id_diagram_layout
              FROM (SELECT dldcs.id_diagram_layout,
                           row_number() over(PARTITION BY dldcs.id_diagram_layout ORDER BY dldcs.id_software DESC, dldcs.rank) rn
                      FROM diag_lay_dep_clin_serv dldcs
                      JOIN prof_dep_clin_serv pdcs
                        ON dldcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE dldcs.id_institution = i_prof.institution
                       AND dldcs.id_software IN (0, i_prof.software)
                       AND dldcs.flg_type = g_flg_type_searchable
                       AND pdcs.id_professional = i_prof.id) l
             WHERE l.rn = 1;
    
    BEGIN
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO l_gender, l_age;
        CLOSE c_pat;
    
        IF l_age IS NULL
        THEN
            -- qd a idade não é desconhecida é necessário atribuir uma idade por defeito para efeitos de configuração.
            -- optou-se por adulto
            l_age := 999;
        END IF;
    
        g_error := 'OPEN c_layouts';
        OPEN c_layouts;
        FETCH c_layouts BULK COLLECT
            INTO l_layouts;
        CLOSE c_layouts;
    
        -- structure column     
        IF i_layer_values(1) IS NULL
           AND i_layer_concept(1) IS NULL
        THEN
        
            dbms_output.put_line('primeira coluna');
            o_final_layer := 0;
        
            g_error := 'SELECT BODY PART TAG + SYSTEM TAG + STRUCTURE TAG';
            OPEN o_layers FOR
                SELECT desc_message description, decode(code_message, 'DIAGRAM_T033', 2, 5) id
                  FROM sys_message
                 WHERE code_message IN ('DIAGRAM_T033', 'DIAGRAM_T034')
                   AND id_language = i_lang
                   AND id_software IN (i_prof.software, 0)
                   AND id_institution IN (i_prof.institution, 0);
        
            o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T032'); -- structure tag
        
            -- next layer                                      
            o_layer_concept := 1; -- structure
        
            RETURN TRUE;
        END IF;
    
        l_layer_concept_last_element := i_layer_concept(i_layer_concept.last);
        l_layer_values_last_element  := i_layer_values(i_layer_values.last);
    
        -- structure was choosen
        IF l_layer_concept_last_element = g_structure_id
        THEN
            -- bodypart choosen?
            IF i_layer_values(1) = 2
            THEN
                -- selecting the available body_parts
                OPEN o_layers FOR
                    SELECT UNIQUE(pk_translation.get_translation(i_lang, t.code_body_part)) description,
                           t.id_body_part id
                      FROM body_part t
                      JOIN diagram_layout dl
                        ON dl.id_body_part = t.id_body_part
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                             t.column_value id_diagram_layout, rownum rank
                              FROM TABLE(l_layouts) t) dldcs
                        ON dl.id_diagram_layout = dldcs.id_diagram_layout
                     WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                           l_gender = 'I')
                       AND (dl.id_body_diag_age_grp IS NULL OR
                           (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                           l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                       AND dl.flg_available = 'Y'
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
                     ORDER BY description;
            
                IF o_layers IS NOT NULL
                THEN
                    o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T033'); --body part tag
                
                    o_layer_concept := 2; -- body part
                
                    o_final_layer := 0;
                ELSE
                    o_final_layer := 1;
                END IF;
            
                -- system choosen
            ELSE
                IF i_layer_values(1) = 5
                THEN
                    -- selecting the available body systems
                    OPEN o_layers FOR
                        SELECT UNIQUE(pk_translation.get_translation(i_lang, t.code_system_apparati)) description,
                               t.id_system_apparati id
                          FROM system_apparati t
                          JOIN sys_appar_organ sao
                            ON sao.id_system_apparati = t.id_system_apparati
                          JOIN diagram_layout dl
                            ON dl.id_sys_appar_organ = sao.id_sys_appar_organ
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value id_diagram_layout, rownum rank
                                  FROM TABLE(l_layouts) t) dldcs
                            ON dl.id_diagram_layout = dldcs.id_diagram_layout
                         WHERE ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                               l_gender = 'I')
                           AND (dl.id_body_diag_age_grp IS NULL OR
                               (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                             FROM body_diag_age_grp bag
                                             LEFT JOIN (SELECT *
                                                         FROM bd_age_grp_soft_inst bagrsi
                                                        WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                          AND bagrsi.id_software IN (i_prof.software, 0)
                                                        ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                               ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                            WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                               l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                             FROM body_diag_age_grp bag
                                             LEFT JOIN (SELECT *
                                                         FROM bd_age_grp_soft_inst bagrsi
                                                        WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                          AND bagrsi.id_software IN (i_prof.software, 0)
                                                        ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                               ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                            WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                           AND dl.flg_available = 'Y'
                           AND dl.flg_type = nvl(i_flg_type, g_flg_type_others)
                         ORDER BY description;
                
                    IF o_layers IS NOT NULL
                    THEN
                        o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T034'); -- system tag
                    
                        o_layer_concept := 5; --system
                    
                        o_final_layer := 0;
                    ELSE
                        o_final_layer := 1;
                    END IF;
                END IF;
            END IF;
        
            RETURN TRUE;
        END IF;
    
        IF l_layer_concept_last_element = g_body_part_id --body part choosen
        THEN
            SELECT COUNT(-1)
              INTO l_count_null_body_side
              FROM diagram_layout t
             WHERE t.id_body_part = i_layer_values(2)
               AND t.id_body_side IS NULL
               AND t.flg_type = nvl(i_flg_type, g_flg_type_others);
        
            SELECT COUNT(t.id_body_part)
              INTO l_count_body_part
              FROM diagram_layout t
             WHERE t.id_body_part = i_layer_values(2)
               AND t.flg_type = nvl(i_flg_type, g_flg_type_others);
        
            IF l_count_body_part <> l_count_null_body_side
            THEN
                -- selecting the available sides
                OPEN o_layers FOR
                    SELECT UNIQUE(decode(t.id_body_side,
                                         NULL,
                                         pk_message.get_message(i_lang, i_prof, 'COMMON_M002'),
                                         pk_translation.get_translation(i_lang, bs.code_body_side))) description,
                           decode(t.id_body_side, NULL, -1, t.id_body_side) id
                      FROM diagram_layout t, body_side bs
                     WHERE t.id_body_part = i_layer_values(2)
                       AND bs.id_body_side(+) = t.id_body_side
                       AND t.flg_type = nvl(i_flg_type, g_flg_type_others);
            
                o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T035'); -- side TAG
            
                o_layer_concept := 3; --side
            
                o_final_layer := 0;
            
                RETURN TRUE;
            ELSE
                -- there are no sides to the selection, so we skip to the layer
                OPEN o_layers FOR
                    SELECT UNIQUE(pk_translation.get_translation(i_lang, bl.code_body_layer)) description,
                           dl.id_body_layer id
                      FROM body_layer bl, diagram_layout dl
                     WHERE dl.id_body_layer = bl.id_body_layer
                       AND dl.id_body_part = i_layer_values(2)
                       AND dl.id_body_side IS NULL
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
            
                IF o_layers IS NOT NULL
                THEN
                
                    o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T036'); -- layer TAG
                
                    o_layer_concept := 4; --layer
                
                    o_final_layer := 0;
                
                    RETURN TRUE;
                
                ELSE
                    --there are no layers also, so we go straight to the figure
                
                    OPEN o_layers FOR
                        SELECT dl.id_diagram_layout id
                          FROM diagram_layout dl
                         WHERE dl.id_body_part = i_layer_values(2)
                           AND dl.flg_available = 'Y'
                           AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
                
                    o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T038'); -- FIGURE TAG
                
                    o_final_layer := 1;
                
                    RETURN TRUE;
                
                END IF;
            END IF;
        
            RETURN TRUE;
        END IF;
    
        IF l_layer_concept_last_element = g_side_id -- SIDE CHOOSEN         
        THEN
        
            SELECT decode(i_layer_values(3), -1, NULL, i_layer_values(3))
              INTO l_choosen_side
              FROM dual;
        
            -- selecting the available layers        
            IF l_choosen_side IS NULL
            THEN
                g_error := 'SELECT AVAILABLE LAYERS';
                OPEN o_layers FOR
                    SELECT UNIQUE(pk_translation.get_translation(i_lang, bl.code_body_layer)) description,
                           dl.id_body_layer id
                      FROM body_layer bl, diagram_layout dl
                     WHERE dl.id_body_layer = bl.id_body_layer
                       AND dl.id_body_part = i_layer_values(2)
                       AND dl.id_body_side IS NULL
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
            ELSE
            
                OPEN o_layers FOR
                    SELECT UNIQUE(pk_translation.get_translation(i_lang, bl.code_body_layer)) description,
                           dl.id_body_layer id
                      FROM body_layer bl, diagram_layout dl
                     WHERE dl.id_body_layer = bl.id_body_layer
                       AND dl.id_body_part = i_layer_values(2)
                       AND dl.id_body_side = l_choosen_side
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
            
            END IF;
        
            o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T036'); -- layer TAG
        
            o_layer_concept := 4; --layer
        
            o_final_layer := 0;
        
            RETURN TRUE;
        
        END IF;
    
        IF l_layer_concept_last_element = g_layer_id -- layer CHOOSEN 
        THEN
            -- SELECTING THE figure
            IF i_layer_values(3) IS NULL
            THEN
                g_error := 'SELECTING THE FIGURES(1)';
                OPEN o_layers FOR
                    SELECT dl.id_diagram_layout id
                      FROM diagram_layout dl
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                             t.column_value id_diagram_layout, rownum rank
                              FROM TABLE(l_layouts) t) dldcs
                        ON dl.id_diagram_layout = dldcs.id_diagram_layout
                     WHERE dl.id_body_part = i_layer_values(2)
                       AND dl.id_body_side IS NULL
                       AND dl.id_body_layer = i_layer_values(4)
                       AND ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                           l_gender = 'I')
                       AND (dl.id_body_diag_age_grp IS NULL OR
                           (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                           l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                       AND dl.flg_available = 'Y'
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
            
            ELSE
                g_error := 'SELECTING THE FIGURES(2)';
                OPEN o_layers FOR
                    SELECT dl.id_diagram_layout id
                      FROM diagram_layout dl
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                             t.column_value id_diagram_layout, rownum rank
                              FROM TABLE(l_layouts) t) dldcs
                        ON dl.id_diagram_layout = dldcs.id_diagram_layout
                     WHERE dl.id_body_part = i_layer_values(2)
                       AND dl.id_body_side = i_layer_values(3)
                       AND dl.id_body_layer = i_layer_values(4)
                       AND ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                           l_gender = 'I')
                       AND (dl.id_body_diag_age_grp IS NULL OR
                           (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                           l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                         FROM body_diag_age_grp bag
                                         LEFT JOIN (SELECT *
                                                     FROM bd_age_grp_soft_inst bagrsi
                                                    WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                      AND bagrsi.id_software IN (i_prof.software, 0)
                                                    ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                           ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                        WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                          
                       AND dl.flg_available = 'Y'
                       AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
            END IF;
        
            o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T038'); -- FIGURE TAG
        
            o_final_layer := 1;
        
            RETURN TRUE;
        
        END IF;
    
        IF l_layer_concept_last_element = g_system_id -- system choosen
        THEN
            -- selecting the available organs
            OPEN o_layers FOR
                SELECT UNIQUE((pk_translation.get_translation(i_lang, so.code_system_organ))) description,
                       sao.id_system_organ id
                  FROM sys_appar_organ sao
                  JOIN diagram_layout dl
                    ON dl.id_sys_appar_organ = sao.id_sys_appar_organ
                  JOIN system_organ so
                    ON so.id_system_organ = sao.id_system_organ
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                         t.column_value id_diagram_layout, rownum rank
                          FROM TABLE(l_layouts) t) dldcs
                    ON dl.id_diagram_layout = dldcs.id_diagram_layout
                 WHERE sao.id_system_apparati = i_layer_values(2)
                   AND ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                       l_gender = 'I')
                   AND (dl.id_body_diag_age_grp IS NULL OR
                       (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                     FROM body_diag_age_grp bag
                                     LEFT JOIN (SELECT *
                                                 FROM bd_age_grp_soft_inst bagrsi
                                                WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                  AND bagrsi.id_software IN (i_prof.software, 0)
                                                ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                       ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                    WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                       l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                     FROM body_diag_age_grp bag
                                     LEFT JOIN (SELECT *
                                                 FROM bd_age_grp_soft_inst bagrsi
                                                WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                  AND bagrsi.id_software IN (i_prof.software, 0)
                                                ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                       ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                    WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                   AND dl.flg_available = 'Y'
                   AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
        
            o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T037'); -- FIGURE TAG
        
            o_final_layer   := 0;
            o_layer_concept := 6; --layer
        
            RETURN TRUE;
        
        END IF;
    
        IF l_layer_concept_last_element = g_organ_id --organ choosen
        THEN
            -- SELECTING THE figure
            OPEN o_layers FOR
                SELECT dl.id_diagram_layout id
                  FROM diagram_layout dl
                  JOIN sys_appar_organ sao
                    ON dl.id_sys_appar_organ = sao.id_sys_appar_organ
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                         t.column_value id_diagram_layout, rownum rank
                          FROM TABLE(l_layouts) t) dldcs
                    ON dl.id_diagram_layout = dldcs.id_diagram_layout
                 WHERE sao.id_system_organ = i_layer_values(3)
                   AND sao.id_system_apparati = i_layer_values(2)
                   AND ((l_gender IS NOT NULL AND nvl(dl.gender, 'I') IN ('I', l_gender)) OR l_gender IS NULL OR
                       l_gender = 'I')
                   AND (dl.id_body_diag_age_grp IS NULL OR
                       (l_age >= (SELECT nvl(tb.min_age, bag.min_age)
                                     FROM body_diag_age_grp bag
                                     LEFT JOIN (SELECT *
                                                 FROM bd_age_grp_soft_inst bagrsi
                                                WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                  AND bagrsi.id_software IN (i_prof.software, 0)
                                                ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                       ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                    WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp) AND
                       l_age <= (SELECT nvl(tb.max_age, bag.max_age)
                                     FROM body_diag_age_grp bag
                                     LEFT JOIN (SELECT *
                                                 FROM bd_age_grp_soft_inst bagrsi
                                                WHERE bagrsi.id_institution IN (i_prof.institution, 0)
                                                  AND bagrsi.id_software IN (i_prof.software, 0)
                                                ORDER BY bagrsi.id_institution DESC, bagrsi.id_software DESC) tb
                                       ON tb.id_body_diag_age_grp = bag.id_body_diag_age_grp
                                    WHERE bag.id_body_diag_age_grp = dl.id_body_diag_age_grp)))
                   AND dl.flg_available = 'Y'
                   AND dl.flg_type = nvl(i_flg_type, g_flg_type_others);
        
            o_layer_name := pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T038'); -- FIGURE TAG
        
            o_final_layer := 1;
        
            RETURN TRUE;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_all_available_figures',
                                              o_error);
            pk_types.open_my_cursor(o_layers);
            RETURN FALSE;
    END get_all_available_figures;

    FUNCTION get_diag_epis_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_first_run IN VARCHAR2,
        o_info      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --if we are not in edition mode, then we must delete the images that have no simbols associated (MJG request)
        IF i_first_run = pk_alert_constant.g_yes
        THEN
            --remove unused diagrams layouts
            IF NOT remove_non_used_diag(i_lang    => i_lang,
                                        i_prof    => i_prof,
                                        i_patient => i_patient,
                                        i_episode => NULL,
                                        o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --we can now commit the changes already
            COMMIT;
        END IF;
    
        g_error := 'GET CURSOR O_INFO';
        OPEN o_info FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order diagram_number,
                   CASE
                    -- 'Created'
                        WHEN ed.flg_status = g_flg_status_open
                             AND ed.dt_last_update_tstz IS NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T002') || ': '
                    -- 'Updated'
                        WHEN ed.flg_status = g_flg_status_open
                             AND ed.dt_last_update_tstz IS NOT NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041') || ': '
                    -- 'Closed'
                        WHEN ed.flg_status = g_flg_status_close THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T012') || ': '
                    
                    END last_update_tag,
                   pk_date_utils.date_time_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) date_time,
                   ed.id_epis_diagram,
                   ed.id_episode
              FROM epis_diagram ed
             WHERE ed.id_episode IN (SELECT e.id_episode
                                       FROM episode e
                                       JOIN visit v
                                         ON v.id_visit = e.id_visit
                                      WHERE v.id_patient = i_patient)
             ORDER BY ed.id_episode DESC, ed.id_epis_diagram DESC, date_time DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_epis_all',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_diag_epis_all;

    FUNCTION get_all_pat_diag_doc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR O_INFO';
        OPEN o_info FOR
            SELECT id_epis_diagram,
                   diagram_order,
                   pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || diagram_order diagram_desc,
                   id_episode,
                   id_professional,
                   pk_prof_utils.get_reg_prof_id_dcs(id_professional, MAX(dt_diagram_detail_tstz), id_episode) id_prof_dcs,
                   pk_date_utils.to_char_insttimezone(i_lang,
                                                      i_prof,
                                                      MAX(dt_diagram_detail_tstz),
                                                      pk_alert_constant.g_dt_yyyymmddhh24miss) dt_lastupdate,
                   COUNT(DISTINCT id_epis_diagram_layout) num_images
              FROM (SELECT ed.id_epis_diagram,
                           ed.diagram_order,
                           ed.id_episode,
                           edl.id_epis_diagram_layout,
                           edd.id_professional,
                           edd.dt_diagram_detail_tstz
                      FROM epis_diagram ed
                      JOIN epis_diagram_layout edl
                        ON edl.id_epis_diagram = ed.id_epis_diagram
                      JOIN epis_diagram_detail edd
                        ON edd.id_epis_diagram_layout = edl.id_epis_diagram_layout
                     WHERE ed.id_patient = i_patient
                       AND edl.flg_status NOT IN
                           (pk_diagram_new.g_diag_lay_removed, pk_diagram_new.g_diag_lay_cancelled)
                       AND edd.dt_diagram_detail_tstz =
                           (SELECT MAX(edd2.dt_diagram_detail_tstz)
                              FROM epis_diagram_detail edd2
                             WHERE edd2.id_epis_diagram_layout = edl.id_epis_diagram_layout))
             GROUP BY id_epis_diagram, diagram_order, id_episode, id_professional
             ORDER BY id_episode, diagram_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_info);
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_PAT_DIAG_DOC',
                                              o_error);
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END get_all_pat_diag_doc;

    FUNCTION get_pat_num_diagrams(i_patient IN patient.id_patient%TYPE) RETURN NUMBER IS
    
        l_num_diag NUMBER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_num_diag
          FROM epis_diagram ed, epis_diagram_detail edd, epis_diagram_layout edl
         WHERE ed.id_patient = i_patient
           AND edl.id_epis_diagram = ed.id_epis_diagram
           AND edl.id_epis_diagram_layout = edd.id_epis_diagram_layout;
    
        RETURN l_num_diag;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_num_diagrams;

    FUNCTION get_x(i_clob IN CLOB) RETURN VARCHAR2 IS
    
        l_var VARCHAR2(32767);
    
    BEGIN
    
        l_var := pk_string_utils.clob_to_plsqlvarchar2(substr(i_clob, 1, instr(i_clob, '|') - 1));
    
        RETURN l_var;
    
    END get_x;

    FUNCTION get_y(i_clob IN CLOB) RETURN VARCHAR2 IS
    
        l_var VARCHAR2(32767);
    
    BEGIN
    
        l_var := pk_string_utils.clob_to_plsqlvarchar2(substr(i_clob, instr(i_clob, '|') + 1, length(i_clob)));
    
        RETURN l_var;
    
    END get_y;

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    END iif;

    FUNCTION get_diag_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_diag    IN epis_diagram.id_epis_diagram%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        o_title_diag OUT pk_types.cursor_type,
        o_diagram    OUT pk_types.cursor_type,
        o_tblx       OUT table_varchar,
        o_tbly       OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'call get_diag_det in REPORTS context';
        RETURN get_diag_det(i_lang                   => i_lang,
                            i_prof                   => i_prof,
                            i_id_diag                => i_id_diag,
                            i_id_epis_diagram_layout => NULL,
                            i_epis                   => i_epis,
                            i_flg_type               => g_flg_type_others,
                            o_title_diag             => o_title_diag,
                            o_diagram                => o_diagram,
                            o_tblx                   => o_tblx,
                            o_tbly                   => o_tbly,
                            o_error                  => o_error);
    END get_diag_det;

    FUNCTION get_diag_det
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_diag                IN epis_diagram.id_epis_diagram%TYPE,
        i_id_epis_diagram_layout IN epis_diagram_layout.id_epis_diagram_layout%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_flg_type               IN diagram_layout.flg_type%TYPE,
        o_title_diag             OUT pk_types.cursor_type,
        o_diagram                OUT pk_types.cursor_type,
        o_tblx                   OUT table_varchar,
        o_tbly                   OUT table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_x         table_varchar := table_varchar();
        tbl_y         table_varchar := table_varchar();
        l_coord       CLOB;
        l_epis_type   episode.id_epis_type%TYPE;
        l_pl          VARCHAR2(0010 CHAR) := '''';
        l_lf          VARCHAR2(0010 CHAR) := chr(10);
        l_diagram     INTEGER;
        l_run_diagram INTEGER;
        l_flag        NUMBER(24);
        l_sql         VARCHAR2(4000);
    
        FUNCTION set_prof(i_prof IN profissional) RETURN VARCHAR2 IS
        BEGIN
        
            RETURN 'profissional(' || to_char(i_prof.id) || ',' || to_char(i_prof.institution) || ',' || i_prof.software || ')';
        
        END set_prof;
    
        FUNCTION get_sql(i_flag IN NUMBER) RETURN VARCHAR2 IS
            l_sql VARCHAR2(4000);
            k_lang    CONSTANT VARCHAR2(0010 CHAR) := to_char(i_lang);
            k_id_diag CONSTANT NUMBER(24) := to_char(i_id_diag);
            k_inst    CONSTANT NUMBER(24) := to_char(i_prof.institution);
            k_soft    CONSTANT NUMBER(24) := to_char(i_prof.software);
            l_prof              VARCHAR2(1000 CHAR);
            l_id_diagram_layout diagram_layout.id_diagram_layout%TYPE;
        BEGIN
        
            l_prof := set_prof(i_prof);
            -- if the required diagram layout type id is 'N' (Neurological assessment)
            -- AND the diagram does not exist
            IF i_flg_type = g_flg_type_neur_assessm
               AND i_id_diag IS NULL
            THEN
                g_error := 'call get_default_lay for flg_type ''' || g_flg_type_neur_assessm || '''';
                IF NOT get_default_lay(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_episode        => i_epis,
                                       i_flg_type       => i_flg_type,
                                       o_diagram_layout => l_id_diagram_layout,
                                       o_error          => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_sql := '           
                SELECT NULL id_epis_diagram_detail,
                       dli.id_diagram_lay_imag,
                       dld.id_diagram_tools,
                       1 layout_order,
                       dli.id_diagram_layout,
                       NULL id_epis_diagram_layout,
                       /*for each different symbol, we must add its radius(kind of...)!
                       (dld.x_position + 128 + decode(dld.id_diagram_tools, 19, 5, 20, 5, 0)) position_x,
                       (dld.y_position + 320 + decode(dld.id_diagram_tools, 19, 5, 20, 5, 0)) position_y,*/
                       dld.x_position position_x,
                       dld.y_position position_y,
                       ' || iif(i_flag = 1, 'NULL coordinates,', '') || '
                       NULL acronym_group,
                       NULL color,
                       dld.symbol_value VALUE,
                       dt.icon,
                       decode(dld.id_diagram_tools, 19, ''0xC86464'', 20, ''0xC86464'', NULL) color_image,
                       NULL notes,
                       ''' || g_flg_status_active || ''' layout_status,
                       ''' || g_flg_status_active || ''' detail_status,
                       dt.rank,
                       dli.id_diagram_image image,
                       NULL dt_notes,
                       NULL dt_notes_str,
                       NULL name_prof_notes,
                       NULL spec_prof_notes,
                       NULL notes_cancel,
                       NULL dt_notes_cancel,
                       NULL dt_notes_cancel_str,
                       NULL name_prof_notes_cancel,
                       NULL spec_prof_notes_cancel,
                       dl.flg_type,
                       dld.flg_orientation
                  FROM diagram_lay_imag dli
                  JOIN diagram_layout dl
                    ON dli.id_diagram_layout = dl.id_diagram_layout
                  JOIN diagram_layout_details dld
                    ON dli.id_diagram_lay_imag = dld.id_diagram_lay_imag
                  JOIN diagram_tools dt
                    ON dld.id_diagram_tools = dt.id_diagram_tools
                 WHERE dl.flg_type = ''' || i_flg_type || '''
                   AND dl.id_diagram_layout = ' || l_id_diagram_layout;
            ELSE
                l_sql := 'SELECT' || l_lf || 'edd.id_epis_diagram_detail' || l_lf || ',edd.id_diagram_lay_imag' || l_lf ||
                         ',edd.id_diagram_tools' || l_lf || ',edl.layout_order' || l_lf || ',edl.id_diagram_layout' || l_lf ||
                         ',edl.id_epis_diagram_layout' || l_lf || ',edd.position_x' || l_lf || ',edd.position_y' ||
                         iif(i_flag = 1, l_lf || ',edd.coordinates', '') || l_lf || ',pk_translation.get_translation(' ||
                         k_lang || ', dtg.code_acronym_group) acronym_group' || l_lf || ',edd.color color,' || l_lf ||
                         'decode(dl.flg_type, ''' || g_flg_type_neur_assessm ||
                         ''', ddn.notes, edd.value) value,-- the notes become values for neur assessm' || l_lf ||
                         'dt.icon,' || l_lf || 'decode(dl.flg_type, ''' || g_flg_type_neur_assessm ||
                         ''', ''0xC86464'', decode(edd.notes_cancel, NULL, dt.icon_color_image, dt.icon_color_cancel)) color_image,' || l_lf ||
                         'decode(dl.flg_type, ''' || g_flg_type_neur_assessm ||
                         ''', NULL, ddn.notes) notes, -- there is no notes for neur assessm' || l_lf ||
                         'edl.flg_status layout_status,' || l_lf || 'edd.flg_status detail_status,' || l_lf ||
                         'dt.rank rank,' || l_lf || 'di.id_diagram_image image,' || l_lf ||
                         'pk_date_utils.date_send_tsz(' || k_lang || ', ddn.dt_notes_tstz, ' || l_prof || ') dt_notes,' || l_lf ||
                         'pk_date_utils.date_char_tsz(' || k_lang || ', ddn.dt_notes_tstz,' || k_inst || ', ' || k_soft ||
                         ') dt_notes_str,' || l_lf || 'pk_prof_utils.get_name_signature(' || k_lang || ', ' || l_prof ||
                         ', ddn.id_professional) name_prof_notes,' || l_lf || 'pk_prof_utils.get_spec_signature(' ||
                         k_lang || ', ' || l_prof || ', ddn.id_professional, ddn.dt_notes_tstz, NULL) spec_prof_notes,' || l_lf ||
                         'edd.notes_cancel notes_cancel,' || l_lf || 'pk_date_utils.date_send_tsz(' || k_lang ||
                         ', edd.dt_cancel_tstz, ' || l_prof || ') dt_notes_cancel,' || l_lf ||
                         'pk_date_utils.date_char_tsz(' || k_lang || ', edd.dt_cancel_tstz, ' || k_inst || ', ' ||
                         k_soft || ') dt_notes_cancel_str,' || l_lf || 'pk_prof_utils.get_name_signature(' || k_lang || ', ' ||
                         l_prof || ', edd.id_prof_cancel) name_prof_notes_cancel,' || l_lf ||
                         'pk_prof_utils.get_spec_signature(' || k_lang || ', ' || l_prof ||
                         ', edd.id_prof_cancel, edd.dt_cancel_tstz, NULL) spec_prof_notes_cancel,' || l_lf ||
                         'dl.flg_type,' || l_lf || 'decode(dl.flg_type, ''' || g_flg_type_neur_assessm ||
                         ''', dld.flg_orientation, NULL) flg_orientation' || l_lf || 'FROM ' || l_lf ||
                         'epis_diagram              ed,' || l_lf || 'diagram_lay_imag          dli,' || l_lf ||
                         'diagram_image             di,' || l_lf || 'epis_diagram_detail       edd,' || l_lf ||
                         'diagram_tools             dt,' || l_lf || 'diagram_tools_group       dtg,' || l_lf ||
                         'epis_diagram_detail_notes ddn,' || l_lf || 'epis_diagram_layout       edl,' || l_lf ||
                         'diagram_layout            dl,' || l_lf || 'diagram_layout_details    dld' || l_lf ||
                         'WHERE edl.id_epis_diagram = ed.id_epis_diagram' || l_lf ||
                         'AND edl.id_diagram_layout = dl.id_diagram_layout' || l_lf ||
                         'AND edl.id_epis_diagram_layout(+) = edd.id_epis_diagram_layout' || l_lf ||
                         'AND edd.id_diagram_lay_imag = dli.id_diagram_lay_imag' || l_lf ||
                         'AND dli.id_diagram_layout = dl.id_diagram_layout' || l_lf ||
                         'AND dli.id_diagram_image = di.id_diagram_image' || l_lf ||
                         'AND edd.id_diagram_tools = dt.id_diagram_tools' || l_lf ||
                         'AND dt.id_diagram_tools_group = dtg.id_diagram_tools_group' || l_lf ||
                         'AND ddn.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail' || l_lf ||
                         'AND edd.id_diagram_lay_imag = dld.id_diagram_lay_imag(+)' || l_lf ||
                         'AND edd.position_x = dld.x_position(+)' || l_lf || 'AND edd.position_y = dld.y_position(+)' || l_lf ||
                         'AND edl.flg_status <> ' || l_pl || g_diag_lay_removed || l_pl || l_lf ||
                         'AND ((ddn.dt_notes_tstz =' || l_lf || '   (SELECT MAX(ddn1.dt_notes_tstz)' || l_lf ||
                         '        FROM epis_diagram_detail_notes ddn1' || l_lf ||
                         '       WHERE ddn1.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail) AND EXISTS' || l_lf ||
                         '    (SELECT ' || l_pl || '0' || l_pl || l_lf || '        FROM epis_diagram_detail_notes ddn2' || l_lf ||
                         '       WHERE ddn2.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail)) OR NOT EXISTS' || l_lf ||
                         '    (SELECT ' || l_pl || '0' || l_pl || l_lf || '       FROM epis_diagram_detail_notes ddn3' || l_lf ||
                         '      WHERE ddn3.id_epis_diagram_detail(+) = edd.id_epis_diagram_detail))' || l_lf ||
                         'AND ed.id_epis_diagram = ' || k_id_diag ||
                         iif(i_id_epis_diagram_layout IS NOT NULL,
                             'AND edl.id_epis_diagram_layout = ' || i_id_epis_diagram_layout,
                             '') || l_lf || 'ORDER BY acronym_group, edd.value, edd.id_epis_diagram_detail';
            END IF;
            RETURN l_sql;
        END get_sql;
    
    BEGIN
    
        --get the id_visit of the current episode
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_epis;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_type := NULL;
        END;
    
        g_error := 'GET CURSOR O_DIAGRAM';
    
        l_flag    := 1;
        l_sql     := get_sql(l_flag);
        l_diagram := dbms_sql.open_cursor;
    
        dbms_sql.parse(l_diagram, l_sql, dbms_sql.native);
    
        dbms_sql.define_column(l_diagram, 9, l_coord);
    
        l_run_diagram := dbms_sql.execute(l_diagram);
    
        LOOP
            BEGIN
                IF dbms_sql.fetch_rows(l_diagram) > 0
                THEN
                    -- get column values of the row 
                    dbms_sql.column_value(l_diagram, 9, l_coord);
                    tbl_x.extend();
                    tbl_y.extend();
                    tbl_x(tbl_x.count) := pk_diagram_new.get_x(l_coord);
                    tbl_y(tbl_y.count) := pk_diagram_new.get_y(l_coord);
                ELSE
                    EXIT;
                END IF;
            END;
        END LOOP;
    
        IF dbms_sql.is_open(l_diagram)
        THEN
            dbms_sql.close_cursor(l_diagram);
        END IF;
    
        l_flag := 2;
        l_sql  := get_sql(l_flag);
    
        OPEN o_diagram FOR l_sql;
    
        o_tblx := tbl_x;
        o_tbly := tbl_y;
    
        -- fetching the title
        OPEN o_title_diag FOR
            SELECT decode(l_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     epi.id_epis_type,
                                                     g_flg_status_close,
                                                     ed.id_epis_diagram,
                                                     g_bd_ti_log),
                              epi.id_epis_type),
                          pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order,
                          pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T001') || ' ' || ed.diagram_order || ' (' ||
                          pk_message.get_message(i_lang,
                                                 profissional(i_prof.id,
                                                              i_prof.institution,
                                                              nvl(t_ti_log.get_epis_type_soft(i_lang,
                                                                                              i_prof,
                                                                                              epi.id_epis_type,
                                                                                              g_flg_status_close,
                                                                                              ed.id_epis_diagram,
                                                                                              g_bd_ti_log),
                                                                  t_ti_log.get_epis_type_soft(i_lang,
                                                                                              i_prof,
                                                                                              epi.id_epis_type,
                                                                                              g_flg_status_open,
                                                                                              ed.id_epis_diagram,
                                                                                              g_bd_ti_log))),
                                                 'IMAGE_T009') || ')') desc_diagram,
                   ed.diagram_order id_diagram_epis
              FROM epis_diagram ed
              JOIN episode epi
                ON epi.id_episode = ed.id_episode
             WHERE ed.id_epis_diagram = i_id_diag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF dbms_sql.is_open(l_diagram)
            THEN
                dbms_sql.close_cursor(l_diagram);
            END IF;
        
            g_error := pk_message.get_message(i_lang, i_prof, 'COMMON_M001') || chr(10) || g_error;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_diag_det',
                                              o_error);
            pk_types.open_my_cursor(o_title_diag);
            pk_types.open_my_cursor(o_diagram);
            RETURN FALSE;
    END get_diag_det;

    FUNCTION get_pat_diag_grid
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        o_diagram_labels OUT pk_types.cursor_type,
        o_diagrams_data  OUT pk_types.cursor_type,
        o_diag_details   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_id_episode table_number := table_number();
    
    BEGIN
    
        g_error          := 'retrieve visit''s episodes';
        l_tbl_id_episode := pk_episode.get_active_epis_by_visit(i_id_visit => pk_visit.get_visit(i_episode => i_id_episode,
                                                                                                 o_error   => o_error));
        IF l_tbl_id_episode.count = 0
        THEN
            l_tbl_id_episode.extend();
            l_tbl_id_episode(1) := i_id_episode;
        END IF;
    
        g_error := 'o_diagram_labels cursor';
        OPEN o_diagram_labels FOR
            SELECT (pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'DIAGRAM_T040')) AS diag_grid_header,
                   (pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'DIAGRAM_T001')) AS diag_prefix,
                   (pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'DIAGRAM_T038')) AS layout_prefix
              FROM dual;
    
        g_error := 'o_diagrams_data cursor';
        OPEN o_diagrams_data FOR
        -- get all the diagrams that are not cancelled nor removed for a given patient and a calculated visit
            SELECT t.id_epis_diagram,
                   t.diagram_order,
                   COUNT(t.id_epis_diagram_layout) num_layouts,
                   CASE
                    -- 'Created'
                        WHEN t.flg_status = g_flg_status_open
                             AND t.dt_last_update_tstz IS NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T002')
                    -- 'Updated'
                        WHEN t.flg_status = g_flg_status_open
                             AND t.dt_last_update_tstz IS NOT NULL THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T041')
                    -- 'Closed'
                        WHEN t.flg_status = g_flg_status_close THEN
                         pk_message.get_message(i_lang, i_prof, 'DIAGRAM_T012')
                    
                    END AS status_desc,
                   pk_date_utils.date_send_tsz(i_lang, nvl(t.dt_last_update_tstz, t.dt_creation_tstz), i_prof) dt_last_update
              FROM (SELECT ed.id_epis_diagram,
                           ed.diagram_order,
                           ed.dt_creation_tstz,
                           edl.id_epis_diagram_layout,
                           ed.dt_last_update_tstz,
                           ed.flg_status
                      FROM epis_diagram ed
                      JOIN epis_diagram_layout edl
                        ON ed.id_epis_diagram = edl.id_epis_diagram
                     WHERE ed.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              column_value
                                               FROM TABLE(l_tbl_id_episode) t)
                       AND ed.id_patient = i_id_patient
                       AND edl.flg_status NOT IN (g_diag_lay_removed, g_diag_lay_cancelled)) t
             GROUP BY t.id_epis_diagram, t.diagram_order, t.dt_creation_tstz, t.dt_last_update_tstz, t.flg_status
             ORDER BY t.diagram_order DESC;
    
        g_error := 'o_diag_details cursor';
        OPEN o_diag_details FOR
        -- get all the layouts that are in diagrams that are not cancelled nor removed for a given patient and a calculated visit
            SELECT ed.id_epis_diagram,
                   edl.id_epis_diagram_layout,
                   edl.layout_order,
                   pk_translation.get_translation(i_lang, dl.code_diagram_layout) layout_title
              FROM epis_diagram ed
              JOIN epis_diagram_layout edl
                ON ed.id_epis_diagram = edl.id_epis_diagram
              JOIN diagram_layout dl
                ON edl.id_diagram_layout = dl.id_diagram_layout
             WHERE ed.id_episode IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      column_value
                                       FROM TABLE(l_tbl_id_episode) t)
               AND ed.id_patient = i_id_patient
               AND edl.flg_status NOT IN (g_diag_lay_removed, g_diag_lay_cancelled)
             ORDER BY ed.diagram_order DESC, edl.layout_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_diagram_labels);
            pk_types.open_cursor_if_closed(o_diagrams_data);
            pk_types.open_cursor_if_closed(o_diag_details);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_PAT_DIAG_GRID',
                                                     o_error);
    END get_pat_diag_grid;

    FUNCTION get_epis_diagram_actions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        o_actions         OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status epis_diagram.flg_status%TYPE;
    
    BEGIN
    
        g_error := 'get epis_diagram.flg_status';
        SELECT ed.flg_status
          INTO l_flg_status
          FROM epis_diagram ed
         WHERE ed.id_epis_diagram = i_id_epis_diagram;
    
        g_error := 'get actions for body diagrams with flg_status: ' || l_flg_status;
        IF NOT pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => g_action_body_diag_subject,
                                     i_from_state => l_flg_status,
                                     o_actions    => o_actions,
                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_actions);
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_EPIS_DIAGRAM_ACTIONS',
                                                     o_error);
    END get_epis_diagram_actions;

    FUNCTION upd_epis_diag_dt_last_update
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_diagram IN epis_diagram.id_epis_diagram%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl_epis_diag_row_ids table_varchar;
    
    BEGIN
    
        g_error := 'update epis_diagram.dt_last_update_tstz to current_timestamp';
        ts_epis_diagram.upd(id_epis_diagram_in     => i_id_epis_diagram,
                            dt_last_update_tstz_in => g_sysdate_tstz,
                            rows_out               => l_tbl_epis_diag_row_ids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIAGRAM',
                                      i_rowids     => l_tbl_epis_diag_row_ids,
                                      o_error      => o_error);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'UPD_EPIS_DIAG_DT_LAST_UPDATE',
                                                     o_error);
    END upd_epis_diag_dt_last_update;

    PROCEDURE inicialize IS
    BEGIN
    
        g_structure_id             := 1;
        g_body_part_id             := 2;
        g_side_id                  := 3;
        g_layer_id                 := 4;
        g_system_id                := 5;
        g_organ_id                 := 6;
        g_flg_status_det_a         := 'A';
        g_flg_status_det_c         := 'C';
        g_epis_cancel              := 'C';
        g_gender_domain            := 'PATIENT.GENDER';
        g_diagram_single_image_url := 'DIAGRAM_SINGLE_IMAGE_URL';
        g_diagram_full_image_url   := 'DIAGRAM_FULL_IMAGE_URL';
        g_flg_status_active        := 'A';
        g_flg_status_open          := 'O';
        g_flg_status_close         := 'C';
    
        g_epis_diag_lay_flg_status_dmn := 'EPIS_DIAGRAM.FLG_STATUS';
    
        g_flg_type_most_freq  := 'M';
        g_flg_type_searchable := 'P';
        g_flg_type_default    := 'D';
    
    END inicialize;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    inicialize();

END pk_diagram_new;
/
