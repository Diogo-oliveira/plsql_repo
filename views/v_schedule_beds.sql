-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW v_schedule_beds AS
SELECT s.*
   FROM schedule s
   WHERE s.flg_sch_type = 'IN';
--CHANGE END: Telmo
