
-- CHANGED BY: Rui Marante
-- CHANGE DATE: 01/06/2011
-- CHANGE REASON: [PM-761]

--ALERT_PHARMACY_TR
grant execute on pk_sysdomain to alert_pharmacy_tr;
grant execute on pk_utils to alert_pharmacy_tr;
grant execute on pk_types to alert_pharmacy_tr;
grant execute on pk_date_utils to alert_pharmacy_tr;
grant execute on pk_sys_list to alert_pharmacy_tr;
grant execute on pk_alert_exceptions to alert_pharmacy_tr;
grant execute on pk_prof_utils to alert_pharmacy_tr;
grant execute on pk_cancel_reason to alert_pharmacy_tr;
grant execute on pk_edit_trail to alert_pharmacy_tr;
grant execute on pk_unit_measure to alert_pharmacy_tr;
--
grant execute on t_error_out to alert_pharmacy_tr;
grant execute on profissional to alert_pharmacy_tr;
grant execute on table_number to alert_pharmacy_tr;
grant execute on table_varchar to alert_pharmacy_tr;
grant execute on table_timestamp to alert_pharmacy_tr;
grant execute on table_table_number to alert_pharmacy_tr;
grant execute on table_table_varchar to alert_pharmacy_tr;
--
grant select on institution to alert_pharmacy_tr;
grant select on sys_config to alert_pharmacy_tr;
grant select on prof_preferences to alert_pharmacy_tr;
grant select on currency to alert_pharmacy_tr;

-- CHANGE END [PM-761]

