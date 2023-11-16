-- CHANGED BY: Filipe Silva
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv
          FROM epis_anamnesis ea
         INNER JOIN episode e ON ea.id_episode = e.id_episode
                             AND e.id_epis_type = 5
         INNER JOIN epis_info ei ON e.id_episode = ei.id_episode
         INNER JOIN institution i ON e.id_institution = i.id_institution
                                 AND i.id_market = 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C';

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
            SELECT seq_epis_pn_work.nextval
              INTO l_id_epis_pn
              FROM dual;
        
            l_id_prof_sign_off := l_get_records(i).id_professional;
            l_dt_sign_off      := l_get_records(i).dt_epis_anamnesis_tstz;
        
            INSERT INTO epis_pn
                (id_epis_pn,
                 id_episode,
                 flg_status,
                 pn_date,
                 id_prof_create,
                 dt_create,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type)
            VALUES
                (l_id_epis_pn,
                 l_get_records(i).id_episode,
                 'M',
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_professional,
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_dep_clin_serv,
                 NULL,
                 l_id_prof_sign_off,
                 l_dt_sign_off,
                 8);
        
            SELECT seq_epis_pn_det_work.nextval
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 96,
                 19,
                 'A',
                 l_get_records(i).desc_epis_anamnesis,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_det_work.nextval
              INTO l_id_epis_pn_det
              FROM dual;
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => profissional(l_get_records(i).id_professional,
                                                                                l_get_records(i).id_institution,
                                                                                11));
        
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 47,
                 6,
                 'A',
                 l_date,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
        
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_anamnesis);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;


-- CHANGED BY: Filipe Silva
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv
          FROM epis_anamnesis ea
         INNER JOIN episode e
            ON ea.id_episode = e.id_episode
           AND e.id_epis_type = 5
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
           AND i.id_market = 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C'
           AND NOT EXISTS (SELECT *
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                 WHERE epn.id_episode = e.id_episode
                   AND epn.flg_status = 'M'
                   AND epn.pn_date = nvl(ea.dt_epis_anamnesis_tstz, epn.pn_date)
                   AND epn.id_prof_create = ea.id_professional
                   AND nvl(epn.id_dep_clin_serv, -1) = nvl(ei.id_dep_clin_serv, -1)
                   AND epn.id_pn_note_type = 8
                   AND epd.id_pn_data_block = 92
                   AND to_char(epd.pn_note) = to_char(ea.desc_epis_anamnesis));

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
            SELECT seq_epis_pn_work.nextval
              INTO l_id_epis_pn
              FROM dual;
        
            l_id_prof_sign_off := l_get_records(i).id_professional;
            l_dt_sign_off      := l_get_records(i).dt_epis_anamnesis_tstz;
        
            INSERT INTO epis_pn
                (id_epis_pn,
                 id_episode,
                 flg_status,
                 pn_date,
                 id_prof_create,
                 dt_create,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type)
            VALUES
                (l_id_epis_pn,
                 l_get_records(i).id_episode,
                 'M',
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_professional,
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_dep_clin_serv,
                 NULL,
                 l_id_prof_sign_off,
                 l_dt_sign_off,
                 8);
        
            SELECT seq_epis_pn_det_work.nextval
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 92,
                 19,
                 'A',
                 l_get_records(i).desc_epis_anamnesis,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_det_work.nextval
              INTO l_id_epis_pn_det
              FROM dual;
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => profissional(l_get_records(i).id_professional,
                                                                                l_get_records(i).id_institution,
                                                                                11));
        
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 47,
                 6,
                 'A',
                 l_date,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
        
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_anamnesis);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/




-- CHANGED BY: Filipe Silva
-- CHANGE REASON: [ALERT-168848] H & P reformulation in INPATIENT (phase 2)
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv
          FROM epis_anamnesis ea
         INNER JOIN episode e ON ea.id_episode = e.id_episode
                             AND e.id_epis_type = 5
         INNER JOIN epis_info ei ON e.id_episode = ei.id_episode
         INNER JOIN institution i ON e.id_institution = i.id_institution
                                 AND i.id_market = 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C';

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
            SELECT seq_epis_pn_work.nextval
              INTO l_id_epis_pn
              FROM dual;
        
            l_id_prof_sign_off := l_get_records(i).id_professional;
            l_dt_sign_off      := l_get_records(i).dt_epis_anamnesis_tstz;
        
            INSERT INTO epis_pn
                (id_epis_pn,
                 id_episode,
                 flg_status,
                 pn_date,
                 id_prof_create,
                 dt_create,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type)
            VALUES
                (l_id_epis_pn,
                 l_get_records(i).id_episode,
                 'M',
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_professional,
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_dep_clin_serv,
                 NULL,
                 l_id_prof_sign_off,
                 l_dt_sign_off,
                 8);
        
            SELECT seq_epis_pn_det_work.nextval
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 96,
                 19,
                 'A',
                 l_get_records(i).desc_epis_anamnesis,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_det_work.nextval
              INTO l_id_epis_pn_det
              FROM dual;
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => profissional(l_get_records(i).id_professional,
                                                                                l_get_records(i).id_institution,
                                                                                11));
        
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 47,
                 6,
                 'A',
                 l_date,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
        
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_anamnesis);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;


