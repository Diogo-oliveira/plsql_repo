-- CHANGED BY: Telmo
-- CHANGE DATE: 02-01-2015
-- CHANGE REASON: ALERT-303513
create type t_sch_hist_upd_info as record (update_date     schedule_hist.dt_update%type,
                                           update_user     schedule_hist.id_prof_update%type);
-- CHANGE END: Telmo
