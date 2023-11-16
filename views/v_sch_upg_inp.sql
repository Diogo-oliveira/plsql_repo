-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW V_SCH_UPG_INP AS
SELECT v.*, sb.id_bed, sb.id_waiting_list external_id, 'W' req_flg_type
FROM V_SCH_UPG_BASE_VIEW v
  JOIN schedule_bed sb ON v.ID_SCHEDULE = sb.id_schedule -- safe join - one-to-one
WHERE v.FLG_SCH_TYPE = 'IN';
--CHANGE END: Telmo