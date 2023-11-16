
-- #########
-- ## DDL ##
-- #########

-- order_set_task_dependency
alter table ORDER_SET_TASK_DEPENDENCY add ID_ORDER_SET NUMBER(24);
comment on column ORDER_SET_TASK_DEPENDENCY.ID_ORDER_SET is 'Order Set ID';

-- #########
-- ## DML ##
-- #########
UPDATE ORDER_SET_TASK_DEPENDENCY a
   SET a.id_order_set =
       (SELECT b.id_order_set
          FROM order_set_task b
         WHERE b.id_order_set_task = a.id_order_set_task_to);

COMMIT;
   
-- #########
-- ## DDL ##
-- #########

-- now we can apply constraints to the new column

-- modify column to not null
alter table ORDER_SET_TASK_DEPENDENCY modify ID_ORDER_SET not null;
-- create foreign key
alter table ORDER_SET_TASK_DEPENDENCY add constraint OSTDP_ODST_FK foreign key (ID_ORDER_SET) references ORDER_SET (ID_ORDER_SET);
-- create index on the new column
create index OSTDP_ORDER_SET_IDX on ORDER_SET_TASK_DEPENDENCY (ID_ORDER_SET);
-- move created index to the proper tablespace
alter index OSTDP_ORDER_SET_IDX rebuild tablespace INDEX_M;



