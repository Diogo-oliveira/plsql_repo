DECLARE
    l_epis_diagnosis epis_diagnosis.id_epis_diagnosis%TYPE;
    l_flg_type_x  CONSTANT epis_diagnosis.flg_type%TYPE := 'X';
    l_dt_very_old CONSTANT epis_diagnosis.dt_epis_diagnosis_tstz%TYPE := to_timestamp('1800-01-01 00:00',
                                                                                      'YYYY-MM-DD HH24:MI');

    PROCEDURE activate_uk IS
        e_name_already_exists EXCEPTION;
        e_uk_already_exists EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_name_already_exists, -955); -- name already exists
        PRAGMA EXCEPTION_INIT(e_uk_already_exists, -2261); -- unique key already exists
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE 'CREATE INDEX eds_epis_diag_typ_uk_ix ON epis_diagnosis(id_episode, id_diagnosis, flg_type)';
        EXCEPTION
            WHEN e_name_already_exists THEN
                dbms_output.put_line('Index eds_epis_diag_typ_uk_ix already created.');
        END;
    
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE epis_diagnosis add CONSTRAINT eds_epis_diag_typ_uk UNIQUE(id_episode, id_diagnosis, flg_type) enable novalidate';
        EXCEPTION
            WHEN e_uk_already_exists THEN
                dbms_output.put_line('Unique key eds_epis_diag_typ_uk already created.');
        END;
    END;
BEGIN
    FOR cur IN (SELECT ed.id_episode, ed.id_diagnosis, ed.flg_type, COUNT(*)
                  FROM epis_diagnosis ed
                 WHERE ed.flg_type != l_flg_type_x
                 GROUP BY ed.id_episode, ed.id_diagnosis, ed.flg_type
                HAVING COUNT(*) > 1
                 ORDER BY ed.id_episode, ed.id_diagnosis, ed.flg_type)
    LOOP
        BEGIN
            SELECT ed.id_epis_diagnosis
              INTO l_epis_diagnosis
              FROM epis_diagnosis ed
             WHERE ed.id_episode = cur.id_episode
               AND ed.id_diagnosis = cur.id_diagnosis
               AND ed.flg_type = cur.flg_type
               AND (SELECT MAX(greatest(nvl(ed.dt_epis_diagnosis_tstz, l_dt_very_old),
                                        nvl(ed.dt_cancel_tstz, l_dt_very_old),
                                        nvl(ed.dt_rulled_out_tstz, l_dt_very_old),
                                        nvl(ed.dt_confirmed_tstz, l_dt_very_old),
                                        nvl(ed.dt_base_tstz, l_dt_very_old)))
                      FROM dual) = (SELECT MAX(greatest(nvl(ed1.dt_epis_diagnosis_tstz, l_dt_very_old),
                                                        nvl(ed1.dt_cancel_tstz, l_dt_very_old),
                                                        nvl(ed1.dt_rulled_out_tstz, l_dt_very_old),
                                                        nvl(ed1.dt_confirmed_tstz, l_dt_very_old),
                                                        nvl(ed1.dt_base_tstz, l_dt_very_old))) dt_max_greatest
                                      FROM epis_diagnosis ed1
                                     WHERE ed1.id_episode = cur.id_episode
                                       AND ed1.id_diagnosis = cur.id_diagnosis
                                       AND ed1.flg_type = cur.flg_type)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_diagnosis := NULL;
                pk_alertlog.log_error(text        => cur.id_episode || ', ' || cur.id_diagnosis || ', ' || cur.flg_type ||
                                                     ' - NO_DATA_FOUND',
                                      object_name => 'MIGRATION');
        END;
    
        IF l_epis_diagnosis IS NOT NULL
        THEN
            UPDATE epis_diagnosis ed
               SET ed.flg_type = l_flg_type_x
             WHERE ed.id_episode = cur.id_episode
               AND ed.id_diagnosis = cur.id_diagnosis
               AND ed.flg_type = cur.flg_type
               AND ed.id_epis_diagnosis != l_epis_diagnosis;
        END IF;
    END LOOP;

    COMMIT;

    activate_uk;
END;
/

DECLARE
    l_dt_very_old CONSTANT epis_diagnosis.dt_epis_diagnosis_tstz%TYPE := to_timestamp('1800-01-01 00:00',
                                                                                      'YYYY-MM-DD HH24:MI');
    l_ed_type_x   CONSTANT VARCHAR2(1) := 'X';
    l_ed_type_d   CONSTANT VARCHAR2(1) := 'D';
    l_ed_type_p   CONSTANT VARCHAR2(1) := 'P';

    l_null_value CONSTANT VARCHAR2(3) := '-!-';
    --
    l_count_d PLS_INTEGER;
    l_count_p PLS_INTEGER;
    l_ed_d    table_number := table_number();
    l_ed_p    table_number := table_number();
    l_ed_x    table_number;
    --
    FUNCTION get_ed_x
    (
        i_episode     IN episode.id_episode%TYPE,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_desc_ed     IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        i_line_number IN PLS_INTEGER
    ) RETURN table_number IS
        l_ret table_number;
    BEGIN
        SELECT t.id_epis_diagnosis BULK COLLECT
          INTO l_ret
          FROM (SELECT ed.id_epis_diagnosis,
                       row_number() over(ORDER BY greatest(nvl(ed.dt_epis_diagnosis_tstz, l_dt_very_old), nvl(ed.dt_cancel_tstz, l_dt_very_old), nvl(ed.dt_rulled_out_tstz, l_dt_very_old), nvl(ed.dt_confirmed_tstz, l_dt_very_old), nvl(ed.dt_base_tstz, l_dt_very_old))) line_number
                  FROM epis_diagnosis ed
                 WHERE ed.id_episode = i_episode
                   AND ed.id_diagnosis = i_diagnosis
                   AND ed.flg_type = l_ed_type_x
                   AND nvl(ed.desc_epis_diagnosis, l_null_value) = nvl(i_desc_ed, l_null_value)) t
         WHERE t.line_number <= i_line_number
         ORDER BY t.line_number;
    
        --The returned ed is ordered by date. Where the first line is the newest record.
        RETURN l_ret;
    END get_ed_x;
