-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/12/2017 15:04
-- CHANGE REASON: [ALERT-334473] 
GRANT SELECT ON V_BMNG_REASON TO ALERT_INTER;
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 04/12/2017 16:09
-- CHANGE REASON: [ALERT-334473] 
begin
pk_versioning.run('GRANT SELECT ON V_BMNG_REASON TO ALERT_INTER');
end;
/

-- CHANGE END: Ana Matos