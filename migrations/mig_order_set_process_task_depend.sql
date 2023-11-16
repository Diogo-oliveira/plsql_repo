
-- #########
-- ## DDL ##
-- #########

-- new id_order_set_process column in order_set_process_task_depend
alter table ORDER_SET_PROCESS_TASK_DEPEND add ID_ORDER_SET_PROCESS NUMBER(24);
comment on column ORDER_SET_PROCESS_TASK_DEPEND.ID_ORDER_SET_PROCESS is 'Order Set process ID';

-- #########
-- ## DML ##
-- #########
UPDATE order_set_process_task_depend a
   SET a.id_order_set_process =
       (SELECT b.id_order_set_process
          FROM order_set_process_task b
         WHERE b.id_order_set_process_task = a.id_order_set_proc_task_to);

COMMIT;
   
-- #########
-- ## DDL ##
-- #########

-- now we can apply constraints to the new column

-- modify column to not null
alter table ORDER_SET_PROCESS_TASK_DEPEND modify ID_ORDER_SET_PROCESS not null;
-- create foreign key
alter table ORDER_SET_PROCESS_TASK_DEPEND add constraint OSPTDP_OSP_FK foreign key (ID_ORDER_SET_PROCESS) references ORDER_SET_PROCESS (ID_ORDER_SET_PROCESS);
-- create index on the new column
create index OSPTDP_ORDER_SET_PROCESS_IDX on ORDER_SET_PROCESS_TASK_DEPEND (ID_ORDER_SET_PROCESS);
-- move created index to the proper tablespace
alter index OSPTDP_ORDER_SET_PROCESS_IDX rebuild tablespace INDEX_M;