BEGIN
    FOR r_ed IN (SELECT ed.id_episode, ed.id_diagnosis, ed.flg_type, ed.desc_epis_diagnosis, COUNT(*) total_x_diags
                   FROM epis_diagnosis ed
                  WHERE ed.flg_type = l_ed_type_x
                    AND ed.id_diagnosis IN (SELECT d.id_diagnosis
                                              FROM diagnosis d
                                             WHERE d.flg_other = 'Y')
                  GROUP BY ed.id_episode, ed.id_diagnosis, ed.flg_type, ed.desc_epis_diagnosis
                  ORDER BY ed.id_episode, ed.id_diagnosis, ed.flg_type, ed.desc_epis_diagnosis)
    LOOP
        BEGIN
            --Count final diagnoses
            SELECT COUNT(*)
              INTO l_count_d
              FROM epis_diagnosis ed
             WHERE ed.id_episode = r_ed.id_episode
               AND ed.id_diagnosis = r_ed.id_diagnosis
               AND ed.flg_type = l_ed_type_d
               AND nvl(ed.desc_epis_diagnosis, l_null_value) = nvl(r_ed.desc_epis_diagnosis, l_null_value);
        
            --Count diferencial diagnoses
            SELECT COUNT(*)
              INTO l_count_p
              FROM epis_diagnosis ed
             WHERE ed.id_episode = r_ed.id_episode
               AND ed.id_diagnosis = r_ed.id_diagnosis
               AND ed.flg_type = l_ed_type_p
               AND nvl(ed.desc_epis_diagnosis, l_null_value) = nvl(r_ed.desc_epis_diagnosis, l_null_value);
        
            IF l_count_d = 0
               AND l_count_p = 0
            THEN
                IF r_ed.total_x_diags >= 2
                THEN
                    --add diagnosis to the two types
                    l_ed_x := get_ed_x(i_episode     => r_ed.id_episode,
                                       i_diagnosis   => r_ed.id_diagnosis,
                                       i_desc_ed     => r_ed.desc_epis_diagnosis,
                                       i_line_number => 2);
                
                    l_ed_d.extend();
                    l_ed_d(l_ed_d.count) := l_ed_x(1);
                
                    l_ed_p.extend();
                    l_ed_p(l_ed_p.count) := l_ed_x(2);
                ELSE
                    --add diagnosis to diferencial type by default
                    l_ed_x := get_ed_x(i_episode     => r_ed.id_episode,
                                       i_diagnosis   => r_ed.id_diagnosis,
                                       i_desc_ed     => r_ed.desc_epis_diagnosis,
                                       i_line_number => 1);
                
                    l_ed_p.extend();
                    l_ed_p(l_ed_p.count) := l_ed_x(1);
                END IF;
            ELSIF l_count_d = 0
                  AND l_count_p = 1
            THEN
                -- add diagnosis to final type
                l_ed_x := get_ed_x(i_episode     => r_ed.id_episode,
                                   i_diagnosis   => r_ed.id_diagnosis,
                                   i_desc_ed     => r_ed.desc_epis_diagnosis,
                                   i_line_number => 1);
            
                l_ed_d.extend();
                l_ed_d(l_ed_d.count) := l_ed_x(1);
            ELSIF l_count_d = 1
                  AND l_count_p = 0
            THEN
                -- add diagnosis to diferencial type
                l_ed_x := get_ed_x(i_episode     => r_ed.id_episode,
                                   i_diagnosis   => r_ed.id_diagnosis,
                                   i_desc_ed     => r_ed.desc_epis_diagnosis,
                                   i_line_number => 1);
            
                l_ed_p.extend();
                l_ed_p(l_ed_p.count) := l_ed_x(1);
            ELSE
                --This kind of ED record is to remain with flag X 
                NULL;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('#################');
                dbms_output.put_line('ERROR INSIDE LOOP');
                dbms_output.put_line('- ID_EPISODE: ' || r_ed.id_episode);
                dbms_output.put_line('- ID_DIAGNOSIS: ' || r_ed.id_diagnosis);
                dbms_output.put_line('- DESC_EPIS_DIAGNOSIS: ' || r_ed.desc_epis_diagnosis);
                dbms_output.put_line('- SQLCODE: ' || SQLCODE);
                dbms_output.put_line('- SQLERRM: ' || SQLERRM);
                dbms_output.put_line('@@@@@@@@@@@@@@@@@');
        END;
    END LOOP;

    --UPDATE DIF DIAG
    UPDATE epis_diagnosis ed
       SET ed.flg_type = l_ed_type_p
     WHERE ed.id_epis_diagnosis IN (SELECT column_value id_epis_diagnosis
                                      FROM TABLE(l_ed_p));

    --UPDATE FINAL DIAG
    UPDATE epis_diagnosis ed
       SET ed.flg_type = l_ed_type_d
     WHERE ed.id_epis_diagnosis IN (SELECT column_value id_epis_diagnosis
                                      FROM TABLE(l_ed_d));

    COMMIT;
END;
/
