-- CHANGED BY: André Silva 
-- CHANGE REASON: EMR-21408
-- CHANGE DATE: 03/10/2019
CREATE OR REPLACE VIEW v_external_cause AS
SELECT ec.id_external_cause,
       ec.code_external_cause,
       ec.rank,
       ec.flg_available,
       ec.id_content
FROM external_cause ec;
-- CHANGED END: André Silva 