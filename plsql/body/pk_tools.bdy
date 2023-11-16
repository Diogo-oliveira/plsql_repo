/*-- Last Change Revision: $Rev: 2027799 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_tools AS

    g_package_name VARCHAR2(32);

    FUNCTION get_institution
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem das instituições onde o profissional está parametrizado  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)      
                Saída:   O_LIST - listagem 
                     O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        --RMGM: Same code in pk_login.get_instit_list(should use same method)
        OPEN o_list FOR
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) desc_inst, i.rank
              FROM institution i, prof_institution pi, inst_attributes ia
             WHERE pi.id_professional = i_prof.id
               AND i.id_institution = pi.id_institution
               AND ia.id_institution(+) = i.id_institution
               AND i.flg_available = 'Y'
               AND pi.flg_state = 'A'
               AND pi.dt_end_tstz IS NULL
             ORDER BY desc_inst;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_INSTITUTION');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_department
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_softwares table_number;
        /******************************************************************************************************
           OBJECTIVO: Obter listagem dos departamentos da instituição seleccionada     
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_INST - instituição seleccionada    
                Saída:   O_LIST - listagem 
                     O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
    
        g_error          := 'GET PROFESSIONAL SOFTWARES';
        l_prof_softwares := pk_prof_utils.get_prof_softwares(i_lang, i_prof, i_inst);
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT dp.id_dept,
                   dp.desc_dep,
                   (CAST(MULTISET (SELECT sd.id_software
                            FROM software_dept sd
                           WHERE sd.id_dept = dp.id_dept
                           ORDER BY sd.id_software) AS table_number) MULTISET INTERSECT l_prof_softwares) id_software
              FROM (SELECT DISTINCT d.id_dept, pk_translation.get_translation(i_lang, d.code_dept) desc_dep
                      FROM dept d
                     INNER JOIN department dep
                        ON (dep.id_dept = d.id_dept)
                     INNER JOIN dep_clin_serv dcs
                        ON (dcs.id_department = dep.id_department)
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                     WHERE d.id_institution = i_inst
                       AND pdcs.id_professional = i_prof.id
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND dep.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes) dp
             ORDER BY desc_dep;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_DEPARTMENT');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_all_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT dpt1.id_department id_service,
                   dpt1.rank,
                   pk_translation.get_translation(i_lang, dpt1.code_department) desc_service
              FROM (SELECT DISTINCT dpt.id_department
                      FROM department dpt
                      JOIN dep_clin_serv dcs
                        ON dcs.id_department = dpt.id_department
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     WHERE dpt.id_dept = i_dep
                       AND dpt.flg_type IS NOT NULL
                       AND dpt.flg_available = g_flg_available
                       AND dcs.flg_available = g_flg_available
                       AND pdcs.id_professional = i_prof.id
                       AND rownum > 0) xsql
              JOIN department dpt1
                ON dpt1.id_department = xsql.id_department
             ORDER BY dpt1.rank, desc_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_ALL_SERVICE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END get_all_service;

    /********************************************************************************************
    * get professional associated departments for enabled services
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    o_list                   list of departments / services   
    * @param    o_error                  error message
    *
    * @return   boolean: false in case of error, otherwise true
    *
    * @author   Carlos Loureiro
    * @version  1.0
    * @since    2009/09/04
    ********************************************************************************************/
    FUNCTION get_prof_dept_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT d.id_dept AS id_dept,
                            pk_translation.get_translation(i_lang, d.code_dept) AS desc_dept,
                            dep.id_department AS id_department,
                            pk_translation.get_translation(i_lang, dep.code_department) desc_department
              FROM dept d
              JOIN department dep
                ON dep.id_dept = d.id_dept
              JOIN dep_clin_serv dcs
                ON dcs.id_department = dep.id_department
              JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
              JOIN software_dept sd
                ON sd.id_dept = d.id_dept
             WHERE d.flg_available = g_flg_available
               AND dep.flg_available = g_flg_available
               AND dcs.flg_available = g_flg_available
               AND pdcs.id_professional = i_prof.id
               AND d.id_institution = i_prof.institution
               AND pdcs.flg_status = g_selected
               AND sd.id_software = i_prof.software
             ORDER BY desc_dept, desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PROF_DEPT_SERVICES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    FUNCTION get_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem dos serviços do departamento seleccionada     
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                 I_INST - instituição seleccionada    
              Saída: O_LIST - listagem 
                 O_ERROR - erro 
          CRIAÇÃO: CRS 2006/11/11 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT d.id_department id_service,
                            pk_translation.get_translation(i_lang, d.code_department) desc_service,
                            nvl(x.total, 0) total,
                            nvl(z.selected, 0) selected
              FROM department d
             INNER JOIN dep_clin_serv dcs
                ON (dcs.id_department = d.id_department)
             INNER JOIN prof_dep_clin_serv pdcs
                ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
              LEFT JOIN (SELECT dcs.id_department, COUNT(*) total
                           FROM dep_clin_serv dcs
                          INNER JOIN clinical_service cli
                             ON (dcs.id_clinical_service = cli.id_clinical_service)
                          INNER JOIN prof_dep_clin_serv pdc
                             ON (dcs.id_dep_clin_serv = pdc.id_dep_clin_serv)
                          WHERE pdc.id_professional = i_prof.id
                            AND dcs.flg_available = pk_alert_constant.g_yes
                            AND cli.flg_available = pk_alert_constant.g_yes
                          GROUP BY dcs.id_department) x
                ON (d.id_department = x.id_department)
              LEFT JOIN (SELECT dcs.id_department, COUNT(*) selected
                           FROM dep_clin_serv dcs
                          INNER JOIN clinical_service cli
                             ON (dcs.id_clinical_service = cli.id_clinical_service)
                          INNER JOIN prof_dep_clin_serv pdc
                             ON (dcs.id_dep_clin_serv = pdc.id_dep_clin_serv)
                          WHERE pdc.id_professional = i_prof.id
                            AND dcs.flg_available = pk_alert_constant.g_yes
                            AND cli.flg_available = pk_alert_constant.g_yes
                            AND pdc.flg_status = g_status_pdcs_s
                          GROUP BY dcs.id_department) z
                ON (d.id_department = z.id_department)
             WHERE d.id_dept = i_dep
               AND pdcs.id_professional = i_prof.id
               AND dcs.flg_available = pk_alert_constant.g_yes
            --      AND PDCS.FLG_STATUS = G_SELECTED  -- JS: Senao nao devolve os departments que não têm dcs seleccionados
             ORDER BY desc_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_SERVICE');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem das salas do departamento seleccionado      
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_DEP - departamento seleccionado    
                Saída:   O_LIST - listagem 
                     O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT r.id_room, nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room, r.rank
              FROM room r
             WHERE r.id_department = i_dep
               AND r.flg_available = g_flg_available
             ORDER BY r.rank, desc_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_ROOM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION create_prof_room
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_room        IN table_number,
        i_room_select IN table_varchar,
        i_room_pref   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Registar alocação de salas do prof. e indicar a preferencial por serviço      
           PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                 I_ROOM - array de salas escolhidas 
                                 I_ROOM_SELECT - array de valores para a coluna de selecção (mesmo nº de 
                                      posições que o array I_ROOM) 
                 I_ROOM_PREF - array de salas preferenciais 
                       (podem ser várias, uma por serviço) 
               Saída:   O_ERROR - erro 
                       
          CRIAÇÃO: SS 2005/11/07 
          ALTERAÇÃO: CRS 2006/11/11 Salas são registadas por serviço 
          NOTAS: 
        ******************************************************************************************************/
        CURSOR c_exist IS
            SELECT pr.flg_pref,
                   r.id_department,
                   pr.id_room,
                   pk_translation.get_translation(i_lang, d.code_department) dep,
                   pk_translation.get_translation(i_lang, i.code_institution) instit
              FROM prof_room pr, room r, department d, institution i
             WHERE pr.id_professional = i_prof.id
               AND r.id_room = pr.id_room
               AND d.id_department = r.id_department
               AND i.id_institution = d.id_institution
             ORDER BY r.id_department;
        r_exist c_exist%ROWTYPE;
    
        CURSOR c_dep(l_id_room IN room.id_room%TYPE) IS
            SELECT id_department
              FROM room
             WHERE id_room = l_id_room;
    
        l_pref        prof_room.flg_pref%TYPE;
        l_dep         room.id_department%TYPE;
        l_desc_dep    VARCHAR2(4000);
        l_desc_instit VARCHAR2(4000);
        l_exist_pref  VARCHAR2(1);
        l_dep1        room.id_department%TYPE;
        l_dep2        room.id_department%TYPE;
    
        CURSOR c_prof_room(l_room IN NUMBER) IS
            SELECT flg_pref
              FROM prof_room
             WHERE id_professional = i_prof.id
               AND id_room = l_room;
    
        CURSOR c_aux_prof_room
        (
            id_r    NUMBER,
            id_prof NUMBER,
            id_d    table_number
        ) IS
            SELECT decode(id_room, id_r, 'Y', 'N') flag, pr.id_prof_room id_pr
              FROM prof_room pr
             WHERE pr.id_professional = id_prof
               AND pr.id_room IN
                   (SELECT id_room
                      FROM room
                     WHERE id_department IN (SELECT /*+ordered use_nl(a d)*/
                                              id_department
                                               FROM TABLE(id_d) a
                                               JOIN department d
                                                 ON d.id_dept = a.column_value
                                              WHERE d.flg_available = pk_alert_constant.g_yes));
    
        l_exception EXCEPTION;
    
        l_depts table_number;
    
    BEGIN
        -- José Brito 10/07/2009 ALERT-35024  Raise error if the parameters are invalid
        g_error := 'VALIDATE PARAMETERS';
        pk_alertlog.log_debug(g_error);
        IF i_room.count <> i_room_select.count
           OR i_room.count <> i_room_pref.count
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'START LOOP';
        pk_alertlog.log_debug(g_error);
        FOR i IN 1 .. i_room.count
        LOOP
            -- Loop sobre o array de IDs de salas     
            g_error := 'OPEN C_PROF_ROOM';
            OPEN c_prof_room(i_room(i));
            FETCH c_prof_room
                INTO l_exist_pref;
            g_found := c_prof_room%FOUND;
            CLOSE c_prof_room;
        
            IF g_found
               AND i_room_select(i) = 'N'
            THEN
                -- Profissional deixou de estar alocado à sala 
                dbms_output.put_line('DELETE PROF_ROOM');
                g_error := 'DELETE PROF_ROOM';
                DELETE prof_room
                 WHERE id_professional = i_prof.id
                   AND id_room = i_room(i);
            
            ELSIF NOT g_found
                  AND i_room_select(i) = 'Y'
            THEN
                -- Profissional passou a estar alocado à sala 
                dbms_output.put_line('INSERT PROF_ROOM');
                g_error := 'INSERT PROF_ROOM';
                INSERT INTO prof_room
                    (id_prof_room, id_professional, id_room, flg_pref, id_category_sub, id_sr_prof_shift)
                VALUES
                    (seq_prof_room.nextval, i_prof.id, i_room(i), i_room_pref(i), NULL, NULL);
            
            ELSIF g_found
                  AND i_room_select(i) = 'Y'
            THEN
                -- Profissional continua a estar alocado à sala 
                dbms_output.put_line('UPDATE PROF_ROOM');
                g_error := 'UPDATE PROF_ROOM';
                UPDATE prof_room
                   SET flg_pref = i_room_pref(i)
                 WHERE id_professional = i_prof.id
                   AND id_room = i_room(i);
            END IF;
        
            IF i_room_pref(i) = 'Y'
            THEN
            
                -- determinar id_dept
                g_error := 'GET SOFTWARE LIST';
                SELECT (CAST(MULTISET (SELECT DISTINCT sd2.id_dept
                                FROM software_dept sd
                                JOIN software_dept sd2
                                  ON sd.id_software = sd2.id_software
                                JOIN dept d2
                                  ON d2.id_dept = sd2.id_dept
                                JOIN TABLE(pk_prof_utils.get_prof_softwares(i_lang, i_prof, d.id_institution))
                                  ON column_value = sd2.id_software
                               WHERE sd.id_dept = d.id_dept
                                 AND d2.id_institution = d.id_institution
                                 AND d2.flg_available = pk_alert_constant.g_yes) AS table_number) MULTISET UNION
                        DISTINCT table_number(d.id_dept)) id_dept
                  INTO l_depts
                  FROM department dpt
                  JOIN room r
                    ON r.id_department = dpt.id_department
                  JOIN dept d
                    ON d.id_dept = dpt.id_dept
                 WHERE r.id_room = i_room(i);
            
                FOR k IN c_aux_prof_room(i_room(i), i_prof.id, l_depts)
                LOOP
                    UPDATE prof_room
                       SET flg_pref = k.flag
                     WHERE id_prof_room = k.id_pr;
                END LOOP;
            END IF;
        
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'T_PARAM_ERROR',
                                              'INVALID ARRAY SIZE',
                                              g_error,
                                              'ALERT',
                                              'PK_TOOLS',
                                              'CREATE_PROF_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'CREATE_PROF_ROOM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION set_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Alterar a sala preferencial 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_ROOM - array de salas preferenciais 
                         (podem ser várias, uma por departamento) 
                Saída:   O_ERROR - erro 
          CRIAÇÃO: CRS 2005/11/13 
          NOTAS: 
        ******************************************************************************************************/
        CURSOR c_dep(l_id_room IN room.id_room%TYPE) IS
            SELECT id_department
              FROM room
             WHERE id_room = l_id_room;
        l_dep room.id_department%TYPE;
    
    BEGIN
        FOR i IN 1 .. i_room.count
        LOOP
            -- Loop sobre o array de IDs de salas preferenciais    
            g_error := 'OPEN C_DEP';
            OPEN c_dep(i_room(i));
            FETCH c_dep
                INTO l_dep;
            CLOSE c_dep;
        
            g_error := 'UPDATE (1)';
            UPDATE prof_room
               SET flg_pref = g_prof_room_npref
             WHERE id_professional = i_prof.id
               AND id_room IN (SELECT id_room
                                 FROM room
                                WHERE id_department = l_dep);
        
            g_error := 'UPDATE (2)';
            UPDATE prof_room
               SET flg_pref = g_prof_room_pref
             WHERE id_professional = i_prof.id
               AND id_room = i_room(i);
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            -- undo changes
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'SET_PROF_ROOM');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION cancel_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Alterar a sala preferencial e/ou cancelar         
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_ROOM - array de salas canceladas 
                             (podem ser várias, uma por departamento) 
                Saída:   O_ERROR - erro 
          CRIAÇÃO: CRS 2005/11/13 
          NOTAS: 
        ******************************************************************************************************/
        CURSOR c_pref(l_room IN prof_room.id_room%TYPE) IS
            SELECT flg_pref
              FROM prof_room
             WHERE id_professional = i_prof.id
               AND id_room = l_room;
    
        l_flg_pref prof_room.flg_pref%TYPE;
    BEGIN
        FOR i IN 1 .. i_room.count
        LOOP
            -- Loop sobre o array de IDs de salas canceladas    
            g_error := 'OPEN C_PREF';
            OPEN c_pref(i_room(i));
            FETCH c_pref
                INTO l_flg_pref;
            CLOSE c_pref;
            IF l_flg_pref = g_prof_room_pref
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'DELETE';
            DELETE prof_room
             WHERE id_professional = i_prof.id
               AND id_room = i_room(i);
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_TOOLS',
                                   'CANCEL_PROF_ROOM',
                                   pk_message.get_message(i_lang, 'TOOLS_M002'),
                                   'U');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'CANCEL_PROF_ROOM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_prof_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem das escolhas da instituição        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)        
                Saída:   O_LIST - listagem das instituições 
                     O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) inst
              FROM prof_room pf, room r, department d, institution i
             WHERE pf.id_professional = i_prof.id
               AND r.id_room = pf.id_room
               AND r.id_department = d.id_department
               AND i.id_institution = d.id_institution
               AND i.id_institution = i_prof.institution
               AND i.flg_available = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_PROF_INST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        i_dep   IN department.id_department%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem das escolhas salas por departamento 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                 I_INST - instituição seleccionada 
                                 I_DEP - Departamento seleccionado   
                Saída:   O_LIST - listagem das instituições 
                 O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          ALTERAÇÃO: CRS 2006/11/10 Alteração do objectivo da função 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT to_char(r.id_room) id_room, -- to_char due to flash restrictions
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   decode(nvl(pr.id_room, 0), 0, 'N', 'Y') flg_select,
                   nvl(pr.flg_pref, g_prof_room_npref) flg_pref
              FROM room r, prof_room pr
             WHERE pr.id_professional(+) = i_prof.id
               AND r.id_room = pr.id_room(+)
               AND r.id_department = i_dep
               AND r.flg_available = g_flg_available
             ORDER BY r.rank, desc_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_PROF_ROOM');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN department.id_department%TYPE,
        o_dcs   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter listagem dos dep. serv. clin.      
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_DEP - departamento seleccionado    
                Saída:   O_DCS - listagem dos dep.clin.serv. disponíveis e escolhidos    
                     O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET O_DCS';
        OPEN o_dcs FOR
            SELECT to_char(dcs.id_dep_clin_serv) id_dep_clin_serv, -- to_char due to flash restrictions
                   dcs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_clin_serv,
                   pdc.flg_default,
                   cli.rank,
                   decode(pdc.flg_status, g_status_pdcs_s, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_select
              FROM dep_clin_serv dcs
             INNER JOIN clinical_service cli
                ON (dcs.id_clinical_service = cli.id_clinical_service)
             INNER JOIN prof_dep_clin_serv pdc
                ON (dcs.id_dep_clin_serv = pdc.id_dep_clin_serv)
             WHERE pdc.id_professional = i_prof.id
               AND dcs.id_department = i_dep
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND cli.flg_available = pk_alert_constant.g_yes
             ORDER BY cli.rank, desc_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_DEP_CLIN_SERV');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_dcs);
                -- return failure
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************
    * Saves the old professional dep_clin_serv in the log table
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_dcs                        dep_clin_serv ID
    * @param i_dft                        default dep_clin_serv: Y - yes; N - no
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             José Silva
    * @version                            1.0   
    * @since                              05-06-2008
    **********************************************************************************************/

    FUNCTION set_dep_clin_serv_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_dcs     IN table_number,
        i_flg     IN table_varchar,
        i_dft     IN table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin    prof_dep_clin_serv_hist.dt_begin%TYPE;
        l_dt_end      prof_dep_clin_serv_hist.dt_end%TYPE;
        l_flg_default prof_dep_clin_serv_hist.flg_default%TYPE;
    
        CURSOR c_prof
        (
            l_id_dcs IN prof_dep_clin_serv.id_dep_clin_serv%TYPE,
            i_dft    IN VARCHAR,
            i_flg    IN VARCHAR
        ) IS
            SELECT coalesce(p.dt_creation, g_sysdate_tstz, current_timestamp),
                   nvl(g_sysdate_tstz, current_timestamp),
                   p.flg_default
              FROM prof_dep_clin_serv p
             WHERE p.id_professional = i_id_prof.id
               AND p.id_dep_clin_serv = l_id_dcs
               AND (i_flg = g_no OR p.flg_default <> i_dft)
               AND p.flg_status = g_selected;
    
    BEGIN
    
        g_error := 'LOOP i_dcs';
        FOR i IN 1 .. i_dcs.count
        LOOP
        
            g_error := 'SET PROF_DEP_CLIN_SERV LOG';
        
            BEGIN
                OPEN c_prof(i_dcs(i), i_dft(i), i_flg(i));
                FETCH c_prof
                    INTO l_dt_begin, l_dt_end, l_flg_default;
                g_found := c_prof%FOUND;
                CLOSE c_prof;
            
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN TRUE;
                
            END;
        
            g_error := 'SET PROF_DEP_CLIN_SERV_HIST: ' || i_dcs(i) || ' / ' || to_char(l_dt_begin) || ' / ' ||
                       i_id_prof.id;
        
            IF g_found
            THEN
            
                ts_prof_dep_clin_serv_hist.ins(id_professional_in  => i_id_prof.id,
                                               id_dep_clin_serv_in => i_dcs(i),
                                               dt_begin_in         => l_dt_begin,
                                               dt_end_in           => l_dt_end,
                                               flg_default_in      => l_flg_default,
                                               id_institution_in   => i_id_prof.institution);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'SET_DEP_CLIN_SERV_HIST');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END set_dep_clin_serv_hist;

    FUNCTION set_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dcs   IN table_number,
        i_flg   IN table_varchar,
        i_dft   IN table_varchar,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Registar a info      
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                     I_DCS - array dos dep.clin.serv. escolhidos  
                     I_FLG - array com indicação se é SELECCIONADO (Y) ou ELIMINADO(N)    
                Saída:   O_ERROR - erro 
          CRIAÇÃO: SS 2005/11/07 
          NOTAS: 
        ******************************************************************************************************/
    
        CURSOR c_prof(l_id_dcs IN prof_dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT 'X'
              FROM prof_dep_clin_serv
             WHERE id_professional = i_prof.id
               AND id_dep_clin_serv = l_id_dcs;
        --    AND FLG_STATUS = G_SELECTED; -- JS: Caso contrário repete as entradas
    
        CURSOR c_prof_dcs IS
            SELECT DISTINCT 'X'
              FROM prof_dep_clin_serv pdcs
             WHERE id_professional = i_prof.id
               AND pdcs.flg_status = g_selected
               AND pdcs.id_institution = i_prof.institution;
    
        CURSOR c_aux_prof_dcs
        (
            id_dcs  NUMBER,
            id_prof NUMBER,
            id_d    table_number
        ) IS
            SELECT decode(id_dep_clin_serv, id_dcs, 'Y', 'N') flag, pdcs.id_prof_dep_clin_serv id_pdcs
              FROM prof_dep_clin_serv pdcs
             WHERE pdcs.id_professional = id_prof
               AND pdcs.id_dep_clin_serv IN
                   (SELECT id_dep_clin_serv
                      FROM dep_clin_serv
                     WHERE id_department IN (SELECT /*+ordered use_nl(a d)*/
                                              id_department
                                               FROM TABLE(id_d) a
                                               JOIN department d
                                                 ON d.id_dept = a.column_value
                                              WHERE d.flg_available = pk_alert_constant.g_yes));
    
        --AND ID_SOFTWARE = I_PROF.SOFTWARE));
    
        l_id_dcs   prof_dep_clin_serv.id_dep_clin_serv%TYPE;
        l_prof     VARCHAR2(1);
        l_prof_dcs VARCHAR2(1);
    
        l_depts table_number;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        IF NOT set_dep_clin_serv_hist(i_lang, i_prof, i_dcs, i_flg, i_dft, o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        -- associar o profissional aos dep.clin.serv.     
        FOR i IN 1 .. i_dcs.count
        LOOP
        
            IF i_dft(i) = 'Y'
            THEN
            
                -- determinar id_dept
                g_error := 'GET SOFTWARE LIST';
                SELECT (CAST(MULTISET (SELECT DISTINCT sd2.id_dept
                                FROM software_dept sd
                                JOIN software_dept sd2
                                  ON sd.id_software = sd2.id_software
                                JOIN dept d2
                                  ON d2.id_dept = sd2.id_dept
                                JOIN TABLE(pk_prof_utils.get_prof_softwares(i_lang, i_prof, d.id_institution))
                                  ON column_value = sd2.id_software
                               WHERE sd.id_dept = d.id_dept
                                 AND d2.id_institution = d.id_institution
                                 AND d2.flg_available = pk_alert_constant.g_yes) AS table_number) MULTISET UNION
                        DISTINCT table_number(d.id_dept)) id_dept
                  INTO l_depts
                  FROM department dpt
                  JOIN dep_clin_serv dcs
                    ON dcs.id_department = dpt.id_department
                  JOIN dept d
                    ON d.id_dept = dpt.id_dept
                 WHERE dcs.id_dep_clin_serv = i_dcs(i);
            
                FOR k IN c_aux_prof_dcs(i_dcs(i), i_prof.id, l_depts)
                LOOP
                
                    ts_prof_dep_clin_serv.upd(flg_default_in => k.flag,
                                              where_in       => 'ID_PROF_DEP_CLIN_SERV = ' || k.id_pdcs);
                
                END LOOP;
            
            ELSE
            
                -- update when flg is removed
                ts_prof_dep_clin_serv.upd(flg_default_in => i_dft(i),
                                          where_in       => 'id_professional = ' || i_prof.id ||
                                                            'AND id_dep_clin_serv =' || i_dcs(i));
            
            END IF;
        
            IF i_flg(i) = 'N'
            THEN
                --Apagar as associações entre o profissional e dep.clin.serv.
                g_error := 'UPDATE PROF_DEP_CLIN_SERV 1';
            
                ts_prof_dep_clin_serv.upd(flg_status_in => 'D',
                                          where_in      => 'id_professional = ' || i_prof.id || 'AND id_dep_clin_serv =' ||
                                                           i_dcs(i));
            
            ELSE
                g_error := 'OPEN C_PROF ' || i_dcs(i);
                OPEN c_prof(i_dcs(i));
                FETCH c_prof
                    INTO l_prof;
                g_found := c_prof%NOTFOUND;
                CLOSE c_prof;
            
                IF g_found
                THEN
                    g_error := 'INSERT INTO PROF_DEP_CLIN_SERV' || i_dcs(i);
                
                    ts_prof_dep_clin_serv.ins(id_prof_dep_clin_serv_in => ts_prof_dep_clin_serv.next_key,
                                              id_professional_in       => i_prof.id,
                                              id_dep_clin_serv_in      => i_dcs(i),
                                              flg_status_in            => g_selected,
                                              flg_default_in           => 'N',
                                              id_institution_in        => i_prof.institution,
                                              dt_creation_in           => current_timestamp);
                
                ELSE
                    g_error := 'UPDATE PROF_DEP_CLIN_SERV 2';
                
                    ts_prof_dep_clin_serv.upd(flg_status_in  => g_selected,
                                              dt_creation_in => current_timestamp,
                                              where_in       => 'id_professional = ' || i_prof.id ||
                                                                'AND id_dep_clin_serv =' || i_dcs(i));
                
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'OPEN C_PROF_DCS';
        OPEN c_prof_dcs;
        FETCH c_prof_dcs
            INTO l_prof_dcs;
        g_found := c_prof_dcs%NOTFOUND;
        CLOSE c_prof_dcs;
    
        IF g_found
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_TOOLS',
                                   'CANCEL_PROF_ROOM',
                                   pk_message.get_message(i_lang, 'TOOLS_M004'),
                                   'U');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'SET_DEP_CLIN_SERV');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_prof_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_inst       IN institution.id_institution%TYPE,
        i_room_cserv IN VARCHAR2,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter departamentos para os quais o profissional está alocado (salas ou serv. clínicos)       
           PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
                 I_PROF - profissional (ID, INSTITUTION, SOFTWARE)  
                 I_DCS - array dos dep.clin.serv. escolhidos  
                 I_FLG - array com indicação se é SELECCIONADO (Y) ou ELIMINADO(N)    
               Saída: O_LIST - lista de departamentos 
                            O_ERROR - erro 
          CRIAÇÃO: CRS 2006/11/10 
          NOTAS: 
        ******************************************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT DISTINCT d.id_department,
                            pk_translation.get_translation(i_lang, d.code_department) desc_dep,
                            decode(decode(d.flg_type,
                                          g_dep_inp,
                                          11,
                                          g_dep_or,
                                          2,
                                          g_dep_cons_ext,
                                          1,
                                          g_dep_cons_pri,
                                          3,
                                          g_dep_cons_cli,
                                          12,
                                          g_dep_ed,
                                          8,
                                          g_dep_lab,
                                          16,
                                          g_dep_imag,
                                          15),
                                   i_prof.software,
                                   'Y',
                                   'N') flg_default
              FROM department d,
                   room       r, --translation t, 
                   prof_room  pr
             WHERE d.id_institution = i_inst
               AND r.id_department = d.id_department
                  --               AND t.code_translation = r.code_room
                  --               AND t.id_language = i_lang
                  --               AND t.desc_translation IS NOT NULL
               AND nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) IS NOT NULL
               AND r.id_room = pr.id_room
               AND pr.id_professional = i_prof.id
               AND d.flg_available = pk_alert_constant.g_yes
             ORDER BY desc_dep;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_PROF_DEP');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION get_soft_lang
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Obter aplicações a que o user tem acesso e língua preferencial em cada        
           PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
                I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                                I_INST - Instituição seleccionada 
        
               Saída: O_LIST - lista de departamentos 
                            O_ERROR - erro 
          CRIAÇÃO: CRS 2007/02/13 
          NOTAS: 
        ******************************************************************************************************/
    
        CURSOR c_all IS
            SELECT l.desc_language
              FROM prof_preferences pp, LANGUAGE l
             WHERE pp.id_professional = i_prof.id
               AND pp.id_institution = i_inst
               AND l.id_language = pp.id_language
               AND rownum = 1;
    
        l_lang           VARCHAR2(50);
        l_triage_type    triage_type.id_triage_type%TYPE;
        l_triage_acronym triage_type.acronym%TYPE;
        l_triage_error EXCEPTION;
    BEGIN
        g_error := 'OPEN C_ALL';
        OPEN c_all;
        FETCH c_all
            INTO l_lang;
        CLOSE c_all;
    
        IF NOT pk_edis_triage.get_default_triage_type(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      o_triage_type    => l_triage_type,
                                                      o_triage_acronym => l_triage_acronym,
                                                      o_error          => o_error)
        THEN
            RAISE l_triage_error;
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT pk_message.get_message(i_lang, 'COMMON_M014') name,
                   l_lang desc_language,
                   '' desc_software,
                   0 order_by,
                   NULL id_software,
                   '' desc_val
              FROM dual
            UNION
            SELECT s.name,
                   l.desc_language,
                   nvl((SELECT REPLACE(sl.desc_software, '<br>', ' ')
                         FROM soft_lang sl
                        WHERE sl.id_software = s.id_software
                          AND sl.id_language = l.id_language),
                       s.desc_software) desc_software,
                   1 order_by,
                   s.id_software,
                   sd.desc_val
              FROM prof_soft_inst psi, prof_preferences pp, software s, LANGUAGE l, sys_domain sd
             WHERE psi.id_professional = i_prof.id
               AND psi.id_institution = i_inst
               AND pp.id_software = psi.id_software
               AND pp.id_professional = psi.id_professional
               AND pp.id_institution = psi.id_institution
               AND s.id_software = psi.id_software
               AND l.id_language = pp.id_language
               AND sd.code_domain(+) = g_domain_template
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.id_language(+) = i_lang
               AND sd.val(+) = pk_sysconfig.get_config(g_config_document_text, i_inst, psi.id_software)
                  --REMOVER AUDITORIA DE MANCHESTER EM INSTITUIÇÕES SEM ESTA TRIAGEM
               AND decode(l_triage_acronym, 'M', s.id_software, decode(s.id_software, 32, NULL, s.id_software)) =
                   s.id_software
             ORDER BY order_by;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'GET_SOFT_LANG');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- fechar os cursores
                pk_types.open_my_cursor(o_list);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION set_soft_lang
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_lang_selected IN language.id_language%TYPE,
        i_inst          IN institution.id_institution%TYPE,
        i_soft          IN software.id_software%TYPE,
        o_lang          OUT language.id_language%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Alterar língua do utilizador     
           PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
                I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                                I_LANG_SELECTED - Língua seleccionada 
                                I_INST - Instituição seleccionada 
                                I_SOFT - Aplicação seleccionada 
        
               Saída: O_LANG - Língua actual, para o utilizador / aplicação / instituição actual 
                            O_ERROR - erro 
          CRIAÇÃO: CRS 2007/02/13 
          NOTAS: 
        ******************************************************************************************************/
    
        -- core tables new params
        l_si_user_info NUMBER := 0;
    
    BEGIN
        g_error := 'GET AB_SOFT_INST_USER_INFO PK:' || i_prof.id || '.' || i_soft || '.' || i_inst;
        BEGIN
            SELECT pp.id_ab_soft_inst_user_info
              INTO l_si_user_info
              FROM ab_soft_inst_user_info pp
              JOIN ab_software_institution si
                ON (pp.id_ab_software_institution = si.id_ab_software_institution)
             WHERE pp.id_ab_user_info = i_prof.id
               AND si.id_ab_software = i_soft
               AND si.id_ab_institution = i_inst;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE;
        END;
    
        g_error := 'UPDATE PROF_PREFERENCES';
        pk_api_ab_tables.update_ab_sw_ins_usr_info(id_ab_soft_inst_user_info_in => l_si_user_info,
                                                   id_ab_language_in            => i_lang_selected,
                                                   id_ab_language_nin           => FALSE);
    
        o_lang := i_lang_selected;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'SET_SOFT_LANG');
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- return failure
                RETURN FALSE;
            END;
    END;

    FUNCTION set_documentation
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************************************
           OBJECTIVO: Alternar entre modo de texto e documentation para HIMSS 2007     
           PARAMETROS: Entrada: I_LANG - Língua registada como preferência do profissional 
                I_PROF - profissional (ID, INSTITUTION, SOFTWARE) 
                                I_TYPE - D - Documentation; N - Normal
        
               Saída: O_ERROR - erro 
          CRIAÇÃO: CRS 2007/02/14 
          NOTAS: 
        ******************************************************************************************************/
        l_config  VARCHAR2(50);
        l_config2 VARCHAR2(50);
    
    BEGIN
        l_config  := pk_sysconfig.get_config('DOCUMENTATION_TEXT', i_prof);
        l_config2 := pk_sysconfig.get_config('DOCUMENTATION_INST', i_prof);
    
        IF i_prof.software = 1
        THEN
            IF i_type = 'D'
               AND l_config != 'D'
            THEN
            
                g_error := 'UPDATE SYS_CONFIG';
                UPDATE sys_config
                   SET VALUE = 'D'
                 WHERE id_sys_config = 'DOCUMENTATION_TEXT'
                   AND id_software = 1
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_CONFIG2';
                UPDATE sys_config
                   SET VALUE = 'D'
                 WHERE id_sys_config = 'DOCUMENTATION_INST'
                   AND id_software = 1
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_BUTTON_PROP(1)';
                UPDATE sys_button_prop
                   SET flg_visible = 'Y'
                 WHERE id_sys_button_prop IN (14799, 14800, 14802); --, 14801
            
                g_error := 'UPDATE SYS_BUTTON_PROP(2)';
                UPDATE sys_button_prop
                   SET flg_visible = 'N'
                 WHERE id_sys_button_prop IN (12396, 12397, 12411); --, 13346
            
                g_error := 'UPDATE SYS_SHORTCUT COMPLAINT';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 14799
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2453;
            
                g_error := 'UPDATE SYS_SHORTCUT HISTORY';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 14800
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2454;
            
                g_error := 'UPDATE SYS_SHORTCUT PHYS EXAM';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 14802
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2460;
            
            ELSIF i_type = 'N'
                  AND l_config != 'N'
            THEN
                g_error := 'UPDATE SYS_CONFIG';
                UPDATE sys_config
                   SET VALUE = 'N'
                 WHERE id_sys_config = 'DOCUMENTATION_TEXT'
                   AND id_software = 1
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_CONFIG2';
                UPDATE sys_config
                   SET VALUE = 'N'
                 WHERE id_sys_config = 'DOCUMENTATION_INST'
                   AND id_software = 1
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_BUTTON_PROP(1)';
                UPDATE sys_button_prop
                   SET flg_visible = 'Y'
                 WHERE id_sys_button_prop IN (12396, 12397, 12411); --, 13346
            
                g_error := 'UPDATE SYS_BUTTON_PROP(2)';
                UPDATE sys_button_prop
                   SET flg_visible = 'N'
                 WHERE id_sys_button_prop IN (14799, 14800, 14802); --, 14801
            
                g_error := 'UPDATE SYS_SHORTCUT COMPLAINT';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 12396
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2453;
            
                g_error := 'UPDATE SYS_SHORTCUT HISTORY';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 12397
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2454;
            
                g_error := 'UPDATE SYS_SHORTCUT PHYS EXAM';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 12411
                 WHERE id_software = 1
                   AND id_shortcut_pk = 2460;
            
            END IF;
        
        ELSIF i_prof.software = 3
        THEN
        
            IF i_type = 'D'
               AND l_config != 'D'
            THEN
                g_error := 'UPDATE SYS_CONFIG';
                UPDATE sys_config
                   SET VALUE = 'D'
                 WHERE id_sys_config = 'DOCUMENTATION_TEXT'
                   AND id_software = 3
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_CONFIG2';
                UPDATE sys_config
                   SET VALUE = 'D'
                 WHERE id_sys_config = 'DOCUMENTATION_INST'
                   AND id_software = 3
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_BUTTON_PROP(1)';
                UPDATE sys_button_prop
                   SET flg_visible = 'Y'
                 WHERE id_sys_button_prop IN (11793, 11794, 11796, 11795);
            
                g_error := 'UPDATE SYS_BUTTON_PROP(2)';
                UPDATE sys_button_prop
                   SET flg_visible = 'N'
                 WHERE id_sys_button_prop IN (7442, 7392, 6994, 7398);
            
                g_error := 'UPDATE SYS_SHORTCUT COMPLAINT';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 11793
                 WHERE id_software = 3
                   AND id_shortcut_pk = 285;
            
                g_error := 'UPDATE SYS_SHORTCUT HISTORY';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 11794
                 WHERE id_software = 3
                   AND id_shortcut_pk = 278;
            
                g_error := 'UPDATE SYS_SHORTCUT PHYS EXAM';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 11795
                 WHERE id_software = 3
                   AND id_shortcut_pk = 287;
            
                g_error := 'UPDATE SYS_SHORTCUT RELEV DISEASES';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 11796
                 WHERE id_software = 3
                   AND id_shortcut_pk = 307;
            
            ELSIF i_type = 'N'
                  AND l_config != 'N'
            THEN
                g_error := 'UPDATE SYS_CONFIG';
                UPDATE sys_config
                   SET VALUE = 'N'
                 WHERE id_sys_config = 'DOCUMENTATION_TEXT'
                   AND id_software = 3
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_CONFIG2';
                UPDATE sys_config
                   SET VALUE = 'N'
                 WHERE id_sys_config = 'DOCUMENTATION_INST'
                   AND id_software = 3
                   AND id_institution = i_prof.institution;
            
                g_error := 'UPDATE SYS_BUTTON_PROP(1)';
                UPDATE sys_button_prop
                   SET flg_visible = 'N'
                 WHERE id_sys_button_prop IN (11793, 11794, 11796, 11795);
            
                g_error := 'UPDATE SYS_BUTTON_PROP(2)';
                UPDATE sys_button_prop
                   SET flg_visible = 'Y'
                 WHERE id_sys_button_prop IN (7442, 7392, 6994, 7398);
            
                g_error := 'UPDATE SYS_SHORTCUT COMPLAINT';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 7442
                 WHERE id_software = 3
                   AND id_shortcut_pk = 285;
            
                g_error := 'UPDATE SYS_SHORTCUT HISTORY';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 7392
                 WHERE id_software = 3
                   AND id_shortcut_pk = 278;
            
                g_error := 'UPDATE SYS_SHORTCUT PHYS EXAM';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 7398
                 WHERE id_software = 3
                   AND id_shortcut_pk = 287;
            
                g_error := 'UPDATE SYS_SHORTCUT RELEV DISEASES';
                UPDATE sys_shortcut
                   SET id_sys_button_prop = 6994
                 WHERE id_software = 3
                   AND id_shortcut_pk = 307;
            END IF;
        
        END IF;
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_TOOLS', 'SET_DOCUMENTATION');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                -- undo changes
                pk_utils.undo_changes;
                -- return failure
                RETURN FALSE;
            END;
    END;
    --
    /********************************************************************************************
    * Nome completo do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_prof_name
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_name professional.name%TYPE;
    BEGIN
        BEGIN
            SELECT p.name
              INTO l_name
              FROM professional p
             WHERE p.id_professional = i_professional;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_name := NULL;
        END;
    
        RETURN l_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --
    /********************************************************************************************
    * Nome abreviado do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/09/24
    **********************************************************************************************/
    FUNCTION get_prof_nick_name
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_name professional.name%TYPE;
    BEGIN
        BEGIN
            SELECT p.nick_name
              INTO l_name
              FROM professional p
             WHERE p.id_professional = i_professional;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_name := NULL;
        END;
    
        RETURN l_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --
    /********************************************************************************************
    * Especialidade do profissional que requisitou
    *
    * @param i_lang                language id
    * @param i_professional        professional id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/10
    **********************************************************************************************/
    FUNCTION get_prof_speciality
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_speciality pk_translation.t_desc_translation;
    BEGIN
        BEGIN
            SELECT pk_translation.get_translation(i_lang, s.code_speciality)
              INTO l_speciality
              FROM speciality s, professional p
             WHERE p.id_professional = i_professional
               AND p.id_speciality = s.id_speciality;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_speciality := NULL;
        END;
    
        RETURN l_speciality;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    --
    /********************************************************************************************
    * Descrição ou abreviatura da instituição
    *
    * @param i_lang                language id
    * @param i_institution         institution id
    * @param i_flg_desc            A - Abreviatura; D - Descrição
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/10
    **********************************************************************************************/
    FUNCTION get_desc_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_flg_desc    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_desc_institution pk_translation.t_desc_translation;
    BEGIN
        BEGIN
            SELECT decode(i_flg_desc,
                          g_abbreviation,
                          i.abbreviation,
                          pk_translation.get_translation(i_lang, i.code_institution))
              INTO l_desc_institution
              FROM institution i
             WHERE i.id_institution = i_institution;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_desc_institution := NULL;
        END;
    
        RETURN l_desc_institution;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Return professional's category.flg_type within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         FLG_TYPE from category table
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2007/12/17
    **********************************************************************************************/
    FUNCTION get_prof_cat(i_prof IN profissional) RETURN VARCHAR2 IS
        l_type category.flg_type%TYPE;
    BEGIN
        g_error := 'GET TYPE';
        SELECT c.flg_type
          INTO l_type
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = c.id_category
           AND rownum = 1;
    
        RETURN l_type;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Return professional's PROFILE_TEMPLATE within institution and software
    *
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         ID_PROFILE_TEMPLATE from PROFILE_TEMPLATE table
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          2008/04/15
    **********************************************************************************************/
    FUNCTION get_prof_profile_template(i_prof IN profissional) RETURN profile_template.id_profile_template%TYPE IS
        l_ptempl profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'GET TEMPLATE';
        SELECT pt.id_profile_template
          INTO l_ptempl
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
           AND ppt.id_profile_template = pt.id_profile_template
           AND ppt.id_software = pt.id_software
           AND pt.flg_available = 'Y';
    
        RETURN l_ptempl;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Professional description ready to be presented in reports
    *
    * @param i_lang                language id
    * @param i_prof                professional
    * @param i_prof_id             professional id who wrote the data
    * @param i_date                Date (timestamp)
    * @param i_episode             Episode ID
    *
    * @return                      Professional description, with name and specialty, if any is defined
    *    
    * @author                      João Taborda
    * @version                     1.0
    * @since                       2008/ABR/15
    *
    * UPDATED
    * ALERT-10363 - Alteração do nome do profissional e especialidade do Timestamp
    * @author  Jose Antunes
    * @version 2.5
    * @date    10-03-2009
    **********************************************************************************************/
    FUNCTION get_prof_description
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_desc pk_translation.t_desc_translation;
        l_sign      pk_translation.t_desc_translation;
    BEGIN
        l_prof_desc := pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => i_prof_id);
    
        l_sign := pk_prof_utils.get_spec_signature(i_lang    => i_lang,
                                                   i_prof    => i_prof,
                                                   i_prof_id => i_prof_id,
                                                   i_dt_reg  => i_date,
                                                   i_episode => i_episode);
    
        IF l_sign IS NOT NULL
        THEN
            l_prof_desc := l_prof_desc || ' (' || l_sign || ')';
        END IF;
    
        RETURN l_prof_desc;
    END get_prof_description;

    /********************************************************************************************
    * Professional description ready to be presented in reports paramedical professional:
    * Professional name (Institution Abr)
    *
    * @param i_lang                language id
    * @param i_prof                professional
    * @param i_prof_id             professional id who wrote the data
    * @param i_date                Date (timestamp)
    * @param i_episode             Episode ID
    *
    * @return                      Professional description, with name and specialty, if any is defined
    *    
    * @author                      Sofia Mendes
    * @version                     2.6.0.3
    * @since                       13-Jul-2010
    *    
    **********************************************************************************************/
    FUNCTION get_prof_description_cat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN professional.id_professional%TYPE,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_prof_desc pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof_id) ||
               decode(cat_table.cat_desc, NULL, NULL, ' (' || cat_table.cat_desc || ')')
          INTO l_prof_desc
          FROM professional p,
               (SELECT pk_prof_utils.get_desc_category(i_lang, i_prof, i_prof_id, i_prof.institution) AS cat_desc
                  FROM dual) cat_table
         WHERE p.id_professional = i_prof.id;
    
        RETURN l_prof_desc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_prof_description_cat;

    /**********************************************************************************************
    * Check the availability of a professional into a software for Exams and Analysis 
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_id_professional         Professional identifier
    * @param       i_id_institution          Institution identifier
    * @param       i_flg_soft_context        Flag to check when analysis or exams
    * @param       o_prof_valid              Flag that returns if the professional is valid or not to the related context
    * @param       o_id_software             The software identifier for the related context where the professional has permissions
    * @param       o_message                 Error message
    *
    * @return                                true on success, otherwise false
    *
    * @value       i_flg_soft_context        {*} 'ANA'- ANALYSIS {*} 'EXA'- EXAMS
    * @value       o_prof_valid              {*} 'Y'- VALID {*} 'N'- NOT VALID
    *
    * @author                                António Neto
    * @version                               2.6.2.0.5
    * @since                                 09-Jan-2011
    **********************************************************************************************/
    FUNCTION get_prof_software
    (
        i_lang             IN language.id_language%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_flg_soft_context IN VARCHAR2,
        o_prof_valid       OUT VARCHAR2,
        o_id_software      OUT NUMBER,
        o_message          OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_flg_soft_context_exa CONSTANT VARCHAR2(3 CHAR) := 'EXA';
        l_flg_soft_context_ana CONSTANT VARCHAR2(3 CHAR) := 'ANA';
    
        l_id_soft_context_exa_15 CONSTANT NUMBER(3) := 15;
        l_id_soft_context_exa_33 CONSTANT NUMBER(3) := 33;
        l_id_soft_context_exa_25 CONSTANT NUMBER(3) := 25;
    
        l_id_soft_context_ana_16 CONSTANT NUMBER(3) := 16;
        l_id_soft_context_ana_33 CONSTANT NUMBER(3) := 33;
    
        l_order_first_1  CONSTANT NUMBER(1) := 1;
        l_order_second_2 CONSTANT NUMBER(1) := 2;
        l_order_third_3  CONSTANT NUMBER(1) := 3;
    
        l_ret BOOLEAN := TRUE;
    
        l_exception EXCEPTION;
    
        l_software_filter table_number;
    
        l_error t_error_out;
    
        PROCEDURE set_error_info IS
            l_message CONSTANT VARCHAR2(15 CHAR) := 'CHECK_TECH_M001';
        BEGIN
            o_prof_valid  := pk_alert_constant.g_no;
            o_id_software := NULL;
            o_message     := pk_message.get_message(i_lang => i_lang, i_code_mess => l_message);
        END set_error_info;
    BEGIN
    
        g_error := 'Check flag to apply filters';
        IF i_flg_soft_context = l_flg_soft_context_exa
        THEN
            --Exams
            l_software_filter := table_number(l_id_soft_context_exa_15,
                                              l_id_soft_context_exa_33,
                                              l_id_soft_context_exa_25);
        ELSIF i_flg_soft_context = l_flg_soft_context_ana
        THEN
            --Analysis
            l_software_filter := table_number(l_id_soft_context_ana_16, l_id_soft_context_ana_33);
        ELSE
            --Other
            RAISE l_exception;
        END IF;
    
        g_error := 'Get software identifier';
        BEGIN
            SELECT t.id_software
              INTO o_id_software
              FROM (SELECT decode(i_flg_soft_context,
                                  l_flg_soft_context_exa,
                                  
                                  decode(ppt.id_software,
                                         l_id_soft_context_exa_15,
                                         l_order_first_1,
                                         l_id_soft_context_exa_33,
                                         l_order_second_2,
                                         l_id_soft_context_exa_25,
                                         l_order_third_3,
                                         NULL),
                                  l_flg_soft_context_ana,
                                  decode(ppt.id_software,
                                         l_id_soft_context_ana_16,
                                         l_order_first_1,
                                         l_id_soft_context_exa_33,
                                         l_order_second_2,
                                         NULL)) sw_rank,
                           ppt.id_software
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_id_professional
                       AND ppt.id_institution = i_id_institution
                       AND ppt.id_software IN (SELECT *
                                                 FROM TABLE(l_software_filter) tn)
                     ORDER BY sw_rank) t
             WHERE rownum = l_order_first_1;
        EXCEPTION
            WHEN no_data_found THEN
                l_ret         := FALSE;
                o_id_software := NULL;
        END;
    
        IF NOT l_ret
           OR o_id_software IS NULL
        THEN
            set_error_info;
        ELSE
            o_prof_valid := pk_alert_constant.g_yes;
            o_message    := NULL;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_PROF_SOFTWARE',
                                              l_error);
            set_error_info;
            RETURN FALSE;
    END get_prof_software;

    /********************************************************************************************
    * Get all institution clinical services.
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_institution            institution id  
    *
    * @return   table_number that contains all clinical services identifiers
    *
    * @author   Gisela Couto
    * @version  2.6.4.1.1
    * @since    2014/08/27
    ********************************************************************************************/
    FUNCTION get_inst_clin_serv_ids
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_number IS
        clin_services table_number := table_number();
        l_error       t_error_out;
    BEGIN
    
        g_error := 'GET ALL CLINICAL SERVICES IDENTIFIERS IN THE INSTITUTION ' || i_institution;
        BEGIN
            SELECT DISTINCT cs.id_clinical_service
              BULK COLLECT
              INTO clin_services
              FROM clinical_service cs
              JOIN dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
              JOIN department d
                ON (dcs.id_department = d.id_department)
              JOIN institution inst
                ON (inst.id_institution = d.id_institution)
             WHERE inst.id_institution = i_institution
               AND cs.flg_available = pk_alert_constant.g_yes
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND d.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                g_error       := 'NO CLINICAL SERVICES FOUNDED';
                clin_services := NULL;
        END;
    
        RETURN clin_services;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_INST_CLIN_SERV_IDS',
                                              l_error);
            RETURN NULL;
    END get_inst_clin_serv_ids;

    /********************************************************************************************
    * Get all institution clinical services.
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_institution            institution id  
    *
    * @return   table_varchar that contains all clinical services codes
    *
    * @author   Gisela Couto
    * @version  2.6.4.1.1
    * @since    2014/08/27
    ********************************************************************************************/
    FUNCTION get_inst_clin_serv_codes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN table_varchar IS
        clin_services table_varchar := table_varchar();
        l_error       t_error_out;
    BEGIN
    
        g_error := 'GET ALL CLINICAL SERVICES CODES IN THE INSTITUTION ' || i_institution;
        BEGIN
            SELECT DISTINCT cs.code_clinical_service
              BULK COLLECT
              INTO clin_services
              FROM clinical_service cs
              JOIN dep_clin_serv dcs
                ON dcs.id_clinical_service = cs.id_clinical_service
              JOIN department d
                ON (dcs.id_department = d.id_department)
              JOIN institution inst
                ON (inst.id_institution = d.id_institution)
             WHERE inst.id_institution = i_institution
               AND cs.flg_available = pk_alert_constant.g_yes
               AND dcs.flg_available = pk_alert_constant.g_yes
               AND d.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                g_error       := 'NO CLINICAL SERVICES FOUNDED';
                clin_services := NULL;
        END;
    
        RETURN clin_services;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_INST_CLIN_SERV_CODES',
                                              l_error);
            RETURN NULL;
    END get_inst_clin_serv_codes;

--
BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_tools;
/
