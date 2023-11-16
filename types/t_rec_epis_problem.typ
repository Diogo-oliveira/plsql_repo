CREATE OR REPLACE TYPE t_rec_epis_problem AS object
(
    id_pat_problem      VARCHAR2(4000),
    type        VARCHAR2(2),
		id_diagnosis NUMBER(24),
		id_episode          NUMBER(24),
    desc_problem VARCHAR2(4000),
		nick_name           VARCHAR2(200),
    dt_order            VARCHAR2(14),
    flg_status          VARCHAR2(2),
    dt_pat_problem      VARCHAR2(50),
    dt_problem          VARCHAR2(4000),
    dt_problem_to_print VARCHAR2(4000)
);
/
