CREATE OR REPLACE TYPE t_rec_odst_mig_link AS OBJECT
(
  order_set_task  NUMBER(24),
  task_type       NUMBER(24),  
  task_link_type  VARCHAR2(1),
  task_link       VARCHAR2(200 CHAR)
);
/