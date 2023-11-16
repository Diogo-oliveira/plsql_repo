CREATE OR REPLACE PACKAGE BODY alert.pk_release_notes AS

    g_all_message_code       VARCHAR2(11) := 'COMMON_M014';
    g_code_release_note_summ VARCHAR2(36) := 'RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM.';
    g_code_release_note_desc VARCHAR2(36) := 'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC.';
    g_version_msg_code       VARCHAR2(17) := 'RELEASE_NOTE_T007';

    FUNCTION get_fixs
    (
        i_lang    IN language.id_language%TYPE,
        i_version IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT v.id_version id_fix, v.desc_version desc_fix
              FROM version v
              JOIN fix f
                ON f.id_fix = v.id_version
             WHERE f.id_version IN (SELECT /*+ opt_estimate( t rows=1) */
                                     t.column_value
                                      FROM TABLE(i_version) t)
             ORDER BY v.desc_version;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FIXS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_fixs;

    FUNCTION get_versions
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT v.id_version,
                            pk_message.get_message(i_lang, g_version_msg_code) || v.desc_version desc_version,
                            v.dt_release
              FROM version v
              JOIN fix f
                ON f.id_version = v.id_version
             ORDER BY 3;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VERSIONS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_versions;

    FUNCTION get_template
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        i_inst    IN prof_profile_template.id_institution%TYPE,
        i_soft    IN table_number,
        o_templ   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market NUMBER;
    
        l_profiles NUMBER(12) := 0;
    
    BEGIN
    
        SELECT COUNT(pti.id_profile_template)
          INTO l_profiles
          FROM profile_template_inst pti
         WHERE pti.id_institution = i_inst;
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_inst),
                   0)
          INTO l_market
          FROM dual;
    
        IF l_profiles = 0
        THEN
            g_error := 'GET O_TEMPL';
            OPEN o_templ FOR
                SELECT DISTINCT pt.id_profile_template,
                                decode(ptm.id_market,
                                       0,
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)

                               FROM software s WHERE s.id_software =' ||
                                                                pt.id_software || '',
                                                                ',') || ') ',
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)

                               FROM software s WHERE s.id_software =' ||
                                                                pt.id_software || '',
                                                                ',') || ') (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', m.code_market)

                               FROM market m WHERE m.id_market =' ||
                                                                ptm.id_market || '',
                                                                ',') || ')') desc_prof_template
                  FROM profile_template pt
                  LEFT JOIN prof_profile_template ppt
                    ON ppt.id_profile_template = pt.id_profile_template
                  LEFT JOIN profile_template_category ptc
                    ON pt.id_profile_template = ptc.id_profile_template
                  LEFT JOIN profile_template_inst pti
                    ON ptc.id_profile_template = pti.id_profile_template
                  LEFT JOIN profile_template_market ptm
                    ON pt.id_profile_template = ptm.id_profile_template
                 WHERE ppt.id_professional = i_id_prof
                   AND ppt.id_institution = i_inst
                   AND pt.flg_available = 'Y'
                   AND pt.id_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                           t.column_value
                                            FROM TABLE(i_soft) t)
                   AND nvl(pt.id_institution, i_inst) LIKE nvl(to_char(i_inst), '%')
                   AND ptc.id_category = (SELECT pc.id_category
                                            FROM prof_cat pc
                                           WHERE pc.id_professional = i_id_prof
                                             AND pc.id_institution = i_inst)
                   AND pti.id_institution = 0
                   AND ptm.id_market IN (l_market, 0)
                   AND (NOT EXISTS (SELECT 'X'
                                      FROM profile_template pt2
                                     WHERE pt2.id_profile_template_appr = pt.id_profile_template) OR
                        ppt.id_professional IS NOT NULL);
        
        ELSE
            g_error := 'GET O_TEMPL';
            OPEN o_templ FOR
                SELECT DISTINCT pt.id_profile_template,
                                decode(ptm.id_market,
                                       0,
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)

                               FROM software s WHERE s.id_software =' ||
                                                                pt.id_software || '',
                                                                ',') || ') ',
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)

                               FROM software s WHERE s.id_software =' ||
                                                                pt.id_software || '',
                                                                ',') || ') (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', m.code_market)

                               FROM market m WHERE m.id_market =' ||
                                                                ptm.id_market || '',
                                                                ',') || ')') intern_name_templ
                  FROM profile_template pt
                  LEFT JOIN prof_profile_template ppt
                    ON ppt.id_profile_template = pt.id_profile_template
                  LEFT JOIN profile_template_category ptc
                    ON pt.id_profile_template = ptc.id_profile_template
                  LEFT JOIN profile_template_inst pti
                    ON ptc.id_profile_template = pti.id_profile_template
                  LEFT JOIN profile_template_market ptm
                    ON pt.id_profile_template = ptm.id_profile_template
                 WHERE ppt.id_professional = i_id_prof
                   AND ppt.id_institution = i_inst
                   AND pt.flg_available = 'Y'
                   AND pt.id_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                           t.column_value
                                            FROM TABLE(i_soft) t)
                   AND nvl(pt.id_institution, i_inst) LIKE nvl(to_char(i_inst), '%')
                   AND ptc.id_category = (SELECT pc.id_category
                                            FROM prof_cat pc
                                           WHERE pc.id_professional = i_id_prof
                                             AND pc.id_institution = i_inst)
                   AND pti.id_institution = i_inst
                   AND ptm.id_market IN (l_market, 0)
                   AND (NOT EXISTS (SELECT 'X'
                                      FROM profile_template pt2
                                     WHERE pt2.id_profile_template_appr = pt.id_profile_template) OR
                        ppt.id_professional IS NOT NULL)
                 ORDER BY intern_name_templ;
        
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
                                              'GET_TEMPLATE',
                                              o_error);
            pk_types.open_my_cursor(o_templ);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_template;

    FUNCTION get_release_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_soft                  IN table_number,
        i_prof_template         IN table_number,
        i_version               IN table_number,
        i_fix                   IN table_number,
        i_rn_start_index        IN NUMBER DEFAULT 1,
        i_rn_num_records        IN NUMBER DEFAULT 100,
        o_list                  OUT pk_types.cursor_type,
        o_default_soft          OUT pk_types.cursor_type,
        o_default_prof_template OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_temp profissional;
    
        l_soft table_number;
    
        l_version table_number;
        l_fix     table_number;
    
        l_prof_template_default table_number := table_number();
        l_prof_template         table_number;
        l_id_prof_template      profile_template.id_profile_template%TYPE;
    
        l_inst_market    market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_inst_market_tn table_number := table_number(l_inst_market);
    
    BEGIN
    
        l_inst_market_tn.extend;
        l_inst_market_tn(l_inst_market_tn.last) := 0;
    
        g_error := 'SOFTWARE VALIDATION';
        IF i_soft IS NULL
           OR i_soft.count = 0
        THEN
            l_soft := table_number(i_prof.software);
        
            OPEN o_default_soft FOR
                SELECT s.id_software, pk_translation.get_translation(i_lang, s.code_software) desc_software
                  FROM software s
                 WHERE s.id_software = i_prof.software;
        
            l_prof_template_default.extend;
            l_prof_template_default(l_prof_template_default.last) := pk_prof_utils.get_prof_profile_template(i_prof);
        
        ELSE
            pk_types.open_cursor_if_closed(o_default_soft);
        
            FOR i IN i_soft.first .. i_soft.last
            LOOP
                l_prof_temp := profissional(i_prof.id, i_prof.institution, i_soft(i));
            
                l_id_prof_template := pk_prof_utils.get_prof_profile_template(l_prof_temp);
            
                IF l_id_prof_template IS NOT NULL
                THEN
                    l_prof_template_default.extend;
                    l_prof_template_default(l_prof_template_default.last) := l_id_prof_template;
                END IF;
            END LOOP;
        
            l_soft := i_soft;
        END IF;
    
        l_soft.extend;
        l_soft(l_soft.last) := 0;
    
        g_error := 'PROFILE VALIDATION';
    
        IF i_prof_template IS NULL
           OR i_prof_template.count = 0
        THEN
            l_prof_template := l_prof_template_default;
        
            OPEN o_default_prof_template FOR
                SELECT id_profile_template id_profile_template,
                       decode(id_market,
                              0,
                              decode(id_profile_template,
                                     0,
                                     pk_message.get_message(i_lang, g_all_message_code),
                                     pk_message.get_message(i_lang, code_profile_template)) ||
                              decode(id_software,
                                     0,
                                     '',
                                     ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                      ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                      id_software || '',
                                                                      ',') || ')'),
                              decode(id_profile_template,
                                     0,
                                     pk_message.get_message(i_lang, g_all_message_code),
                                     pk_message.get_message(i_lang, code_profile_template)) ||
                              decode(id_software,
                                     0,
                                     '',
                                     ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                      ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                      id_software || '',
                                                                      ',') || ')') || ' (' ||
                              pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                       ', m.code_market)
                               FROM market m WHERE m.id_market = ' ||
                                                       id_market || '',
                                                       ',') || ')') desc_prof_template
                  FROM (SELECT DISTINCT ptm.id_market,
                                        pt.id_profile_template,
                                        pt.code_profile_template,
                                        pt.id_software,
                                        rank() over(ORDER BY pt.id_profile_template DESC, ptm.id_market DESC) rank_row
                          FROM profile_template pt
                          JOIN profile_template_market ptm
                            ON ptm.id_profile_template = pt.id_profile_template
                         WHERE pt.id_profile_template IN
                               (SELECT /*+ opt_estimate( t rows=1) */
                                 column_value
                                  FROM TABLE(l_prof_template_default) t)
                           AND ptm.id_market IN (SELECT /*+ opt_estimate( t rows=1) */
                                                  column_value
                                                   FROM TABLE(l_inst_market_tn) t));
        ELSE
        
            pk_types.open_cursor_if_closed(o_default_prof_template);
            l_prof_template := i_prof_template;
        
        END IF;
    
        g_error := 'VERSION VALIDATION';
        IF i_version IS NULL
           OR i_version.count = 0
        THEN
            l_version := NULL;
        ELSE
            l_version := i_version;
        END IF;
    
        g_error := 'FIX VALIDATION';
        IF i_fix IS NULL
           OR i_fix.count = 0
        THEN
            l_fix := NULL;
        ELSE
            l_fix := i_fix;
        END IF;
    
        l_prof_template.extend;
        l_prof_template(l_prof_template.last) := 0;
    
        g_error := 'SELECT RELEASE NOTES';
        OPEN o_list FOR
            SELECT topmost_rn.*,
                   pk_date_utils.dt_chr(i_lang, topmost_rn.dt_release, i_prof.institution, i_prof.software) date_release_fix,
                   (SELECT pk_message.get_message(i_lang, g_version_msg_code) || desc_version
                      FROM version
                     WHERE id_version = topmost_rn.id_version) desc_version,
                   (SELECT SET(CAST(COLLECT(decode(s.id_software,
                                                   0,
                                                   pk_message.get_message(i_lang, g_all_message_code),
                                                   pk_translation.get_translation(i_lang, s.code_software))) AS
                                    table_varchar)) desc_s
                      FROM release_note_prof_temp_market rntmp
                      JOIN profile_template_market ptm
                        ON ptm.id_profile_template_market = rntmp.id_profile_template_market
                      JOIN profile_template pt
                        ON ptm.id_profile_template = pt.id_profile_template
                      JOIN software s
                        ON s.id_software = pt.id_software
                     WHERE rntmp.id_release_note = topmost_rn.id_release_note) desc_softwares,
                   decode(topmost_rn.id_market,
                          0,
                          decode(topmost_rn.id_profile_template,
                                 0,
                                 pk_message.get_message(i_lang, g_all_message_code),
                                 pk_message.get_message(i_lang, topmost_rn.code_profile_template)) ||
                          
                          decode(topmost_rn.id_software,
                                 0,
                                 '',
                                 ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                  ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                  topmost_rn.id_software || '',
                                                                  ',') || ')'),
                          decode(topmost_rn.id_profile_template,
                                 0,
                                 pk_message.get_message(i_lang, g_all_message_code),
                                 pk_message.get_message(i_lang, topmost_rn.code_profile_template)) ||
                          decode(topmost_rn.id_software,
                                 0,
                                 '',
                                 ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                  ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                  topmost_rn.id_software || '',
                                                                  ',') || ')') || ' (' ||
                          pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                   ', m.code_market)
                               FROM market m WHERE m.id_market = ' ||
                                                   topmost_rn.id_market || '',
                                                   ',') || ')') desc_prof_template
              FROM (SELECT *
                      FROM (SELECT COUNT(*) over() total_rn,
                                   COUNT(*) over(PARTITION BY all_rn.id_profile_template, all_rn.id_fix ORDER BY all_rn.id_profile_template, all_rn.id_fix) total_rn_group,
                                   dense_rank() over(ORDER BY all_rn.id_profile_template, all_rn.id_fix) rank_group,
                                   row_number() over(ORDER BY all_rn.id_profile_template, all_rn.id_fix, all_rn.title_release_note) rank_rn,
                                   all_rn.*
                              FROM (SELECT rn.id_release_note,
                                           f.id_version,
                                           v.dt_release,
                                           f.id_fix,
                                           v.desc_version desc_fix,
                                           pt.id_profile_template,
                                           ptm.id_market,
                                           pt.id_software,
                                           pt.code_profile_template,
                                           pk_translation.get_translation(i_lang, rn.code_release_note_summ) title_release_note,
                                           pk_translation_lob.get_translation(i_lang, rn.code_release_note_desc) desc_release_note
                                      FROM release_note rn
                                      JOIN release_note_prof_temp_market rnptm
                                        ON rn.id_release_note = rnptm.id_release_note
                                      JOIN profile_template_market ptm
                                        ON ptm.id_profile_template_market = rnptm.id_profile_template_market
                                      JOIN release_note_fix rnf
                                        ON rnf.id_release_note = rn.id_release_note
                                      JOIN fix f
                                        ON f.id_fix = rnf.id_fix
                                      JOIN version v
                                        ON v.id_version = f.id_fix
                                      JOIN profile_template pt
                                        ON pt.id_profile_template = ptm.id_profile_template
                                     WHERE ptm.id_market IN (SELECT /*+ opt_estimate(table t rows=2) */
                                                              column_value
                                                               FROM TABLE(l_inst_market_tn) t)
                                       AND pt.id_software IN (SELECT /*+ opt_estimate(table t rows=10) */
                                                               column_value
                                                                FROM TABLE(l_soft) t)
                                          
                                       AND pt.id_profile_template IN
                                           (SELECT /*+ opt_estimate(table t rows=10) */
                                             column_value
                                              FROM TABLE(l_prof_template) t)
                                       AND EXISTS
                                     (SELECT 1
                                              FROM (SELECT rank() over(PARTITION BY f1.id_version ORDER BY v1.dt_release DESC) rank_version,
                                                           rank() over(ORDER BY v1.dt_release DESC) rank_version_sem,
                                                           f1.id_fix,
                                                           f1.id_version,
                                                           v1.dt_release
                                                      FROM version v1
                                                      JOIN fix f1
                                                        ON f1.id_fix = v1.id_version
                                                     WHERE ((f1.id_version IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                                                column_value
                                                                                 FROM TABLE(l_version) t)) OR
                                                           l_version IS NULL)
                                                          
                                                       AND ((f1.id_fix IN (SELECT /*+ opt_estimate(table t rows=10) */
                                                                            column_value
                                                                             FROM TABLE(l_fix) t)) OR l_fix IS NULL)
                                                       AND EXISTS (SELECT 1
                                                              FROM (SELECT f.id_fix
                                                                      FROM version v
                                                                      JOIN fix f
                                                                        ON f.id_fix = v.id_version
                                                                      JOIN release_note_fix rnf
                                                                        ON rnf.id_version = f.id_version
                                                                       AND rnf.id_fix = f.id_fix
                                                                     WHERE rnf.id_release_note IN
                                                                           (SELECT rnptm.id_release_note
                                                                              FROM profile_template_market ptm
                                                                              JOIN release_note_prof_temp_market rnptm
                                                                                ON rnptm.id_profile_template_market =
                                                                                   ptm.id_profile_template_market
                                                                             WHERE ptm.id_profile_template IN
                                                                                   (SELECT /*+ opt_estimate(table t rows=10) */
                                                                                     column_value
                                                                                      FROM TABLE(l_prof_template) t)
                                                                               AND ptm.id_market IN
                                                                                   (SELECT /*+ opt_estimate(table t rows=2) */
                                                                                     column_value
                                                                                      FROM TABLE(l_inst_market_tn) t))
                                                                       AND pk_translation.get_translation(i_lang,
                                                                                                          'RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM.' ||
                                                                                                          rnf.id_release_note) IS NOT NULL
                                                                       AND pk_translation_lob.get_translation(i_lang,
                                                                                                              'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC.' ||
                                                                                                              rnf.id_release_note) IS NOT NULL) aux1
                                                             WHERE aux1.id_fix = f1.id_fix)) aux
                                             WHERE (l_version IS NOT NULL AND
                                                   id_version IN (SELECT column_value
                                                                     FROM TABLE(l_version)) OR (l_version IS NULL))
                                               AND (l_fix IS NOT NULL AND
                                                   id_fix IN (SELECT column_value
                                                                 FROM TABLE(l_fix)) OR
                                                   l_fix IS NULL AND rank_version_sem = 1)
                                               AND aux.id_fix = f.id_fix)
                                       AND pk_translation.get_translation(i_lang, rn.code_release_note_summ) IS NOT NULL
                                       AND pk_translation_lob.get_translation(i_lang, rn.code_release_note_desc) IS NOT NULL
                                     ORDER BY v.dt_release DESC, pt.id_profile_template) all_rn) all_rn_with_rank
                     WHERE all_rn_with_rank.rank_rn <= i_rn_start_index + i_rn_num_records - 1) topmost_rn
             WHERE topmost_rn.rank_rn >= i_rn_start_index;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RELEASE_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_default_soft);
            pk_types.open_my_cursor(o_default_prof_template);
            RETURN FALSE;
    END get_release_notes;

    FUNCTION search_release_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_soft           IN table_number,
        i_prof_template  IN table_number,
        i_version        IN table_number,
        i_fix            IN table_number,
        i_rn_start_index IN NUMBER DEFAULT 1,
        i_rn_num_records IN NUMBER DEFAULT 100,
        i_search         IN VARCHAR2 DEFAULT '',
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_soft           table_number;
        l_prof_template  table_number;
        l_version        table_number;
        l_fix            table_number;
        l_inst_market    market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_inst_market_tn table_number := table_number(l_inst_market);
    
    BEGIN
    
        l_inst_market_tn.extend;
        l_inst_market_tn(l_inst_market_tn.last) := 0;
    
        g_error := 'SOFTWARE VALIDATION';
        l_soft  := i_soft;
        l_soft.extend;
        l_soft(l_soft.last) := 0;
    
        g_error         := 'PROFILE VALIDATION';
        l_prof_template := i_prof_template;
    
        l_prof_template.extend;
        l_prof_template(l_prof_template.last) := 0;
    
        g_error   := 'VERSION VALIDATION';
        l_version := i_version;
    
        g_error := 'FIX VALIDATION';
        l_fix   := i_fix;
    
        g_error := 'SELECT RELEASE NOTES';
        OPEN o_list FOR
            SELECT topmost_rn.*,
                   pk_date_utils.dt_chr(i_lang, topmost_rn.dt_release, i_prof.institution, i_prof.software) date_release_fix,
                   (SELECT pk_message.get_message(i_lang, g_version_msg_code) || desc_version
                      FROM version
                     WHERE id_version = topmost_rn.id_version) desc_version,
                   (SELECT SET(CAST(COLLECT(decode(s.id_software,
                                                   0,
                                                   pk_message.get_message(i_lang, g_all_message_code),
                                                   pk_translation.get_translation(i_lang, s.code_software))) AS
                                    table_varchar)) desc_s
                      FROM release_note_prof_temp_market rntmp
                      JOIN profile_template_market ptm
                        ON ptm.id_profile_template_market = rntmp.id_profile_template_market
                      JOIN profile_template pt
                        ON ptm.id_profile_template = pt.id_profile_template
                      JOIN software s
                        ON s.id_software = pt.id_software
                     WHERE rntmp.id_release_note = topmost_rn.id_release_note) desc_softwares,
                   decode(topmost_rn.id_market,
                          0,
                          decode(topmost_rn.id_profile_template,
                                 0,
                                 pk_message.get_message(i_lang, g_all_message_code),
                                 pk_message.get_message(i_lang, topmost_rn.code_profile_template)) ||
                          
                          decode(topmost_rn.id_software,
                                 0,
                                 '',
                                 ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                  ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                  topmost_rn.id_software || '',
                                                                  ',') || ')'),
                          decode(topmost_rn.id_profile_template,
                                 0,
                                 pk_message.get_message(i_lang, g_all_message_code),
                                 pk_message.get_message(i_lang, topmost_rn.code_profile_template)) ||
                          decode(topmost_rn.id_software,
                                 0,
                                 '',
                                 ' (' || pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                  ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                  topmost_rn.id_software || '',
                                                                  ',') || ')') || ' (' ||
                          pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                   ', m.code_market)
                               FROM market m WHERE m.id_market = ' ||
                                                   topmost_rn.id_market || '',
                                                   ',') || ')') desc_prof_template
              FROM (SELECT *
                      FROM (SELECT COUNT(*) over() total_rn,
                                   COUNT(*) over(PARTITION BY all_rn.dt_release, all_rn.id_profile_template ORDER BY all_rn.dt_release, all_rn.id_profile_template) total_rn_group,
                                   dense_rank() over(ORDER BY all_rn.dt_release, all_rn.id_profile_template) rank_group,
                                   row_number() over(ORDER BY all_rn.dt_release, all_rn.id_profile_template, all_rn.title_release_note) rank_rn,
                                   all_rn.*
                              FROM (SELECT rn.id_release_note,
                                           f.id_version,
                                           v.dt_release,
                                           f.id_fix,
                                           v.desc_version           desc_fix,
                                           pt.id_profile_template,
                                           ptm.id_market,
                                           pt.id_software,
                                           pt.code_profile_template,
                                           ls.desc_vc               title_release_note,
                                           ls.desc_clob             desc_release_note
                                      FROM release_note rn
                                      JOIN release_note_prof_temp_market rnptm
                                        ON rn.id_release_note = rnptm.id_release_note
                                      JOIN profile_template_market ptm
                                        ON ptm.id_profile_template_market = rnptm.id_profile_template_market
                                      JOIN release_note_fix rnf
                                        ON rnf.id_release_note = rn.id_release_note
                                      JOIN fix f
                                        ON f.id_fix = rnf.id_fix
                                      JOIN version v
                                        ON v.id_version = f.id_fix
                                      JOIN profile_template pt
                                        ON pt.id_profile_template = ptm.id_profile_template
                                    -- Get items that contain search keyword
                                      JOIN (SELECT aux1.id_release_note,
                                                  pk_translation.get_translation(i_lang,
                                                                                 'RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM.' ||
                                                                                 aux1.id_release_note) desc_vc,
                                                  pk_translation_lob.get_translation(i_lang,
                                                                                     'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC.' ||
                                                                                     aux1.id_release_note) desc_clob
                                             FROM (SELECT id_release_note
                                                   
                                                     FROM (SELECT desc_translation desc_vc,
                                                                  to_number(substr(code_translation,
                                                                                   instr(code_translation, '.', -1, 1) + 1)) id_release_note
                                                             FROM TABLE(pk_translation.get_search_translation(i_lang,
                                                                                                              i_search,
                                                                                                              'RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM')) aux)
                                                   UNION
                                                   SELECT id_release_note
                                                   
                                                     FROM (SELECT desc_translation desc_clob,
                                                                  to_number(substr(code_translation,
                                                                                   instr(code_translation, '.', -1, 1) + 1)) id_release_note
                                                             FROM TABLE(pk_translation_lob.get_search_translation(i_lang,
                                                                                                                  i_search,
                                                                                                                  'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC')) aux)) aux1
                                            WHERE pk_translation.get_translation(i_lang,
                                                                                 'RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM.' ||
                                                                                 aux1.id_release_note) IS NOT NULL
                                              AND pk_translation_lob.get_translation(i_lang,
                                                                                     'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC.' ||
                                                                                     aux1.id_release_note) IS NOT NULL) ls
                                        ON (ls.id_release_note = rn.id_release_note)
                                     WHERE ptm.id_market IN (SELECT /*+ opt_estimate(table t rows=2) */
                                                              column_value
                                                               FROM TABLE(l_inst_market_tn) t)
                                       AND pt.id_software IN (SELECT /*+ opt_estimate(table t rows=10) */
                                                               column_value
                                                                FROM TABLE(l_soft) t)
                                       AND pt.id_profile_template IN
                                           (SELECT /*+ opt_estimate(table t rows=10) */
                                             column_value
                                              FROM TABLE(l_prof_template) t)
                                       AND EXISTS
                                     (SELECT 1
                                              FROM (SELECT rank() over(PARTITION BY f1.id_version ORDER BY v1.dt_release DESC) rank_version,
                                                           rank() over(ORDER BY v1.dt_release DESC) rank_version_sem,
                                                           f1.id_fix,
                                                           f1.id_version,
                                                           v1.dt_release
                                                      FROM version v1
                                                      JOIN fix f1
                                                        ON f1.id_fix = v1.id_version
                                                     WHERE ((f1.id_version IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                                                column_value
                                                                                 FROM TABLE(l_version) t)) OR
                                                           l_version IS NULL)
                                                       AND ((f1.id_fix IN (SELECT /*+ opt_estimate(table t rows=10) */
                                                                            column_value
                                                                             FROM TABLE(l_fix) t)) OR l_fix IS NULL)
                                                       AND EXISTS (SELECT 1
                                                              FROM (SELECT f.id_fix
                                                                      FROM version v
                                                                      JOIN fix f
                                                                        ON f.id_fix = v.id_version
                                                                      JOIN release_note_fix rnf
                                                                        ON rnf.id_version = f.id_version
                                                                       AND rnf.id_fix = f.id_fix
                                                                     WHERE rnf.id_release_note IN
                                                                           (SELECT rnptm.id_release_note
                                                                              FROM profile_template_market ptm
                                                                              JOIN release_note_prof_temp_market rnptm
                                                                                ON rnptm.id_profile_template_market =
                                                                                   ptm.id_profile_template_market
                                                                             WHERE ptm.id_profile_template IN
                                                                                   (SELECT /*+ opt_estimate(table t rows=10) */
                                                                                     column_value
                                                                                      FROM TABLE(l_prof_template) t)
                                                                               AND ptm.id_market IN
                                                                                   (SELECT /*+ opt_estimate(table t rows=2) */
                                                                                     column_value
                                                                                      FROM TABLE(l_inst_market_tn) t))) aux1
                                                             WHERE aux1.id_fix = f1.id_fix)) aux
                                             WHERE (l_version IS NOT NULL AND
                                                   id_version IN (SELECT column_value
                                                                     FROM TABLE(l_version)) OR (l_version IS NULL))
                                               AND (l_fix IS NOT NULL AND
                                                   id_fix IN (SELECT column_value
                                                                 FROM TABLE(l_fix)) OR
                                                   l_fix IS NULL AND rank_version_sem = 1)
                                               AND aux.id_fix = f.id_fix)) all_rn) all_rn_with_rank
                     WHERE all_rn_with_rank.rank_rn <= i_rn_start_index + i_rn_num_records - 1) topmost_rn
             WHERE topmost_rn.rank_rn >= i_rn_start_index;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SEARCH_RELEASE_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END search_release_notes;

    FUNCTION get_profile_template_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN prof_profile_template.id_institution%TYPE,
        i_id_software    IN table_number,
        o_templ          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_profiles NUMBER(12) := 0;
        l_market   institution.id_market%TYPE;
    
    BEGIN
    
        SELECT COUNT(pti.id_profile_template)
          INTO l_profiles
          FROM profile_template_inst pti
         WHERE pti.id_institution = i_id_institution;
    
        SELECT nvl((SELECT i.id_market
                     FROM institution i
                    WHERE i.id_institution = i_id_institution),
                   0)
          INTO l_market
          FROM dual;
    
        IF l_profiles = 0
        THEN
            g_error := 'GET O_TEMPL';
            OPEN o_templ FOR
                SELECT DISTINCT pt.id_profile_template,
                                decode(ptm.id_market,
                                       0,
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                pt.id_software || '',
                                                                ',') || ') ',
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                pt.id_software || '',
                                                                ',') || ') (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', m.code_market)
                               FROM market m WHERE m.id_market = ' ||
                                                                ptm.id_market || '',
                                                                ',') || ')') desc_prof_template
                  FROM profile_template pt, profile_template_inst pti, profile_template_market ptm
                 WHERE pt.id_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                           column_value
                                            FROM TABLE(i_id_software) t)
                   AND pt.flg_available = pk_alert_constant.g_available
                   AND pti.id_institution = 0
                   AND pti.id_profile_template = pt.id_profile_template
                   AND ptm.id_profile_template = pti.id_profile_template
                   AND ptm.id_market IN (0, l_market)
                 ORDER BY desc_prof_template;
        
        ELSE
            g_error := 'GET O_TEMPL';
            OPEN o_templ FOR
                SELECT DISTINCT pt.id_profile_template,
                                decode(ptm.id_market,
                                       0,
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                pt.id_software || '',
                                                                ',') || ') ',
                                       pk_message.get_message(i_lang, pt.code_profile_template) || ' (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', s.code_software)
                               FROM software s WHERE s.id_software = ' ||
                                                                pt.id_software || '',
                                                                ',') || ') (' ||
                                       pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                ', m.code_market)
                               FROM market m WHERE m.id_market = ' ||
                                                                ptm.id_market || '',
                                                                ',') || ')') desc_prof_template
                  FROM profile_template pt, profile_template_inst pti, profile_template_market ptm
                 WHERE pt.id_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                           column_value
                                            FROM TABLE(i_id_software) t)
                   AND pt.flg_available = pk_alert_constant.g_available
                   AND pti.id_institution = i_id_institution
                   AND pti.id_profile_template = pt.id_profile_template
                   AND ptm.id_profile_template = pti.id_profile_template
                   AND ptm.id_market IN (0, l_market)
                 ORDER BY desc_prof_template;
        
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
                                              'GET_PROFILE_TEMPLATE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_templ);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_profile_template_list;

    FUNCTION get_prof_template_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_all_cat NUMBER := pk_sysconfig.get_config('REL_NOTES_ALL_PROFILES', i_prof);
    
    BEGIN
    
        g_error := 'GET_PROF_TEMPLATE_LIST';
        IF l_all_cat = 1
        THEN
            IF NOT get_profile_template_list(i_lang, i_prof.institution, i_soft, o_list, o_error)
            THEN
                g_error := 'Invoking GET_PROFILE_TEMPLATE_LIST';
                RETURN FALSE;
            END IF;
        ELSE
            IF NOT get_template(i_lang, i_prof.id, i_prof.institution, i_soft, o_list, o_error)
            THEN
                g_error := 'Invoking GET_TEMPLATE';
                RETURN FALSE;
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
                                              g_package_name,
                                              'GET_PROF_TEMPLATE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_prof_template_list;

    FUNCTION get_software_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_all_soft      NUMBER := pk_sysconfig.get_config('REL_NOTES_ALL_SOFTWARES', i_prof);
        l_timestamp_str VARCHAR2(100 CHAR);
        l_offset        VARCHAR2(100 CHAR);
    
        l_list      pk_types.cursor_type;
        l_software  table_number;
        l_desc_lang table_varchar;
        l_desc_icon table_varchar;
        l_lang_pref table_number;
    
    BEGIN
    
        g_error := 'GET_SOFTWARE_LIST';
        IF l_all_soft = 0
        THEN
            IF NOT pk_login.get_software_list(i_lang, i_prof, l_list, l_timestamp_str, l_offset, o_error)
            THEN
                g_error := 'PK_LOGIN.GET_SOFTWARE_LIST';
                RETURN FALSE;
            END IF;
        
            BEGIN
                LOOP
                    FETCH l_list BULK COLLECT
                        INTO l_software, l_desc_lang, l_desc_icon, l_lang_pref;
                
                    OPEN o_list FOR
                        SELECT t1.v1 id_software, t2.v2 desc_software, t3.v3 icon, t4.v4 id_lang_pref
                          FROM (SELECT /*+opt_estimate (table val1 rows=1)*/
                                 rownum rn, v.column_value v1
                                  FROM TABLE(l_software) v) t1,
                               (SELECT /*+opt_estimate (table val2 rows=1)*/
                                 rownum rn, v.column_value v2
                                  FROM TABLE(l_desc_lang) v) t2,
                               (SELECT /*+opt_estimate (table val2 rows=1)*/
                                 rownum rn, v.column_value v3
                                  FROM TABLE(l_desc_icon) v) t3,
                               (SELECT /*+opt_estimate (table val2 rows=1)*/
                                 rownum rn, v.column_value v4
                                  FROM TABLE(l_lang_pref) v) t4
                         WHERE t1.rn = t2.rn
                           AND t1.rn = t3.rn
                           AND t1.rn = t4.rn
                           AND t1.v1 IN (SELECT s.id_software
                                           FROM software s
                                          WHERE s.flg_viewer = pk_alert_constant.g_no)
                         ORDER BY desc_software;
                
                    EXIT WHEN l_list%NOTFOUND;
                
                END LOOP;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        ELSE
            g_error := 'GET ALL SOFTWARES';
            OPEN o_list FOR
                SELECT s.id_software,
                       pk_translation.get_translation(i_lang, s.code_software) desc_software,
                       pk_translation.get_translation(i_lang, s.code_icon) icon,
                       i_lang id_lang_pref
                  FROM software s
                 WHERE s.flg_mni = pk_login.g_flg_mni
                   AND s.flg_viewer = pk_alert_constant.g_no
                   AND EXISTS (SELECT 1
                          FROM profile_template pt
                          JOIN profile_template_category ptc
                            ON ptc.id_profile_template = pt.id_profile_template
                         WHERE pt.id_software = s.id_software)
                 ORDER BY desc_software;
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
                                              'GET_SOFTWARE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_software_list;

    PROCEDURE insert_version
    (
        i_id_version        IN version.id_version%TYPE,
        i_desc_version      IN version.desc_version%TYPE,
        i_dt_release        IN version.dt_release%TYPE,
        i_id_version_parent IN version.id_version%TYPE
    ) IS
    
    BEGIN
    
        g_error := 'INSERTING VERSION';
        INSERT INTO version
            (id_version, desc_version, dt_release)
        VALUES
            (i_id_version, i_desc_version, i_dt_release);
    
        g_error := 'INSERTING FIX';
        IF i_id_version_parent IS NOT NULL
        THEN
            INSERT INTO fix
                (id_version, id_fix)
            VALUES
                (i_id_version_parent, i_id_version);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR INSERTING ' || i_id_version;
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => 'INSERT_VERSION');
            RAISE;
    END insert_version;

    PROCEDURE insert_rn_prof_temp_market
    (
        i_id_release_note IN release_note.id_release_note%TYPE,
        i_cat             IN table_number,
        i_soft            IN table_number,
        i_market          IN table_number
    ) IS
    
        l_coll_cat    table_number := table_number();
        l_coll_market table_number := table_number();
        l_coll_soft   table_number := table_number();
        l_all_cat     BOOLEAN;
        l_all_market  BOOLEAN;
        l_all_soft    BOOLEAN;
    
        FUNCTION test_all
        (
            coll      IN table_number,
            all_value IN NUMBER
        ) RETURN BOOLEAN IS
            l_indice NUMBER;
        BEGIN
            l_indice := pk_utils.search_table_number(coll, all_value);
        
            IF l_indice > -1
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END;
    
    BEGIN
    
        SELECT rc1.id_category
          BULK COLLECT
          INTO l_coll_cat
          FROM release_note_jira_category rc1
         WHERE rc1.id_jira_category IN (SELECT /*+ opt_estimate( t rows=1) */
                                         column_value
                                          FROM TABLE(i_cat) t);
    
        SELECT rm1.id_market
          BULK COLLECT
          INTO l_coll_market
          FROM release_note_jira_market rm1
         WHERE rm1.id_jira_market IN (SELECT /*+ opt_estimate( t rows=1) */
                                       column_value
                                        FROM TABLE(i_market) t);
    
        SELECT rs1.id_software
          BULK COLLECT
          INTO l_coll_soft
          FROM release_note_jira_software rs1
         WHERE rs1.id_jira_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                         column_value
                                          FROM TABLE(i_soft) t);
    
        IF test_all(l_coll_cat, -1)
        THEN
            l_all_cat := TRUE;
        
            SELECT id_category
              BULK COLLECT
              INTO l_coll_cat
              FROM category;
        END IF;
    
        IF test_all(l_coll_market, 0)
        THEN
            l_all_market := TRUE;
        
            SELECT id_market
              BULK COLLECT
              INTO l_coll_market
              FROM market;
        ELSE
            l_coll_market.extend;
            l_coll_market(l_coll_market.count) := 0;
        END IF;
    
        IF test_all(l_coll_soft, 0)
        THEN
            l_all_soft := TRUE;
        
            SELECT id_software
              BULK COLLECT
              INTO l_coll_soft
              FROM software
             WHERE flg_viewer = 'N';
        END IF;
    
        IF l_all_cat
           AND l_all_market
           AND l_all_soft
        THEN
            INSERT INTO release_note_prof_temp_market
                (id_release_note, id_profile_template_market)
            VALUES
                (i_id_release_note, 1);
        ELSE
            INSERT INTO release_note_prof_temp_market
                (id_release_note, id_profile_template_market)
                SELECT i_id_release_note id_release_note, ptm.id_profile_template_market id_profile_template_market
                  FROM profile_template_market ptm
                 WHERE ptm.id_profile_template IN
                       (SELECT DISTINCT ptc.id_profile_template
                          FROM profile_template pt
                          JOIN profile_template_category ptc
                            ON ptc.id_profile_template = pt.id_profile_template
                          JOIN category c
                            ON c.id_category = ptc.id_category
                         WHERE c.id_category IN (SELECT /*+ opt_estimate( t rows=1) */
                                                  column_value
                                                   FROM TABLE(l_coll_cat) t)
                           AND pt.id_software IN (SELECT /*+ opt_estimate( t rows=1) */
                                                   column_value
                                                    FROM TABLE(l_coll_soft) t))
                   AND ptm.id_market IN (SELECT /*+ opt_estimate( t rows=1) */
                                          column_value
                                           FROM TABLE(l_coll_market) t);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END insert_rn_prof_temp_market;

    PROCEDURE insert_release_note
    (
        i_id_fix  IN version.id_version%TYPE,
        i_id_jira IN release_note_fix.id_jira%TYPE,
        i_lang    IN table_number,
        i_summ    IN table_varchar,
        i_desc    IN table_clob,
        i_cat     IN table_number,
        i_soft    IN table_number,
        i_market  IN table_number
    ) IS
    
        l_id_release_note            release_note.id_release_note%TYPE;
        l_id_version                 version.id_version%TYPE;
        l_ins_code_release_note_summ release_note.code_release_note_summ%TYPE;
        l_ins_code_release_note_desc release_note.code_release_note_desc%TYPE;
        rn_exception                 EXCEPTION;
    
    BEGIN
    
        SELECT rn.id_release_note
          INTO l_id_release_note
          FROM release_note_fix rnf
          JOIN release_note rn
            ON rn.id_release_note = rnf.id_release_note
         WHERE rnf.id_jira = i_id_jira;
    
        UPDATE release_note_fix rnf
           SET rnf.id_fix = i_id_fix
         WHERE rnf.id_jira = i_id_jira;
    
        DELETE FROM release_note_prof_temp_market rnptm
         WHERE rnptm.id_release_note = l_id_release_note;
    
        insert_rn_prof_temp_market(l_id_release_note, i_cat, i_soft, i_market);
    
        l_ins_code_release_note_summ := g_code_release_note_summ || l_id_release_note;
        l_ins_code_release_note_desc := g_code_release_note_desc || l_id_release_note;
    
        g_error := 'UPDATING SUMMARY TRANSLATION';
        IF i_lang.count = i_summ.count
        THEN
            FOR i IN i_lang.first .. i_lang.last
            LOOP
                pk_translation.insert_into_translation(i_lang(i), l_ins_code_release_note_summ, i_summ(i));
            END LOOP;
        ELSE
            RAISE rn_exception;
        END IF;
    
        g_error := 'UPDATING DESC TRANSLATION_LOB';
        IF i_lang.count = i_desc.count
        THEN
            FOR i IN i_lang.first .. i_lang.last
            LOOP
                pk_translation_lob.insert_into_translation(i_lang(i), l_ins_code_release_note_desc, i_desc(i));
            END LOOP;
        ELSE
            RAISE rn_exception;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
        
            g_error := 'INSERTING RELEASE NOTE';
            SELECT seq_release_note.nextval
              INTO l_id_release_note
              FROM dual;
        
            l_ins_code_release_note_summ := g_code_release_note_summ || l_id_release_note;
            l_ins_code_release_note_desc := g_code_release_note_desc || l_id_release_note;
        
            g_error := 'INSERTING RELEASE NOTE';
            INSERT INTO release_note
                (id_release_note, code_release_note_summ, code_release_note_desc)
            VALUES
                (l_id_release_note, l_ins_code_release_note_summ, l_ins_code_release_note_desc);
        
            g_error := 'INSERTING RELEASE_NOTE_PROF_TEMP_MARKET';
            insert_rn_prof_temp_market(l_id_release_note, i_cat, i_soft, i_market);
        
            g_error := 'INSERTING SUMMARY TRANSLATION';
            IF i_lang.count = i_summ.count
            THEN
                FOR i IN i_lang.first .. i_lang.last
                LOOP
                    pk_translation.insert_into_translation(i_lang(i), l_ins_code_release_note_summ, i_summ(i));
                END LOOP;
            ELSE
                RAISE rn_exception;
            END IF;
        
            g_error := 'INSERTING DESC TRANSLATION_LOB';
            IF i_lang.count = i_desc.count
            THEN
                FOR i IN i_lang.first .. i_lang.last
                LOOP
                    pk_translation_lob.insert_into_translation(i_lang(i), l_ins_code_release_note_desc, i_desc(i));
                END LOOP;
            ELSE
                RAISE rn_exception;
            END IF;
        
            g_error := 'INSERTING RELEASE NOTE FIX';
            SELECT v.id_version
              INTO l_id_version
              FROM version v
              JOIN fix f
                ON v.id_version = f.id_version
               AND f.id_fix = i_id_fix;
        
            INSERT INTO release_note_fix
                (id_release_note, id_version, id_fix, id_jira)
            VALUES
                (l_id_release_note, l_id_version, i_id_fix, i_id_jira);
        
        WHEN OTHERS THEN
            g_error := 'ERROR INSERTING ' || i_id_jira;
            pk_alertlog.log_error(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => 'INSERT_RELEASE_NOTE');
            RAISE;
    END insert_release_note;

    PROCEDURE delete_release_note(i_id_jira IN release_note_fix.id_jira%TYPE) IS
    
        l_id_rn release_note.id_release_note%TYPE;
    
        rn_exception EXCEPTION;
    
    BEGIN
        g_error := 'Start delete - ' || i_id_jira;
    
        DELETE FROM release_note_fix rnf
         WHERE rnf.id_jira = i_id_jira
        RETURNING rnf.id_release_note INTO l_id_rn;
    
        g_error := 'delete (id_release_note ' || l_id_rn || ') from release_note_fix :' || SQL%ROWCOUNT;
    
        IF l_id_rn IS NOT NULL
        THEN
            DELETE FROM release_note_prof_temp_market rnp
             WHERE rnp.id_release_note = l_id_rn;
        
            g_error := 'delete from release_note_prof_temp_market :' || SQL%ROWCOUNT;
        
            DELETE FROM release_note rn
             WHERE rn.id_release_note = l_id_rn;
        
            g_error := 'delete from release_note :' || SQL%ROWCOUNT;
        
            pk_translation.delete_code_translation(i_code => table_varchar('RELEASE_NOTE.CODE_RELEASE_NOTE_SUMM.' ||
                                                                           l_id_rn));
        
            g_error := 'delete from translation :' || SQL%ROWCOUNT;
        
            DELETE FROM translation_lob t
             WHERE t.code_translation = 'RELEASE_NOTE.CODE_RELEASE_NOTE_DESC.' || l_id_rn;
        
            g_error := 'delete from translation_lob :' || SQL%ROWCOUNT;
        
        ELSE
            pk_alertlog.log_warn('Unknown release note identifier for ' || i_id_jira,
                                 g_package_name,
                                 'DELETE_RELEASE_NOTE');
            pk_utils.undo_changes;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR DELETING ' || i_id_jira;
            pk_alertlog.log_error(text            => g_error,
                                  object_name     => g_package_name,
                                  sub_object_name => 'DELETE_RELEASE_NOTE');
            RAISE;
    END delete_release_note;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_release_notes;
/
