/*-- Last Change Revision: $Rev: 2026902 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_context_api IS

    k_context_name CONSTANT VARCHAR2(0100 CHAR) := 'ALERT_CONTEXT';

    PROCEDURE set_parameter
    (
        p_name  IN VARCHAR2,
        p_value IN VARCHAR2
    ) IS
    BEGIN
        dbms_session.set_context(k_context_name, p_name, p_value);
    END set_parameter;

    PROCEDURE set_context_vars IS
        l_prof_id   NUMBER(24);
        l_prof_inst NUMBER(24);
        l_prof_sw   NUMBER(24);
    BEGIN
    
        SELECT nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), USER),
               to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'),
                         '999999999999999999999999D999',
                         'NLS_NUMERIC_CHARACTERS = ''. '''),
               to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 3, ';'), ',', '.'),
                         '999999999999999999999999D999',
                         'NLS_NUMERIC_CHARACTERS = ''. ''')
          INTO l_prof_id, l_prof_inst, l_prof_sw
          FROM dual;
    
        pk_context_api.set_parameter('i_prof', l_prof_id);
        pk_context_api.set_parameter('i_institution', l_prof_inst);
        pk_context_api.set_parameter('i_software', l_prof_sw);
    END set_context_vars;

    PROCEDURE clear_all_parameters IS
    BEGIN
        dbms_session.clear_context(k_context_name);
    END clear_all_parameters;
	
END pk_context_api;
/
