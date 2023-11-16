-- CHANGED BY: Ana Moita
-- CHANGE DATE: 27/06/2019 
-- CHANGE REASON: [EMR-16741] 
grant
    SELECT , INSERT, UPDATE, DELETE ON doc_category TO alert_apex_tools;

grant
    SELECT ON doc_category TO alert_apex_tools_content;
grant
    SELECT , INSERT, UPDATE, DELETE ON doc_category TO alert_config;

grant
    SELECT , references ON doc_category TO alert_default;
grant
    SELECT , references, ALTER, INDEX, debug ON doc_category TO alert_viewer;
-- CHANGE END: Ana Moita