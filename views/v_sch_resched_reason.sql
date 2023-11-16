-- CHANGED BY: Telmo
-- CHANGE DATE: 15-10-2010
-- CHANGE REASON: ALERT-126053

CREATE OR REPLACE VIEW V_SCH_RESCHED_REASON
 (ID_RESCHED_REASON
 ,CODE_RESCHED_REASON
 ,ID_CONTENT
 ,FLG_AVAILABLE)
 AS SELECT SRSR.ID_RESCHED_REASON ID_RESCHED_REASON
          ,SRSR.CODE_RESCHED_REASON CODE_RESCHED_REASON
          ,SRSR.ID_CONTENT ID_CONTENT
          ,SRSR.FLG_AVAILABLE FLG_AVAILABLE
FROM SCH_RESCHED_REASON SRSR;

-- CHANGE END: Telmo