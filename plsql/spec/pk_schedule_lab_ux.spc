/*-- Last Change Revision: $Rev: 2028956 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:57 +0100 (ter, 02 ago 2022) $*/
create or replace package PK_SCHEDULE_LAB_UX is

  -- Author  : TELMO.CASTRO
  -- Created : 23/12/2014 15:30:59
  -- Purpose : Gateway to the Lab underworld
  
  
  
/* returns all LAB appointments for TODAY, scheduled for the given profissional's intitution.
  * Only appointments WITHOUT requisition. That means no row in table schedule_analysis.
  *
  * @param i_lang                        Language identifier
  * @param i_prof                        Professional data: id, institution and software
  *
  * @RETURN t_table_sch_lab_daily_apps   nested table of t_rec_sch_lab_daily_apps
  *
  * @author  Telmo
  * @version 2.6.3.8
  * @date    03-09-2013
  */
  function get_today_lab_appoints
  (
    i_lang             IN language.id_language%TYPE,
    i_prof             IN profissional,
    i_day              IN schedule.dt_begin_tstz%type default null)
  RETURN t_table_sch_lab_daily_apps;


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
  ) return boolean;
    

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
  ) return boolean;
    
    
 ----------- PUBLIC VARS, CONSTANTS ---------------
    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

end PK_SCHEDULE_LAB_UX;
/
