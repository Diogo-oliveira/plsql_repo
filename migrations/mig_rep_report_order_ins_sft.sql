-- CHANGED BY: ricardo.pires
-- CHANGE DATE: 25/08/2014 
-- CHANGE REASON: ALERT-293378 

-- data migration
declare
  tbl_id_reports table_number;
  tbl_task_type  table_number;

  cursor c_xpto is
    select r.id_reports, r.id_task_type
      from reports r
      join REP_REPORT_ORDER_INS_SFT rrois
        on rrois.id_reports = r.id_reports
     where 1 = 1
          --rrois.id_task_type_context != r.id_task_type
       and r.id_task_type is not null;

begin

  open c_xpto;
  fetch c_xpto bulk collect
    into tbl_id_reports, tbl_task_type;
  close c_xpto;

  forall i in 1 .. tbl_id_reports.count
    UPDATE rep_report_order_ins_sft rrois
       SET rrois.id_task_type_context = tbl_task_type(i)
     WHERE rrois.id_reports = tbl_id_reports(i);
END;
/
