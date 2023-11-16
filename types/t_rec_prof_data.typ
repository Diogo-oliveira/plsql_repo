-- CHANGED BY: Joana Barroso
-- CHANGED DATE: 20-06-2013
-- CHANGED REASON: ALERT-260167 

create or replace type t_rec_prof_data as object
(
  id_profile_template NUMBER(24),
  id_functionality    NUMBER(24),
  id_category         NUMBER(24),
  flg_category        VARCHAR2(1CHAR),
  id_market           NUMBER(24));
/  



-- CHANGE END: Joana Barroso
