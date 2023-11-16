-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 21/05/2013 16:55
-- CHANGE REASON: [ALERT-248672] new obj
grant insert, update, select, delete on origin_soft_inst to alert_adtcod_cfg;
-- CHANGE END:  Rui Gomes

-- CHANGED BY: Kátia Marques
-- CHANGE DATE: 10-09-2010
-- CHANGE REASON: SCH-8248 SCH-8244 Origin Refactoring  
grant select on origin_soft_inst to ALERT_APSSCHDLR_TR;
-- CHANGE END: Kátia Marques



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.ORIGIN_SOFT_INST to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso
