-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-1-21
-- CHANGE REASON: [CALERT-1265] Progress notes Calendar view
CREATE OR REPLACE TYPE t_rec_note_type_condition force AS OBJECT
(
    id_pn_area          NUMBER(24), -- pn_area identifieridentifier
    id_pn_note_type     NUMBER(24), -- note type 
    note_type_desc      VARCHAR(200 CHAR), -- note event date
    cal_delay_time      NUMBER(6), -- delay time condition
    cal_icu_delay_time  NUMBER(6), -- delay time condition for ICU
    cal_expect_date     NUMBER(6), -- calculate date condition
    flg_cal_type        VARCHAR2(3 CHAR),-- flg type
    flg_cal_time_filter VARCHAR2(2 CHAR), -- flg calculate time
	flg_edit_condition  VARCHAR2(1 CHAR)
)
;
/
-- CHANGE END: Amanda Lee
