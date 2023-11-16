grant select on cancel_reason to alert_viewer; 

-- CHANGED BY: Ana Rita Martins
-- CHANGED DATE: 14-07-2009
-- CHANGE REASON: CODING-636
grant select, references on CANCEL_REASON to ALERT_ADTCOD;
-- CHANGE END: Ana Rita Martins

-- CHANGED BY: Susana Silva
-- CHANGE DATE: 15/03/2010 15:06
-- CHANGE REASON: [ALERT-79326] 
grant select, references on CANCEL_REASON to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Telmo
-- CHANGE DATE: 14-12-2010
-- CHANGE REASON: APS-1048
grant select on ALERT.cancel_reason to alert_basecomp;
-- CHANGE END: Telmo

-- CHANGED BY:  Telmo
-- CHANGE DATE: 04-05-2011
-- CHANGE REASON: APS-1581
grant select on CANCEL_REASON to ALERT_APSSCHDLR_TR;
-- CHANGE END:  Telmo


-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:42
-- CHANGE REASON: [ALERT-206286 ] 
grant references,select on CANCEL_REASON to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Alexis Nascimento
-- CHANGE DATE: 23/09/2014 09:35
-- CHANGE REASON: [ALERT-296372] ALERT® PHARMACY: New pharmacist profile
GRANT SELECT,REFERENCES ON ALERT.cancel_reason TO ALERT_PHARMACY_DATA;
-- CHANGE END: Alexis Nascimento


-- CHANGED BY: Vitor Oliveira
-- CHANGED DATE: 2015-1-6
-- CHANGED REASON: ALERT-292149

grant select on CANCEL_REASON to ALERT_PRODUCT_MT;
-- CHANGE END: Vitor Oliveira


-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 18/01/2016 10:29
-- CHANGE REASON: [ALERT-317861] Medication&Pharmacy - Product
GRANT REFERENCES, SELECT ON cancel_reason TO alert_product_mt WITH GRANT OPTION;
-- CHANGE END: rui.mendonca


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.CANCEL_REASON to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Diogo Oliveira
-- CHANGE DATE: 14/11/2017 09:00
GRANT SELECT ON CANCEL_REASON TO ALERT_INTER;
-- CHANGE END: Diogo Oliveira


-- CHANGED BY: Adriana Salgueiro
-- CHANGED DATE: 2020-10-26
-- CHANGED REASON: EMR-37315

grant SELECT on ALERT.CANCEL_REASON to ALERT_CORE_CNT;
-- CHANGE END: Adriana Salgueiro
