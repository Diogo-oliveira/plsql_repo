CREATE OR REPLACE TYPE t_rec_header_data force AS OBJECT
(
    text           VARCHAR2(4000),
    description    VARCHAR2(4000),
    icon           VARCHAR2(4000),
    action         VARCHAR2(4000),
    action_param   VARCHAR2(4000),
    shortcut       VARCHAR2(4000),
    SOURCE         VARCHAR2(4000),
    status         VARCHAR2(64),
    tooltip_title  VARCHAR2(4000),
    tooltip_text   VARCHAR2(4000),
    tooltip_icon   VARCHAR2(4000),
    tooltip_status VARCHAR2(64)

)
/
