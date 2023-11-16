-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH_386
CREATE OR REPLACE VIEW V_COUNTRY AS
SELECT c.id_country, 
       c.code_country, 
       c.flg_available, 
       c.code_nationality, 
       c.alpha2_code, 
       c.id_content
  FROM country c;
  
-- CHANGE END: Telmo Castro