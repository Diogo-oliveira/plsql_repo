-- CHANGED BY: Daniel Silva
-- CHANGE DATE: 2012-10-11
-- CHANGE REASON: [ALERT-225529]
CREATE OR REPLACE TYPE t_rec_doc_count_by_cat AS OBJECT
(
    rank              NUMBER,
    id_doc_ori_type   NUMBER,
    desc_ori_type     VARCHAR2(4000),
    num_docs          NUMBER,
    doc_oids          table_varchar
);
/
-- CHANGE END:  daniel.silva

-- CHANGED BY: daniel.silva
-- CHANGE DATE: 2013.09.24
-- CHANGE REASON: [ALERT-265962]
DECLARE
    e_already_dropped EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_dropped, -4043);
BEGIN
  EXECUTE IMMEDIATE 'DROP TYPE t_tbl_rec_doc_count_by_cat force'; 
EXCEPTION 
  WHEN e_already_dropped THEN 
    NULL;
END;
/

CREATE OR REPLACE TYPE t_rec_doc_count_by_cat AS OBJECT
(
    rank              NUMBER,
    id_doc_ori_type   NUMBER,
    desc_ori_type     VARCHAR2(4000),
    num_docs          NUMBER,
    doc_oids          table_varchar,
    id_docs           table_number_id,
    doc_dates         table_timestamp_tstz,
    doc_titles        table_varchar
);

CREATE OR REPLACE TYPE t_tbl_rec_doc_count_by_cat IS TABLE OF t_rec_doc_count_by_cat;
/
-- CHANGE END:  daniel.silva

