


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-2
-- CHANGED REASON: EMR-3023

-- Grant/Revoke object privileges 
grant
    SELECT , INSERT, DELETE ON cat_supply_mc TO alert_apex_tools;
grant
    SELECT , INSERT, UPDATE, DELETE ON cat_supply_mc TO alert_config;
-- CHANGE END: Ana Moita
