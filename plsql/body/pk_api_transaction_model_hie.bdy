/*-- Last Change Revision: $Rev: 2026742 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:45 +0100 (ter, 02 ago 2022) $*/
create or replace package body PK_API_TRANSACTION_MODEL_HIE is

  /* CAN'T TOUCH THIS */
  g_error    VARCHAR2(1000 CHAR);
  g_owner    VARCHAR2(30 CHAR);
  g_package  VARCHAR2(30 CHAR);
  g_function VARCHAR2(128 CHAR);
  g_exception EXCEPTION;

  -- Author  : LUIS.COSTA
  -- Created : 25-NOV-2011

  /***********************************************************************
                          GLOBAL - Generic Functions
  ***********************************************************************/

  /********************************************************************************************
  * Gets hie transaction model data
  *
  * @return  TRUE if succeeded. FALSE otherwise.
  *
  ********************************************************************************************/
  FUNCTION get_transaction_model_data(i_id_institution IN institution.id_institution%TYPE,
                                      i_id_software    IN software.id_software%TYPE,
                                      i_id_language    IN language.id_language%TYPE,
                                      o_data           OUT pk_types.cursor_type,
                                      o_error          OUT t_error_out)
    RETURN BOOLEAN is
  
  
  begin
  
    g_function := 'get_transaction_model_data';
    g_error    := 'Execution code';
    g_package  := 'PK_API_TRANSACTION_MODEL_HIE';
    g_owner    := 'HIE';
  
    alertlog.pk_alertlog.log_info(text            => g_error,
                                  object_name     => g_package,
                                  sub_object_name => g_function);
  
  
  
  
    OPEN o_data FOR
      select ia.id_currency,
             pk_translation.get_translation(i_id_language,
                                            'CURRENCY.CODE_CURRENCY.' ||
                                            ia.id_currency) desc_currency,
             xft.id_content health_fac_code,
             pk_translation.get_translation(i_id_language,
                                            xft.code_healthcare_facility_type) health_fac_code_display_name,
             pk_sysconfig.get_config('XDS_ALERT_CONTENT_SCHEME', 0, 0) code_coding_scheme,
             i_id_language language_code,
             pk_translation.get_translation(i_id_language,
                                            'LANGUAGE.CODE_LANGUAGE.' ||
                                            i_id_language) language_display_name,
             pk_sysconfig.get_config(i_code_cf   => MY_ALERT_REPORT_UPLOAD_PRICE,
                                     i_prof_inst => i_id_institution,
                                     i_prof_soft => i_id_software) transaction_cost,
             pk_sysconfig.get_config(i_code_cf   => T_M_CODE_REPORT_ODD,
                                     i_prof_inst => i_id_institution,
                                     i_prof_soft => i_id_software) transaction_item_id
        from institution i
       inner join inst_attributes ia
          on i.id_institution = ia.id_institution
        left join xds_healthcare_facility_type xft
          on xft.flg_type = i.flg_type
       where i.id_institution = i_id_institution
         and i.flg_available = 'Y';
  
    RETURN TRUE;
  
  EXCEPTION
    WHEN OTHERS THEN
      pk_alert_exceptions.process_error(i_lang     => i_id_language,
                                        i_sqlcode  => SQLCODE,
                                        i_sqlerrm  => SQLERRM,
                                        i_message  => g_error,
                                        i_owner    => g_owner,
                                        i_package  => g_package,
                                        i_function => g_function,
                                        o_error    => o_error);
      pk_types.open_my_cursor(o_data);
      RETURN FALSE;
    
  END get_transaction_model_data;

begin
  /* CAN'T TOUCH THIS */
  /* Who am I */
  alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
  /* Log init */
  alertlog.pk_alertlog.log_init(object_name => g_package);
end PK_API_TRANSACTION_MODEL_HIE;

/
