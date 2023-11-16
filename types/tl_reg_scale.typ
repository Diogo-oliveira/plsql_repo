CREATE OR REPLACE TYPE "ALERT"."TL_REG_SCALE" AS OBJECT
( block varchar2(200),
  upper_axis varchar2(50),
  lower_axis varchar2(50),
  dt_begin   date,
  dt_end  date  
)

/



