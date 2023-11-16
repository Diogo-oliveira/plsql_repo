CREATE OR REPLACE TYPE tr_co_sign_det force  AS OBJECT (
  id_co_sign      NUMBER(24),
  desc_co_sign    VARCHAR2(4000),
  prof_rec        VARCHAR2(4000),
  dt_reg          VARCHAR2(200),
  dt_reg_target   VARCHAR2(200),
  h_reg_target    VARCHAR2(200),
  req_notes       VARCHAR2(4000),
  prof_order      VARCHAR2(4000),
  dt_order        VARCHAR2(200),
  dt_order_target VARCHAR2(200),
  h_order_target  VARCHAR2(200),
  cp_sign_mode    VARCHAR2(4000),
  co_sign_notes   VARCHAR2(200),
  flg_co_sign     VARCHAR2(10),
  co_signed_by    VARCHAR2(4000),
  dt_reg_co_sign  VARCHAR2(200),
  co_sign_date    VARCHAR2(200),
  co_sign_time    VARCHAR2(200), 
  desc_co_sign_third_line VARCHAR2(200), 
  co_sign_Type            VARCHAR2(2)
)
/