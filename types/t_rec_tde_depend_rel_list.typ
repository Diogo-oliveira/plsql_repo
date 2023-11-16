-- CHANGED BY: Carlos Loureiro
-- CHANGED DATE: 04-JUL-2010
-- CHANGED REASON: [ALERT-109296] TDE Core versioning (DDL)
CREATE OR REPLACE TYPE t_rec_tde_depend_rel_list AS OBJECT
(
    id_relationship_type    NUMBER(24),
    id_task_dependency_from NUMBER(24),
    id_task_dependency_to   NUMBER(24),
    id_task_type_from       NUMBER(24),
    id_task_type_to         NUMBER(24),
    flg_episode_task_from   VARCHAR2(1 CHAR),
    flg_episode_task_to     VARCHAR2(1 CHAR),    
    flg_depend_support_from VARCHAR2(1 CHAR),
    flg_depend_support_to   VARCHAR2(1 CHAR),
    flg_schedule_from       VARCHAR2(1 CHAR),
    flg_schedule_to         VARCHAR2(1 CHAR),
    lag_min                 NUMBER(24),
    lag_max                 NUMBER(24),
    id_unit_measure_lag     NUMBER(24)
);
-- CHANGE END: Carlos Loureiro
