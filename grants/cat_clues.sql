-- CHANGED BY: Alexander Camilo
-- CHANGE DATE: 03/05/2018 12:00
-- CHANGE REASON: [EMR-2257] Import Cat_clues data
grant select on cat_clues to alert_adtcod_cfg;
grant select on cat_clues to alert_ro;
grant select on cat_clues to alert_config;
-- CHANGE END: Alexander Camilo

-- CHANGED BY: André Silva
-- CHANGE DATE: 21/05/2018
-- CHANGE REASON: EMR-3599
grant select on cat_clues to alert_inter;
-- CHANGE END: André Silva