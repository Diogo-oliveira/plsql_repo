-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 16/05/2016 15:14
-- CHANGE REASON: [ALERT-320961] Discharge Care Instructions - DB - Allow multiple values on discharge instructions
INSERT INTO disch_notes_discussed (id_discharge_notes, instructions_discussed)
SELECT dn.id_discharge_notes, dn.instructions_discussed
  FROM discharge_notes dn
 WHERE dn.instructions_discussed IS NOT NULL
   AND NOT EXISTS (SELECT 1
          FROM disch_notes_discussed dnd
         WHERE dnd.id_discharge_notes = dn.id_discharge_notes);
-- CHANGE END: Vanessa Barsottelli