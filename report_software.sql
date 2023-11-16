-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 22/10/2014 15:47
-- CHANGE REASON: [ALERT-299375] table review type of report association
DECLARE
BEGIN
    UPDATE report_software rs
       SET rs.flg_cda_type = decode(rs.id_report, 691, 'P', 693, 'M', 694, 'M');
END;
/
-- CHANGE END:  Rui Gomes