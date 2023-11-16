CREATE OR REPLACE TYPE t_rec_reminder_param AS OBJECT
(
    id_reminder         NUMBER(24),
    id_reminder_param   NUMBER(24),
    internal_name       VARCHAR2(200 CHAR),
    desc_reminder_param VARCHAR2(1000 CHAR),
    id_sys_list_group   NUMBER(24),
		rank                NUMBER(12)
)
