CREATE OR REPLACE TYPE todo_list_01_rec force AS OBJECT
(
id_patient          number,
id_episode          number,
id_visit          number,
id_external_request     number,
dt_begin_tstz_e       timestamp with local time zone,
flg_type          varchar2(0100 char),
flg_task          varchar2(0100 char),
icon            varchar2(0100 char),
flg_icon_type         varchar2(0100 char),
task_count          number,
task            VARCHAR2(0200 CHAR),
id_sys_shortcut       NUMBER,
flg_status_e          VARCHAR2(0200 char),
id_schedule         number,
text            varchar2(4000),
prof_name         varchar2(1000 char),
note_name         varchar2(1000 char),
time_to_sort        number(20,10)
);
/

CREATE OR REPLACE TYPE todo_list_01_tbl AS table of todo_list_01_rec;