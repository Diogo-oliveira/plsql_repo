-- CHANGED BY: Sofia Mendes
-- CHANGE REASON: ALERT-69406 Single page note for Discharge Summary
DECLARE

    CURSOR c_get_records IS
        SELECT pdn.*, ei.id_dep_clin_serv, il.id_language, e.id_institution, ei.id_software
          FROM phy_discharge_notes pdn
         INNER JOIN episode e
            ON pdn.id_episode = e.id_episode
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT JOIN institution_language il
            ON e.id_institution = il.id_institution
         WHERE pdn.flg_status = 'A'
           AND NOT EXISTS (SELECT *
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                 WHERE epn.id_episode = e.id_episode
                   AND epn.flg_status = 'M'
                   AND epn.dt_pn_date = nvl(pdn.dt_creation, epn.dt_pn_date)
                   AND epn.id_prof_create = pdn.id_professional
                   AND nvl(epn.id_dep_clin_serv, -1) = nvl(ei.id_dep_clin_serv, -1)
                   AND epn.id_pn_note_type = 13
                   AND epd.id_pn_data_block = 147
                   AND dbms_lob.compare(epd.pn_note, pdn.notes) = 0);

    TYPE c_cursor_type IS TABLE OF c_get_records%ROWTYPE;
    l_get_records c_cursor_type;
    l_limit       PLS_INTEGER := 1000;

    l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    l_id_epis_pn_det     epis_pn_det.id_epis_pn_det%TYPE;
    l_id_prof_sign_off   epis_pn.id_prof_signoff%TYPE;
    l_dt_sign_off        epis_pn.dt_signoff%TYPE;
    l_id_epis_pn_signoff epis_pn_signoff.id_epis_pn_signoff%TYPE;
    l_date               VARCHAR2(1000 CHAR);

BEGIN

    OPEN c_get_records;
    LOOP
        FETCH c_get_records BULK COLLECT
            INTO l_get_records LIMIT l_limit;
    
        FOR i IN 1 .. l_get_records.count
        LOOP
            BEGIN
                SELECT seq_epis_pn.nextval
                  INTO l_id_epis_pn
                  FROM dual;
            
                l_id_prof_sign_off := l_get_records(i).id_professional;
                l_dt_sign_off      := l_get_records(i).dt_creation;
                
                 l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => nvl(l_get_records(i).id_language, 2),
                                                             i_date => l_get_records(i).dt_creation,
                                                             i_prof => profissional(l_get_records(i).id_professional,
                                                                                    l_get_records(i).id_institution,
                                                                                    l_get_records(i).id_software));
            if(l_date is not null) then
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
                     id_pn_area)
                VALUES
                    (l_id_epis_pn,
                     l_get_records(i).id_episode,
                     'M',
                     l_get_records(i).dt_creation,
                     l_get_records(i).id_professional,
                     l_get_records(i).dt_creation,
                     l_get_records(i).id_dep_clin_serv,
                     NULL,
                     l_id_prof_sign_off,
                     l_dt_sign_off,
                     13,
                     4);
            
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
                     l_get_records(i).id_professional,
                     l_get_records(i).dt_creation,
                     147,
                     17,
                     'A',
                     l_get_records(i).notes,
                     l_get_records(i).dt_creation);
            
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
                     l_get_records(i).id_professional,
                     l_get_records(i).dt_creation,
                     47,
                     6,
                     'A',
                     l_date,
                     l_get_records(i).dt_creation);
            
                SELECT seq_epis_pn_signoff.nextval
                  INTO l_id_epis_pn_signoff
                  FROM dual;
            
                INSERT INTO epis_pn_signoff
                    (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                VALUES
                    (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).notes);
            
                SELECT seq_epis_pn_signoff.nextval
                  INTO l_id_epis_pn_signoff
                  FROM dual;
                INSERT INTO epis_pn_signoff
                    (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
                VALUES
                    (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
            end if;
            
            EXCEPTION
                WHEN OTHERS THEN
                    dbms_output.put_line('ERROR: ' || l_get_records(i).id_phy_discharge_notes || 'l_get_records(i).notes: ' || l_get_records(i).notes ||
                    ' l_date: ' || l_date
                     || ' SQLERR: ' || SQLERRM);
                   null;
            END;
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/
