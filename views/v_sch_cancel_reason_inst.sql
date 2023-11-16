create or replace view v_sch_cancel_reason_inst as
select s.id_sch_cancel_reason_inst,
       s.id_sch_cancel_reason,
       cr.code_cancel_reason,
			 cr.rank,
       s.id_institution,
       s.id_software,
       decode(s.flg_available, 'Y', 'A', 'I')  flg_available
  from sch_cancel_reason_inst s
	join sch_cancel_reason cr on cr.id_sch_cancel_reason = s.id_sch_cancel_reason;