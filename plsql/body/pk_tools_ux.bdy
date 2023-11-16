/*-- Last Change Revision: $Rev: 1996760 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2021-08-18 11:50:03 +0100 (qua, 18 ago 2021) $*/
CREATE OR REPLACE PACKAGE BODY pk_tools_ux IS

    /* CAN'T TOUCH THIS */
    g_owner     VARCHAR2(30 CHAR);
  g_package_name  VARCHAR2(30 CHAR);



   FUNCTION get_institution
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN is
  begin

        RETURN pk_tools.get_institution(i_lang => i_lang, i_prof => i_prof, o_list => o_list, o_error => o_error);

  end get_institution;

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN is
  begin

        RETURN pk_tools.get_department(i_lang  => i_lang,
                                       i_prof  => i_prof,
                                       i_inst  => i_inst,
                                       o_list  => o_list,
                                       o_error => o_error);

  end get_department;

      FUNCTION get_all_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN is
  begin

        RETURN pk_tools.get_all_service(i_lang  => i_lang,
                                        i_prof  => i_prof,
                                        i_dep   => i_dep,
                                        o_list  => o_list,
                                        o_error => o_error);

  end get_all_service;


    FUNCTION get_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN is
  begin

        RETURN pk_tools.get_prof_room(i_lang  => i_lang,
                                      i_prof  => i_prof,
                                      i_inst  => i_inst,
                                      i_dep   => i_dep,
                                      o_list  => o_list,
                                      o_error => o_error);

  end get_prof_room;

  FUNCTION create_prof_room
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room        IN table_number,
        i_room_select IN table_varchar,
        i_room_pref   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN is
  begin

        RETURN pk_tools.create_prof_room(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_room        => i_room,
                                         i_room_select => i_room_select,
                                         i_room_pref   => i_room_pref,
                                         o_error       => o_error);
    END create_prof_room;

    FUNCTION get_service
        (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_tools.get_service(i_lang  => i_lang,
                                    i_prof  => i_prof,
                                    i_dep   => i_dep,
                                    o_list  => o_list,
                                    o_error => o_error);
    
    END get_service;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_tools.get_dep_clin_serv(i_lang  => i_lang,
                                          i_prof  => i_prof,
                                          i_dep   => i_dep,
                                          o_dcs   => o_dcs,
                                          o_error => o_error);
    END get_dep_clin_serv;

    FUNCTION set_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dcs   IN table_number,
        i_flg   IN table_varchar,
        i_dft   IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    begin
        RETURN pk_tools.set_dep_clin_serv(i_lang  => i_lang,
                                          i_prof  => i_prof,
                                          i_dcs   => i_dcs,
                                          i_flg   => i_flg,
                                          i_dft   => i_dft,
                                          o_error => o_error);
    
    END set_dep_clin_serv;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
END pk_tools_ux;
