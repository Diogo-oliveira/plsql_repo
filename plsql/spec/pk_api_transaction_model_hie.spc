/*-- Last Change Revision: $Rev: 2028498 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:10 +0100 (ter, 02 ago 2022) $*/
create or replace package PK_API_TRANSACTION_MODEL_HIE is

  -- Author  : LUIS.COSTA
  -- Created : 11/24/2011 6:17:20 PM
  -- Purpose : 

  -- Public type declarations

  -- Public constant declarations
  MY_ALERT_REPORT_UPLOAD_PRICE constant varchar2(300) := 'SYS_CONFIG_ADT_PHR_MY_ALERT_REPORT_UPLOAD_PRICE';
  T_M_CODE_REPORT_ODD          constant varchar2(300) := 'SYS_CONFIG_TRANSACTIONAL_MODEL_CODE_REPORT_ODD';

  -- Public variable declarations

  -- Public function and procedure declarations
  FUNCTION get_transaction_model_data(i_id_institution IN institution.id_institution%TYPE,
                                      i_id_software    IN software.id_software%TYPE,
                                      i_id_language    IN language.id_language%TYPE,
                                      o_data           OUT pk_types.cursor_type,
                                      o_error          OUT t_error_out)
    RETURN BOOLEAN;

end PK_API_TRANSACTION_MODEL_HIE;
/