CREATE OR REPLACE TYPE t_medication_attributes AS OBJECT
(
med_id varchar2(255),
flg_type varchar2(255),
dci_id varchar2(255),
route_id varchar2(255),
dosagem varchar2(255)
);