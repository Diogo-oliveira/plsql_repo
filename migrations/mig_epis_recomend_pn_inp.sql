-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit
DECLARE

    l_id_institution institution.id_institution%TYPE;
    l_id_software    software.id_software%TYPE;
    l_flg_type       VARCHAR2(1 CHAR) := 'M';
    l_id_market      market.id_market%TYPE := 2;
    l_id_epis_type   epis_type.id_epis_type%TYPE := 5;
    l_id_language    language.id_language%TYPE;

    CURSOR c_get_records IS
        SELECT sid.session_id,
               sid.id_professional,
               sid.session_day,
               sid.id_episode,
               sid.id_institution,
               sid.highest_time,
               sid.id_language,
               sid.dt_epis_recomend_tstz_max,
               sid.id_software
          FROM (SELECT a.session_id,
                       a.id_professional,
                       a.id_institution,
                       a.id_software,
                       a.id_episode,
                       pk_date_utils.trunc_insttimezone(profissional(a.id_professional, a.id_institution, a.id_software),
                                                        a.dt_epis_recomend_tstz,
                                                        NULL) session_day,
                       pk_date_utils.dt_chr_hour_tsz(a.id_language,
                                                     MAX(a.dt_epis_recomend_tstz),
                                                     profissional(a.id_professional, a.id_institution, a.id_software)) highest_time,
                       a.id_language,
                       MAX(a.dt_epis_recomend_tstz) dt_epis_recomend_tstz_max
                  FROM (SELECT i.id_institution, il.id_language, ei.id_software, er.*
                          FROM epis_recomend er
                         INNER JOIN (SELECT id_notes_config
                                      FROM notes_config cfg
                                     WHERE cfg.notes_code NOT IN ('BGN', 'END')) nc
                            ON (er.id_notes_config = nc.id_notes_config)
                         INNER JOIN episode e
                            ON er.id_episode = e.id_episode
                           AND e.id_epis_type = l_id_epis_type
                         INNER JOIN institution i
                            ON e.id_institution = i.id_institution
                           AND i.id_market <> l_id_market
                         INNER JOIN epis_info ei
                            ON e.id_episode = ei.id_episode
                         INNER JOIN institution_language il
                            ON i.id_institution = il.id_institution
                         WHERE er.flg_type IN (l_flg_type)) a
                 GROUP BY pk_date_utils.trunc_insttimezone(profissional(a.id_professional,
                                                                        a.id_institution,
                                                                        a.id_software),
                                                           a.dt_epis_recomend_tstz,
                                                           NULL),
                          a.session_id,
                          a.id_professional,
                          a.id_episode,
                          a.id_institution,
                          a.id_language,
                          a.id_software) sid
         ORDER BY sid.session_day, sid.highest_time, sid.session_id, sid.id_professional;

    CURSOR c_grp IS
        SELECT ngp.*
          FROM notes_group ngp
         WHERE ngp.flg_available = 'Y'
           AND ngp.id_notes_group IN (SELECT ngg.id_notes_group
                                        FROM notes_grp_cfg ngg
                                       WHERE ngg.id_software = l_id_software
                                         AND ngg.id_institution = l_id_institution)
         ORDER BY rank;

    -----
    l_header VARCHAR2(1000 CHAR);

    l_list_group_notes  table_varchar := table_varchar();
    l_list_group_status table_varchar := table_varchar();

    l_error_msg VARCHAR2(1000 CHAR);
    l_error     t_error_out;

    l_max_iterator PLS_INTEGER;

    l_year  VARCHAR2(0050);
    l_month VARCHAR2(0050);
    l_day   VARCHAR2(0050);
    l_date  VARCHAR2(0100);

    l_format_date sys_message.desc_message%TYPE;

    l_time_frame_desc      VARCHAR2(4000 CHAR);
    l_highest_time         VARCHAR2(4000 CHAR);
    l_prev_time_frame_desc VARCHAR2(4000 CHAR);
    l_prev_highest_time    VARCHAR2(4000 CHAR);
    l_prev_date            VARCHAR2(4000 CHAR);
    l_diary_desc           sys_message.desc_message%TYPE;

    l_has_new_separator BOOLEAN := FALSE;
    l_has_new_day       BOOLEAN := FALSE;
    l_is_first_time     BOOLEAN := FALSE;

    l_item_str            CLOB;
    l_id_profile_template profile_template.id_profile_template%TYPE;
    l_ret                 BOOLEAN;
    l_count               PLS_INTEGER;
    l_aux                 PLS_INTEGER;
    l_prof                profissional;

    l_id_epis_pn epis_pn.id_epis_pn%TYPE;

    l_has_entered BOOLEAN;

    FUNCTION get_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_session_id     IN epis_recomend.session_id%TYPE,
        i_id_notes_group IN notes_group.id_notes_group%TYPE,
        i_id_episode     IN epis_recomend.id_episode%TYPE,
        i_flg_report     IN notes_profile_inst.flg_print%TYPE,
        i_header         IN VARCHAR2,
        io_items         IN OUT CLOB,
        io_has_items     IN OUT BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_line VARCHAR2(32000);
        l_item VARCHAR2(32000);
    
        l_desc_header notes_group.desc_header%TYPE;
        l_code_header notes_group.code_header%TYPE;
    
        l_status epis_documentation.flg_status%TYPE;
    
        l_notes       table_varchar := table_varchar();
        l_status_list table_varchar := table_varchar();
    
        l_has_outdated BOOLEAN := FALSE;
    
        l_entered BOOLEAN := TRUE;
    
        CURSOR c_erd IS
            SELECT erd.id_epis_recomend,
                   erd.desc_epis_recomend,
                   erd.id_notes_config,
                   ncg.code_group_desc,
                   erd.id_item,
                   ncg.notes_code,
                   ncg.flg_id_item,
                   ngp.desc_header,
                   ngp.code_header,
                   ngp.desc_format,
                   ngp.grp_delimiter
              FROM epis_recomend erd
              JOIN notes_grp_cfg ngc
                ON erd.id_notes_config = ngc.id_notes_config
              JOIN notes_group ngp
                ON ngp.id_notes_group = ngc.id_notes_group
              JOIN notes_config ncg
                ON ncg.id_notes_config = ngc.id_notes_config
             WHERE erd.session_id = i_session_id
               AND erd.id_episode = i_id_episode
               AND ngc.id_notes_group = i_id_notes_group
               AND ngc.id_software = i_prof.software
               AND ngc.id_institution = i_prof.institution
             ORDER BY dt_epis_recomend_tstz;
        --
    
    BEGIN
    
        FOR erd IN c_erd
        LOOP
        
            l_desc_header := erd.desc_header;
            l_code_header := erd.code_header;
        
            IF not pk_clinical_notes.get_item(i_lang,
                                          i_prof,
                                          erd.flg_id_item,
                                          erd.desc_epis_recomend,
                                          erd.id_item,
                                          erd.notes_code,
                                          erd.code_group_desc,
                                          pk_alert_constant.g_no,
                                          l_item,
                                          l_status,
                                          o_error)
            THEN
                raise_application_error(-20001,
                                        'ERROR: pk_clinical_notes.get_item id_epis_recomend: ' || erd.id_epis_recomend ||
                                        ' flg_id_item: ' || erd.flg_id_item || ' desc_epis_recomend: ' ||
                                        erd.desc_epis_recomend || 'id_item: ' || erd.id_item || ' notes_code: ' ||
                                        erd.notes_code || ' code_group_desc: ' || erd.code_group_desc || ' l_item: ' ||
                                        l_item || ' l_status: ' || l_status || chr(13) || o_error.log_id || ' -> ' ||
                                        o_error.err_desc || chr(13) || 'i_lang:' || i_lang || 'i_prof.institution: ' ||
                                        i_prof.institution || ' i_prof.id: ' || i_prof.id || ' i_prof.software: ' ||
                                        i_prof.software);
            END IF;
        
            IF ((l_has_outdated = FALSE OR l_status = pk_alert_constant.g_active) AND
               NOT (i_flg_report = pk_alert_constant.g_yes AND l_status <> pk_alert_constant.g_active))
            THEN
                IF l_entered
                THEN
                    io_items  := io_items || i_header || chr(13);
                    l_entered := FALSE;
                END IF;
            
                IF l_status IN (pk_alert_constant.g_cancelled, pk_alert_constant.g_outdated)
                THEN
                    io_items := io_items || erd.desc_epis_recomend || chr(13);
                END IF;
            
                l_item := REPLACE(erd.desc_format, '@1', l_item);
                IF l_item IS NULL
                THEN
                    l_item := chr(13);
                ELSE
                    l_item := l_item || chr(13) || chr(13);
                END IF;
                io_items := io_items || l_item;
            
                io_has_items := TRUE;
            END IF;
        
            IF (l_status <> pk_alert_constant.g_active AND l_has_outdated = FALSE)
            THEN
                l_has_outdated := TRUE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    END get_group;

