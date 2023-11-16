-- CHANGED BY: Bruno Martins
-- CHANGE DATE: 2010-07-29
-- CHANGE REASON: ADT-2923

grant insert on professional to alert_adtcod;

-- CHANGE END: Bruno Martins

-- CHANGED BY: Miguel Moreira
-- CHANGE DATE: 22/06/2011
-- CHANGE REASON: SECAUTH-1985
GRANT SELECT, INSERT, UPDATE ON ALERT.PROFESSIONAL TO ALERT_IDP;
GRANT SELECT ON ALERT.SEQ_PROFESSIONAL TO ALERT_IDP;

-- END

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:57
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on PROFESSIONAL to alert_product_mt;
grant references on PROFESSIONAL to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on PROFESSIONAL to alert_product_mt;
grant references on PROFESSIONAL to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on PROFESSIONAL to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 19:30
-- CHANGE REASON: [ALERT-206929] 
grant  select  on professional to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 04/05/2012 09:32
-- CHANGE REASON: [ALERT-229206] VERSIONING TERMINOLOGY SERVER - SCHEMA ALERT - GRANTS
GRANT SELECT ON ALERT.PROFESSIONAL TO ALERT_CORE_DATA;
/
GRANT REFERENCES ON ALERT.PROFESSIONAL TO ALERT_CORE_DATA;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Pedro Pinheiro
-- CHANGE DATE: 23/04/2013 09:20
-- CHANGE REASON: [ARCHDB-1411] - Lucene search on professional name
GRANT SELECT,REFERENCES ON ALERT.PROFESSIONAL TO ALERT_CORE_FUNC;
-- CHANGE END: Pedro Pinheiro

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 05/12/2013 18:14
-- CHANGE REASON: [ALERT-271069] 
grant select, references on alert.professional to alert_core_Data;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 09:35
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT,REFERENCES ON ALERT.PROFESSIONAL TO ALERT_PHARMACY_DATA;
-- CHANGE END: Alexis Nascimento


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.PROFESSIONAL to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso


-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 26/01/2017 08:27
-- CHANGE REASON: [ALERT-328195 ] 
GRANT SELECT ON PROFESSIONAL TO ALERT_INTER;
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Nuno Amorim
-- CHANGE DATE: 28/05/2018
-- CHANGE REASON: [EMR-3495] 
GRANT SELECT ON PROFESSIONAL TO ALERT_APSSCHDLR_TR;
-- CHANGE END: Nuno Amorim

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/12/2020 10:26
-- CHANGE REASON: [EMR-39746]
grant select, references on professional to alert_product_tr;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 15/12/2020 10:33
-- CHANGE REASON: [EMR-39746]
grant select, references on professional to adw_stg  WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira

-- CHANGED BY: Cristina Oliveira
-- CHANGE DATE: 28/01/2021 08:39
-- CHANGE REASON: [EMR-41232]
GRANT SELECT ON professional TO alert_product_tr WITH GRANT OPTION;
-- CHANGE END: Cristina Oliveira