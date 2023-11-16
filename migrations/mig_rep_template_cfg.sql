-- CHANGED BY: ricardo.pires
-- CHANGE DATE: 2014-07-04
-- CHANGE REASON: ALERT-289431
--migrate data
BEGIN
   FOR elem_rep_template_cfg IN (select rtc.id_rep_template, rtc.id_doc_area, rtc.id_reports, rtc.id_concept, rtc.id_market, rtc.id_software, rtc.id_institution from rep_template_cfg rtc)                                                                                                                               
       LOOP                                 
            -- move data from id_rep_template to id_doc_template
            UPDATE rep_template_cfg rtc SET rtc.id_doc_template=elem_rep_template_cfg.id_rep_template
            WHERE rtc.id_doc_area=elem_rep_template_cfg.id_doc_area
              AND rtc.id_reports=elem_rep_template_cfg.id_reports
              AND rtc.id_concept=elem_rep_template_cfg.id_concept
              AND rtc.id_market=elem_rep_template_cfg.id_market
              AND rtc.id_software=elem_rep_template_cfg.id_software
              AND rtc.id_institution=elem_rep_template_cfg.id_institution;
     END LOOP; 
 END;
/
-- CHANGE END: ricardo.pires