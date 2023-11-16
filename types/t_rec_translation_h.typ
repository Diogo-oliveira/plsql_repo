-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 20/10/2010 10:40
-- CHANGE REASON: [ALERT-127927] Review V_TRANSLATION
CREATE OR REPLACE TYPE t_rec_translation_h AS OBJECT
(
    id_language      number(6),
    id_translation   number(24),
    code_translation varchar2(200 char), 
    descr            varchar2(4000)
);
-- CHANGE END: Rui Spratley