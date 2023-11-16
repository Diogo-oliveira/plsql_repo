-- CHANGED BY: António Neto
-- CHANGE DATE: 25/02/2011 17:38
-- CHANGE REASON: [ALERT-164712] DDL Migrations - H & P reformulation in INPATIENT

DECLARE
    TYPE tab_critical_care_read IS TABLE OF critical_care_read%ROWTYPE;

    l_tab_critical_care_read  tab_critical_care_read;
    l_first_patient_condition BOOLEAN;
    l_critical_care_str       CLOB := empty_clob;
    l_desc_critical_care      pk_translation.t_desc_translation;
    l_append_point            BOOLEAN := TRUE;
    l_lang                    language.id_language%TYPE := 2;
    l_id_software             software.id_software%TYPE := 11;

    l_tab_pn_soap_block table_number := table_number();
    l_tab_pn_area_block table_number := table_number();
    l_tab_notes         table_clob := table_clob();

    l_id_pn_soap_block    pn_soap_block.id_pn_soap_block%TYPE := 16;
    l_id_pn_data_block    pn_data_block.id_pn_data_block%TYPE := 83;
    l_date                VARCHAR2(1000 CHAR);
    l_id_institution      episode.id_institution%TYPE;
    l_dep_clin_serv       epis_info.id_dep_clin_serv%TYPE;
    l_id_epis_pn          epis_pn.id_epis_pn%TYPE;
    l_error               t_error_out;
    l_table_number_empty  table_number := table_number();
    l_table_varchar_empty table_varchar := table_varchar();
    l_table_table_number  table_table_number := table_table_number();
    l_epis_documentation  epis_documentation.id_epis_documentation%TYPE;
    l_error_msg           VARCHAR2(4000);

