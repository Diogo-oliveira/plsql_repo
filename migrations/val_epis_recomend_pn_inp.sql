-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit
DECLARE
    /* Leave as is */
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    /* Leave as is */
    PROCEDURE announce_error IS
    BEGIN
        dbms_output.put_line('Error on data migration. Please look into alertlog.tlog table in ''MIGRATION'' section. Example:
select *
  from alertlog.tlog
 where lsection = ''MIGRATION''
 order by 2 desc, 3 desc, 1 desc;');
    END announce_error;

    /* Leave as is */
    FUNCTION should_execute RETURN BOOLEAN IS
    BEGIN
        RETURN &exec_val = 1;
    END should_execute;

    /* Edit this function */
    PROCEDURE do_my_validation IS
        /* Declarations */
        /* example: */
        e_has_findings EXCEPTION;
        l_id_institution      institution.id_institution%TYPE;
        l_id_software         software.id_software%TYPE;
        l_flg_type            VARCHAR2(1 CHAR) := 'M';
        l_id_market           market.id_market%TYPE := 2;
        l_id_epis_type        epis_type.id_epis_type%TYPE := 5;
        l_id_language         language.id_language%TYPE;
        l_prof                profissional;
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_count               PLS_INTEGER;
    
        l_has_entered BOOLEAN;
    
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
                           pk_date_utils.trunc_insttimezone(profissional(a.id_professional,
                                                                         a.id_institution,
                                                                         a.id_software),
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
                             INNER JOIN epis_info ei
                                ON e.id_episode = ei.id_episode
                             INNER JOIN institution i
                                ON e.id_institution = i.id_institution
                               AND i.id_market <> l_id_market
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
    
        l_num_findings_diary PLS_INTEGER := 0;
        l_num_findings_pn    PLS_INTEGER;
        l_error              t_error_out;
    
        FUNCTION get_group
        (
            i_lang           IN language.id_language%TYPE,
            i_prof           IN profissional,
            i_session_id     IN epis_recomend.session_id%TYPE,
            i_id_notes_group IN notes_group.id_notes_group%TYPE,
            i_id_episode     IN epis_recomend.id_episode%TYPE,
            i_flg_report     IN notes_profile_inst.flg_print%TYPE,
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
            
                IF pk_clinical_notes.get_item(i_lang,
                                              i_prof,
                                              erd.flg_id_item,
                                              erd.desc_epis_recomend,
                                              erd.id_item,
                                              erd.notes_code,
                                              erd.code_group_desc,
                                              pk_alert_constant.g_no,
                                              l_item,
                                              l_status,
                                              o_error) = FALSE
                THEN
                    raise_application_error(-20001,
                                            'ERROR: pk_clinical_notes.get_item id_epis_recomend: ' ||
                                            erd.id_epis_recomend || chr(13) || o_error.log_id || ' -> ' ||
                                            o_error.err_desc);
                END IF;
            
                IF ((l_has_outdated = FALSE OR l_status = pk_alert_constant.g_active) AND
                   NOT (i_flg_report = pk_alert_constant.g_yes AND l_status <> pk_alert_constant.g_active))
                THEN
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
        /* Initializations */
    
        /* Data validation */
        /* there is no validation possible */
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
        
            l_has_entered := FALSE;
        
            FOR grp IN c_grp
            LOOP
            
                IF NOT get_group(i_lang           => l_id_language,
                                 i_prof           => profissional(c.id_professional, l_id_institution, l_id_software),
                                 i_session_id     => c.session_id,
                                 i_id_notes_group => grp.id_notes_group,
                                 i_id_episode     => c.id_episode,
                                 i_flg_report     => 'N',
                                 io_has_items     => l_has_entered,
                                 o_error          => l_error)
                THEN
                    NULL;
                END IF;
            END LOOP;
        
            IF l_has_entered
            THEN
                l_num_findings_diary := l_num_findings_diary + 1;
            END IF;
        
        END LOOP;
    
        BEGIN
            SELECT COUNT(*)
              INTO l_num_findings_pn
              FROM epis_pn epn
             INNER JOIN episode e
                ON epn.id_episode = e.id_episode
               AND e.id_epis_type = 5
             INNER JOIN institution i
                ON e.id_institution = i.id_institution
               AND i.id_market <> l_id_market
             WHERE epn.id_pn_note_type = pk_prog_notes_constants.g_note_type_id_ftn_7
               AND epn.flg_status = 'M';
        EXCEPTION
            WHEN no_data_found THEN
                l_num_findings_pn := 0;
        END;
    dbms_output.put_line(l_num_findings_diary);
		dbms_output.put_line(l_num_findings_pn);
        IF l_num_findings_diary IS NOT NULL
           AND l_num_findings_pn < l_num_findings_diary
        THEN
            RAISE e_has_findings;
        END IF;
    
    EXCEPTION
        /* Exceptions handling */
        /* example: */
        WHEN OTHERS THEN
            log_error('BAD VALUE: Error on migration Diary: ' || l_num_findings_diary || ' PN: ' || l_num_findings_pn);
            /* in the end call announce_error to warn the installation script */
            announce_error;
    END do_my_validation;

BEGIN
    /* Leave as is */
    IF should_execute
    THEN
        do_my_validation;
    END IF;

EXCEPTION
    /* Leave as is */
    WHEN OTHERS THEN
        log_error('UNEXPECTED ERROR: ' || SQLERRM);
        announce_error;
END;
/
-- CHANGE END: ANTONIO.NETO
