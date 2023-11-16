-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 19/09/2013 15:05
-- CHANGE REASON: [ALERT-104571] 
UPDATE discharge_notes dn
   SET dn.discharge_instructions = dn.recommended;
-- CHANGE END:  sergio.dias