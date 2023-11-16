-- CHANGED BY: Susana Silva
-- CHANGE DATE: 05/03/2010 09:49
-- CHANGE REASON: [ALERT-79477 ] 
grant select, references on PROFILE_TEMPLATE to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: Susana Silva
-- CHANGE DATE: 15/03/2010 15:06
-- CHANGE REASON: [ALERT-79326] 
grant select, references on PROFILE_TEMPLATE to ALERT_DEFAULT;
-- CHANGE END: Susana Silva

-- CHANGED BY: José Brito
-- CHANGE DATE: 10/12/2010 16:48
-- CHANGE REASON: [ALERT-146613] Grant for profile_template
BEGIN
EXECUTE IMMEDIATE 'GRANT SELECT ON ALERT.PROFILE_TEMPLATE TO ALERT_ADTCOD';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito

-- CHANGED BY: José Brito
-- CHANGE DATE: 10/12/2010 16:49
-- CHANGE REASON: [ALERT-148454] Grant for profile_template
BEGIN
EXECUTE IMMEDIATE 'GRANT SELECT ON ALERT.PROFILE_TEMPLATE TO ALERT_ADTCOD';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('WARNING: Object already exists.');
END;
/
-- CHANGE END: José Brito

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 12:40
-- CHANGE REASON: [ALERT-206772] 
grant references, select on profile_template to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 17:50
-- CHANGE REASON: [ALERT-206929] 
GRANT REFERENCES,SELECT  ON profile_template TO ALERT_PRODUCT_TR;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 09/05/2014 17:31
-- CHANGE REASON: [ALERT-283653] 
grant select on profile_template  to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 28/05/2014 10:54
-- CHANGE REASON: [ALERT-281087] 
grant select on profile_template to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 29/05/2014 09:04
-- CHANGE REASON: [ALERT-283483] 
grant select, references on profile_template to alert_core_data;
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.profile_template to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes

-- CHANGED BY: André Silva
-- CHANGE DATE: 25/07/2018
-- CHANGE REASON: [CEMR-1441] 
grant select on profile_template to alert_inter;
-- CHANGE END: André Silva


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-7-26
-- CHANGED REASON: CEMR-1903

-- CHANGED BY: Kelsey Lai
-- CHANGE DATE: 2018-06-01
-- CHANGE REASON: [CEMR-1632] [Subtask] [CNT] DB alert_core_cnt.doc_template and alert_core_cnt_api.pk_cnt_doc_template
grant select on alert.profile_template to alert_core_cnt with grant option;
-- CHANGE END: Kelsey Lai

-- CHANGE END: Ana Moita


-- CHANGED BY: filipe.f.pereira
-- CHANGE DATE: 
-- CHANGE REASON: 
grant references on PROFILE_TEMPLATE to ALERT_ADTCOD_CFG;
-- CHANGE END: filipe.f.pereira