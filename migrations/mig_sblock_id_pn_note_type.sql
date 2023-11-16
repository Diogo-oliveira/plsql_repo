-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 28/Oct/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2). Re-organize the structure of the imaging data blocks
DECLARE
    l_count            PLS_INTEGER := 0;
    l_note_types       table_number := table_number(2, 3, 4, 5, 7, 8);
    l_id_pn_note_type  pn_note_type.id_pn_note_type%TYPE;
    l_rank             pn_sblock_mkt.rank%TYPE;
    l_id_market        market.id_market%TYPE;
    l_id_institution   institution.id_institution%TYPE;
    l_id_department    department.id_department%TYPE;
    l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
BEGIN
    UPDATE pn_sblock_mkt p
       SET p.id_pn_note_type = 1
     WHERE p.id_software <> 11;

    UPDATE pn_sblock_soft_inst p
       SET p.id_pn_note_type = 1
     WHERE p.id_software <> 11;

    --MKT
    FOR i IN 1 .. l_note_types.count
    LOOP
        FOR rec IN (SELECT DISTINCT pm.id_pn_soap_block, pm.id_software, pm.id_market
                      FROM pn_dblock_mkt pm
                     WHERE pm.id_pn_note_type = l_note_types(i))
        LOOP
            l_id_pn_note_type := NULL;
        
            BEGIN
                SELECT id_pn_note_type, id_market
                  INTO l_id_pn_note_type, l_id_market
                  FROM (SELECT ps.id_pn_note_type, ps.id_market, rank() over(ORDER BY ps.id_market DESC) origin_rank
                          FROM pn_sblock_mkt ps
                         WHERE ps.id_pn_soap_block = rec.id_pn_soap_block
                           AND ps.id_market IN (0, rec.id_market)
                           AND ps.id_software = rec.id_software
                           AND (ps.id_pn_note_type IS NULL OR ps.id_pn_note_type = l_note_types(i)))
                 WHERE origin_rank = 1
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    --get rank
                    BEGIN
                        SELECT p.rank
                          INTO l_rank
                          FROM pn_sblock_mkt p
                         WHERE p.id_pn_soap_block = rec.id_pn_soap_block
                           AND p.id_market IN (0, rec.id_market)
                           AND p.id_software = rec.id_software
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_rank := 10;
                    END;
                    --insert new record
                    INSERT INTO pn_sblock_mkt
                        (id_pn_soap_block, rank, id_software, id_pn_note_type, id_market)
                    VALUES
                        (rec.id_pn_soap_block, l_rank, rec.id_software, l_note_types(i), rec.id_market);
            END;
        
            IF (l_id_pn_note_type IS NULL)
            THEN
                UPDATE pn_sblock_mkt ps
                   SET ps.id_pn_note_type = l_note_types(i)
                 WHERE ps.id_pn_soap_block = rec.id_pn_soap_block
                   AND ps.id_market = l_id_market
                   AND ps.id_software = rec.id_software
                   AND ps.id_pn_note_type IS NULL;
            END IF;
        END LOOP;
    END LOOP;

    --SOFT_INST
    FOR i IN 1 .. l_note_types.count
    LOOP
        --id_institution, id_software, id_department, id_dep_clin_serv, id_pn_soap_block
        FOR rec IN (SELECT DISTINCT pm.id_pn_soap_block,
                                    pm.id_software,
                                    pm.id_institution,
                                    pm.id_department,
                                    pm.id_dep_clin_serv
                      FROM pn_dblock_soft_inst pm
                     WHERE pm.id_pn_note_type = l_note_types(i))
        LOOP
            l_id_pn_note_type := NULL;
        
            BEGIN
                SELECT id_pn_note_type, id_institution, id_department, id_dep_clin_serv
                  INTO l_id_pn_note_type, l_id_institution, l_id_department, l_id_dep_clin_serv
                  FROM (SELECT ps.id_pn_note_type,
                               id_institution,
                               id_department,
                               id_dep_clin_serv,
                               rank() over(ORDER BY ps.id_institution, ps.id_department, ps.id_dep_clin_serv DESC) origin_rank
                          FROM pn_sblock_soft_inst ps
                         WHERE ps.id_pn_soap_block = rec.id_pn_soap_block
                           AND ps.id_institution IN (0, rec.id_institution)
                           AND ps.id_department IN (0, rec.id_department)
                           AND ps.id_dep_clin_serv IN (0, rec.id_dep_clin_serv)
                           AND ps.id_software = rec.id_software
                           AND (ps.id_pn_note_type IS NULL OR ps.id_pn_note_type = l_note_types(i)))
                 WHERE origin_rank = 1
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    --get rank
                    SELECT p.rank
                      INTO l_rank
                      FROM pn_sblock_soft_inst p
                     WHERE p.id_pn_soap_block = rec.id_pn_soap_block
                       AND p.id_institution = rec.id_institution
                       AND p.id_department = rec.id_department
                       AND p.id_dep_clin_serv = rec.id_dep_clin_serv
                       AND p.id_software = rec.id_software
                       AND rownum = 1;
                    --insert new record
                    INSERT INTO pn_sblock_soft_inst
                        (id_pn_soap_block,
                         rank,
                         id_software,
                         id_pn_note_type,
                         id_institution,
                         id_department,
                         id_dep_clin_serv)
                    VALUES
                        (rec.id_pn_soap_block,
                         l_rank,
                         rec.id_software,
                         l_note_types(i),
                         rec.id_institution,
                         rec.id_department,
                         rec.id_dep_clin_serv);
            END;
        
            IF (l_id_pn_note_type IS NULL)
            THEN
                UPDATE pn_sblock_soft_inst ps
                   SET ps.id_pn_note_type = l_note_types(i)
                 WHERE ps.id_pn_soap_block = rec.id_pn_soap_block
                   AND ps.id_institution = l_id_institution
                   AND ps.id_department = l_id_department
                   AND ps.id_dep_clin_serv = l_id_dep_clin_serv
                   AND ps.id_software = rec.id_software
                   AND ps.id_pn_note_type IS NULL;
            END IF;
        END LOOP;
    END LOOP;

    UPDATE pn_sblock_mkt p
       SET p.id_pn_note_type = 2
     WHERE p.id_pn_note_type IS NULL;

    UPDATE pn_sblock_soft_inst p
       SET p.id_pn_note_type = 2
     WHERE p.id_pn_note_type IS NULL;

END;
/
