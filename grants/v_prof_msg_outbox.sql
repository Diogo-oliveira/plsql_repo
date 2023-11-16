-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 22/10/2014 19:48
-- CHANGE REASON: [ALERT-297786] messages support views
grant select, references on v_prof_msg_outbox to alert_viewer, alert_inter;
-- CHANGE END:  Rui Gomes