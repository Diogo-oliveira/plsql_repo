-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit

DECLARE

    l_id_doc_area epis_documentation.id_doc_area%TYPE := 6746;

    CURSOR c_get_records IS
        SELECT epn.id_epis_pn,
               decode(epn.flg_status, 'C', 'Y', 'N') flg_status_note,
               decode(ed.flg_status, 'A', 'N', 'Y') flg_status_doc,
               epn.id_prof_cancel,
               ed.id_epis_documentation,
               ed.id_professional,
               nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz) dt_documentation,
               ed.id_episode,
               ed.notes_cancel,
               ed.id_cancel_reason,
               ed.dt_cancel_tstz,
               il.id_language,
               ei.id_software,
               e.id_institution,
               ei.id_dep_clin_serv,
               pk_translation.get_translation(il.id_language, dt.code_doc_template) template_desc
          FROM epis_documentation ed
         INNER JOIN episode e
            ON ed.id_episode = e.id_episode
           AND e.id_epis_type = 5
          LEFT JOIN doc_template dt
            ON ed.id_doc_template = dt.id_doc_template
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
         INNER JOIN institution_language il
            ON i.id_institution = il.id_institution
          LEFT OUTER JOIN epis_pn_det_task epdt
            ON ed.id_epis_documentation = epdt.id_task
           AND epdt.id_task_type = 36
          LEFT OUTER JOIN epis_pn_det epd
            ON epdt.id_epis_pn_det = epd.id_epis_pn_det
           AND epd.id_pn_data_block = 83
           AND epd.id_pn_soap_block = 16
          LEFT OUTER JOIN epis_pn epn
            ON epd.id_epis_pn = epn.id_epis_pn
						and epn.id_pn_note_type = 5
         WHERE ed.id_doc_area = l_id_doc_area
           AND i.id_market <> 2
           AND ed.flg_status = 'A';

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records   c_cursor_type;
    l_limit         PLS_INTEGER := 1000;
    l_records_count PLS_INTEGER;

    l_id_epis_pn          epis_pn.id_epis_pn%TYPE;
    l_date                VARCHAR2(1000 CHAR);
    l_id_institution      institution.id_institution%TYPE;
    l_id_software         software.id_software%TYPE;
    l_id_language         language.id_language%TYPE;
    l_prof                profissional;
    l_id_profile_template profile_template.id_profile_template%TYPE;
    l_error               t_error_out;

    l_cur_data           pk_types.cursor_type;
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

    l_id_pn_soap_block pn_soap_block.id_pn_soap_block%TYPE := 16;
    l_id_pn_data_block pn_data_block.id_pn_data_block%TYPE := 83;

    l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;

