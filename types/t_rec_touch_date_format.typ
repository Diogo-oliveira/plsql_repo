CREATE OR REPLACE TYPE t_rec_touch_date_format IS OBJECT
(
    date_type        VARCHAR2(200),
    date_type_config VARCHAR2(200),
    format_config    VARCHAR2(200),
    format           VARCHAR2(200)
)
;
