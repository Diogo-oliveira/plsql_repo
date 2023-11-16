-- CHANGED BY: Luis Fernandes
-- CHANGED DATE: 2011-08-30
-- CHANGE REASON: ALERT-331948

grant select on country_market to alert_apex_tools_content;

-- CHANGED END: Luis Fernandes

-- CHANGED BY: Anna Kurowska
-- CHANGE DATE: 09/06/2020 16:53
-- CHANGE REASON: [EMR-32936] - [DB] Context to get geographic location > Wrong location
grant select, references on country_market to alert_adtcod;
-- CHANGE END: Anna Kurowska