-- CHANGED BY: Amanda Lee
-- CHANGE DATE: 2018-1-21
-- CHANGE REASON: [CALERT-1265] Progress notes Calendar view
CREATE OR REPLACE TYPE t_rec_note_type_dt force AS OBJECT
(
    id_pn_note_type NUMBER(24), -- note type identifier
    id_episode      NUMBER(24), -- episode identifier
    dt_event        TIMESTAMP WITH LOCAL TIME ZONE -- note event date
)
;
-- CHANGE END: Amanda Lee
/
