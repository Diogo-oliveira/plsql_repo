-- CHANGED BY: Vanessa Barsottelli
-- CHANGE DATE: 29/11/2013 08:40
-- CHANGE REASON: [ALERT-270228] Development Global Search INP (ALERT_38120)
UPDATE vital_sign_notes vsn
   SET id_episode =
       (SELECT DISTINCT vsr.id_episode
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_notes = vsn.id_vital_sign_notes);
-- CHANGE END: Vanessa Barsottelli
