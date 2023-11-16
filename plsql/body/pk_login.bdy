/*-- Last Change Revision: $Rev: 2027332 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_login IS

    k_no         CONSTANT VARCHAR2(0001 CHAR) := 'N';
    k_yes        CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    k_all        CONSTANT NUMBER(24) := 0;
    k_zero_value CONSTANT NUMBER(24) := 0;

    TYPE t_tbl_config IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(200 CHAR);
    TYPE t_tbl_cat IS TABLE OF category%ROWTYPE INDEX BY BINARY_INTEGER;

    t_list_config table_varchar := table_varchar('PROF_ROOM_PREF',
                                                 'SOFTWARE_ID_OUTP',
                                                 'SOFTWARE_ID_CARE',
                                                 'SOFTWARE_ID_EDIS',
                                                 'SOFTWARE_ID_CLINICS',
                                                 'SOFTWARE_ID_UBU',
                                                 'SOFTWARE_ID_TRIAGE',
                                                 'SOFTWARE_ID_NUTRI',
                                                 'SOFTWARE_ID_INP',
                                                 'SOFTWARE_ID_ORIS',
                                                 'SOFTWARE_ID_AT',
                                                 'SOFTWARE_ID_ITECH',
                                                 'SOFTWARE_ID_RT',
                                                 'SOFTWARE_ID_ASSIST',
                                                 'SOFTWARE_ID_PHISIOTERAPY',
                                                 'SOFTWARE_ID_BACKOFFICE',
                                                 'LOGIN_TOOLS',
                                                 'PROFILE_DOCTOR',
                                                 'PROFILE_NURSE',
                                                 'ID_EPIS_TYPE_EDIS',
                                                 'ID_EPIS_TYPE_INPATIENT',
                                                 'ID_EPIS_TYPE_INPATIENT_LUDOTHERAPY',
                                                 'SOFTWARE_ID_CM',
                                                 'APPLICATION_TIMEOUT',
                                                 'PROFILE_ADMINISTRADOR',
                                                 'SOFTWARE_ID_P1',
                                                 'SOFTWARE_ID_CODING',
                                                 'SOFTWARE_ID_PHAMACY');

    FUNCTION iif
    (
        i_exp   IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        IF i_exp
        THEN
            l_return := i_true;
        ELSE
            l_return := i_false;
        END IF;
    
        RETURN l_return;
    
    END iif;

    FUNCTION return_row_v(i_tbl IN table_varchar) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        END IF;
    
        RETURN l_return;
    
    END return_row_v;

    FUNCTION return_row_n(i_tbl IN table_number) RETURN NUMBER IS
    
        l_return NUMBER(24);
    
    BEGIN
    
        IF i_tbl.count > 0
        THEN
            l_return := i_tbl(1);
        END IF;
    
        RETURN l_return;
    
    END return_row_n;

    FUNCTION initialize_config
    (
        i_id_prof IN profissional,
        i_tbl_cfg IN table_varchar
    ) RETURN t_tbl_config IS
    
        l_tbl_cfg t_tbl_config;
    
    BEGIN
    
        <<load_all_soft_sys_config>>
        FOR i IN 1 .. i_tbl_cfg.count
        LOOP
            l_tbl_cfg(i_tbl_cfg(i)) := pk_sysconfig.get_config(i_tbl_cfg(i), i_id_prof);
        END LOOP load_all_sys_config;
    
        RETURN l_tbl_cfg;
    
    END initialize_config;

    FUNCTION get_prof_num_mecan
    (
        i_prof_id        IN NUMBER,
        i_id_institution IN NUMBER
    ) RETURN VARCHAR2 IS
    
        tbl_num table_varchar := table_varchar();
        l_num   prof_institution.num_mecan%TYPE;
    
    BEGIN
    
        SELECT num_mecan
          BULK COLLECT
          INTO tbl_num
          FROM prof_institution
         WHERE id_professional = i_prof_id
           AND id_institution = i_id_institution;
    
        l_num := return_row_v(tbl_num);
    
        RETURN l_num;
    
    END get_prof_num_mecan;

    FUNCTION get_cat_info(i_prof IN profissional) RETURN category%ROWTYPE IS
    
        t_cat t_tbl_cat;
        r_cat category%ROWTYPE;
    
    BEGIN
    
        SELECT cat.*
          BULK COLLECT
          INTO t_cat
          FROM prof_cat pc
          JOIN category cat
            ON (cat.id_category = pc.id_category)
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        IF t_cat.count > k_zero_value
        THEN
            r_cat := t_cat(1);
        ELSE
            r_cat := NULL;
        END IF;
    
        RETURN r_cat;
    
    END get_cat_info;

    FUNCTION check_if_room_pref_exist(i_id_prof IN profissional) RETURN BOOLEAN IS
    
        l_count NUMBER(24);
        l_bool  BOOLEAN;
    
    BEGIN
    
        --(Verificar se para o software em questão profissional já tem uma sala preferencial)
        -- Esta alteração é importante para a criação de episódios temporários no EDIS
    
        SELECT COUNT(1)
          INTO l_count
          FROM prof_room
         WHERE id_professional = i_id_prof.id
           AND id_room IN (SELECT r.id_room
                             FROM room r
                             JOIN department d
                               ON (d.id_department = r.id_department)
                             JOIN software_dept sd
                               ON (sd.id_dept = d.id_dept)
                            WHERE d.id_institution = i_id_prof.institution
                              AND sd.id_software = i_id_prof.software)
           AND flg_pref = k_yes;
    
        l_bool := l_count > 0;
    
        RETURN l_bool;
    
    END check_if_room_pref_exist;

    FUNCTION get_pck_shortcut
    (
        i_id_prof     IN profissional,
        i_name        IN VARCHAR2,
        i_profile     IN NUMBER,
        i_prof_parent IN NUMBER
    ) RETURN NUMBER IS
    
        l_tbl table_number;
        k_pattern CONSTANT VARCHAR2(0050 CHAR) := 'ALERT';
        l_value         VARCHAR2(0010 CHAR);
        l_flg_dont_jump BOOLEAN := FALSE;
    
        l_return NUMBER(24) := NULL;
    
    BEGIN
    
        IF instr(upper(i_name), k_pattern) > 0
        THEN
        
            l_value := pk_sysconfig.get_config('JUMP_TO_ALERT_SCREEN_ON_INIT', i_id_prof);
            -- check if jump to alert screen is enable
            l_flg_dont_jump := (l_value = k_no);
        END IF;
    
        IF l_flg_dont_jump
        THEN
            l_return := NULL;
        ELSE
        
            SELECT id_sys_shortcut
              BULK COLLECT
              INTO l_tbl
              FROM (SELECT s.id_sys_shortcut, s.id_institution
                      FROM sys_shortcut s
                      JOIN profile_templ_access pa
                        ON (pa.id_software = s.id_software)
                     WHERE s.intern_name = i_name
                       AND s.id_software = i_id_prof.software
                       AND pa.id_profile_template = i_prof_parent
                       AND pa.flg_add_remove = pk_access.g_flg_type_add
                       AND s.id_institution IN (k_all, i_id_prof.institution)
                       AND (pa.id_sys_shortcut = s.id_sys_shortcut OR
                           s.id_sys_shortcut = (SELECT ss.id_parent
                                                   FROM sys_shortcut ss
                                                  WHERE ss.id_shortcut_pk = pa.id_shortcut_pk))
                       AND NOT EXISTS (SELECT k_zero_value
                              FROM profile_templ_access p
                             WHERE p.id_profile_template = i_profile
                               AND p.id_sys_button_prop = s.id_sys_button_prop
                               AND p.flg_add_remove = pk_access.g_flg_type_remove)
                    UNION ALL
                    SELECT s.id_sys_shortcut, s.id_institution
                      FROM sys_shortcut s
                      JOIN profile_templ_access pa
                        ON (pa.id_software = s.id_software)
                     WHERE s.intern_name = i_name
                       AND s.id_software = i_id_prof.software
                       AND pa.flg_add_remove = pk_access.g_flg_type_add
                       AND pa.id_profile_template = i_profile
                       AND s.id_institution IN (k_all, i_id_prof.institution)
                       AND (pa.id_sys_shortcut = s.id_sys_shortcut OR
                           s.id_sys_shortcut = (SELECT ss.id_parent
                                                   FROM sys_shortcut ss
                                                  WHERE ss.id_shortcut_pk = pa.id_shortcut_pk))
                     ORDER BY id_institution DESC, id_sys_shortcut ASC);
        
            l_return := return_row_n(l_tbl);
        
        END IF; -- L_FLG_DONT_JUMP
    
        RETURN l_return;
    
    END get_pck_shortcut;

    FUNCTION check_if_prof_is_resp
    (
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE
    ) RETURN BOOLEAN IS
    
        l_count  NUMBER(24);
        l_return BOOLEAN := FALSE;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_info ei
          JOIN episode epis
            ON (ei.id_episode = epis.id_episode)
         WHERE (ei.id_professional = i_prof.id OR ei.id_first_nurse_resp = i_prof.id)
           AND epis.flg_status = g_epis_active
           AND epis.id_epis_type = i_id_epis_type;
    
        l_return := l_count > 0;
    
        RETURN l_return;
    
    END check_if_prof_is_resp;

    FUNCTION check_if_user_is_profile_admin(i_prof IN profissional) RETURN BOOLEAN IS
    
        l_return BOOLEAN := FALSE;
        l_count  NUMBER(24);
        l_id     profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        l_id := pk_sysconfig.get_config('PROFILE_ADMINISTRADOR', i_prof);
    
        SELECT COUNT(1)
          INTO l_count
          FROM prof_profile_template
         WHERE id_professional = i_prof.id
           AND id_profile_template = l_id
           AND id_software = i_prof.software
           AND id_institution = i_prof.institution;
    
        l_return := l_count > 0;
    
        RETURN l_return;
    
    END check_if_user_is_profile_admin;

    FUNCTION check_prof_dcs_default(i_prof IN profissional) RETURN BOOLEAN IS
    
        l_return BOOLEAN := FALSE;
        l_count  NUMBER(24);
        k_pdcs_flg_status  CONSTANT VARCHAR2(1 CHAR) := g_selected;
        k_pdcs_flg_default CONSTANT VARCHAR2(1 CHAR) := k_yes;
    
    BEGIN
    
        -- validar se tem serviço por defeito
        SELECT COUNT(1)
          INTO l_count
          FROM prof_dep_clin_serv pdcs
          JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
          JOIN department dpt
            ON dpt.id_department = dcs.id_department
          JOIN software_dept sdt
            ON dpt.id_dept = sdt.id_dept
         WHERE pdcs.flg_default = k_pdcs_flg_default
           AND sdt.id_software = i_prof.software
           AND pdcs.flg_status = k_pdcs_flg_status
           AND pdcs.id_professional = i_prof.id;
    
        l_return := l_count > 0;
        RETURN l_return;
    
    END check_prof_dcs_default;

    PROCEDURE upd_prof_soft_inst(i_id_prof IN profissional) IS
    
    BEGIN
    
        UPDATE prof_soft_inst
           SET flg_log = k_yes, dt_log_tstz = current_timestamp
         WHERE id_professional = i_id_prof.id
           AND id_software = i_id_prof.software
           AND id_institution = i_id_prof.institution;
    
    END upd_prof_soft_inst;

    FUNCTION set_login
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_state professional.flg_state%TYPE;
        l_next      prof_in_out.id_prof_in_out%TYPE;
        l_insert    BOOLEAN := FALSE;
        l_char      VARCHAR2(1);
    
        CURSOR c_state IS
            SELECT p.flg_state
              FROM professional p
             WHERE p.id_professional = i_id_prof.id;
    
        CURSOR c_inout IS
            SELECT 'X'
              FROM prof_in_out
             WHERE id_professional = i_id_prof.id
               AND id_institution = i_id_prof.institution
               AND id_software = i_id_prof.software;
    
        CURSOR c_dtout IS
            SELECT 'X'
              FROM prof_in_out
             WHERE id_professional = i_id_prof.id
               AND dt_out_tstz IS NULL
               AND id_institution = i_id_prof.institution
               AND id_software = i_id_prof.software;
    
        user_inactive_excep  EXCEPTION;
        user_not_found_excep EXCEPTION;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET CURSOR C_STATE';
        OPEN c_state;
        FETCH c_state
            INTO l_flg_state;
        g_found := c_state%NOTFOUND;
        CLOSE c_state;
        IF g_found
        THEN
            RAISE user_not_found_excep;
        END IF;
    
        g_error := 'CHECK STATE';
        IF l_flg_state = 'I'
        THEN
            RAISE user_inactive_excep;
        ELSIF l_flg_state = 'A'
        THEN
            g_error := 'GET CURSOR C_INOUT';
            OPEN c_inout;
            FETCH c_inout
                INTO l_char;
            g_found := c_inout%NOTFOUND;
            CLOSE c_inout;
        
            IF g_found
            THEN
                -- Prof não tem registos em PROF_IN_OUT 
                l_insert := TRUE;
            ELSE
                l_char  := NULL;
                g_error := 'GET CURSOR C_DTOUT';
                OPEN c_dtout;
                FETCH c_dtout
                    INTO l_char;
                g_found := c_dtout%NOTFOUND;
                CLOSE c_dtout;
            
                IF g_found
                THEN
                    -- Todos os registos de PROF_IN_OUT têm DT_OUT preenchida 
                    l_insert := TRUE;
                END IF;
            END IF;
        
            IF l_insert
            THEN
                g_error := 'GET SEQ_PROF_IN_OUT.NEXTVAL';
                l_next  := seq_prof_in_out.nextval;
            
                g_error := 'INSERT';
                INSERT INTO prof_in_out
                    (id_prof_in_out, id_professional, dt_in_tstz, id_institution, id_software)
                VALUES
                    (l_next, i_id_prof.id, g_sysdate_tstz, i_id_prof.institution, i_id_prof.software);
            
                COMMIT;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN user_inactive_excep THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'LOGIN_M005');
                l_ret           BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'LOGIN_M005',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_LOGIN',
                                   l_error_message,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN l_ret;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LOGIN',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_login;

    FUNCTION set_logout
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_state professional.flg_state%TYPE;
        l_id        prof_in_out.id_prof_in_out%TYPE;
    
        CURSOR c_state IS
            SELECT p.flg_state
              FROM professional p
             WHERE p.id_professional = i_id_prof.id;
    
        CURSOR c_dtout IS
            SELECT id_prof_in_out
              FROM prof_in_out
             WHERE id_professional = i_id_prof.id
               AND dt_out_tstz IS NULL
               AND id_institution = i_id_prof.institution
               AND id_software = i_id_prof.software;
    
        user_not_found_excep     EXCEPTION;
        user_inactive_excep      EXCEPTION;
        no_prof_inout_recs_excep EXCEPTION;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'GET CURSOR C_STATE';
        OPEN c_state;
        FETCH c_state
            INTO l_flg_state;
        g_found := c_state%NOTFOUND;
        CLOSE c_state;
        IF g_found
        THEN
            RAISE user_not_found_excep;
        END IF;
    
        g_error := 'CHECK STATE';
        IF l_flg_state = 'I'
        THEN
            RAISE user_inactive_excep;
        ELSIF l_flg_state = 'A'
        THEN
            g_error := 'GET CURSOR C_DTOUT';
            OPEN c_dtout;
            FETCH c_dtout
                INTO l_id;
            g_found := c_dtout%NOTFOUND;
            CLOSE c_dtout;
            IF g_found
            THEN
                -- Não há registos em PROF_IN_OUT sem DT_OUT 
                RAISE no_prof_inout_recs_excep;
            END IF;
        
            g_error := 'UPDATE';
            UPDATE prof_in_out
               SET dt_out_tstz = g_sysdate_tstz, flg_automatic = g_flg_logout
             WHERE id_prof_in_out = l_id;
        
            g_error := 'UPDATE PROF_SOFT_INST';
            UPDATE prof_soft_inst
               SET flg_log = g_flg_logout
             WHERE id_professional = i_id_prof.id
               AND id_software = i_id_prof.software
               AND id_institution = i_id_prof.institution;
        
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN user_inactive_excep THEN
            DECLARE
                l_error_in      t_error_in := t_error_in();
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'LOGIN_M005');
                l_ret           BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   'LOGIN_M005',
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_LOGOUT',
                                   l_error_message,
                                   'U');
            
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_utils.undo_changes;
                RETURN l_ret;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LOGOUT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_logout;

    FUNCTION get_prof_pref
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN OUT profissional,
        o_lang         OUT language.id_language%TYPE,
        o_desc_lang    OUT language.desc_language%TYPE,
        o_time         OUT prof_preferences.timeout%TYPE,
        o_first_screen OUT prof_preferences.first_screen%TYPE,
        o_photo        OUT VARCHAR2,
        o_nick_name    OUT professional.nick_name%TYPE,
        o_name         OUT professional.name%TYPE,
        o_cat_type     OUT category.flg_type%TYPE,
        o_clin_cat     OUT category.flg_clinical%TYPE,
        o_header       OUT VARCHAR2,
        o_shortcut     OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_num_mecan    OUT prof_institution.num_mecan%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        no_prof_preferences_excep EXCEPTION;
        function_call_excep       EXCEPTION;
        prof_category_excep       EXCEPTION;
        prof_name_excep           EXCEPTION;
        l_code_message            VARCHAR2(0200 CHAR);
    
        l_header     VARCHAR2(1 CHAR);
        l_num_alerts NUMBER;
    
        l_alert_code    VARCHAR2(0050 CHAR);
        l_shortcut_code VARCHAR2(0050 CHAR);
        l_prof_profile  prof_profile_template.id_profile_template%TYPE;
        l_prof_parent   profile_template.id_parent%TYPE;
        l_id_epis_type  epis_type.id_epis_type%TYPE;
        l_first_screen  prof_preferences.first_screen%TYPE;
        l_shortcut      sys_shortcut.id_sys_shortcut%TYPE;
    
        l_error_message VARCHAR2(4000);
        l_ret           BOOLEAN;
        l_bool          BOOLEAN;
        l_prf           profile_template%ROWTYPE;
        r_cat           category%ROWTYPE;
        l_prof_info     t_prof_info;
        t_cfg           t_tbl_config;
    
        l_error_in t_error_in := t_error_in();
    
    BEGIN
    
        -- Inicialization of sys_configs
        t_cfg := initialize_config(i_id_prof, t_list_config);
    
        -- Qual order by número mecanográfico do profissional
        g_error := 'OPEN c_prof_template';
        l_prf   := pk_access.get_profile(i_id_prof);
    
        l_prof_profile := l_prf.id_profile_template;
        l_prof_parent  := l_prf.id_parent;
    
        IF l_prof_profile IS NULL
        THEN
            l_code_message  := 'ALERT_A001';
            l_error_message := pk_message.get_message(i_lang, l_code_message);
            RAISE prof_category_excep;
        END IF;
    
        g_error            := 'GET_PROF_ROOM_PREFER';
        g_prof_room_prefer := t_cfg('PROF_ROOM_PREF');
    
        g_error     := 'GET CURSOR C_PROF ';
        l_prof_info := pk_prof_utils.get_prof_info(i_id_prof);
    
        IF l_prof_info.id_language IS NULL
        THEN
            RAISE no_prof_preferences_excep;
        END IF;
    
        g_error := 'GET CURSOR C_CAT';
    
        r_cat := get_cat_info(i_id_prof);
    
        IF i_id_prof.software IN (t_cfg('SOFTWARE_ID_OUTP'),
                                  t_cfg('SOFTWARE_ID_CARE'),
                                  t_cfg('SOFTWARE_ID_EDIS'),
                                  t_cfg('SOFTWARE_ID_CLINICS'),
                                  t_cfg('SOFTWARE_ID_UBU'),
                                  t_cfg('SOFTWARE_ID_TRIAGE'),
                                  t_cfg('SOFTWARE_ID_NUTRI'),
                                  t_cfg('SOFTWARE_ID_CM'))
        THEN
            g_error := 'GET CURSOR C_ROOM';
            l_bool  := check_if_room_pref_exist(i_id_prof);
        
            -- BOOL_06
            IF NOT l_bool
               AND (r_cat.flg_type IN (g_doctor, g_nurse, g_nutri))
            THEN
            
                -- Não tem sala preferencial 
                l_first_screen := NULL;
                -- BOOL_07
                IF g_prof_room_prefer = k_yes
                THEN
                    g_error    := 'GET CURSOR C_SHORTCUT - tools_my_rooms';
                    l_shortcut := get_pck_shortcut(i_id_prof, 'TOOLS_MY_ROOMS', l_prof_profile, l_prof_parent);
                END IF; -- BOOL_07
            
            ELSE
            
                l_bool := t_cfg('LOGIN_TOOLS') = k_yes;
                l_bool := l_bool AND (i_id_prof.software IN (t_cfg('SOFTWARE_ID_EDIS'), t_cfg('SOFTWARE_ID_UBU')));
            
                -- BOOL_05
                IF l_bool
                THEN
                    g_error    := 'GET CURSOR C_SHORTCUT - tools_my_rooms';
                    l_shortcut := get_pck_shortcut(i_id_prof, 'TOOLS_MY_ROOMS', l_prof_profile, l_prof_parent);
                ELSE
                    -- BOOL_04
                    g_error := 'CALL TO PK_ALERTS.GET_PROF_ALERTS_COUNT';
                    IF NOT pk_alerts.get_prof_alerts_count(i_lang       => i_lang,
                                                           i_prof       => i_id_prof,
                                                           o_num_alerts => l_num_alerts,
                                                           o_error      => o_error)
                    THEN
                        --RAISE function_call_excep;
                        l_num_alerts := k_zero_value;
                    ELSE
                        l_num_alerts := 1;
                    END IF;
                    -- BOOL_04
                
                    -- BOOL_03
                    IF nvl(l_num_alerts, k_zero_value) != k_zero_value
                    THEN
                        g_error        := 'SET O_SHORTCUT';
                        l_first_screen := NULL;
                    
                        g_error    := 'GET CURSOR C_SHORTCUT - alertas';
                        l_shortcut := get_pck_shortcut(i_id_prof, 'ALERTS', l_prof_profile, l_prof_parent);
                    ELSE
                    
                        l_shortcut := get_pck_shortcut(i_id_prof, 'TOOLS_MYSPECIALTIES', l_prof_profile, l_prof_parent);
                        l_bool     := l_shortcut IS NOT NULL;
                        l_bool     := l_bool AND (pk_prof_utils.get_prof_dcs(i_id_prof) IS NULL);
                    
                        -- BOOL_02
                        IF l_bool
                        THEN
                            l_shortcut := l_shortcut;
                        
                        ELSIF l_prof_profile IN (t_cfg('PROFILE_DOCTOR'), t_cfg('PROFILE_NURSE'))
                        THEN
                        
                            g_error        := 'OPEN c_epis_prof_resp';
                            l_id_epis_type := t_cfg('ID_EPIS_TYPE_EDIS');
                        
                            -- BOOL_01
                            l_bool := check_if_prof_is_resp(i_id_prof, l_id_epis_type);
                            l_bool := l_bool AND
                                      (i_id_prof.software IN (t_cfg('SOFTWARE_ID_EDIS'), t_cfg('SOFTWARE_ID_UBU')));
                        
                            l_shortcut_code := iif(l_bool, 'MY_PATIENTS', 'ALL_PATIENTS');
                            l_shortcut      := get_pck_shortcut(i_id_prof,
                                                                l_shortcut_code,
                                                                l_prof_profile,
                                                                l_prof_parent);
                        
                        ELSE
                            l_shortcut := NULL;
                        END IF; -- BOOL_02                    
                    END IF; -- BOOL_03                
                END IF; -- BOOL_05            
            END IF; -- BOOL_06
        
        ELSIF i_id_prof.software IN (t_cfg('SOFTWARE_ID_INP'), t_cfg('SOFTWARE_ID_AT'))
        THEN
        
            l_bool := check_if_user_is_profile_admin(i_id_prof);
        
            l_num_alerts := k_zero_value;
            l_shortcut   := NULL;
        
            -- se nao tiver prefil admin entao
            -- BOOL_15
            IF NOT l_bool
            THEN
                g_error := 'CALL TO PK_ALERTS.GET_PROF_ALERTS_COUNT';
                -- BOOL_10
                IF NOT pk_alerts.get_prof_alerts_count(i_lang       => i_lang,
                                                       i_prof       => i_id_prof,
                                                       o_num_alerts => l_num_alerts,
                                                       o_error      => o_error)
                THEN
                    --RAISE function_call_excep;
                    l_num_alerts := k_zero_value;
                ELSE
                    l_num_alerts := 1;
                END IF;
            
                -- BOOL_10
                l_shortcut := NULL;
            
                -- BOOL_11
                IF nvl(l_num_alerts, k_zero_value) != k_zero_value
                THEN
                    l_first_screen := NULL;
                END IF; -- BOOL_11
            
                -- validar se tem serviço por defeito
                l_bool := check_prof_dcs_default(i_id_prof);
            
                -- BOOL_12
                l_shortcut_code := iif((NOT l_bool), 'TOOLS_MYSPECIALTIES', '');
            
                IF l_shortcut_code IS NOT NULL
                THEN
                    l_shortcut := get_pck_shortcut(i_id_prof, l_shortcut_code, l_prof_profile, l_prof_parent);
                END IF;
            END IF; -- BOOL_15
        
        ELSIF i_id_prof.software IN (t_cfg('SOFTWARE_ID_RT'),
                                     t_cfg('SOFTWARE_ID_ASSIST'),
                                     t_cfg('SOFTWARE_ID_ORIS'),
                                     t_cfg('SOFTWARE_ID_BACKOFFICE'),
                                     t_cfg('SOFTWARE_ID_PHISIOTERAPY'),
                                     t_cfg('SOFTWARE_ID_P1'),
                                     t_cfg('SOFTWARE_ID_PHAMACY'))
        THEN
            g_error := 'CALL TO PK_ALERTS.GET_PROF_ALERTS_COUNT';
            IF NOT pk_alerts.get_prof_alerts_count(i_lang       => i_lang,
                                                   i_prof       => i_id_prof,
                                                   o_num_alerts => l_num_alerts,
                                                   o_error      => o_error)
            THEN
                l_num_alerts := k_zero_value;
            ELSE
                l_num_alerts := 1;
            END IF;
        
            IF nvl(l_num_alerts, k_zero_value) != k_zero_value
            THEN
                g_error        := 'SET O_SHORTCUT';
                l_first_screen := NULL;
            
                g_error := 'GET CURSOR C_SHORTCUT';
            
                CASE i_id_prof.software
                    WHEN t_cfg('SOFTWARE_ID_BACKOFFICE') THEN
                        l_alert_code := 'BLOCKED_LOGIN';
                    WHEN t_cfg('SOFTWARE_ID_ITECH') THEN
                        l_alert_code := 'ALERTS_ITECH';
                    ELSE
                        l_alert_code := 'ALERTS';
                END CASE;
            
                l_shortcut := get_pck_shortcut(i_id_prof, l_alert_code, l_prof_profile, l_prof_parent);
            END IF;
        END IF;
    
        l_bool   := (r_cat.flg_type IN ('D', 'N', 'P', 'M', 'T', 'F', 'A', 'C', 'R'));
        l_header := iif(l_bool, k_yes, k_no);
    
        g_error := 'GET PREFERENCES';
        IF r_cat.flg_type IS NULL
        THEN
            --The user doesn't have recorded Category.
            l_code_message  := 'LOGIN_M003';
            l_error_message := pk_message.get_message(i_lang, 'LOGIN_M003');
            RAISE prof_category_excep;
        ELSIF l_prof_info.name IS NULL
              OR l_prof_info.nick_name IS NULL
        THEN
            --The user doesn't have recorded Name.
            l_error_message := pk_message.get_message(i_lang, 'LOGIN_M004');
            RAISE prof_name_excep;
        ELSIF l_prof_info.timeout IS NULL
        THEN
            l_prof_info.timeout := t_cfg('APPLICATION_TIMEOUT');
        END IF;
    
        g_error := 'UPDATE PROF_SOFT_INST';
        upd_prof_soft_inst(i_id_prof);
    
        g_error := 'CALL TO SET_LOGIN';
        IF NOT pk_login.set_login(i_lang => i_lang, i_id_prof => i_id_prof, o_error => o_error)
        THEN
            RAISE function_call_excep;
        END IF;
    
        -- Resultados    
        o_num_mecan    := get_prof_num_mecan(i_id_prof.id, i_id_prof.institution);
        o_lang         := l_prof_info.id_language;
        o_desc_lang    := l_prof_info.desc_language;
        o_time         := l_prof_info.timeout;
        o_first_screen := l_prof_info.first_screen;
        o_photo        := l_prof_info.profphoto;
        o_name         := l_prof_info.name;
        o_nick_name    := l_prof_info.nick_name;
    
        o_cat_type := r_cat.flg_type;
        o_clin_cat := r_cat.flg_clinical;
    
        o_header       := l_header;
        o_first_screen := l_first_screen;
        o_shortcut     := l_shortcut;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN prof_category_excep
             OR prof_name_excep THEN
            l_error_in.set_all(i_lang,
                               l_code_message,
                               l_error_message,
                               g_error,
                               g_package_owner,
                               g_package_name,
                               'GET_PROF_PREF',
                               l_error_message,
                               'U');
        
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_utils.undo_changes;
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_PREF',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_pref;

    /*
    * Actualizar em PROF_IN_OUT os registos de todos os profissionais cujo login já ocorreu há 12h ou +. 
    * Além disso, grava como definitivos todos os registos temporários dos prof. nessas condições.
    */

    PROCEDURE prof_out_automatic
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        o_error          OUT t_error_out
    ) IS
    
        l_prof profissional;
        l_msg  sys_config.value%TYPE;
    
        CURSOR c_id_prof IS
            SELECT id_prof_in_out
              FROM prof_in_out
             WHERE dt_out_tstz IS NULL
               AND pk_date_utils.get_timestamp_diff(current_timestamp, dt_in_tstz) >= to_number(l_msg) / 24
               AND id_institution = i_id_institution
               AND id_software = i_id_software;
    
        CURSOR c_prof IS
            SELECT id_professional
              FROM prof_soft_inst
             WHERE id_institution = i_id_institution
               AND id_software = i_id_software
               AND pk_date_utils.get_timestamp_diff(current_timestamp, dt_log_tstz) >= to_number(l_msg) / 24;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_prof := profissional(NULL, i_id_institution, i_id_software);
    
        g_error := 'CALL TO PK_SYSCONFIG.GET_CONFIG';
        l_msg   := pk_sysconfig.get_config('PROF_OUT_AUTOMATIC', l_prof);
    
        g_error := 'BEGIN LOOP1';
        FOR r_prof IN c_prof
        LOOP
            g_error := 'UPDATE PROF_SOFT_INST ID_PROF' || r_prof.id_professional;
            UPDATE prof_soft_inst
               SET flg_log = g_flg_logout
             WHERE id_professional = r_prof.id_professional;
        END LOOP;
    
        g_error := 'BEGIN LOOP2';
        FOR r_id_prof IN c_id_prof
        LOOP
            g_error := 'UPDATE PROF_IN_OUT ID_PROF_IN_OUT' || r_id_prof.id_prof_in_out;
            UPDATE prof_in_out
               SET dt_out_tstz = g_sysdate_tstz, flg_automatic = g_flg_log
             WHERE id_prof_in_out = r_id_prof.id_prof_in_out;
        
            l_prof := profissional(r_id_prof.id_prof_in_out, NULL, NULL);
        
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PROF_OUT_AUTOMATIC',
                                              o_error);
            pk_utils.undo_changes;
    END prof_out_automatic;

    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_all VARCHAR2(200);
    
    BEGIN
        --- deve devolver 'Y' para apresentar todas as fotos no easy login
        l_all := pk_sysconfig.get_config('ALL_PHOTO_LOGIN', i_prof);
    
        IF l_all = k_no
        THEN
            g_error := 'OPEN O_INFO (1)';
            OPEN o_info FOR
                SELECT p.id_professional,
                       p.nick_name,
                       su.login desc_user,
                       k_zero_value rank,
                       decode(nvl(pp.id_prof_photo, k_zero_value),
                              k_zero_value,
                              NULL,
                              pk_profphoto.get_prof_photo(profissional(p.id_professional,
                                                                       i_prof.institution,
                                                                       i_prof.software))) photo
                  FROM professional p
                  JOIN ab_user_info su
                    ON (p.id_professional = su.id_ab_user_info)
                  JOIN prof_soft_inst psi
                    ON (psi.id_professional = p.id_professional)
                  JOIN prof_photo pp
                    ON (pp.id_professional = p.id_professional)
                 WHERE su.id_ab_user_info = i_prof.id
                   AND psi.id_institution = i_prof.institution
                   AND psi.id_software IN (i_prof.software, 15, 16)
                   AND psi.flg_log = pk_alert_constant.g_yes
                UNION ALL
                SELECT p.id_professional,
                       p.nick_name,
                       su.login desc_user,
                       1 rank,
                       decode(nvl(pp.id_prof_photo, k_zero_value),
                              k_zero_value,
                              NULL,
                              pk_profphoto.get_prof_photo(profissional(p.id_professional,
                                                                       i_prof.institution,
                                                                       i_prof.software))) photo
                  FROM professional p
                  JOIN ab_user_info su
                    ON (p.id_professional = su.id_ab_user_info)
                  JOIN prof_photo pp
                    ON (pp.id_professional = p.id_professional)
                 WHERE su.id_ab_user_info != i_prof.id
                   AND EXISTS
                 (SELECT k_zero_value
                          FROM prof_soft_inst psi
                          JOIN prof_institution pi
                            ON (pi.id_institution = psi.id_institution AND pi.id_professional = psi.id_professional)
                          JOIN prof_cat pc
                            ON (pc.id_professional = psi.id_professional)
                          JOIN category cat
                            ON (cat.id_category = pc.id_category)
                          LEFT JOIN prof_dep_clin_serv pdcs
                            ON (pdcs.id_professional = psi.id_professional AND pdcs.flg_status = g_selected AND
                               ((cat.flg_type != g_cat_type_tec AND
                               pdcs.id_dep_clin_serv IN
                               (SELECT id_dep_clin_serv
                                     FROM prof_dep_clin_serv
                                    WHERE id_professional = i_prof.id)) OR cat.flg_type = g_cat_type_tec))
                          LEFT JOIN prof_room pr
                            ON (pr.id_professional = psi.id_professional AND
                               ((cat.flg_type IN (g_cat_type_doc, g_cat_type_nur) AND
                               pr.id_room IN (SELECT id_room
                                                   FROM prof_room
                                                  WHERE id_professional = i_prof.id
                                                    AND flg_pref = g_prof_room_pref)) OR
                               cat.flg_type NOT IN (g_cat_type_doc, g_cat_type_nur)))
                         WHERE psi.id_professional = p.id_professional
                           AND psi.id_institution = i_prof.institution
                           AND psi.id_software IN (i_prof.software, 15, 16)
                           AND psi.flg_log = pk_alert_constant.g_yes
                           AND cat.flg_type NOT IN (g_cat_type_adm)
                           AND cat.flg_prof = g_cat_prof_y
                           AND pi.id_prof_institution IN
                               (SELECT id_prof_institution
                                  FROM prof_institution
                                 WHERE id_prof_institution IN
                                       (SELECT MAX(id_prof_institution)
                                          FROM prof_institution pr
                                         WHERE pr.id_professional = p.id_professional
                                           AND pr.id_institution = i_prof.institution)
                                   AND flg_state = 'A'
                                   AND pi.id_professional = p.id_professional
                                   AND pi.id_institution = i_prof.institution))
                 ORDER BY rank, nick_name;
        
        ELSE
            g_error := 'OPEN O_INFO (2)';
            OPEN o_info FOR
                SELECT p.id_professional,
                       p.nick_name,
                       su.login desc_user,
                       k_zero_value rank,
                       decode(nvl(pp.id_prof_photo, k_zero_value),
                              k_zero_value,
                              NULL,
                              pk_profphoto.get_prof_photo(profissional(p.id_professional,
                                                                       i_prof.institution,
                                                                       i_prof.software))) photo
                  FROM professional p
                  JOIN ab_user_info su
                    ON (p.id_professional = su.id_ab_user_info)
                  JOIN prof_soft_inst psi
                    ON (psi.id_professional = p.id_professional)
                  JOIN prof_photo pp
                    ON (pp.id_professional = p.id_professional)
                 WHERE su.id_ab_user_info = i_prof.id
                   AND psi.flg_log = pk_alert_constant.g_yes
                   AND psi.id_institution = i_prof.institution
                   AND psi.id_software IN (i_prof.software, 15, 16)
                UNION ALL
                SELECT p.id_professional,
                       p.nick_name,
                       su.login desc_user,
                       1 rank,
                       decode(nvl(pp.id_prof_photo, k_zero_value),
                              k_zero_value,
                              NULL,
                              pk_profphoto.get_prof_photo(profissional(p.id_professional,
                                                                       i_prof.institution,
                                                                       i_prof.software))) photo
                  FROM professional p
                  JOIN ab_user_info su
                    ON (p.id_professional = su.id_ab_user_info)
                  JOIN prof_soft_inst psi
                    ON (psi.id_professional = p.id_professional)
                  JOIN prof_photo pp
                    ON (pp.id_professional = p.id_professional)
                 WHERE su.id_ab_user_info != i_prof.id
                   AND psi.flg_log = pk_alert_constant.g_yes
                   AND psi.id_institution = i_prof.institution
                   AND psi.id_software IN (i_prof.software, 15, 16)
                   AND EXISTS (SELECT k_zero_value
                          FROM prof_institution pi
                         WHERE pi.id_prof_institution IN
                               (SELECT MAX(id_prof_institution)
                                  FROM prof_institution pr
                                 WHERE pr.id_professional = p.id_professional
                                   AND pr.id_institution = i_prof.institution)
                           AND flg_state = 'A'
                           AND pi.id_professional = p.id_professional
                           AND pi.id_institution = i_prof.institution)
                 ORDER BY rank, nick_name;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_list;

    FUNCTION get_software_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_software      OUT pk_types.cursor_type,
        o_timestamp_str OUT VARCHAR2,
        o_gmt_offset    OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception        EXCEPTION;
        l_count_software    NUMBER(24);
        l_count_institution NUMBER(24);
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_software FOR
            SELECT s.id_software,
                   pk_translation.get_translation(nvl(asi.id_ab_language, i_lang), s.code_software) desc_software,
                   pk_translation.get_translation(nvl(asi.id_ab_language, i_lang), s.code_icon) icon,
                   asi.id_ab_language id_lang_pref
              FROM ab_soft_inst_user_info asi
              JOIN software s
                ON (asi.id_ab_software = s.id_software)
             WHERE s.flg_mni = g_flg_mni
               AND asi.id_ab_user_info = i_prof.id
               AND asi.id_ab_institution = i_prof.institution
             ORDER BY desc_software;
    
        g_error := 'GET COUNT SOFTWARE';
        SELECT COUNT(1)
          INTO l_count_software
          FROM ab_soft_inst_user_info asi
          JOIN software s
            ON (asi.id_ab_software = s.id_software)
         WHERE s.flg_mni = g_flg_mni
           AND asi.id_ab_user_info = i_prof.id
           AND asi.id_ab_institution = i_prof.institution;
    
        g_error := 'GET COUNT INSTITUTION';
        SELECT COUNT(1)
          INTO l_count_institution
          FROM prof_institution pi
          JOIN institution i
            ON (i.id_institution = pi.id_prof_institution)
         WHERE pi.id_professional = i_prof.id
           AND pi.flg_state = g_prof_inst_state
           AND pi.dt_end_tstz IS NULL
           AND i.flg_available = k_yes;
    
        o_timestamp_str := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof);
    
        o_gmt_offset := pk_date_utils.get_gmt_offset(i_lang => i_lang, i_prof => i_prof);
    
        IF l_count_software = k_zero_value
           AND l_count_institution > k_zero_value
        THEN
            RAISE my_exception;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
    
        WHEN my_exception THEN
            DECLARE
                l_error_message VARCHAR2(4000) := pk_message.get_message(i_lang, 'LOGIN_M010');
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  'LOGIN_M010',
                                                  l_error_message,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_SOFTWARE_LIST',
                                                  'U',
                                                  o_error);
            
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SOFTWARE_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_software);
            RETURN FALSE;
    END get_software_list;

    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN professional.id_professional%TYPE,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count      NUMBER(24);
        my_exception EXCEPTION;
    
        k_error_login   CONSTANT VARCHAR2(0100 CHAR) := 'ERR_LOGIN';
        k_error_general CONSTANT VARCHAR2(0100 CHAR) := 'ERR_GENERAL';
    
        FUNCTION run_error(i_mode IN NUMBER) RETURN BOOLEAN IS
            l_error_message VARCHAR2(4000);
            l_sqlcode       NUMBER(24);
            l_msg_type      VARCHAR2(0001 CHAR);
        BEGIN
        
            CASE i_mode
                WHEN k_error_login THEN
                
                    l_sqlcode       := 'LOGIN_M002';
                    l_error_message := pk_message.get_message(i_lang, l_sqlcode);
                    l_msg_type      := 'U';
                
                WHEN k_error_general THEN
                    l_sqlcode       := SQLCODE;
                    l_error_message := SQLERRM;
                    l_msg_type      := 'E';
            END CASE;
        
            pk_alert_exceptions.process_error(i_lang,
                                              l_sqlcode,
                                              l_error_message,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_INSTIT_LIST',
                                              l_msg_type,
                                              o_error);
            pk_types.open_my_cursor(o_info);
        
            RETURN FALSE;
        
        END run_error;
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_info FOR
            SELECT i.id_institution,
                   pk_translation.get_translation(i_lang, i.code_institution) desc_instit,
                   pk_message.get_message(i_lang, g_disclaimer || ia.id_country) disclaimer,
                   tz.timezone_region
              FROM institution i
              JOIN prof_institution pi
                ON (pi.id_institution = i.id_institution)
              LEFT OUTER JOIN inst_attributes ia
                ON (ia.id_institution = i.id_institution)
              JOIN timezone_region tz
                ON tz.id_timezone_region = i.id_timezone_region
             WHERE pi.id_professional = i_prof
               AND i.flg_available = k_yes
               AND pi.flg_state = g_prof_inst_state
               AND pi.dt_end_tstz IS NULL
             ORDER BY desc_instit;
    
        l_count := SQL%ROWCOUNT;
    
        IF l_count = k_zero_value
        THEN
            RAISE my_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            RETURN run_error(i_mode => k_error_login);
        
        WHEN OTHERS THEN
            RETURN run_error(i_mode => k_error_general);
    END get_instit_list;

    FUNCTION get_prof_login
    (
        i_lang    IN language.id_language%TYPE,
        i_prof_id IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
    
        tbl_login table_varchar;
    
        l_return VARCHAR(1000 CHAR);
    
    BEGIN
    
        SELECT fsu.login
          BULK COLLECT
          INTO tbl_login
          FROM ab_user_info fsu
         WHERE fsu.id_ab_user_info = i_prof_id;
    
        IF tbl_login.count > k_zero_value
        THEN
            l_return := tbl_login(1);
        END IF;
    
        RETURN l_return;
    
    END get_prof_login;

    FUNCTION get_server_time
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_timestamp_str OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_timestamp TIMESTAMP WITH TIME ZONE;
    
    BEGIN
    
        RETURN pk_date_utils.get_timestamp_anytimezone(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_timestamp     => NULL,
                                                       i_timestamp_str => NULL,
                                                       i_timezone      => NULL,
                                                       o_timestamp     => l_timestamp,
                                                       o_timestamp_str => o_timestamp_str,
                                                       o_error         => o_error);
    
    END get_server_time;

    FUNCTION get_support_info
    (
        i_lang               IN NUMBER,
        i_host_internal_name IN VARCHAR2,
        i_env_internal_name  IN VARCHAR2,
        o_result             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_hub_core.get_support_info(i_lang               => i_lang,
                                            i_host_internal_name => i_host_internal_name,
                                            i_env_internal_name  => i_env_internal_name,
                                            o_result             => o_result,
                                            o_error              => o_error);
    
    END get_support_info;

BEGIN

    g_epis_active := 'A';
    g_flg_log     := 'Y';
    g_flg_logout  := 'N';
    g_doctor      := 'D';
    g_nurse       := 'N';
    g_nutri       := 'U';
    g_terapeuta   := 'F';
    g_found_true  := 'Y';
    g_room_pref   := 'Y';

    g_cat_type_doc   := 'D';
    g_cat_type_nur   := 'N';
    g_cat_type_tec   := 'T';
    g_cat_type_adm   := 'A';
    g_cat_prof_y     := 'Y';
    g_prof_room_pref := 'Y';

    g_flg_mni         := 'Y';
    g_prof_inst_state := 'A';

    g_selected    := 'S';
    g_login_tools := 'Y';

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);

END pk_login;
/
