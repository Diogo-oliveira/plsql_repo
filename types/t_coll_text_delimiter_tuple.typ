-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 26/06/2012 17:33
-- CHANGE REASON: [ALERT-233665] API that retrieves the content of a set of Touch-option documentation entries in plain-text format
CREATE OR REPLACE TYPE t_coll_text_delimiter_tuple  AS TABLE OF t_rec_text_delimiter_tuple;
-- CHANGE END: Ariel Machado