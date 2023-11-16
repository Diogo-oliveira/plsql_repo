-- CHANGED BY: Susana Silva
-- CHANGE DATE: 08/03/2010 11:49
-- CHANGE REASON: [ALERT-79827] 
grant select, references on UNIT_MEASURE to alert_Default;
-- CHANGE END: Susana Silva

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 22/11/2011 15:57
-- CHANGE REASON: [ALERT-206165 ] 10_ALERT_Table_Grants
grant references on UNIT_MEASURE to alert_product_mt;
grant references on UNIT_MEASURE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 09:58
-- CHANGE REASON: [ALERT-206286 ] 
grant references on UNIT_MEASURE to alert_product_mt;
grant references on UNIT_MEASURE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 23/11/2011 11:43
-- CHANGE REASON: [ALERT-206286 ] 
grant references on UNIT_MEASURE to alert_product_mt;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Pedro Quinteiro
-- CHANGE DATE: 24/11/2011 12:40
-- CHANGE REASON: [ALERT-206772] 
grant references, select on UNIT_MEASURE to alert_product_mt;
grant references, select on UNIT_MEASURE to alert_product_tr;
-- CHANGE END: Pedro Quinteiro

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 09/12/2013 14:07
-- CHANGE REASON: [ALERT-271432] 
grant select, references on unit_measure to alert_core_data;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Nuno Gomes
-- CHANGE DATE: 12/03/2014 17:07
-- CHANGE REASON: [CODING-1888] 
grant select, references on unit_measure to alert_coding_tr;
-- CHANGE END: Nuno Gomes



-- CHANGED BY:  luis.r.silva
-- CHANGE DATE: 07/05/2014 09:01
-- CHANGE REASON: [ALERT-283775] 
grant select on unit_measure to alert_apex_tools;
-- CHANGE END:  luis.r.silva

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 14/02/2017 17:27
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('grant references, select on UNIT_MEASURE to alert_product_tr with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 07/03/2017 15:04
-- CHANGE REASON: [ALERT-328830 ] New ADW Report to identify prescriptions for Expensive Drugs - Medication View
BEGIN
    pk_versioning.run('grant references, select on UNIT_MEASURE to alert_product_tr with grant option');
END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 30/06/2017 15:15
-- CHANGE REASON: [ALERT-331764] More grants ALERT TO ALERT_APEX_TOOLS_CONTENT

grant select on alert.unit_measure to alert_apex_tools_content;

-- CHANGE END: Luis Fernandes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 09/01/2018 16:30
-- CHANGE REASON: [ALERT-334916 ] Dispensation action per time interval
BEGIN
    pk_versioning.run('grant references, select on UNIT_MEASURE to ALERT_PHARMACY_DATA with grant option');
END;
/
-- CHANGE END: Sofia Mendes


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2018-1-15
-- CHANGED REASON: ALERT-335044

BEGIN
pk_versioning.run(i_sql => 'grant select on alert.unit_measure to alert_pharmacy_func with grant option');
END;
/
-- CHANGE END: Joao Coutinho



-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2018-5-3
-- CHANGED REASON: CEMR-1390

grant select, insert, update on alert.unit_measure to alert_core_cnt with grant option;
-- CHANGE END: Ana Moita
