
CREATE OR REPLACE TYPE tr_co_sign_list force  AS OBJECT (
  id_co_sign       NUMBER(24),
  order_type_icon  VARCHAR2(200),
  desc_co_sign     VARCHAR2(4000),
  desc_co_sign_det VARCHAR2(4000),
  nick_name        VARCHAR2(4000),
  flg_type         VARCHAR2(10),
  dt_order         VARCHAR2(200),
  dt_order_target  VARCHAR2(200),
  h_order_target   VARCHAR2(200),
  m_time_stamp     VARCHAR2(200),
  flg_co_sign      VARCHAR2(10),
  with_notes       VARCHAR2(200),  
  dt_order_reg         TIMESTAMP WITH LOCAL TIME ZONE, 
  desc_co_sign_third_line VARCHAR2(200),  
  co_sign_notes           VARCHAR2(4000)  , 
  co_sign_Type            VARCHAR2(2)
)
/