CREATE OR REPLACE TYPE "TL_REG_DATE_EPIS" AS OBJECT
( actual_date date,
  dt_begin   date,
  dt_end  date,
  ID_EPISODE NUMBER(24), 
  dt_begin_EPIS   date,
  dt_end_EPIS  date,
   ID_SOFTWARE NUMBER(24),
 ID_PATIENT NUMBER(24)
  
)

/

