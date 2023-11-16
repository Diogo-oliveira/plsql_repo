-- CHANGED BY: pedro.henriques
-- CHANGE DATE: 30/05/2016 09:31
-- CHANGE REASON: [320999] 
DECLARE 


 
         CURSOR c_supplies IS
    SELECT es.id_episode, es.id_epis_context, 
                DECODE(es.flg_type,'I','P','D','M',es.flg_type) as flg_type , es.id_professional,
                pk_translation.get_translation((SELECT id_language FROM prof_preferences WHERE ID_PROFESSIONAL = es.id_professional AND id_software = ei.id_software AND id_institution = v.id_institution ), s.code_supplies) || DECODE(esd.qty,NULL,'', ' (' || esd.qty || ')') as desc_supplies
            FROM epis_supplies es
                        INNER JOIN epis_supplies_det esd ON es.id_epis_supplies = esd.id_epis_supplies
                        INNER JOIN  supplies s ON esd.id_supplies = s.id_supplies
                        INNER JOIN episode ep ON ep.id_episode = es.id_episode
INNER JOIN visit v ON v.id_visit = ep.id_visit
        INNER JOIN epis_info ei ON ep.id_episode = ei.id_episode;


 TYPE t_supplies IS TABLE OF c_supplies%ROWTYPE;
         l_supplies_tab t_supplies; 


 function get_supplies return t_supplies  is
tbl_supplies t_supplies;
begin

OPEN c_supplies;
    FETCH c_supplies BULK COLLECT INTO l_supplies_tab;
                CLOSE c_supplies;
  
                return l_supplies_tab;
    
        end get_supplies;

  
BEGIN
     l_supplies_tab := get_supplies();  
     
     forall idx in 1..l_supplies_tab.count 
      insert into supply_workflow
        (ID_SUPPLY_WORKFLOW ,ID_EPISODE,ID_SUPPLY, ID_PROFeSSIONAL,ID_CONTEXT,FLG_CONTEXT, FLG_STATUS, DT_SUPPLY_WORKFLOW, ID_SUPPLY_AREA,SUPPLY_MIGRATION)
        values
        (seq_supply_workflow.nextval,l_supplies_tab(idx).id_episode,21563,l_supplies_tab(idx).id_professional,l_supplies_tab(idx).id_epis_context,l_supplies_tab(idx).flg_type,'R', SYSDATE, 1, l_supplies_tab(idx).desc_supplies); 
     
         forall idx in 1..l_supplies_tab.count 
insert into supply_workflow_hist
(ID_SUPPLY_WORKFLOW_HIST ,ID_SUPPLY_WORKFLOW, ID_EPISODE,ID_SUPPLY, ID_PROFeSSIONAL,ID_CONTEXT,FLG_CONTEXT, FLG_STATUS, DT_SUPPLY_WORKFLOW, ID_SUPPLY_AREA,SUPPLY_MIGRATION)
values
(seq_supply_workflow_hist.nextval,seq_supply_workflow.currval,l_supplies_tab(idx).id_episode,21563,l_supplies_tab(idx).id_professional,l_supplies_tab(idx).id_epis_context,l_supplies_tab(idx).flg_type,'R', SYSDATE, 1,l_supplies_tab(idx).desc_supplies); 
     
     
     COMMIT;
END;
-- CHANGE END: pedro.henriques