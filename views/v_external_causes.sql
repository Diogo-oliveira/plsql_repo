-- CHANGED BY: Gisela Couto 
-- CHANGE REASON: 17/03/2014
-- CHANGE DATE:ALERT-273668 [External Causes] Create View needed for filter according to structure defined in Terminology Server to be consumed by Coding 
CREATE OR REPLACE VIEW v_external_causes AS
SELECT ec.id_external_cause, ec.code_external_cause,ec.id_content,ec.rank 
FROM external_cause ec
WHERE ec.flg_available='Y';
-- CHANGED END: Gisela Couto 