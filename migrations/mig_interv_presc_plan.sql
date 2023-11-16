-- CHANGED BY:  Nuno Neves
-- CHANGE DATE: 23/02/2012 09:36
-- CHANGE REASON: [ALERT-220101] 
declare 
  i integer;
   l_id_epis_documentation table_number;
   l_id_interv_presc_plan  table_number;
begin
 
  SELECT DISTINCT (ed.id_epis_documentation) id_epis_documentation, ed.id_epis_context id_interv_presc_plan bulk collect into l_id_epis_documentation,l_id_interv_presc_plan
  FROM epis_documentation ed
  JOIN interv_prescription ip
    ON ed.id_episode = ip.id_episode
  JOIN interv_presc_det ipd
    ON ip.id_interv_prescription = ipd.id_interv_prescription
  JOIN interv_presc_plan ipp
    ON ipp.id_interv_presc_det = ipd.id_interv_presc_det
  JOIN alert.doc_template_context d
    ON ipd.id_intervention = d.id_context
 WHERE ed.id_doc_area = 1082
   AND ipp.id_interv_presc_plan = ed.id_epis_context;
   
   for i in 1 .. l_id_epis_documentation.count loop
     dbms_output.put_line('i= '||i ||' interv_presc_plan = '||l_id_interv_presc_plan(i) ||' epis_doc= '||l_id_epis_documentation(i) );
     
     update interv_presc_plan ipp
     set ipp.id_epis_documentation=l_id_epis_documentation(i)
     where ipp.id_interv_presc_plan=l_id_interv_presc_plan(i)
     and ipp.id_epis_documentation is null;
     
   end loop; 
end;
-- CHANGE END:  Nuno Neves