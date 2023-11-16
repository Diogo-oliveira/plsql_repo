-- CHANGED BY: Joana Barroso
-- CHANGE DATE: 27/11/2013 08:20
-- CHANGE REASON: [ALERT-270542] 
UPDATE doc_external
     SET dt_last_identification = dt_last_identification_tstz;
-- CHANGE END: Joana Barroso