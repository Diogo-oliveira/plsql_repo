create or replace type t_rec_pharm_drug as object 
(
    id_drug_req_det number(24),
    id_status number(24),
    drug_desc varchar2(4000),
    status_desc varchar2(4000),
    req_date varchar2(4000)
);
