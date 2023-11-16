CREATE OR REPLACE TYPE t_rec_sum_act_meds AS OBJECT
(
    drug    varchar2(255),
MED_TYPE varchar2(1),
presc    NUMBER(24),
flg_status varchar2(255),
med_descr varchar2(255),
cell_state varchar2(255),
cell_date timestamp with local time zone
);