BEGIN

    FOR c IN c_get_records
    LOOP
        l_id_software         := c.id_software;
        l_prof                := profissional(c.id_professional, c.id_institution, l_id_software);
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(l_prof);
        l_id_language         := c.id_language;
    
        SELECT COUNT(1)
          INTO l_count
          FROM notes_profile_inst
         WHERE id_profile_template = l_id_profile_template
           AND id_institution = c.id_institution;
    
        l_id_institution := c.id_institution;
        IF l_count = 0
        THEN
            l_id_institution := 0;
        END IF;
    
        l_item_str          := '';
        l_list_group_notes  := table_varchar();
        l_list_group_status := table_varchar();
    
        l_has_entered := FALSE;
    
        FOR grp IN c_grp
        LOOP
            l_list_group_notes := table_varchar();
        
            l_header := nvl(pk_translation.get_translation(i_lang => l_id_language, i_code_mess => grp.code_header),
                            grp.desc_header);
        
            IF NOT get_group(i_lang           => l_id_language,
                             i_prof           => profissional(c.id_professional, l_id_institution, l_id_software),
                             i_session_id     => c.session_id,
                             i_id_notes_group => grp.id_notes_group,
                             i_id_episode     => c.id_episode,
                             i_flg_report     => 'N',
                             i_header         => l_header,
                             io_items         => l_item_str,
                             io_has_items     => l_has_entered,
                             o_error          => l_error)
            THEN
                raise_application_error(-20001,
                                        'ERROR: get_group for id_session: ' || c.session_id || ' id_notes_group: ' ||
                                        grp.id_notes_group || ' id_episode: ' || c.id_episode || chr(13) ||
                                        l_error.log_id || ' -> ' || l_error.err_desc);
            
            END IF;
        END LOOP;
    
        IF l_has_entered
        THEN
        
            IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => l_id_language,
                                                        i_prof                => l_prof,
                                                        i_epis_pn             => NULL,
                                                        i_id_dictation_report => NULL,
                                                        i_id_episode          => c.id_episode,
                                                        i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                                        i_id_pn_note_type     => pk_prog_notes_constants.g_note_type_id_ftn_7,
                                                        i_dt_pn_date          => c.dt_epis_recomend_tstz_max,
                                                        i_id_dep_clin_serv    => NULL,
                                                        i_id_pn_data_block    => table_number(pk_prog_notes_constants.g_dblock_free_text_pn_92),
                                                        i_id_pn_soap_block    => table_number(pk_prog_notes_constants.g_sblock_free_text_pn_17),
                                                        i_id_task             => table_number(NULL),
                                                        i_id_task_type        => table_number(NULL),
                                                        i_pn_note             => table_clob(l_item_str),
                                                        i_id_professional     => l_prof.id,
                                                        i_dt_create           => c.dt_epis_recomend_tstz_max,
                                                        i_dt_last_update      => c.dt_epis_recomend_tstz_max,
                                                        i_dt_sent_to_hist     => c.dt_epis_recomend_tstz_max,
                                                        i_id_prof_sign_off    => l_prof.id,
                                                        i_dt_sign_off         => c.dt_epis_recomend_tstz_max,
                                                        o_id_epis_pn          => l_id_epis_pn,
                                                        o_error               => l_error)
            THEN
                raise_application_error(-20001,
                                        'ERROR: pk_prog_notes_core.set_save_def_note for id_session: ' || c.session_id ||
                                        ' id_episode: ' || c.id_episode || chr(13) || ' l_id_language: ' ||
                                        l_id_language || ' l_prof: ' || l_prof.id || ',' || l_prof.institution || ', ' ||
                                        l_prof.software ||
                                        
                                        chr(13) || l_error.log_id || ' -> ' || l_error.err_desc);
            END IF;
        
        END IF;
    
    END LOOP;

END;
/

-- CHANGE END: ANTONIO.NETO
