-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-01-21
-- CHANGE REASON: [CALERT-212] Progress notes Calendar view
CREATE OR REPLACE TYPE t_rec_calendar_note_det force AS OBJECT
(
    id_episode           NUMBER(24),
    id_epis_pn           NUMBER(24),
    note_date_time       TIMESTAMP WITH LOCAL TIME ZONE, -- Time of registry last update
    id_pn_note_type      NUMBER(24), -- note type identifier
    note_type_desc       CLOB, -- note description
    note_flg_status      VARCHAR2(2 CHAR), -- id_pn_note_type and dt_event final status
    note_flg_status_desc VARCHAR2(50 CHAR), -- note flg_status description
	note_info_desc       VARCHAR2(200 CHAR),
    note_prof_signature  VARCHAR2(200 CHAR),
    id_prof              NUMBER(24),
    note_flg_ok          VARCHAR2(1 CHAR),
    note_flg_cancel      VARCHAR2(1 CHAR),
    note_nr_addendums    NUMBER(24),
    flg_editable         VARCHAR2(1 CHAR),
    flg_write            VARCHAR2(1 CHAR),
    viewer_category      NUMBER(24),
    viewer_category_desc VARCHAR2(50 CHAR), -- note flg_status description
    time_status          VARCHAR2(2 CHAR) -- id_pn_note_type and dt_event final status    
)
;
/
-- CHANGE END: Amanda Lee