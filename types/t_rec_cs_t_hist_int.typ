CREATE OR REPLACE TYPE t_rec_cs_t_hist_int force AS OBJECT
(
id_co_sign_hist 	NUMBER(24),
id_co_sign 			NUMBER(24),
id_episode 			NUMBER(24),
id_task_type 		NUMBER(24),
id_action 			NUMBER(24),
id_task 			NUMBER(24),
id_task_group 		NUMBER(24),
id_order_type 		NUMBER(12),
code_order_type 	VARCHAR2(200 CHAR),
id_prof_created 	NUMBER(24),
id_prof_ordered_by 	NUMBER(24),
id_prof_co_signed 	NUMBER(24),
dt_req 				TIMESTAMP(6) WITH LOCAL TIME ZONE,
dt_created 			TIMESTAMP(6) WITH LOCAL TIME ZONE,
dt_ordered_by 		TIMESTAMP(6) WITH LOCAL TIME ZONE,
dt_co_signed 		TIMESTAMP(6) WITH LOCAL TIME ZONE,
flg_status 			VARCHAR2(2 CHAR),
co_sign_notes 		CLOB,
flg_made_auth 		VARCHAR2(1 CHAR)
)
/