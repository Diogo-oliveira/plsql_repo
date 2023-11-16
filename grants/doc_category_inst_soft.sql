-- CHANGED BY: Ana Moita
-- CHANGE DATE: 27/06/2019 
-- CHANGE REASON: [EMR-16741] 
grant select, insert, update, delete on DOC_CATEGORY_INST_SOFT to ALERT_APEX_TOOLS;
grant select on DOC_CATEGORY_INST_SOFT to ALERT_APEX_TOOLS_CONTENT;
grant select, insert, update, delete on DOC_CATEGORY_INST_SOFT to ALERT_CONFIG;
grant select on DOC_CATEGORY_INST_SOFT to ALERT_CORE_CNT with grant option;
grant select, references on DOC_CATEGORY_INST_SOFT to ALERT_DEFAULT;
grant select, references, alter, index, debug on DOC_CATEGORY_INST_SOFT to ALERT_VIEWER;
grant select on DOC_CATEGORY_INST_SOFT to APEX_ALERT_DEFAULT;
-- CHANGE END: Ana Moita
