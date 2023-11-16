DROP TYPE "T_TBL_PRESCRIPTION_DETAILS";

CREATE OR REPLACE TYPE "T_PRESCRIPTION_DETAILS" AS OBJECT
(
drug    varchar2(255),
id_drug  varchar2(255),
unique_drug varchar2(255),
med_type varchar2(255),
icon_type varchar2(255),
subject VARCHAR2(255),
record_type  varchar2(255),
record_id    NUMBER(24),
flg_status varchar2(255),
cell_date timestamp with local time zone,
cell_state varchar2(255),
id_presc NUMBER(24),
id_episode  NUMBER(24),
show_presc_emb_list varchar2(1),
show_conversion_list varchar2(1),
vers varchar2(255),
desc_status varchar2(255)
);

CREATE OR REPLACE TYPE "T_TBL_PRESCRIPTION_DETAILS" IS TABLE OF t_prescription_details;