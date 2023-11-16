-- CHANGED BY: ANTONIO.NETO
-- CHANGE DATE: 20/Mar/2012 
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness / Current visit
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv, il.id_language, ei.id_software id_soft
          FROM epis_anamnesis ea
         INNER JOIN episode e
            ON ea.id_episode = e.id_episode
           AND e.id_epis_type = 5
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
           AND i.id_market <> 2
         INNER JOIN institution_language il
            ON e.id_institution = il.id_institution
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C'
           AND NOT EXISTS (SELECT *
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                 WHERE epn.id_episode = e.id_episode
                   AND epn.flg_status = 'M'
                   AND epn.dt_pn_date = nvl(ea.dt_epis_anamnesis_tstz, epn.dt_pn_date)
                   AND epn.id_prof_create = ea.id_professional
                   AND nvl(epn.id_dep_clin_serv, -1) = nvl(ei.id_dep_clin_serv, -1)
                   AND epn.id_pn_note_type = 8
                   AND epd.id_pn_data_block = 92
                   AND to_char(dbms_lob.substr(epd.pn_note, 4000, 1)) = to_char(dbms_lob.substr(ea.desc_epis_anamnesis, 4000, 1)));

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records c_cursor_type;
    l_limit       PLS_INTEGER := 1000;

    l_id_epis_pn          epis_pn.id_epis_pn%TYPE;
    l_date                VARCHAR2(1000 CHAR);
    l_id_institution      institution.id_institution%TYPE;
    l_id_software         software.id_software%TYPE;
    l_id_language         language.id_language%TYPE;
    l_prof                profissional;
    l_id_profile_template profile_template.id_profile_template%TYPE;
    l_error               t_error_out;

BEGIN

    OPEN c_get_records;
    LOOP
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        FOR i IN 1 .. l_get_records.count
        LOOP
        
            l_id_institution      := l_get_records(i).id_institution;
            l_id_software         := l_get_records(i).id_soft;
            l_id_language         := l_get_records(i).id_language;
            l_prof                := profissional(l_get_records(i).id_professional, l_id_institution, l_id_software);
            l_id_profile_template := pk_prof_utils.get_prof_profile_template(l_prof);
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => l_id_language,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => l_prof);
        
            IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => l_id_language,
                                                        i_prof                => l_prof,
                                                        i_epis_pn             => NULL,
                                                        i_id_dictation_report => NULL,
                                                        i_id_episode          => l_get_records(i).id_episode,
                                                        i_pn_flg_status       => 'M',
                                                        i_id_pn_note_type     => 8,
                                                        i_dt_pn_date          => l_get_records(i).dt_epis_anamnesis_tstz,
                                                        i_id_dep_clin_serv    => l_get_records(i).id_dep_clin_serv,
                                                        i_id_pn_data_block    => table_number(92, 47),
                                                        i_id_pn_soap_block    => table_number(19, 6),
                                                        i_id_task             => table_number(NULL, NULL),
                                                        i_id_task_type        => table_number(NULL, NULL),
                                                        i_pn_note             => table_clob(l_get_records(i)
                                                                                            .desc_epis_anamnesis,
                                                                                            l_date),
                                                        i_id_professional     => l_prof.id,
                                                        i_dt_create           => l_get_records(i).dt_epis_anamnesis_tstz,
                                                        i_dt_last_update      => l_get_records(i).dt_epis_anamnesis_tstz,
                                                        i_dt_sent_to_hist     => l_get_records(i).dt_epis_anamnesis_tstz,
                                                        i_id_prof_sign_off    => l_prof.id,
                                                        i_dt_sign_off         => l_get_records(i).dt_epis_anamnesis_tstz,
                                                        o_id_epis_pn          => l_id_epis_pn,
                                                        o_error               => l_error)
            THEN
                raise_application_error(-20001,
                                        'ERROR: pk_prog_notes_core.set_save_def_note for id_episode: ' || l_get_records(i).id_episode ||
                                        ' dt_epis_anamnesis_tstz: ' || l_get_records(i).dt_epis_anamnesis_tstz || chr(13) || ' l_id_language: ' ||
                                        l_id_language  || chr(13) || ' l_prof: ' || l_prof.id || ',' || l_prof.institution || ', ' ||
                                        l_prof.software ||
                                        chr(13) || chr(13) || l_error.log_id || ' -> ' || l_error.err_desc);
            END IF;
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/

-- CHANGE END: ANTONIO.NETO
