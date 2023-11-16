/*-- Last Change Revision: $Rev: 2027682 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:59 +0100 (ter, 02 ago 2022) $*/
create or replace package body PK_SCHEDULE_LAB_UX is

  /*
  *
  */
  function get_today_lab_appoints
  (
    i_lang             IN language.id_language%TYPE,
    i_prof             IN profissional,
    i_day              IN schedule.dt_begin_tstz%type default null)
  RETURN t_table_sch_lab_daily_apps IS
  BEGIN
    RETURN pk_schedule_lab.get_today_lab_appoints(i_lang => i_lang, 
                                                  i_prof => i_prof,
                                                  i_day => i_day);
  END get_today_lab_appoints;
  
  
  /*
  *  ALERT-303513. Details of a lab schedule 
  */
  FUNCTION get_sch_detail
  (
    i_lang                  IN language.id_language%TYPE,
    i_prof                  IN profissional,
    i_id_schedule           IN schedule.id_schedule%type,
    o_detail                OUT pk_types.cursor_type,
    o_error                 OUT t_error_out
  ) return boolean IS
  BEGIN
    g_error := 'CALL pk_schedule_lab.get_sch_detail. i_id_schedule=' || nvl(to_char(i_id_schedule), 'null');
    pk_schedule_lab.get_sch_detail(i_lang => i_lang, 
                                   i_prof => i_prof, 
                                   i_id_schedule => i_id_schedule, 
                                   o_detail => o_detail);
    return true;
  EXCEPTION
    when others then
      pk_alert_exceptions.process_error(i_lang     => i_lang,
                                        i_sqlcode  => SQLCODE,
                                        i_sqlerrm  => SQLERRM,
                                        i_message  => g_error,
                                        i_owner    => g_package_owner,
                                        i_package  => g_package_name,
                                        i_function => 'GET_SCH_DETAIL',
                                        o_error    => o_error);
      pk_types.open_my_cursor(i_cursor => o_detail);
      RETURN FALSE;
  END get_sch_detail;
    

  /*
  *  ALERT-303513. History of a lab schedule 
  */
  FUNCTION get_sch_hist
  (
    i_lang                  IN language.id_language%TYPE,
    i_prof                  IN profissional,
    i_id_schedule           IN schedule.id_schedule%type,
    o_detail                OUT pk_types.cursor_type,
    o_error                 OUT t_error_out
  ) return boolean IS
  BEGIN
    g_error := 'CALL pk_schedule_lab.get_sch_hist. i_id_schedule=' || nvl(to_char(i_id_schedule), 'null');
    pk_schedule_lab.get_sch_hist(i_lang => i_lang, 
                                 i_prof => i_prof, 
                                 i_id_schedule => i_id_schedule, 
                                 o_detail => o_detail);
                                 
    return true;
  EXCEPTION
    when others then
      pk_alert_exceptions.process_error(i_lang     => i_lang,
                                        i_sqlcode  => SQLCODE,
                                        i_sqlerrm  => SQLERRM,
                                        i_message  => g_error,
                                        i_owner    => g_package_owner,
                                        i_package  => g_package_name,
                                        i_function => 'GET_SCH_HIST',
                                        o_error    => o_error);
      pk_types.open_my_cursor(i_cursor => o_detail);
      RETURN FALSE;
  END get_sch_hist;

begin
  -- Log initialization
    pk_alertlog.log_init(object_name => g_package_name,
                         owner       => g_package_owner);
end PK_SCHEDULE_LAB_UX;
/
