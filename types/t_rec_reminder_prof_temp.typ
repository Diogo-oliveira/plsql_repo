CREATE OR REPLACE TYPE t_rec_reminder_prof_temp AS OBJECT
(
    id_reminder_param   NUMBER(24),
    id_profile_template NUMBER(24),
    flg_selected_value  VARCHAR2(2 CHAR), -- sys_list_group_rel.flg_context related
    id_recurr_option    NUMBER(24),
    value               VARCHAR2(200 CHAR)
)
