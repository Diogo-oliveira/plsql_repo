-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
CREATE OR REPLACE VIEW V_SCH_CANCEL_REASON AS
SELECT id_sch_cancel_reason,
       code_cancel_reason,
       flg_available
  FROM sch_cancel_reason;
  
-- CHANGE END: Telmo Castro

-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 19/11/2010 17:03
-- CHANGE REASON: [ALERT-143110] 
CREATE OR REPLACE VIEW V_SCH_CANCEL_REASON AS
SELECT id_sch_cancel_reason,
       code_cancel_reason,
       flg_available
  FROM sch_cancel_reason;
-- CHANGE END: Sérgio Santos