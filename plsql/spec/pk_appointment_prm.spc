/*-- Last Change Revision: $Rev: 1469680 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-21 16:47:37 +0100 (ter, 21 mai 2013) $*/

CREATE OR REPLACE PACKAGE pk_appointment_PRM is
		SUBTYPE t_clob IS CLOB;
		SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
		SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
		SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
		SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

		-- content loader method signature
		FUNCTION load_appointment_def(i_lang       IN language.id_language%TYPE,
																	o_result_tbl OUT NUMBER,
																	o_error      OUT t_error_out) RETURN BOOLEAN;
		-- searcheable loader method signature

		-- frequent loader method signature

		--translation methods
		FUNCTION set_appointments_transl(i_lang  IN language.id_language%TYPE,
																		  o_result_tbl OUT NUMBER,
																		 o_error OUT t_error_out) RETURN BOOLEAN;

		-- global vars
		g_error         t_big_char;
		g_flg_available t_flg_char;
		g_active        t_flg_char;
		g_version       t_low_char;
		g_func_name     t_med_char;

		g_array_size  NUMBER;
		g_array_size1 NUMBER;
END pk_appointment_PRM;
/