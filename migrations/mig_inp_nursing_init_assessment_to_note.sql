-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 04/11/2013 
-- CHANGE REASON: ALERT-221428 Nurse - Single Page documentation (INP) 

DECLARE

    CURSOR c_get_records IS
        SELECT ed.id_epis_documentation,
               ed.id_professional,
               nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz) dt_documentation,
               ed.id_episode,
               ed.notes_cancel,
               ed.id_cancel_reason,
               ed.dt_cancel_tstz,
               nvl(il.id_language, 2) id_language,
               ei.id_software,
               e.id_institution,
               ei.id_dep_clin_serv,
               pk_translation.get_translation(il.id_language, dt.code_doc_template) template_desc,
               ed.flg_status,
               nvl(ed.dt_cancel_tstz, ed.dt_last_update_tstz) dt_cancel
          FROM epis_documentation ed
         INNER JOIN episode e
            ON ed.id_episode = e.id_episode
          LEFT JOIN doc_template dt
            ON ed.id_doc_template = dt.id_doc_template
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
          LEFT OUTER JOIN institution_language il
            ON i.id_institution = il.id_institution
         WHERE ed.id_doc_area IN (35, 37)
           AND ei.id_software = 11
               
           AND pk_date_utils.dt_chr_date_hour_tsz(i_lang => nvl(il.id_language, 2),
                                                  i_date => nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz),
                                                  i_prof => profissional(ed.id_professional,
                                                                         e.id_institution,
                                                                         ei.id_software)) IS NOT NULL;

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records   c_cursor_type;
    l_limit         PLS_INTEGER := 1000;
    l_records_count PLS_INTEGER;

    l_id_epis_pn     epis_pn.id_epis_pn%TYPE;
    l_date           VARCHAR2(1000 CHAR);
    l_id_institution institution.id_institution%TYPE;
    l_id_software    software.id_software%TYPE;
    l_id_language    language.id_language%TYPE;
    l_prof           profissional;
    l_error          t_error_out;

    l_id_doc_component   doc_component.id_doc_component%TYPE;
    l_desc_doc_component VARCHAR2(4000);
    l_desc_element       VARCHAR2(4000);
    l_desc_info          VARCHAR2(4000);
    l_note               CLOB;

    l_msg_notes     VARCHAR2(4000);
    l_form          VARCHAR2(4000);
    l_doc_area_name VARCHAR2(4000);
    l_2_points      VARCHAR2(2 CHAR) := ': ';

    l_cancel_msg VARCHAR2(4000);

    l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;

    l_id_epis_pn_det      epis_pn_det.id_epis_pn_det%TYPE;
    l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
    l_id_epis_pn_signoff  epis_pn_signoff.id_epis_pn_signoff%TYPE;
    l_desc                CLOB;
    l_flg_status          epis_pn.flg_status%TYPE;

    PROCEDURE get_plain_text_entries
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_documentation_list IN table_number,
        o_desc                    OUT CLOB
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_plain_text_entries';
    BEGIN
    
        SELECT CASE
                    WHEN template_title IS NOT NULL THEN
                     template_title || chr(10) || plain_text_entry
                    ELSE
                     plain_text_entry
                END plain_text_entry
          INTO o_desc
          FROM (
               -- Documentation entries
               WITH ed_entries AS (SELECT /*+ materialize */
                                    ed.id_epis_documentation,
                                    ed.dt_creation_tstz,
                                    ed.flg_status,
                                    ed.id_doc_area,
                                    ed.id_doc_template,
                                    ed.notes
                                     FROM epis_documentation ed
                                    WHERE ed.id_epis_documentation IN
                                          (SELECT /*+ opt_estimate(table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(i_epis_documentation_list) t)),
               
               -- Free-text entries
               ed_free_text AS (SELECT /*+ materialize */
                                 e.id_epis_documentation, e.dt_creation_tstz, e.notes
                                  FROM ed_entries e
                                 WHERE e.id_doc_template IS NULL
                                   AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
               
               -- Additional Notes for template entries
               ed_additional_notes AS (SELECT /*+ materialize */
                                        e.id_epis_documentation, e.notes
                                         FROM ed_entries e
                                        WHERE e.id_doc_template IS NOT NULL
                                          AND coalesce(dbms_lob.getlength(e.notes), 0) > 0),
               
               -- Lines of documentation entries (components)
               edd_lines AS (SELECT /*+ materialize */
                             DISTINCT edd.id_epis_documentation,
                                      edd.id_documentation,
                                      dtad.rank rank_component,
                                      dc.code_doc_component,
                                      d.id_documentation_parent,
                                      ed.id_doc_template,
                                      ed.id_doc_area
                               FROM epis_documentation ed
                              INNER JOIN epis_documentation_det edd
                                 ON ed.id_epis_documentation = edd.id_epis_documentation
                              INNER JOIN documentation d
                                 ON d.id_documentation = edd.id_documentation
                              INNER JOIN doc_component dc
                                 ON dc.id_doc_component = d.id_doc_component
                              INNER JOIN doc_template_area_doc dtad
                                 ON dtad.id_doc_template = ed.id_doc_template
                                AND dtad.id_doc_area = ed.id_doc_area
                                AND dtad.id_documentation = edd.id_documentation
                              WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                                   FROM ed_entries t)),
               
               -- Lines of titles (Components of type "Title")
               edd_titles AS (SELECT /*+ materialize */
                               t.id_epis_documentation,
                               d.id_documentation,
                               dc.code_doc_component,
                               dtad.rank rank_component
                                FROM (SELECT DISTINCT l.id_epis_documentation,
                                                      l.id_documentation_parent,
                                                      l.id_doc_area,
                                                      l.id_doc_template
                                        FROM edd_lines l
                                       WHERE l.id_documentation_parent IS NOT NULL) t
                               INNER JOIN documentation d
                                  ON d.id_documentation = t.id_documentation_parent
                               INNER JOIN doc_component dc
                                  ON dc.id_doc_component = d.id_doc_component
                               INNER JOIN doc_template_area_doc dtad
                                  ON dtad.id_doc_template = t.id_doc_template
                                 AND dtad.id_doc_area = t.id_doc_area
                                 AND dtad.id_documentation = t.id_documentation_parent
                               WHERE dc.flg_type = 'T'
                                 AND dc.flg_available = 'Y'
                                 AND d.flg_available = 'Y'),
               
               -- Documented elements 
               edd_elements AS (SELECT /*+ materialize */
                                 ed.id_epis_documentation,
                                 d.id_documentation,
                                 d.id_documentation_parent,
                                 dc.id_doc_component,
                                 dc.code_doc_component,
                                 de.id_doc_element,
                                 pk_touch_option.get_epis_formatted_element(i_lang, i_prof, edd.id_epis_documentation_det) desc_element,
                                 de.separator,
                                 dtad.rank rank_component,
                                 de.rank rank_element
                                  FROM epis_documentation ed
                                 INNER JOIN epis_documentation_det edd
                                    ON ed.id_epis_documentation = edd.id_epis_documentation
                                 INNER JOIN documentation d
                                    ON d.id_documentation = edd.id_documentation
                                 INNER JOIN doc_template_area_doc dtad
                                    ON dtad.id_doc_template = ed.id_doc_template
                                   AND dtad.id_doc_area = ed.id_doc_area
                                   AND dtad.id_documentation = edd.id_documentation
                                 INNER JOIN doc_component dc
                                    ON dc.id_doc_component = d.id_doc_component
                                 INNER JOIN doc_element_crit decr
                                    ON decr.id_doc_element_crit = edd.id_doc_element_crit
                                 INNER JOIN doc_element de
                                    ON de.id_doc_element = edd.id_doc_element
                                 WHERE ed.id_epis_documentation IN (SELECT t.id_epis_documentation
                                                                      FROM ed_entries t)),
               -- Formated Touch-option template entries in plain text (titles + components: elements + additional notes)
               full_entries_as_text AS (SELECT /*+ materialize */
                                         x.id_epis_documentation,
                                         x.id_documentation,
                                         
                                         pk_translation.get_translation(i_lang, x.code_doc_component) desc_component,
                                         pk_string_utils.concat_element_list(CAST(MULTISET
                                                                                  (SELECT e.desc_element,
                                                                                          CASE
                                                                                               WHEN e.separator IS NULL THEN
                                                                                                '; '
                                                                                               WHEN e.separator = '[NONE]' THEN
                                                                                                NULL
                                                                                               ELSE
                                                                                                e.separator
                                                                                           END delimiter
                                                                                     FROM edd_elements e
                                                                                    WHERE e.id_epis_documentation =
                                                                                          x.id_epis_documentation
                                                                                      AND e.id_documentation =
                                                                                          x.id_documentation
                                                                                    ORDER BY e.rank_element) AS
                                                                                  t_coll_text_delimiter_tuple)) desc_element_list,
                                         x.rank_component
                                          FROM edd_lines x
                                        -- Titles  
                                        UNION ALL
                                        SELECT t.id_epis_documentation,
                                               t.id_documentation,
                                               chr(10) ||
                                               
                                               pk_translation.get_translation(i_lang, t.code_doc_component) desc_component,
                                               NULL desc_element_list,
                                               t.rank_component
                                          FROM edd_titles t
                                        
                                        UNION ALL
                                        -- Additional Notes
                                        SELECT an.id_epis_documentation,
                                               NULL id_documentation,
                                               chr(10) ||
                                               
                                               pk_message.get_message(i_lang, i_prof, 'DOCUMENTATION_T010') desc_component,
                                               
                                               to_char(an.notes) desc_element_list,
                                               
                                               1000 rank_component
                                          FROM ed_additional_notes an
                                         ORDER BY id_epis_documentation, rank_component)
               
               -- Main query:
               -- Touch-option entries
                   SELECT tot.id_epis_documentation,
                          e.dt_creation_tstz,
                          pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || e.id_doc_template) template_title,
                          tot.plain_text_entry
                     FROM (SELECT x.id_epis_documentation,
                                  TRIM(leading chr(10) FROM
                                       pk_utils.concat_table_l(CAST(MULTISET
                                                                    (SELECT pk_string_utils.concat_if_exists(f.desc_component,
                                                                                                              CASE
                                                                                                              -- Punctuation character at end of line
                                                                                                                  WHEN f.desc_element_list IS NULL THEN
                                                                                                                   NULL
                                                                                                                  WHEN instr('!,.:;?',
                                                                                                                             substr(f.desc_element_list, -1)) = 0 THEN
                                                                                                                   f.desc_element_list || '.'
                                                                                                                  ELSE
                                                                                                                   f.desc_element_list
                                                                                                              END,
                                                                                                              ': ')
                                                                       FROM full_entries_as_text f
                                                                      WHERE f.id_epis_documentation =
                                                                            x.id_epis_documentation
                                                                      ORDER BY id_epis_documentation, rank_component) AS
                                                                    table_varchar),
                                                               chr(10))) plain_text_entry
                             FROM full_entries_as_text x
                            GROUP BY x.id_epis_documentation) tot
                    INNER JOIN ed_entries e
                       ON e.id_epis_documentation = tot.id_epis_documentation
                   UNION ALL
                   -- Free-text entries
                   SELECT ft.id_epis_documentation,
                          ft.dt_creation_tstz,
                          NULL template_title,
                          
                          ft.notes plain_text_entry
                     FROM ed_free_text ft
                    ORDER BY dt_creation_tstz DESC);
    
    
    EXCEPTION
        WHEN OTHERS THEN
            o_desc := ' ';
        
    END get_plain_text_entries;

    FUNCTION cancel_progress_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN NUMBER,
        i_cancel_reason IN NUMBER,
        i_notes_cancel  IN VARCHAR2,
        i_dt_cancel     IN epis_pn_hist.dt_cancel%TYPE DEFAULT current_timestamp
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR rec IN (SELECT eso.id_epis_pn_signoff,
                           eso.id_epis_pn,
                           eso.id_pn_soap_block,
                           eso.pn_signoff_note,
                           eso.id_prof_last_update,
                           eso.dt_last_update
                      FROM epis_pn_signoff eso
                     WHERE eso.id_epis_pn = i_epis_pn)
        LOOP
        
            INSERT INTO epis_pn_signoff_hist
                (id_epis_pn_signoff,
                 dt_epis_pn_signoff_hist,
                 id_epis_pn,
                 id_pn_soap_block,
                 pn_signoff_note,
                 id_prof_last_update,
                 dt_last_update)
            VALUES
                (rec.id_epis_pn_signoff,
                 i_dt_cancel,
                 rec.id_epis_pn,
                 rec.id_pn_soap_block,
                 rec.pn_signoff_note,
                 rec.id_prof_last_update,
                 rec.dt_last_update);
        
        END LOOP;
    
        FOR rec IN (SELECT ep.id_epis_pn,
                           ep.id_episode,
                           ep.flg_status,
                           ep.dt_pn_date,
                           ep.id_prof_create,
                           ep.dt_create,
                           ep.id_dep_clin_serv,
                           ep.id_prof_last_update,
                           ep.dt_last_update,
                           ep.dt_signoff,
                           ep.id_prof_signoff,
                           ep.id_prof_cancel,
                           ep.dt_cancel,
                           ep.id_cancel_reason,
                           ep.notes_cancel,
                           ep.id_dictation_report,
                           ep.id_pn_note_type,
                           ep.id_pn_area,
                           ep.flg_auto_saved,
                           ep.id_software
                      FROM epis_pn ep
                     WHERE ep.id_epis_pn = i_epis_pn)
        LOOP
        
            INSERT INTO epis_pn_hist
                (id_epis_pn,
                 dt_epis_pn_hist,
                 id_episode,
                 flg_status,
                 dt_pn_date,
                 id_prof_create,
                 dt_create,
                 dt_last_update,
                 id_prof_last_update,
                 id_prof_cancel,
                 dt_cancel,
                 id_cancel_reason,
                 notes_cancel,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type,
                 id_pn_area,
                 id_software)
            VALUES
                (i_epis_pn,
                 i_dt_cancel,
                 rec.id_episode,
                 rec.flg_status,
                 rec.dt_pn_date,
                 rec.id_prof_create,
                 rec.dt_create,
                 rec.dt_last_update,
                 rec.id_prof_last_update,
                 rec.id_prof_cancel,
                 rec.dt_cancel,
                 rec.id_cancel_reason,
                 rec.notes_cancel,
                 rec.id_dep_clin_serv,
                 rec.id_dictation_report,
                 rec.id_prof_signoff,
                 rec.dt_signoff,
                 rec.id_pn_note_type,
                 rec.id_pn_area,
                 rec.id_software);
        
        END LOOP;
    
        FOR rec IN (SELECT epd.id_epis_pn_det,
                           epd.id_epis_pn,
                           epd.id_professional,
                           epd.dt_pn,
                           epd.id_pn_data_block,
                           epd.id_pn_soap_block,
                           epd.flg_status,
                           epd.pn_note,
                           epd.dt_note
                      FROM epis_pn_det epd
                     WHERE epd.id_epis_pn = i_epis_pn)
        LOOP
        
            INSERT INTO epis_pn_det_hist
                (id_epis_pn_det,
                 dt_epis_pn_det_hist,
                 id_epis_pn,
                 id_professional,
                 dt_pn,
                 id_pn_data_block,
                 id_pn_soap_block,
                 flg_status,
                 pn_note)
            VALUES
                (rec.id_epis_pn_det,
                 i_dt_cancel,
                 rec.id_epis_pn,
                 rec.id_professional,
                 rec.dt_pn,
                 rec.id_pn_data_block,
                 rec.id_pn_soap_block,
                 rec.flg_status,
                 rec.pn_note);
        
        END LOOP;
    
        FOR rec IN (SELECT epdt.id_epis_pn_det_task,
                           epdt.id_epis_pn_det,
                           epdt.id_task,
                           epdt.id_task_type,
                           epdt.flg_status,
                           epdt.pn_note,
                           epdt.dt_last_update,
                           epdt.id_prof_last_update,
                           epdt.flg_table_origin
                      FROM epis_pn_det_task epdt
                      JOIN epis_pn_det epd
                        ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                     WHERE epd.id_epis_pn = i_epis_pn)
        LOOP
            INSERT INTO epis_pn_det_task_hist
                (id_epis_pn_det_task,
                 dt_epis_pn_det_task_hist,
                 id_epis_pn_det,
                 id_task,
                 id_task_type,
                 flg_status,
                 pn_note,
                 dt_last_update,
                 id_prof_last_update,
                 flg_table_origin)
            VALUES
                (rec.id_epis_pn_det_task,
                 i_dt_cancel,
                 rec.id_epis_pn_det,
                 rec.id_task,
                 rec.id_task_type,
                 rec.flg_status,
                 rec.pn_note,
                 rec.dt_last_update,
                 rec.id_prof_last_update,
                 rec.flg_table_origin);
        
        END LOOP;
    
        UPDATE epis_pn epn
           SET epn.flg_status       = 'C',
               epn.id_prof_cancel   = i_prof.id,
               epn.dt_cancel        = i_dt_cancel,
               epn.id_cancel_reason = i_cancel_reason,
               epn.notes_cancel     = i_notes_cancel
         WHERE epn.id_epis_pn = i_epis_pn;
    
        RETURN TRUE;
    
    END cancel_progress_note;

