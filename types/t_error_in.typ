CREATE OR REPLACE TYPE "T_ERROR_IN" AS OBJECT
(
    id_lang             NUMBER(24),
    obj_owner           VARCHAR2(0200 CHAR),
    object_name         VARCHAR2(0200 CHAR),
    func_proc_name      VARCHAR2(0200 CHAR),
    error_name_in       VARCHAR2(4000),
    error_code_in       VARCHAR2(0200 CHAR),
    err_instance_id_out NUMBER(24),
    user_text           VARCHAR2(4000),
    user_action         VARCHAR2(4000),
    flg_action          VARCHAR2(1 CHAR), -- S=ERROR SYSTEM; D=DEFAULT USER ERROR; U=USER SPECIFIED ERROR
    grab_settings       NUMBER,
    prm01               t_error_parameter,
    prm02               t_error_parameter,
    prm03               t_error_parameter,
    prm04               t_error_parameter,
    prm05               t_error_parameter,
    prm_null            VARCHAR2(0010 CHAR),
    msg_title           VARCHAR2(0200 CHAR),
    flg_msg_type        VARCHAR2(0001 CHAR),

    CONSTRUCTOR FUNCTION t_error_in RETURN SELF AS RESULT,

    MEMBER PROCEDURE initialize,
    MEMBER PROCEDURE set_prm
    (
        i_index IN NUMBER,
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE set_prm01
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE set_prm02
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE set_prm03
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE set_prm04
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE set_prm05
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ),
    MEMBER PROCEDURE print_me,
    MEMBER PROCEDURE set_all
    (
        i_id_lang       IN NUMBER,
        i_sqlcode       IN VARCHAR2,
        i_sqlerrm       IN VARCHAR2,
        i_user_err      IN VARCHAR2,
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2,
        i_action        IN VARCHAR2,
        i_flg_action    IN VARCHAR2,
        i_msg_title     IN VARCHAR2 DEFAULT NULL,
        i_msg_type      IN VARCHAR2 DEFAULT 'E'
    ),
    MEMBER PROCEDURE set_all
    (
        i_id_lang       IN NUMBER,
        i_sqlcode       IN VARCHAR2,
        i_sqlerrm       IN VARCHAR2,
        i_user_err      IN VARCHAR2,
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2
    ),
    MEMBER PROCEDURE set_lang(i_id_lang IN NUMBER),
    MEMBER PROCEDURE set_action
    (
        i_action     IN VARCHAR2,
        i_flg_action IN VARCHAR2
    ),
    MEMBER FUNCTION get_user_action RETURN VARCHAR2,
    MEMBER PROCEDURE set_errors
    (
        i_sqlcode  IN VARCHAR2,
        i_sqlerrm  IN VARCHAR2,
        i_user_err IN VARCHAR2
    ),
    MEMBER PROCEDURE set_msg_type(i_flg_msg_type IN VARCHAR2),
    MEMBER PROCEDURE set_msg_title(i_msg_title IN VARCHAR2),
    MEMBER PROCEDURE set_package_id
    (
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2
    )

)
INSTANTIABLE NOT FINAL
/
CREATE OR REPLACE TYPE BODY t_error_in AS

    CONSTRUCTOR FUNCTION t_error_in RETURN SELF AS RESULT IS
    BEGIN
        initialize;
        RETURN;
    END t_error_in;

    -- ************************************************
    MEMBER PROCEDURE initialize IS
    BEGIN
    
        self.err_instance_id_out := NULL;
        self.prm_null            := NULL;
    
        self.prm01 := t_error_parameter();
        self.prm02 := t_error_parameter();
        self.prm03 := t_error_parameter();
        self.prm04 := t_error_parameter();
        self.prm05 := t_error_parameter();
    
        self.set_package_id(self.prm_null, self.prm_null, self.prm_null);
    
        self.prm04.set_prm(self.prm_null, self.prm_null);
        self.prm05.set_prm(self.prm_null, self.prm_null);
    
        self.set_lang(-1);
        self.set_errors(self.prm_null, self.prm_null, self.prm_null);
        self.err_instance_id_out := -1;
        self.grab_settings       := 0;
        self.set_action(self.prm_null, 'S');
        self.set_msg_title(self.prm_null);
        self.set_msg_type('E');
    
    END initialize;
    -- ################################################

    MEMBER PROCEDURE set_lang(i_id_lang IN NUMBER) IS
    BEGIN
        self.id_lang := i_id_lang;
    END set_lang;

    MEMBER PROCEDURE set_action
    (
        i_action     IN VARCHAR2,
        i_flg_action IN VARCHAR2
    ) IS
    BEGIN
        self.user_action := i_action;
        self.flg_action  := i_flg_action;
    END set_action;

    MEMBER PROCEDURE set_prm
    (
        i_index IN NUMBER,
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
    BEGIN
    
        IF i_index = 0
        THEN
            NULL;
        ELSIF i_index = 1
        THEN
            self.set_prm01(i_name, i_value);
        ELSIF i_index = 2
        THEN
            self.set_prm02(i_name, i_value);
        ELSIF i_index = 3
        THEN
            self.set_prm03(i_name, i_value);
        ELSIF i_index = 4
        THEN
            self.set_prm04(i_name, i_value);
        ELSIF i_index = 5
        THEN
            self.set_prm05(i_name, i_value);
        END IF;
    
    END set_prm;

    MEMBER PROCEDURE set_prm01
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_name  VARCHAR2(0100);
        l_value VARCHAR2(4000);
    BEGIN
        l_name  := nvl(i_name, 'OWNER');
        l_value := nvl(i_value, self.prm_null);
    
        self.prm01.set_prm(l_name, l_value);
    END set_prm01;

    MEMBER PROCEDURE set_prm02
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_name  VARCHAR2(0100);
        l_value VARCHAR2(4000);
    BEGIN
        l_name  := nvl(i_name, 'PACKAGE');
        l_value := nvl(i_value, self.prm_null);
    
        self.prm02.set_prm(l_name, l_value);
    END set_prm02;

    MEMBER PROCEDURE set_prm03
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_name  VARCHAR2(0100);
        l_value VARCHAR2(4000);
    BEGIN
        l_name  := nvl(i_name, 'FUNCTION');
        l_value := nvl(i_value, self.prm_null);
    
        self.prm03.set_prm(l_name, l_value);
    END set_prm03;

    MEMBER PROCEDURE set_prm04
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_name  VARCHAR2(0100);
        l_value VARCHAR2(4000);
    BEGIN
        l_name  := nvl(i_name, self.prm_null);
        l_value := nvl(i_value, self.prm_null);
    
        self.prm04.set_prm(l_name, l_value);
    END set_prm04;

    MEMBER PROCEDURE set_prm05
    (
        i_name  IN VARCHAR2,
        i_value IN VARCHAR2
    ) IS
        l_name  VARCHAR2(0100);
        l_value VARCHAR2(4000);
    BEGIN
        l_name  := nvl(i_name, self.prm_null);
        l_value := nvl(i_value, self.prm_null);
    
        self.prm05.set_prm(l_name, l_value);
    END set_prm05;

    -- ****************************************************************************
    MEMBER PROCEDURE set_package_id
    (
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2
    ) IS
    BEGIN
    
        self.obj_owner      := i_owner;
        self.object_name    := i_pck_name;
        self.func_proc_name := i_function_name;
    
        self.set_prm(1, 'OWNER', i_owner);
        self.set_prm(2, 'PACKAGE', i_pck_name);
        self.set_prm(3, 'FUNCTION', i_function_name);
    
    END set_package_id;

    MEMBER PROCEDURE set_errors
    (
        i_sqlcode  IN VARCHAR2,
        i_sqlerrm  IN VARCHAR2,
        i_user_err IN VARCHAR2
    ) IS
    BEGIN
    
        self.error_name_in := i_sqlerrm;
        self.error_code_in := i_sqlcode;
        self.user_text     := i_user_err;
    
    END set_errors;

    MEMBER PROCEDURE set_msg_type(i_flg_msg_type IN VARCHAR2) IS
    BEGIN
        self.flg_msg_type := i_flg_msg_type;
    END set_msg_type;

    MEMBER PROCEDURE set_msg_title(i_msg_title IN VARCHAR2) IS
    BEGIN
        self.msg_title := i_msg_title;
    END set_msg_title;

    -- ************************************************
    MEMBER PROCEDURE print_me IS
    BEGIN
    
        dbms_output.put_line('LANG               :' || self.id_lang);
        dbms_output.put_line('OWNER              :' || self.obj_owner);
        dbms_output.put_line('OBJECT_NAME        :' || self.object_name);
        dbms_output.put_line('func_proc_name     :' || self.func_proc_name);
        dbms_output.put_line('ERROR_NAME_IN      :' || self.error_name_in);
        dbms_output.put_line('ERROR_CODE_IN      :' || self.error_code_in);
        dbms_output.put_line('ERR_INSTANCE_ID_OUT:' || self.err_instance_id_out);
        dbms_output.put_line('USER_TEXT          :' || self.user_text);
        dbms_output.put_line('GRAB_SETTINGS      :' || self.grab_settings);
        dbms_output.put_line('MSG_TITLE          :' || self.msg_title);
        dbms_output.put_line('FLG_MSG_TYPE       :' || self.flg_msg_type);
    
    END print_me;
    -- ################################################

    MEMBER PROCEDURE set_all
    (
        i_id_lang       IN NUMBER,
        i_sqlcode       IN VARCHAR2,
        i_sqlerrm       IN VARCHAR2,
        i_user_err      IN VARCHAR2,
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2,
        i_action        IN VARCHAR2,
        i_flg_action    IN VARCHAR2,
        i_msg_title     IN VARCHAR2 DEFAULT NULL,
        i_msg_type      IN VARCHAR2 DEFAULT 'E'
    ) IS
    BEGIN
    
        self.set_lang(i_id_lang);
        self.set_errors(i_sqlcode, i_sqlerrm, i_user_err);
        self.set_package_id(i_owner, i_pck_name, i_function_name);
        self.set_action(i_action, i_flg_action);
        self.set_msg_title(i_msg_title);
        self.set_msg_type(i_msg_type);
    
    END set_all;

    MEMBER PROCEDURE set_all
    (
        i_id_lang       IN NUMBER,
        i_sqlcode       IN VARCHAR2,
        i_sqlerrm       IN VARCHAR2,
        i_user_err      IN VARCHAR2,
        i_owner         IN VARCHAR2,
        i_pck_name      IN VARCHAR2,
        i_function_name IN VARCHAR2
    ) IS
    BEGIN
    
        self.set_all(i_id_lang, i_sqlcode, i_sqlerrm, i_user_err, i_owner, i_pck_name, i_function_name, NULL, 'S');
    
    END set_all;

    MEMBER FUNCTION get_user_action RETURN VARCHAR2 IS
        l_s_msg  VARCHAR2(4000);
        l_u_msg  VARCHAR2(4000);
        l_d_msg  VARCHAR2(4000);
        l_return VARCHAR2(4000);
    BEGIN
    
        l_s_msg := pk_message.get_message(self.id_lang, 'COMMON_M001');
        l_d_msg := pk_message.get_message(self.id_lang, 'ERROR_LABEL_10');
        l_u_msg := self.user_action;
    
        l_return := l_s_msg;
        IF self.flg_action = 'U'
        THEN
            l_return := l_u_msg;
        ELSIF self.flg_action = 'D'
        THEN
            l_return := l_d_msg;
        END IF;
    
        RETURN l_return;
    
    END get_user_action;

END;
/