BEGIN
    OPEN c_get_records;
    LOOP
    
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        l_records_count := l_get_records.count;
        FOR i IN 1 .. l_records_count
        LOOP
        
            l_id_institution      := l_get_records(i).id_institution;
            l_id_software         := l_get_records(i).id_software;
            l_id_language         := l_get_records(i).id_language;
            l_prof                := profissional(l_get_records(i).id_professional, l_id_institution, l_id_software);
            l_id_profile_template := pk_prof_utils.get_prof_profile_template(l_prof);
        
            IF l_get_records(i).id_epis_pn IS NULL
            THEN
            
                l_date      := pk_date_utils.dt_chr_date_hour_tsz(i_lang => l_id_language,
                                                                  i_date => l_get_records(i).dt_documentation,
                                                                  i_prof => l_prof);
                l_msg_notes := pk_message.get_message(i_lang => l_id_language, i_code_mess => 'DOCUMENTATION_T010');
                l_form      := pk_message.get_message(i_lang => l_id_language, i_code_mess => 'DOCUMENTATION_M040');
            
                l_doc_area_name := l_get_records(i).template_desc;
                IF l_doc_area_name IS NULL
                THEN
                    SELECT pk_translation.get_translation(l_id_language, sps.code_summary_page_section)
                      INTO l_doc_area_name
                      FROM summary_page_section sps
                     WHERE sps.id_doc_area = l_id_doc_area
                       AND sps.id_summary_page = 42;
                END IF;
            
                IF NOT
                    pk_summary_page.get_summ_last_doc_area(i_lang               => l_id_language,
                                                           i_prof               => l_prof,
                                                           i_epis_documentation => l_get_records(i).id_epis_documentation,
                                                           i_doc_area           => l_id_doc_area,
                                                           o_documentation      => l_cur_data,
                                                           o_error              => l_error)
                THEN
                    raise_application_error(-20001,
                                            'ERROR: pk_summary_page.get_summ_last_doc_area for id_epis_documentation: ' || l_get_records(i)
                                            .id_epis_documentation || chr(13) || ' l_id_doc_area: ' || l_id_doc_area ||
                                             chr(13) || chr(13) || l_error.log_id || ' -> ' || l_error.err_desc);
                ELSE
                    l_note := NULL;
                    LOOP
                    
                        FETCH l_cur_data
                            INTO l_id_doc_component,
                                 l_id_epis_documentation,
                                 l_desc_doc_component,
                                 l_desc_element,
                                 l_desc_info;
                        IF NOT l_cur_data%FOUND
                        THEN
                            EXIT;
                        END IF;
                    
                        IF l_desc_doc_component IS NULL
                        THEN
                            l_desc_doc_component := l_msg_notes || l_2_points;
                        END IF;
                    
                        IF l_note IS NULL
                        THEN
                            l_note := l_form || ': ' || l_doc_area_name;
                        END IF;
                        l_note := l_note || chr(13) || l_desc_doc_component || l_desc_element;
                    
                    END LOOP;
                    IF l_note IS NOT NULL
                    THEN
                        IF NOT
                            pk_prog_notes_core.set_save_def_note(i_lang                => l_id_language,
                                                                 i_prof                => l_prof,
                                                                 i_epis_pn             => NULL,
                                                                 i_id_dictation_report => NULL,
                                                                 i_id_episode          => l_get_records(i).id_episode,
                                                                 i_pn_flg_status       => 'M',
                                                                 i_id_pn_note_type     => 5,
                                                                 i_dt_pn_date          => l_get_records(i).dt_documentation,
                                                                 i_id_dep_clin_serv    => l_get_records(i).id_dep_clin_serv,
                                                                 i_id_pn_data_block    => table_number(l_id_pn_data_block,
                                                                                                       47),
                                                                 i_id_pn_soap_block    => table_number(l_id_pn_soap_block,
                                                                                                       6),
                                                                 i_id_task             => table_number(l_get_records(i)
                                                                                                       .id_epis_documentation,
                                                                                                       NULL),
                                                                 i_id_task_type        => table_number(36, NULL),
                                                                 i_pn_note             => table_clob(l_note, l_date),
                                                                 i_id_professional     => l_prof.id,
                                                                 i_dt_create           => l_get_records(i).dt_documentation,
                                                                 i_dt_last_update      => l_get_records(i).dt_documentation,
                                                                 i_dt_sent_to_hist     => l_get_records(i).dt_documentation,
                                                                 i_id_prof_sign_off    => l_prof.id,
                                                                 i_dt_sign_off         => l_get_records(i).dt_documentation,
                                                                 o_id_epis_pn          => l_id_epis_pn,
                                                                 o_error               => l_error)
                        THEN
                            raise_application_error(-20001,
                                                    'ERROR: pk_prog_notes_core.set_save_def_note for id_episode: ' || l_get_records(i)
                                                    .id_episode || ' dt_epis_anamnesis_tstz: ' || l_get_records(i)
                                                    .dt_documentation || chr(13) || ' l_id_language: ' || l_id_language ||
                                                     chr(13) || ' l_note: ' || l_note || ' l_prof: ' || l_prof.id || ',' ||
                                                     l_prof.institution || ', ' || l_prof.software || chr(13) || chr(13) ||
                                                     l_error.log_id || ' -> ' || l_error.err_desc);
                        END IF;
                    END IF;
                
                END IF;
            END IF;
        
        END LOOP;
    
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/

-- CHANGE END: ANTONIO.NETO