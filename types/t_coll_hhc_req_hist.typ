create or replace type t_rec_hhc_req_hist force as object (
descr varchar2(4000 char),
val clob,
tipo varchar2(3 char),
flg_status VARCHAR2(1 CHAR),
id_request number
);
/

CREATE OR REPLACE TYPE t_coll_hhc_req_hist IS TABLE OF t_rec_hhc_req_hist;
/
