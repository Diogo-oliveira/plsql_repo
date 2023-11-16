CREATE OR REPLACE TYPE t_rec_events_info AS OBJECT
(
   data         VARCHAR2(1000 CHAR),
   id_sch_event VARCHAR2(1000 CHAR),
   label_full   VARCHAR2(4000),
   label        VARCHAR2(4000),
   flg_select   VARCHAR2(1 CHAR),
   order_field  NUMBER(12),
   order_field2 NUMBER(12),
   no_prof      VARCHAR2(1 CHAR)
)
;
/
