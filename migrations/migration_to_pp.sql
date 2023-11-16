DECLARE
    l_id_language         language.id_language%TYPE;
    l_profiles            table_number := table_number(508, 35, 505);
    l_profiles_final      table_number := table_number(124, 121, 123);
    l_id_profile_template profile_template.id_profile_template%TYPE;
    l_error               t_error_out;
BEGIN
    FOR rec IN (SELECT *
                  FROM prof_profile_template ppt
                  JOIN TABLE(l_profiles) p
                    ON p.column_value = ppt.id_profile_template
                   AND EXISTS (SELECT pi.id_prof_institution
                          FROM prof_institution pi
                         WHERE pi.id_professional = ppt.id_professional
                           AND pi.id_institution = ppt.id_institution
                           AND pi.dt_end_tstz IS NULL))
    LOOP
    
        BEGIN
            SELECT il.id_language
              INTO l_id_language
              FROM institution_language il
             WHERE il.flg_available = 'Y'
               AND il.id_institution = rec.id_institution
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_language := 2;
        END;
    
        IF (rec.id_profile_template IN (508))
        THEN
            l_id_profile_template := 124;
            --
        ELSIF (rec.id_profile_template IN (35))
        THEN
            l_id_profile_template := 121;
            --
        ELSE
            l_id_profile_template := 123;
        END IF;
    
        IF NOT pk_api_backoffice.intf_set_template_list(i_lang             => l_id_language,
                                                        i_id_profissional  => rec.id_professional,
                                                        i_institution_list => table_number(rec.id_institution),
                                                        i_software_list    => table_number(rec.id_software),
                                                        i_template_list    => table_number(l_id_profile_template),
                                                        o_error            => l_error)
        THEN
            dbms_output.put_line(l_error.ora_sqlerrm || ' lcall: ' || l_error.log_id || ' l_id_profile_template: ' ||
                                 l_id_profile_template || ' id_professional: ' || rec.id_professional ||
                                 ' id_institution: ' || rec.id_institution || ' id_software: ' || rec.id_software);
        END IF;
    
        COMMIT;
    END LOOP;

END;

