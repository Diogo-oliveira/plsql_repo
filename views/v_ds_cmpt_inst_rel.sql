create or replace view v_ds_cmpt_inst_rel as 
  SELECT
  id_ds_cmpt_mkt_rel      
  ,id_ds_cmpt_inst_rel     
  ,id_ds_component_parent  
  ,id_ds_component_child   
  ,id_profile_template     
  ,id_institution          
  ,id_software             
  ,id_category             
  ,rank                    
  ,gender                  
  ,age_min_value           
  ,age_min_unit_measure    
  ,age_max_value           
  ,age_max_unit_measure    
  ,id_unit_measure         
  ,id_unit_measure_subtype 
  ,max_len                 
  ,min_len                 
  ,min_value               
  ,max_value               
  ,position                
  --,flg_default_value    
  ,comp_size
  ,comp_offset  
    ,flg_label_visible
  FROM DS_CMPT_INST_REL
  ;

  
