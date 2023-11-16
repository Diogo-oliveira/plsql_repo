create or replace package PK_ADT_REST_SERVICES is

  -- Author  : NUNO.AMORIM
  -- Created : 04/11/2020 11:19:04
  -- Purpose : Consume REST Services from ADT application

  -- Public function and procedure declarations
  FUNCTION merge_patient(i_lang          IN NUMBER,
                         i_prof          IN profissional,
                         i_idpatient     IN NUMBER,
                         i_idpatienttemp IN NUMBER) RETURN BOOLEAN;

end PK_ADT_REST_SERVICES;
/