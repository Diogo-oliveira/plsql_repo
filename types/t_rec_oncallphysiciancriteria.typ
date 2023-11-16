

-- José Brito 27/04/2009 ALERT-10317
CREATE OR REPLACE TYPE t_rec_oncallphysiciancriteria AS OBJECT(id_on_call_physician NUMBER(24),
																															 id_professional NUMBER(24),
																															 name VARCHAR2(200),
																															 id_speciality NUMBER(24),
																															 desc_spec VARCHAR2(200),
																															 title_notes VARCHAR2(200),
																															 dt_start VARCHAR2(4000),
																															 dt_start_extend VARCHAR2(4000),
																															 dt_end VARCHAR2(4000),
																															 dt_end_extend VARCHAR2(4000),
																															 period_status VARCHAR2(1),
																															 period_status_desc VARCHAR2(200));
																															 
																															 