-- CHANGED BY: Filipe Silva
-- CHANGE REASON: [ALERT-168848] H and P reformulation in INPATIENT (phase 2)
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv
          FROM epis_anamnesis ea
         INNER JOIN episode e
            ON ea.id_episode = e.id_episode
           AND e.id_epis_type = 5
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
           AND i.id_market = 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C'
           AND NOT EXISTS (SELECT *
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                 WHERE epn.id_episode = e.id_episode
                   AND epn.flg_status = 'M'
                   AND epn.pn_date = nvl(ea.dt_epis_anamnesis_tstz, epn.pn_date)
                   AND epn.id_prof_create = ea.id_professional
                   AND nvl(epn.id_dep_clin_serv, -1) = nvl(ei.id_dep_clin_serv, -1)
                   AND epn.id_pn_note_type = 8
                   AND epd.id_pn_data_block = 92
                   AND to_char(epd.pn_note) = to_char(ea.desc_epis_anamnesis));

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
            SELECT seq_epis_pn_work.nextval
              INTO l_id_epis_pn
              FROM dual;
        
            l_id_prof_sign_off := l_get_records(i).id_professional;
            l_dt_sign_off      := l_get_records(i).dt_epis_anamnesis_tstz;
        
            INSERT INTO epis_pn
                (id_epis_pn,
                 id_episode,
                 flg_status,
                 pn_date,
                 id_prof_create,
                 dt_create,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type)
            VALUES
                (l_id_epis_pn,
                 l_get_records(i).id_episode,
                 'M',
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_professional,
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_dep_clin_serv,
                 NULL,
                 l_id_prof_sign_off,
                 l_dt_sign_off,
                 8);
        
            SELECT seq_epis_pn_det_work.nextval
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 92,
                 19,
                 'A',
                 l_get_records(i).desc_epis_anamnesis,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_det_work.nextval
              INTO l_id_epis_pn_det
              FROM dual;
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => profissional(l_get_records(i).id_professional,
                                                                                l_get_records(i).id_institution,
                                                                                11));
        
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 47,
                 6,
                 'A',
                 l_date,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
        
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_anamnesis);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/

-- CHANGED BY: Filipe Silva
-- CHANGE REASON: [ALERT-168848] H and P reformulation in INPATIENT (phase 2)
DECLARE

    CURSOR c_get_records IS
        SELECT ea.*, ei.id_dep_clin_serv
          FROM epis_anamnesis ea
         INNER JOIN episode e
            ON ea.id_episode = e.id_episode
           AND e.id_epis_type = 5
         INNER JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         INNER JOIN institution i
            ON e.id_institution = i.id_institution
           AND i.id_market = 2
         WHERE ea.flg_status = 'A'
           AND ea.flg_type = 'C'
           AND NOT EXISTS (SELECT *
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                 WHERE epn.id_episode = e.id_episode
                   AND epn.flg_status = 'M'
                   AND epn.pn_date = nvl(ea.dt_epis_anamnesis_tstz, epn.pn_date)
                   AND epn.id_prof_create = ea.id_professional
                   AND nvl(epn.id_dep_clin_serv, -1) = nvl(ei.id_dep_clin_serv, -1)
                   AND epn.id_pn_note_type = 8
                   AND epd.id_pn_data_block = 92
                   AND to_char(epd.pn_note) = to_char(ea.desc_epis_anamnesis));

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
            SELECT seq_epis_pn_work.nextval
              INTO l_id_epis_pn
              FROM dual;
        
            l_id_prof_sign_off := l_get_records(i).id_professional;
            l_dt_sign_off      := l_get_records(i).dt_epis_anamnesis_tstz;
        
            INSERT INTO epis_pn
                (id_epis_pn,
                 id_episode,
                 flg_status,
                 pn_date,
                 id_prof_create,
                 dt_create,
                 id_dep_clin_serv,
                 id_dictation_report,
                 id_prof_signoff,
                 dt_signoff,
                 id_pn_note_type)
            VALUES
                (l_id_epis_pn,
                 l_get_records(i).id_episode,
                 'M',
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_professional,
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 l_get_records(i).id_dep_clin_serv,
                 NULL,
                 l_id_prof_sign_off,
                 l_dt_sign_off,
                 8);
        
            SELECT seq_epis_pn_det_work.nextval
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 92,
                 19,
                 'A',
                 l_get_records(i).desc_epis_anamnesis,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_det_work.nextval
              INTO l_id_epis_pn_det
              FROM dual;
        
            l_date := pk_date_utils.dt_chr_date_hour_tsz(i_lang => 2,
                                                         i_date => l_get_records(i).dt_epis_anamnesis_tstz,
                                                         i_prof => profissional(l_get_records(i).id_professional,
                                                                                l_get_records(i).id_institution,
                                                                                11));
        
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
                 l_get_records(i).dt_epis_anamnesis_tstz,
                 47,
                 6,
                 'A',
                 l_date,
                 l_get_records(i).dt_epis_anamnesis_tstz);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
        
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 17, l_get_records(i).desc_epis_anamnesis);
        
            SELECT seq_epis_pn_signoff.nextval
              INTO l_id_epis_pn_signoff
              FROM dual;
            INSERT INTO epis_pn_signoff
                (id_epis_pn_signoff, id_epis_pn, id_pn_soap_block, pn_signoff_note)
            VALUES
                (l_id_epis_pn_signoff, l_id_epis_pn, 6, l_date);
        
        END LOOP;
        EXIT WHEN c_get_records%NOTFOUND;
    END LOOP;

END;
/