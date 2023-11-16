-- CHANGED BY: goncalo.almeida
-- CHANGE DATE: 11/Jul/2011 09:28
-- CHANGE REASON: ALERT-188049
BEGIN
    UPDATE rep_profile_template_det rptd
       SET rptd.id_reports = 299
     WHERE rptd.id_rep_profile_template IN (3, 4, 9, 10, 11, 13, 40, 41, 42, 43, 77, 82)
       AND rptd.id_reports = 194;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
-- CHANGE END

-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:18
-- CHANGE REASON: ALERT-206242
BEGIN
     MERGE INTO rep_profile_template_det rptd
     USING (SELECT 76 id_rep_profile_template, 490 id_reports, 0 id_institution, 'R' flg_area_report FROM dual) args
     ON (rptd.id_rep_profile_template = args.id_rep_profile_template AND rptd.id_reports = args.id_reports AND rptd.id_rep_screen IS NULL AND rptd.id_institution = args.id_institution AND rptd.flg_area_report = args.flg_area_report)
     WHEN NOT MATCHED THEN
         INSERT
             (id_rep_profile_template_det,
              id_rep_profile_template,
              id_reports,
              id_rep_screen,
              flg_area_report,
              rank,
              flg_action,
              value_action,
              id_institution,
              flg_available)
         VALUES
             (seq_rep_profile_template_det.NEXTVAL, 76, 490, NULL, 'R', 10001, 'OR', NULL, 0, 'Y')
     WHEN MATCHED THEN
         UPDATE
            SET flg_available = 'Y', rank = 10001;
END; 
/ 
-- CHANGE END


-- CHANGED BY: tiago.lourenco
-- CHANGE DATE: 22/Nov/2011 18:18
-- CHANGE REASON: ALERT-206242
BEGIN
     MERGE INTO rep_profile_template_det rptd
     USING (SELECT 77 id_rep_profile_template, 490 id_reports, 0 id_institution, 'R' flg_area_report FROM dual) args
     ON (rptd.id_rep_profile_template = args.id_rep_profile_template AND rptd.id_reports = args.id_reports AND rptd.id_rep_screen IS NULL AND rptd.id_institution = args.id_institution AND rptd.flg_area_report = args.flg_area_report)
     WHEN NOT MATCHED THEN
         INSERT
             (id_rep_profile_template_det,
              id_rep_profile_template,
              id_reports,
              id_rep_screen,
              flg_area_report,
              rank,
              flg_action,
              value_action,
              id_institution,
              flg_available)
         VALUES
             (seq_rep_profile_template_det.NEXTVAL, 77, 490, NULL, 'R', 10001, 'OR', NULL, 0, 'Y')
     WHEN MATCHED THEN
         UPDATE
            SET flg_available = 'Y', rank = 10001;
END; 
/ 
-- CHANGE END
