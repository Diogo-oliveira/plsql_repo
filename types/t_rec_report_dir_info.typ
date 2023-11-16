create or replace type t_rec_report_dir_info as object
(
				id_presc_directions number(24),
				id_presc_dir_interval number(24),
				dt_begin varchar2(4000),
				dt_end varchar2(4000),
				duration varchar2(4000),
				dose varchar2(4000),
				frequency_desc varchar2(4000),
				hours varchar2(4000),
				notes varchar2(4000),
				route	varchar2(4000)
);