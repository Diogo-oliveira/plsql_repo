create or replace view v_sch_dep_type as
SELECT id_sch_dep_type, dep_type, intern_name, code_dep_type, flg_available, code_sched_subtype, dep_type_group, duration
FROM sch_dep_type;
