-- CHANGED BY: Susana Silva
-- CHANGE DATE: 03/03/2010 15:43
-- CHANGE REASON: [ALERT-78803] 
grant select, references on task_type to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Susana Silva
-- CHANGE DATE: 03/03/2010 15:43
-- CHANGE REASON: [ALERT-78803] 
grant select, references on task_type to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 04/05/2012 09:32
-- CHANGE REASON: [ALERT-229206] VERSIONING TERMINOLOGY SERVER - SCHEMA ALERT - GRANTS
GRANT SELECT ON ALERT.TASK_TYPE TO ALERT_CORE_DATA;
/
GRANT REFERENCES ON ALERT.TASK_TYPE TO ALERT_CORE_DATA;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 02/12/2013 12:29
-- CHANGE REASON: [ALERT-267338] 
grant select on task_type to alert_core_tech;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 05/12/2013 10:55
-- CHANGE REASON: [ALERT-271385] 
grant select on alert.task_type to alert_core_tech;
grant select, references on alert.task_type to alert_core_data;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Bruno Martins
-- CHANGED DATE: 2014-04-08
-- CHANGE REASON: ADT-8075

grant select, references on task_type to alert_adtcod;

-- CHANGED END: Bruno Martins


-- CHANGED BY: Alexis Nascimento
-- CHANGED DATE: 2014-09-23
-- CHANGE REASON: ALERT-278848 

grant select, references on task_type to alert_pharmacy_data;

-- CHANGED END: Alexis Nascimento

-- CHANGED BY: Luciano Lema
-- CHANGE DATE: 03/06/2016 12:27
-- CHANGE REASON: [ALERT-321625] New table to associate task_types to editor types and update function Pk_api_editor.get_task_type_id
--                
grant references ON task_type TO alert_product_mt;
-- CHANGE END: Luciano Lema


-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2017-1-03
-- CHANGED REASON: ALERT-327486
grant SELECT on ALERT.TASK_TYPE to ALERT_APEX_TOOLS;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-5-10
-- CHANGED REASON: EMR-3283
GRANT SELECT ON alert.task_type TO alert_core_cnt WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-06-06
-- CHANGED REASON: EMR-1118
GRANT SELECT ON task_type TO alert_core_func WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso



-- CHANGED BY: Humberto Cardoso
-- CHANGED DATE: 2018-07-12
-- CHANGED REASON: EMR-4142
GRANT SELECT ON task_type TO alert_core_func WITH GRANT OPTION;
-- CHANGE END: Humberto Cardoso
