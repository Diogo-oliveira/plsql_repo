create or replace TYPE g_rec_list_treat_manag_notes as object(
        id_treat_manag                      NUMBER(24),
		desc_treat_manag                    VARCHAR2(1000),
		desc_treatment_management           VARCHAR2(4000),
        dt_treat_manag                      VARCHAR2(1000),
        date_target                         VARCHAR2(1000),
        hour_target                         VARCHAR2(1000),
        timestamp_target                    VARCHAR2(1000),
        prof_name                           VARCHAR2(1000),
        desc_speciality				        VARCHAR2(1000));
				
				
create or replace TYPE g_rec_list_treat_manag_notes as object(
        id_treat_manag                      NUMBER(24),
		    desc_treat_manag                    VARCHAR2(1000 CHAR),
		    desc_treatment_management           VARCHAR2(1000 CHAR),
        dt_treat_manag                      VARCHAR2(1000 CHAR),
        date_target                         VARCHAR2(1000 CHAR),
        hour_target                         VARCHAR2(1000 CHAR),
        timestamp_target                    VARCHAR2(1000 CHAR),
        prof_name                           VARCHAR2(1000 CHAR),
        desc_speciality				              VARCHAR2(1000 CHAR));
/
