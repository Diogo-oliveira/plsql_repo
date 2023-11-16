/*-- Last Change Revision: $Rev: 1996759 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2021-08-18 11:48:02 +0100 (qua, 18 ago 2021) $*/
CREATE OR REPLACE PACKAGE pk_tools_ux IS


	 FUNCTION get_institution
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
	
	    FUNCTION get_all_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
	
	
    FUNCTION get_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
	
	FUNCTION create_prof_room
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room        IN table_number,
        i_room_select IN table_varchar,
        i_room_pref   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dcs   IN table_number,
        i_flg   IN table_varchar,
        i_dft   IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

end pk_tools_ux;
/


