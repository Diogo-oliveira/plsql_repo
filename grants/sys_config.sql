-- CHANGED BY: Filipa Moura
-- CHANGE DATE: 
-- CHANGE REASON: SECAUTH-1153

grant select on ALERT.SYS_CONFIG to ALERT_IDP;

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on SYS_CONFIG to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 12:40
-- CHANGE REASON: [ALERT-206772] 
grant references, select on sys_config to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 17:52
-- CHANGE REASON: [ALERT-206929] 
GRANT SELECT,REFERENCES ON SYS_CONFIG TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 17:53
-- CHANGE REASON: [ALERT-206929] 
GRANT SELECT,REFERENCES ON SYS_CONFIG TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 19:30
-- CHANGE REASON: [ALERT-206929] 
grant  insert, update on sys_config to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 19:48
-- CHANGE REASON: [ALERT-206929] 
grant  execute on pk_episode to alert_inter;
-- CHANGE END: Pedro Quinteiro


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.SYS_CONFIG to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso

-- CHANGED BY: Joao Tavares
-- CHANGE DATE: 30/09/2019 15:15
-- CHANGE REASON: [ARCH-7867] 
grant select on sys_config to alert_core_data with grant option;
-- CHANGE END: Joao Tavares