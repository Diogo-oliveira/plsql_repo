/*-- Last Change Revision: $Rev: 1469680 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2013-05-21 16:47:37 +0100 (ter, 21 mai 2013) $*/

create or replace package pk_pasthistory_PRM is
		SUBTYPE t_clob IS clob;
		SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
		SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
		SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
		SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

		-- content loader method signature

		-- searcheable loader method signature

		-- frequent loader method signature
		FUNCTION set_clin_serv_ad_freq(i_lang              in language.id_language%type,
																	 i_institution       in institution.id_institution%type,
																	 i_mkt               in table_number,
																	 i_vers              in table_varchar,
																	 i_software          in table_number,
																	 i_clin_serv_in      in table_number,
																	 i_clin_serv_out     in clinical_service.id_clinical_service%type,
																	 i_dep_clin_serv_out in dep_clin_serv.id_dep_clin_serv%type,
																	 o_result_tbl        out number,
																	 o_error             out t_error_out)
				RETURN BOOLEAN;
		-- global vars
		g_error         t_big_char;
		g_flg_available t_flg_char;
		g_active        t_flg_char;
		g_version       t_low_char;
		g_func_name     t_med_char;

		g_array_size  NUMBER;
		g_array_size1 NUMBER;
end pk_pasthistory_PRM;
/
