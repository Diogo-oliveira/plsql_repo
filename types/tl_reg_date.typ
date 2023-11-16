
CREATE OR REPLACE TYPE "TL_REG_DATE" AS OBJECT
( actual_date date,
  dt_begin   date,
  dt_end  date
)

/


-- CHANGED BY: Lu�s Maia
-- CHANGED DATE: 2009-Abr-18
-- CHANGING REASON: Actualiza��o da estrutura do type "TL_REG_DATE".
CREATE OR REPLACE TYPE "TL_REG_DATE" AS OBJECT
( actual_date date,
  dt_begin   date,
  dt_end  date,
  dt_begin_tzh  VARCHAR2(200)
)
/
-- CHANGE END Lu�s Maia

