CREATE OR REPLACE TYPE t_table_epis_hid_hist IS TABLE OF t_rec_epis_hid_hist;

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/01/2010 
-- CHANGE REASON: [ALERT-156910]: Intake and Output-Have the possibility to register bowel movements. 
drop type t_table_epis_hid_hist;

CREATE OR REPLACE TYPE t_rec_epis_hid_hist AS OBJECT
(
    id_history       NUMBER(24),
    dt_history       TIMESTAMP(6)
        WITH LOCAL TIME ZONE,    
    tbl_labels table_varchar,
    tbl_values table_varchar,
    tbl_types         table_varchar,
    tbl_info_labels  table_varchar,
    tbl_info_values  table_varchar

);

CREATE OR REPLACE TYPE t_table_epis_hid_hist IS TABLE OF t_rec_epis_hid_hist;