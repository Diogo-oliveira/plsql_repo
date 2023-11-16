-- CHANGED BY: Luis Fernandes
-- CHANGE DATE: 27-JAN-2017
-- CHANGE REASON: ALERT-328309
grant select on rep_profile_template to alert_apex_tools;
-- CHANGE END: Luis Fernandes

grant select, references on REP_PROFILE_TEMPLATE to ALERT_DEFAULT;