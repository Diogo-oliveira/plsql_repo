create or replace type t_rec_screen_detail force as object (
descr varchar2(4000 char),
val varchar2(4000 char),
tipo varchar2(3 char),
flg_status VARCHAR2(1 CHAR)
);
/

CREATE OR REPLACE TYPE t_coll_screen_detail IS TABLE OF t_rec_screen_detail;
/