--Rui Batista
--2010/01/28
grant select on sys_list to alert_viewer; 

-- CHANGED BY:  Mauro Sousa
-- CHANGE DATE: 01/06/2010 11:54
-- CHANGE REASON: [ALERT-99455] 
GRANT REFERENCES ON SYS_LIST TO alert_default;
-- CHANGE END:  Mauro Sousa

-- CHANGED BY:  Miguel Monteiro
-- CHANGE DATE: 01/07/2020 16:30
-- CHANGE REASON: [ARCH-8121] 
grant select on sys_list to alert_adtcod;
-- CHANGE END:  Miguel Monteiro