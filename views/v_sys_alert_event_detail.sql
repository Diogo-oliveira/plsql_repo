
CREATE OR REPLACE VIEW v_sys_alert_event_detail AS
SELECT id_sys_alert_event,
       id_sys_alert_event_detail,
       dt_sys_alert_event_detail_tstz,
       dt_event,
       id_professional,
       prof_nick_name,
       desc_detail,
       id_detail_group,
       desc_detail_group
  FROM sys_alert_event_detail;