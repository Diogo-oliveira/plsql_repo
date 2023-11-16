-- CHANGED BY: daniel.albuquerque
-- CHANGE DATE: 28/Jun/2011 12:21
-- CHANGE REASON: ALERT-186050
BEGIN
    DELETE FROM rep_unique_identifier_excep ruie
     WHERE ruie.rep_unique_identifier IN ('UX_CHIEFCOMPLAINT_005', 'UX_CHIEFCOMPLAINT_003');

END;
/
-- CHANGE END

-- CHANGED BY: daniel.albuquerque
-- CHANGED DATE: 07/Jul/2011
-- CHANGED REASON: ALERT-187584
BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE rep_unique_identifier = 'UX_LAB_012';
END; 
/ 
-- CHANGE END
