
-- CHANGED BY: Rui Marante
-- CHANGE DATE: 01/06/2011
-- CHANGE REASON: [PM-761]

--ALERT_PHARMACY_MT
grant execute on pk_date_utils to alert_pharmacy_mt;
grant execute on pk_types to alert_pharmacy_mt;
grant execute on pk_edit_trail to alert_pharmacy_mt;
--
grant execute on profissional to alert_pharmacy_mt;
grant execute on table_number to alert_pharmacy_mt;
grant execute on table_table_number to alert_pharmacy_mt;
--
grant select on language to alert_pharmacy_mt;

-- CHANGE END [PM-761]

