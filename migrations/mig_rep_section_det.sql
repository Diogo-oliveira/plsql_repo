-- CHANGED BY: goncalo.almeida
-- CHANGE DATE: 20/Jun/2011 15:56
-- CHANGE REASON: ALERT-185442
BEGIN
    UPDATE rep_section_det
       SET id_rep_section = 404
     WHERE id_rep_section = 189;
END;
/
-- CHANGE END

-- CHANGED BY: goncalo.almeida
-- CHANGE DATE: 26/Oct/2011 14:37
-- CHANGE REASON: ALERT-201847
begin
  update rep_section_Det rsd set rsd.id_software = 11 where rsd.id_reports = 330 and rsd.id_rep_section = 524 and rsd.id_software = 0;
end;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 57
     WHERE rsd.id_reports = 50
       AND rsd.id_rep_section = 487;
END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 62
     WHERE rsd.id_reports = 225
       AND rsd.id_rep_section = 487;
END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 47
     WHERE rsd.id_reports = 74
       AND rsd.id_rep_section = 487;
END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 162
     WHERE rsd.id_reports = 50
       AND rsd.id_rep_section = 488;
END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 167
     WHERE rsd.id_reports = 225
       AND rsd.id_rep_section = 488;
END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 02/Nov/2011 15:46
-- CHANGE REASON: ALERT-202859
BEGIN
    UPDATE rep_section_det rsd
       SET rsd.rank = 147
     WHERE rsd.id_reports = 74
       AND rsd.id_rep_section = 488;
END;
/
-- CHANGE END



-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
DELETE FROM rep_section_det rsd WHERE rsd.id_reports in (42,74,50,225,271,272,369,370,371) AND rsd.id_rep_section = 462;
END;
/
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 371 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 371, 462, 0, 0, 2, 262, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 370 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 370, 462, 0, 0, 2, 262, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 369 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 369, 462, 0, 0, 2, 257, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 272 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 272, 462, 0, 0, 2, 302, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 271 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 271, 462, 0, 0, 2, 302, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 225 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 225, 462, 0, 0, 2, 377, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 74 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 74, 462, 0, 0, 2, 357, 'A', 'Y');
END;
/ 
-- CHANGE END

-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 42 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 42, 462, 0, 0, 2, 302, 'A', 'Y');
END;
/ 
-- CHANGE END


-- CHANGED BY: jorge.matos
-- CHANGE DATE: 03/Nov/2011 14:45
-- CHANGE REASON: ALERT-203000
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 50 id_reports, 462 id_rep_section, 0 id_software, 0 id_institution, 0 id_market
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_default, flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 50, 462, 0, 0, 2, 372, 'A', 'Y');
END;
/ 
-- CHANGE END




-- CHANGED BY: Tiago Lourenço
-- CHANGE DATE: 27/12/2011
-- CHANGE REASON: [ALERT-211599] Issue Replication: Patient electronic copy of Health Information (specific CDA report for ambulatory)
BEGIN
    DELETE FROM rep_section_det rsd
     WHERE rsd.id_reports = 437
       AND rsd.id_rep_section = 507
           AND rsd.id_software = 0;
                         

    MERGE INTO rep_section_det rsd
    USING (SELECT 437 id_reports, 507 id_rep_section, 8 id_software, 0 id_institution, 0 id_market
             FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det,
             id_reports,
             id_rep_section,
             id_software,
             id_institution,
             id_market,
             rank,
             flg_default,
             flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 437, 507, 8, 0, 0, 0, 'A', 'Y');

    MERGE INTO rep_section_det rsd
    USING (SELECT 437 id_reports, 507 id_rep_section, 11 id_software, 0 id_institution, 0 id_market
             FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det,
             id_reports,
             id_rep_section,
             id_software,
             id_institution,
             id_market,
             rank,
             flg_default,
             flg_visible)
        VALUES
            (seq_rep_section_det.NEXTVAL, 437, 507, 11, 0, 0, 0, 'A', 'Y');

END;
/
-- CHANGE END: Tiago Lourenço

-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 506 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default, flg_date_filters)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 506, 0, 0, 0, 0, 'Y', 0, 'A', 'N')
    WHEN MATCHED THEN
        UPDATE
           SET flg_default = 'A', rank = 0, flg_visible = 'Y', flg_date_filters = 'N';
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 518 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default, flg_date_filters)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 518, 0, 0, 0, 0, 'Y', 0, 'A', 'N')
    WHEN MATCHED THEN
        UPDATE
           SET flg_default = 'A', rank = 0, flg_visible = 'Y', flg_date_filters = 'N';
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 519 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default, flg_date_filters)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 519, 0, 0, 0, 0, 'Y', 0, 'A', 'N')
    WHEN MATCHED THEN
        UPDATE
           SET flg_default = 'A', rank = 0, flg_visible = 'Y', flg_date_filters = 'N';
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 520 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default, flg_date_filters)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 520, 0, 0, 0, 0, 'Y', 0, 'A', 'N')
    WHEN MATCHED THEN
        UPDATE
           SET flg_default = 'A', rank = 0, flg_visible = 'Y', flg_date_filters = 'N';
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 506 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 506, 0, 0, 0, 0, 'Y', 0, 'A', 'N');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 518 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 518, 0, 0, 0, 0, 'Y', 0, 'A', 'N');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 519 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 519, 0, 0, 0, 0, 'Y', 0, 'A', 'N');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 520 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 520, 0, 0, 0, 0, 'Y', 0, 'A', 'N');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 506 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 506, 0, 0, 0, 0, 'Y', 0, 'A');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 518 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 518, 0, 0, 0, 0, 'Y', 0, 'A');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 519 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 519, 0, 0, 0, 0, 'Y', 0, 'A');
END;
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:22
-- CHANGE REASON: ALERT-206242
BEGIN
    MERGE INTO rep_section_det rsd
    USING (SELECT 490 id_reports, 520 id_rep_section, 0 id_software, 0 id_institution, 0 id_market, 0 id_rep_profile_template
        FROM dual) args
    ON (rsd.id_reports = args.id_reports AND rsd.id_rep_section = args.id_rep_section AND rsd.id_software = args.id_software AND rsd.id_institution = args.id_institution AND rsd.id_market = args.id_market and rsd.id_rep_profile_template = args.id_rep_profile_template)
    WHEN NOT MATCHED THEN
        INSERT
            (id_rep_section_det, id_reports, id_rep_section, id_software, id_institution, id_market, rank, flg_visible, id_rep_profile_template, flg_default)
        VALUES
            (seq_rep_section_det.NEXTVAL, 490, 520, 0, 0, 0, 0, 'Y', 0, 'A');
END;
/ 
-- CHANGE END
