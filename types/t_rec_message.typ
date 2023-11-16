-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 06/05/2011 11:28
-- CHANGE REASON: [ALERT-176644] cdr data model (changes_ddl.sql)
CREATE OR REPLACE TYPE t_rec_message AS OBJECT
(
    code_message VARCHAR2(200 CHAR), -- message code
    mandatory    VARCHAR2(1 CHAR), -- is the message for a mandatory field? Y/N

    CONSTRUCTOR FUNCTION t_rec_message RETURN SELF AS RESULT
)
;
-- CHANGE END: Pedro Carneiro