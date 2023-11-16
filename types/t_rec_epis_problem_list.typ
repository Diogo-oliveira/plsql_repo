CREATE OR REPLACE TYPE t_rec_epis_problem_list AS OBJECT
(
    id_pat_problem      VARCHAR2(4000),
		type        VARCHAR2(2),
    id_diagnosis        NUMBER(24),
		id_episode          NUMBER(24),
    problem_desc        VARCHAR2(4000),
    flg_status          VARCHAR(2),
    dt_problem_to_print VARCHAR2(4000),
    nick_name           VARCHAR2(200),
    current_state_desc  VARCHAR2(4000),
    old_state_desc      VARCHAR2(4000),
		full_desc           VARCHAR2(4000)
)
;
/
