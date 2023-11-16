-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 2010-03-12
-- CHANGE REASON: ALERT-81106
-->T_REC_WTL_SKIS|type
CREATE OR REPLACE TYPE "T_REC_WTL_SKIS" AS OBJECT
(
    id_wtl_sort_key           NUMBER(24),
    rank                      NUMBER(24),
	  id_wtl_checklist	        NUMBER(24),
		value                     VARCHAR(200)		
);

-- CHANGED BY: Telmo
-- CHANGE DATE: 28-03-2012
-- CHANGE REASON: ALERT-225382
DROP TYPE T_TABLE_WTL_SKIS; 

CREATE OR REPLACE TYPE T_REC_WTL_SKIS AS OBJECT
(
    id_wtl_sort_key           NUMBER(24),
    rank                      NUMBER(24),
	id_wtl_checklist	        NUMBER(24),
	value                     VARCHAR2(200),
    internal_name             VARCHAR2(200)
);

CREATE OR REPLACE TYPE T_TABLE_WTL_SKIS AS TABLE OF T_REC_WTL_SKIS;

--CHANGE END: Telmo


-- CHANGED BY: Telmo
-- CHANGE DATE: 28-03-2012
-- CHANGE REASON: ALERT-225382
DROP TYPE T_TABLE_WTL_SKIS; 
/
CREATE OR REPLACE TYPE T_REC_WTL_SKIS AS OBJECT
(
    id_wtl_sort_key           NUMBER(24),
    rank                      NUMBER(24),
	id_wtl_checklist	        NUMBER(24),
	value                     VARCHAR2(200),
    internal_name             VARCHAR2(200)
);
/
CREATE OR REPLACE TYPE T_TABLE_WTL_SKIS AS TABLE OF T_REC_WTL_SKIS;
/
--CHANGE END: Telmo