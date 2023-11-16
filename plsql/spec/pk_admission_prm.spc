/*-- Last Change Revision: $Rev: 1786996 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2017-06-16 17:03:16 +0100 (sex, 16 jun 2017) $*/

create or replace package pk_admission_PRM is
		SUBTYPE t_clob IS clob;
		SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
		SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
		SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
		SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

		-- content loader method signature

		-- searcheable loader method signature
		FUNCTION set_wtl_urg_level_search(i_lang        in language.id_language%type,
																			i_institution in institution.id_institution%type,
																			i_mkt         in table_number,
																			i_vers        in table_varchar,
																			i_software    in table_number,
																			o_result_tbl  out number,
																			o_error       out t_error_out)
				RETURN BOOLEAN;
		-- frequent loader method signature

		-- global vars
		g_error         t_big_char;
		g_flg_available t_flg_char;
		g_active        t_flg_char;
		g_version       t_low_char;
		g_func_name     t_med_char;

		g_array_size  NUMBER;
		g_array_size1 NUMBER;
end pk_admission_PRM;
/