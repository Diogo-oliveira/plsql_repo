-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 31/10/2017 15:15
-- CHANGE REASON: [    ALERT-333958] Need to get patient bed history for a given episode
--                
GRANT SELECT  ON V_BMNG_ALLOCATION_BED TO ALERT_INTER;
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/12/2017 16:09
-- CHANGE REASON: [ALERT-334473] 
begin
pk_versioning.run('GRANT SELECT ON V_BMNG_ALLOCATION_BED TO ALERT_INTER');
end;
/
-- CHANGE END: Ana Matos