BEGIN
    SELECT ch.* BULK COLLECT
      INTO l_tab_critical_care_read
      FROM critical_care_read ch
     ORDER BY ch.id_critical_care_read;

    IF (l_tab_critical_care_read.exists(1))
    THEN
        FOR i IN 1 .. l_tab_critical_care_read.count
        LOOP
        
            SELECT e.id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = l_tab_critical_care_read(i).id_episode;
        
            --get institution language
            BEGIN
                SELECT il.id_language
                  INTO l_lang
                  FROM institution_language il
                 WHERE il.id_institution = l_id_institution;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
            --dbms_output.put_line('start id_critical_care_read: ' || l_tab_critical_care_read(i).id_critical_care_read);
            -- CONSTRUCT THE NOTE TEXT
            l_first_patient_condition := TRUE;
            FOR recdet IN (SELECT ccd.*
                             FROM critical_care_det ccd
                             JOIN critical_care cc
                               ON cc.id_critical_care = ccd.id_critical_care
                            WHERE ccd.id_critical_care_read = l_tab_critical_care_read(i).id_critical_care_read
                            ORDER BY cc.id_critical_care)
            LOOP
                --patient condition
                IF (recdet.id_critical_care IN (1, 2, 3, 4))
                THEN
                    --in the 1st record get title
                    IF (l_first_patient_condition = TRUE)
                    THEN
                        l_critical_care_str := pk_message.get_message(l_lang, 'CRITICAL_CARE_N_M001') || ' ';
                    END IF;
                
                    SELECT pk_translation.get_translation(l_lang, cc.code_critical_care) desc_critical_care
                      INTO l_desc_critical_care
                      FROM critical_care cc
                     WHERE cc.id_critical_care = recdet.id_critical_care;
                
                    l_critical_care_str := l_critical_care_str || CASE
                                               WHEN l_first_patient_condition = FALSE THEN
                                                '; '
                                           END || CASE
                                               WHEN recdet.id_critical_care = 4 THEN
                                                recdet.value
                                               ELSE
                                                l_desc_critical_care
                                           END;
                
                    l_first_patient_condition := FALSE;
                
                ELSE
                    IF (l_critical_care_str IS NOT NULL)
                    THEN
                        l_critical_care_str := l_critical_care_str || '.';
                    END IF;
                
                    IF (recdet.id_critical_care = 5)
                    THEN
                        SELECT pk_translation.get_translation(l_lang, cc.code_critical_care) desc_critical_care
                          INTO l_desc_critical_care
                          FROM critical_care cc
                         WHERE cc.id_critical_care = recdet.id_critical_care;
                    
                        --remove the final point if it exists in the current language translation
                        IF (substr(l_desc_critical_care, length(l_desc_critical_care), 1) = '.')
                        THEN
                            l_desc_critical_care := substr(l_desc_critical_care, 0, length(l_desc_critical_care) - 1);
                        END IF;
                    
                        l_critical_care_str := l_critical_care_str || chr(10) || l_desc_critical_care || ': ' ||
                                               recdet.value;
                    END IF;
                
                    IF (recdet.id_critical_care = 6)
                    THEN
                        IF (l_append_point = TRUE)
                        THEN
                            l_critical_care_str := l_critical_care_str || '.';
                            l_append_point      := TRUE;
                        END IF;
                    
                        SELECT pk_translation.get_translation(l_lang, cc.code_critical_care) desc_critical_care
                          INTO l_desc_critical_care
                          FROM critical_care cc
                         WHERE cc.id_critical_care = recdet.id_critical_care;
                    
                        l_critical_care_str := l_critical_care_str || chr(10) ||
                                               REPLACE(l_desc_critical_care,
                                                       '@1',
                                                       pk_medical_decision.get_ccare_hour_min(i_lang  => l_lang,
                                                                                              i_value => recdet.value));
                        l_append_point      := FALSE;
                    END IF;
                
                END IF;
            
            END LOOP;
        
            IF (l_append_point = TRUE)
            THEN
                l_critical_care_str := l_critical_care_str || '.';
                l_append_point      := FALSE;
            END IF;
        
            IF (l_tab_critical_care_read(i).notes IS NOT NULL)
            THEN
                IF (l_append_point = TRUE)
                THEN
                    l_critical_care_str := l_critical_care_str || '.';
                END IF;
                l_critical_care_str := l_critical_care_str || chr(10) ||
                                       pk_message.get_message(i_lang => l_lang, i_code_mess => 'CRITICAL_CARE_N_T002') || ': ' || l_tab_critical_care_read(i)
                                      .notes;
            END IF;
        
            /*dbms_output.put_line(l_critical_care_str);
            dbms_output.put_line('');*/
        
            --call pk_touch_option.set_epis_document_internal
            IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => l_lang,
                                                              i_prof                  => profissional(l_tab_critical_care_read(i)
                                                                                                      .id_professional,
                                                                                                      l_id_institution,
                                                                                                      l_id_software),
                                                              i_prof_cat_type         => pk_prof_utils.get_category(i_lang => l_lang,
                                                                                                                    i_prof => profissional(l_tab_critical_care_read(i)
                                                                                                                                           .id_professional,
                                                                                                                                           l_id_institution,
                                                                                                                                           l_id_software)),
                                                              i_epis                  => l_tab_critical_care_read(i)
                                                                                         .id_episode,
                                                              i_doc_area              => 6746,
                                                              i_doc_template          => 501938,
                                                              i_epis_documentation    => NULL,
                                                              i_flg_type              => 'N',
                                                              i_id_documentation      => l_table_number_empty,
                                                              i_id_doc_element        => l_table_number_empty,
                                                              i_id_doc_element_crit   => l_table_number_empty,
                                                              i_value                 => l_table_varchar_empty,
                                                              i_notes                 => l_critical_care_str,
                                                              i_id_epis_complaint     => NULL,
                                                              i_id_doc_element_qualif => l_table_table_number,
                                                              i_epis_context          => NULL,
                                                              i_dt_creation           => l_tab_critical_care_read(i)
                                                                                         .dt_creation_tstz,
                                                              i_flg_status            => 'A',
                                                              o_epis_documentation    => l_epis_documentation,
                                                              o_error                 => l_error)
            THEN
                l_error_msg := 'ERROR creating template. id_episode: ' || l_tab_critical_care_read(i).id_episode ||
                               ' text: ' || l_critical_care_str || ' id_critical_care_read: ' || l_tab_critical_care_read(i)
                              .id_critical_care_read;
                dbms_output.put_line(l_error_msg);
                pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_CRITICAL_CARE_NOTES');
            END IF;
        
            --- CREATE PROGRESS NOTE
            l_tab_pn_soap_block := table_number();
            l_tab_pn_area_block := table_number();
            l_tab_notes         := table_clob();
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => l_lang,
                                                         i_date => l_tab_critical_care_read(i).dt_creation_tstz,
                                                         i_prof => profissional(l_tab_critical_care_read(i)
                                                                                .id_professional,
                                                                                l_id_institution,
                                                                                l_id_software));
        
            IF (l_date IS NOT NULL)
            THEN
                l_tab_pn_soap_block.extend;
                l_tab_pn_soap_block(1) := 6;
            
                l_tab_pn_area_block.extend;
                l_tab_pn_area_block(1) := 47;
            
                l_tab_notes.extend;
                l_tab_notes(1) := l_date;
            END IF;
        
            l_tab_pn_soap_block.extend;
            l_tab_pn_soap_block(l_tab_pn_soap_block.last) := l_id_pn_soap_block;
        
            l_tab_pn_area_block.extend;
            l_tab_pn_area_block(l_tab_pn_area_block.last) := l_id_pn_data_block;
        
            l_tab_notes.extend;
            l_tab_notes(l_tab_notes.last) := l_critical_care_str;
        
            SELECT e.id_dep_clin_serv
              INTO l_dep_clin_serv
              FROM epis_info e
             WHERE e.id_episode = l_tab_critical_care_read(i).id_episode;
        
            IF NOT
                pk_prog_notes_core.set_save_def_note(i_lang                  => l_lang,
                                                     i_prof                  => NULL,
                                                     i_epis_pn               => NULL,
                                                     i_id_dictation_report   => NULL,
                                                     i_id_episode            => l_tab_critical_care_read(i).id_episode,
                                                     i_pn_flg_status         => 'M',
                                                     i_pn_flg_type           => 'CC',
                                                     i_pn_date               => l_tab_critical_care_read(i)
                                                                                .dt_creation_tstz,
                                                     i_id_dep_clin_serv      => l_dep_clin_serv,
                                                     i_id_pn_data_block      => l_tab_pn_area_block,
                                                     i_id_pn_soap_block      => l_tab_pn_soap_block,
                                                     i_id_epis_documentation => table_number(NULL, l_epis_documentation),
                                                     i_pn_note               => l_tab_notes,
                                                     i_id_professional       => l_tab_critical_care_read(i).id_professional,
                                                     i_dt_last_update        => l_tab_critical_care_read(i)
                                                                                .dt_creation_tstz,
                                                     i_dt_create             => l_tab_critical_care_read(i)
                                                                                .dt_creation_tstz,
                                                     i_dt_sent_to_hist       => NULL,
                                                     i_id_prof_sign_off      => l_tab_critical_care_read(i).id_professional,
                                                     i_dt_sign_off           => l_tab_critical_care_read(i)
                                                                                .dt_creation_tstz,
                                                     o_id_epis_pn            => l_id_epis_pn,
                                                     o_error                 => l_error)
            THEN
                l_error_msg := 'ERROR. id_episode: ' || l_tab_critical_care_read(i).id_episode || ' text: ' ||
                               l_critical_care_str || ' id_critical_care_read: ' || l_tab_critical_care_read(i)
                              .id_critical_care_read;
                dbms_output.put_line(l_error_msg);
                pk_alertlog.log_debug(text => l_error_msg, object_name => 'MIGRATION_CRITICAL_CARE_NOTES');
            END IF;
        
            /*dbms_output.put_line('id_critical_care_read: ' || l_tab_critical_care_read(i).id_critical_care_read ||
                                 '  id_epis_documentation: ' || l_epis_documentation || '  l_id_epis_pn: ' ||
                                 l_id_epis_pn);
            dbms_output.put_line('');*/
        END LOOP;
    END IF;

END;
/

-- CHANGE END: António Neto
