-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 05/05/2011 14:40
-- CHANGE REASON: [ALERT-175521] - Substituição do ecrã de requisição nas ecografias
CREATE OR REPLACE TYPE rec_preg_result_det IS OBJECT
(
    id_pat_pregnancy NUMBER,
    label_weeks      VARCHAR2(1000 CHAR),
    weeks_pregnant   NUMBER,
    label_trimester  VARCHAR2(1000 CHAR),
    trimester        VARCHAR2(30 CHAR)
);
-- CHANGE END: Alexandre Santos