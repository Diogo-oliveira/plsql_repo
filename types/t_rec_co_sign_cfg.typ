-- CHANGED BY:  Elisabete Bugalho
-- CHANGE DATE: 22/04/2015 
-- CHANGE REASON: [ALERT-310274] 
BEGIN
   pk_versioning.run(i_sql => q'[CREATE OR REPLACE TYPE t_rec_co_sign_cfg force  AS OBJECT
(
	id_task_type          NUMBER(24),
	desc_task_type        VARCHAR2(1000 CHAR),
	icon_task_type        VARCHAR2(200 CHAR),
	flg_task_type         VARCHAR2(2 CHAR),
	id_action             NUMBER(24),
	desc_action           VARCHAR2(1000 CHAR),
	flg_needs_cosign      VARCHAR2(1 CHAR),
	flg_has_cosign        VARCHAR2(1 CHAR),
	id_task_type_action   NUMBER(24),
	func_task_description VARCHAR2(1000 CHAR),
	func_instructions     VARCHAR2(1000 CHAR),
	func_task_action_desc VARCHAR2(1000 CHAR),
	id_config             NUMBER(24),
	id_inst_owner         NUMBER(24)
)
 ]');
 
END;
/
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY:  Nuno Alves
-- CHANGE DATE: 15/10/2015 16:00
-- CHANGE REASON: ALERT-311010 - [EXAMS] Discharge button - Co-sign - Co-sign requests originated from recurrent imaging/other exams are not sorted properly when accessing the co-sign area
DECLARE

    PROCEDURE run_ddl(i_sql IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE i_sql;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('WARNING - ' || REPLACE(srcstr => SQLERRM, oldsub => 'ORA-', newsub => '') || '; ' ||
                                 i_sql || ';');
    END run_ddl;

BEGIN

    run_ddl(i_sql => 'CREATE OR REPLACE TYPE t_rec_co_sign_cfg  force AS OBJECT
(
  id_task_type          NUMBER(24),
  desc_task_type        VARCHAR2(1000 CHAR),
  icon_task_type        VARCHAR2(200 CHAR),
  flg_task_type         VARCHAR2(2 CHAR),
  id_action             NUMBER(24),
  desc_action           VARCHAR2(1000 CHAR),
  flg_needs_cosign      VARCHAR2(1 CHAR),
  flg_has_cosign        VARCHAR2(1 CHAR),
  id_task_type_action   NUMBER(24),
  func_task_description VARCHAR2(1000 CHAR),
  func_instructions     VARCHAR2(1000 CHAR),
  func_task_action_desc VARCHAR2(1000 CHAR),
  func_task_exec_date   VARCHAR2(1000 CHAR),
  id_config             NUMBER(24),
  id_inst_owner         NUMBER(24)
)
 ');

END;
/
-- CHANGE END: Nuno Alves