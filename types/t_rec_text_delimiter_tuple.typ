-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 26/06/2012 17:33
-- CHANGE REASON: [ALERT-233665] API that retrieves the content of a set of Touch-option documentation entries in plain-text format
CREATE OR REPLACE TYPE t_rec_text_delimiter_tuple IS OBJECT
(
    text VARCHAR2(32767),
    delimiter   VARCHAR2(10)
);
-- CHANGE END: Ariel Machado