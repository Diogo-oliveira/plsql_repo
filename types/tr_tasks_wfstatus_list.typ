create or replace type tr_tasks_wfstatus_list as object (
  id_task number(24), 
	id_susp_task number(24),
  desc_task varchar2(4000),
  epis_type varchar2(4000),
	dt_task varchar2(4000),
	flg_context varchar2(100)
);
/