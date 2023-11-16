-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
begin
update task_timeline_ea ttea
set ttea.id_ref_group = (SELECT m.id_monitorization FROM monitorization_vs m
                        where m.id_monitorization_vs = ttea.id_task_refid)
where ttea.id_tl_task = 6;
end;
/

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 26/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
begin
update task_timeline_ea ttea
set ttea.id_ref_group = (SELECT m.id_monitorization FROM monitorization_vs m
                        where m.id_monitorization_vs = ttea.id_task_refid)
where ttea.id_tl_task = 6;
end;
/
