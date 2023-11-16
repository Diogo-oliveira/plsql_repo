-- CHANGED BY: Joel Lopes
-- CHANGE DATE: 15/01/2013
-- CHANGE REASON: 
CREATE OR REPLACE TYPE t_rec_fields force AS OBJECT
(
    field_id          VARCHAR2(100 CHAR),
    field_title       VARCHAR2(2000 CHAR),
    field_mandatory   VARCHAR2(2 CHAR), -- Y/N
    field_active      VARCHAR2(2 CHAR), -- Y/N
    field_description VARCHAR2(2000 CHAR),
    field_value       VARCHAR2(2000 CHAR),
    field_info        VARCHAR2(2 CHAR),
    rank              NUMBER
)
;