BEGIN
    OPEN c_get_records;
    LOOP
    
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        l_records_count := l_get_records.count;
        FOR i IN 1 .. l_records_count
        LOOP
        
            l_id_institution := l_get_records(i).id_institution;
            l_id_software    := l_get_records(i).id_software;
            l_id_language    := l_get_records(i).id_language;
            l_prof           := profissional(l_get_records(i).id_professional, l_id_institution, l_id_software);
        
            l_id_epis_pn := NULL;
            l_flg_status := NULL;
        
            BEGIN
            
                --check if the record were already inserted in the single page
                BEGIN
                    SELECT epn.id_epis_pn, epn.flg_status
                      INTO l_id_epis_pn, l_flg_status
                      FROM epis_pn_det_task epdt
                      JOIN epis_pn_det epd
                        ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                      JOIN epis_pn epn
                        ON epn.id_epis_pn = epd.id_epis_pn
                     WHERE epn.id_episode = l_get_records(i).id_episode
                       AND epn.flg_status IN ('M', 'C')
                       AND epn.id_pn_note_type = 17
                       AND epd.id_pn_data_block = 167
                       AND epdt.id_task = l_get_records(i).id_epis_documentation
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
                l_date      := pk_date_utils.dt_chr_date_hour_tsz(i_lang => l_id_language,
                                                                  i_date => l_get_records(i).dt_documentation,
                                                                  i_prof => l_prof);
                l_msg_notes := pk_message.get_message(i_lang => l_id_language, i_code_mess => 'DOCUMENTATION_T010');
                l_form      := pk_message.get_message(i_lang => l_id_language, i_code_mess => 'DOCUMENTATION_M040');
            
                get_plain_text_entries(i_lang                    => l_id_language,
                                       i_prof                    => l_prof,
                                       i_epis_documentation_list => table_number(l_get_records(i).id_epis_documentation),
                                       o_desc                    => l_desc);
            
                IF l_desc IS NOT NULL
                THEN
                
                    IF (l_id_epis_pn IS NULL)
                    THEN
                        SELECT seq_epis_pn.nextval
                          INTO l_id_epis_pn
                          FROM dual;
                    
                        IF (l_get_records(i).id_software IS NULL)
                        THEN
                            SELECT etsi.id_software
                              INTO l_get_records(i).id_software
                              FROM episode e
                              JOIN epis_type_soft_inst etsi
                                ON e.id_epis_type = etsi.id_epis_type
                             WHERE e.id_episode = l_get_records(i).id_episode
                               AND rownum = 1;
                        
                        END IF;
                    
                        INSERT INTO epis_pn
                            (id_epis_pn,
                             id_episode,
                             flg_status,
                             dt_pn_date,
                             id_prof_create,
                             dt_create,
                             id_dep_clin_serv,
                             id_dictation_report,
                             id_prof_signoff,
                             dt_signoff,
                             id_pn_note_type,
                             id_pn_area,
                             id_software)
                        VALUES
                            (l_id_epis_pn,
                             l_get_records(i).id_episode,
                             'M',
                             l_get_records(i).dt_documentation,
                             l_prof.id,
                             l_get_records(i).dt_documentation,
                             l_get_records(i).id_dep_clin_serv,
                             NULL,
                             l_prof.id,
                             l_get_records(i).dt_documentation,
                             17,
                             6,
                             l_get_records(i).id_software);
                    
                        SELECT seq_epis_pn_det.nextval
                          INTO l_id_epis_pn_det
                          FROM dual;
                    
                        INSERT INTO epis_pn_det
                            (id_epis_pn_det,
                             id_epis_pn,
                             id_professional,
                             dt_pn,
                             id_pn_data_block,
                             id_pn_soap_block,
                             flg_status,
                             pn_note,
                             dt_note)
                        VALUES
                            (l_id_epis_pn_det,
                             l_id_epis_pn,
                             l_prof.id,
                             l_get_records(i).dt_documentation,
                             167,
                             4,
                             'A',
                             NULL,
                             l_get_records(i).dt_documentation);
                    
                        SELECT seq_epis_pn_det_task.nextval
                          INTO l_id_epis_pn_det_task
                          FROM dual;
                    
                        INSERT INTO epis_pn_det_task
                            (id_epis_pn_det_task,
                             id_epis_pn_det,
                             id_task,
                             id_task_type,
                             flg_status,
                             pn_note,
                             dt_last_update,
                             id_prof_last_update,
                             flg_table_origin)
                        VALUES
                            (l_id_epis_pn_det_task,
                             l_id_epis_pn_det,
                             l_get_records(i).id_epis_documentation,
                             36,
                             'A',
                             l_desc,
                             l_get_records(i).dt_documentation,
                             l_prof.id,
                             'D');
                    
                        SELECT seq_epis_pn_det.nextval
                          INTO l_id_epis_pn_det
                          FROM dual;
                    
                        INSERT INTO epis_pn_det
                            (id_epis_pn_det,
                             id_epis_pn,
                             id_professional,
                             dt_pn,
                             id_pn_data_block,
                             id_pn_soap_block,
                             flg_status,
                             pn_note,
                             dt_note)
                        VALUES
                            (l_id_epis_pn_det,
                             l_id_epis_pn,
                             l_prof.id,
                             l_get_records(i).dt_documentation,
                             47,
                             6,
                             'A',
                             l_date,
                             l_get_records(i).dt_documentation);
                    
                        SELECT seq_epis_pn_signoff.nextval
                          INTO l_id_epis_pn_signoff
                          FROM dual;
                    
                        INSERT INTO epis_pn_signoff
                            (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                        VALUES
                            (l_id_epis_pn_signoff, l_id_epis_pn, 4, l_desc);
                    
                        SELECT seq_epis_pn_signoff.nextval
                          INTO l_id_epis_pn_signoff
                          FROM dual;
                        INSERT INTO epis_pn_signoff
                            (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                        VALUES
                            (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
                    
                    END IF;
                
                END IF;
            
                IF (l_get_records(i).flg_status IN ('O', 'I', 'C') AND (l_flg_status <> 'C' OR l_flg_status IS NULL))
                THEN
                    --cancel the note
                    IF NOT cancel_progress_note(i_lang          => l_id_language,
                                                i_prof          => l_prof,
                                                i_epis_pn       => l_id_epis_pn,
                                                i_cancel_reason => NULL,
                                                i_notes_cancel  => pk_message.get_message(i_lang      => l_id_language,
                                                                                          i_code_mess => 'PN_M022'),
                                                i_dt_cancel     => l_get_records(i).dt_cancel)
                    THEN
                        dbms_output.put_line('cancel_progress_note l_id_epis_pn: ' || l_id_epis_pn || chr(13) ||
                                             SQLERRM);
                    END IF;
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('mig_edis_progress_notes_to_recheck l_id_epis_pn: ' || l_id_epis_pn ||
                                         ' id_epis_documentation: ' || l_get_records(i).id_epis_documentation ||
                                         chr(13) || SQLERRM);
            END;
            COMMIT;
        END LOOP;
    
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('mig_edis_progress_notes_to_recheck l_id_epis_pn: ' || l_id_epis_pn || chr(13) || SQLERRM);
END;
/

-- CHANGE END: Sofia.Mendes
