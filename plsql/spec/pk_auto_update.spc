/*-- Last Change Revision: $Rev: 899572 $*/
/*-- Last Change by: $Author: sergio.lopes $*/
/*-- Date of last change: $Date: 2011-03-01 12:32:50 +0000 (ter, 01 mar 2011) $*/

create or replace package pk_auto_update is

  -- Author  : RAFAEL.SANTOS
  -- Created : 28-03-2010 23:13:21
  -- Purpose : Performe content auto-update
  -- Updated : 23-12-2010 by Sergio Lopes

  procedure start_balance(
    i_vers IN VARCHAR2, i_sup_vers IN VARCHAR2
  );
  
  procedure run_job_balance(
    i_vers IN VARCHAR2
  );
  
  procedure run_balance(
    i_id_process IN NUMBER,
    i_vers       IN VARCHAR2
  );
  
/*  FUNCTION auto_update_table
  (
  i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;*/
  
  FUNCTION update_mi_med
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_mi_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_mi_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_med_alrgn_grp
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_med_alrgn_pick_list
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_other_product
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_manip_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_dietary
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_manip
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  

  FUNCTION update_me_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_manip_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;

  
  FUNCTION update_med_alrgn_grp_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_med_alrgn_cross_grp
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  

  FUNCTION update_mi_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_mi_med_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_med_atc_interaction
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_mi_med_atc_interaction
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  

  FUNCTION update_me_dxid_atc_contra
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_mi_dxid_atc_contra
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_med_ingred
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_med_alrgn_cross
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
    
  
  FUNCTION update_me_med
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_icd9_dxid
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;

 
  FUNCTION update_me_med_atc
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_me_med_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_med_regulation
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_me_med_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_med_subst
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_pharm_group
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_regulation
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;


  FUNCTION update_me_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
    FUNCTION update_me_price_type
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_me_med_price_hist_det
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_drug_unit
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  
  FUNCTION update_form_farm_unit
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION update_interact_message_format

  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  FUNCTION update_interact_message
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
  FUNCTION update_mi_med_route
  (
    i_id_process IN NUMBER, i_vers IN VARCHAR2
  ) RETURN BOOLEAN;
  
end pk_auto_update;
/