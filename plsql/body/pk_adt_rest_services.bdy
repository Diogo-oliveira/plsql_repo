create or replace package body PK_ADT_REST_SERVICES is
  -- Private variable declarations
  g_error   VARCHAR2(1000 CHAR);
  g_owner   VARCHAR2(30 CHAR);
  g_package VARCHAR2(40 CHAR);

  -- Function and procedure implementations
  FUNCTION create_new_transaction(i_prof profissional, i_lang NUMBER)
    RETURN VARCHAR2 IS
    l_transaction_id      VARCHAR2(4000);
    l_application_context sys_config.id_sys_config%TYPE := 'REST_ADT_CONTEXT';
    l_application_port    sys_config.id_sys_config%TYPE := 'REST_ADT_PORT';
  
  BEGIN
  
    g_error := 'CALL pk_rest_api.GETTRANSACTIONID ERROR GETTING TRANSACTION ID';
    IF NOT
        pk_rest_api.gettransactionid(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_application_context => l_application_context,
                                     i_application_port    => l_application_port,
                                     o_transaction         => l_transaction_id) THEN
      pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                      text_in       => g_error);
    END IF;
  
    g_error := 'CALL pk_rest_api.BEGINTRANSACTION: ' || l_transaction_id;
    IF NOT
        pk_rest_api.begintransaction(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_transaction => l_transaction_id) THEN
      pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                      text_in       => g_error);
    END IF;
  
    RETURN l_transaction_id;
  
  EXCEPTION
    WHEN OTHERS THEN
      pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                      text_in       => g_error);
      RETURN NULL;
  END;

  FUNCTION merge_patient(i_lang          IN NUMBER,
                         i_prof          IN profissional,
                         i_idpatient     IN NUMBER,
                         i_idpatienttemp IN NUMBER) RETURN BOOLEAN IS
    l_http_method varchar2(4 CHAR) := 'POST';
    l_service     varchar2(250 CHAR) := '/internal/identity/patient/' ||
                                        i_idpatient || '/patientTemp/' ||
                                        i_idpatienttemp;
  
    l_status              varchar2(50 CHAR);
    l_data                JSON_ELEMENT_T;
    l_error               JSON_ARRAY_T;
    l_application_context sys_config.id_sys_config%TYPE := 'REST_ADT_CONTEXT';
    l_application_port    sys_config.id_sys_config%TYPE := 'REST_ADT_PORT';
  
  BEGIN
  
    RETURN pk_rest_api.make_internal_rest_request(i_application_context => l_application_context,
                                                  i_application_port    => l_application_port,
                                                  i_service             => l_service,
                                                  i_http_method         => l_http_method,
                                                  i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  o_status              => l_status,
                                                  o_data                => l_data,
                                                  o_error               => l_error);
  
  EXCEPTION
    WHEN OTHERS THEN
      pk_alertlog.log_fatal(text        => 'PK_ADT_REST_SERVICES.MERGE_PATIENT ERROR',
                            object_name => g_package,
                            owner       => g_owner);
      RETURN FALSE;
    
  END merge_patient;

begin
  /* CAN'T TOUCH THIS */
  /* Who am I */
  pk_alertlog.who_am_i(owner => g_owner, name => g_package);
  /* Log init */
  pk_alertlog.log_init(object_name => g_package);
end PK_ADT_REST_SERVICES;
/