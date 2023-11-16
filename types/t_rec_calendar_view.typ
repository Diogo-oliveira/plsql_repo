-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2017-11-16
-- CHANGE REASON: [CALERT-212] Progress notes Calendar view
CREATE OR REPLACE TYPE t_rec_calendar_view force AS OBJECT
(
    id_pn_note_type NUMBER(24), -- note type identifier
    dt_1            table_varchar, -- calendar day1
    dt_2            table_varchar, -- calendar day2
    dt_3            table_varchar, -- calendar day3
    dt_4            table_varchar, -- calendar day4
    dt_5            table_varchar, -- calendar day5
    dt_6            table_varchar, -- calendar day6
    dt_7            table_varchar  -- calendar day7
)
;
-- CHANGE END: Amanda Lee
/
