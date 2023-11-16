CREATE OR REPLACE TYPE t_rec_osdt_task force AS OBJECT
(
    id_order_set          NUMBER(24),
    id_order_set_task     NUMBER(24),
    group_type_id         NUMBER(24),
    id_task_type          NUMBER(24),
    task_link_type        VARCHAR2(10 CHAR),
    task_type_desc        VARCHAR2(4000 CHAR),
    task_title            VARCHAR2(4000 CHAR),
    task_instruct         varchar2(4000 CHAR),
    dependency_desc       VARCHAR2(4000 CHAR),
    order_status_desc     VARCHAR2(4000 CHAR),
    registry              VARCHAR2(4000 CHAR),
    updated              VARCHAR2(4000 CHAR),             
    task_rn               NUMBER(24),
    rn                    NUMBER(24)
)
;
/