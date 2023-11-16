-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 16:24
-- CHANGE REASON:     ALERT-310274 03 - Packages, Types & Views Versioning
BEGIN
    pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_table_desc_info_ranked AS TABLE OF t_rec_desc_info_ranked
 ]');
END;
/