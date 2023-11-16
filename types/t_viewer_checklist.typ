-->t_viewer_checklist|alert|type
CREATE OR REPLACE TYPE t_viewer_checklist force AS OBJECT
(
    checklist_id           NUMBER(24),
    checklist_description  VARCHAR2(1000 CHAR),
    id_viewer_rank         NUMBER(12),
    checklist_icon_color   VARCHAR2(1000 CHAR),
    checklist_icon_name    VARCHAR2(1000 CHAR),
    checklist_icon_tooltip VARCHAR2(1000 CHAR)
);
/

