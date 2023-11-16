/*-- Last Change Revision: $Rev: 2026790 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_p1 IS

    /** @headcom
    * Public Function. Get P1 Origin Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_PROF                  Professional Id
    * @param      O_P1_ORIG_INST             Cursor with information listing the institutions origin of P1 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/16
    */
    FUNCTION get_p1_orig_instit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        o_p1_orig_inst OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1_ORIG_INSTIT CURSOR';
        OPEN o_p1_orig_inst FOR
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) desc_instit, i.ext_code
              FROM institution i, prof_soft_inst psi
             WHERE psi.id_professional = i_id_prof
               AND i.id_institution = psi.id_institution
               AND psi.id_software = 26
               AND i.flg_available = g_flg_avail
               AND i.flg_type IN ('C', 'E')
             ORDER BY desc_instit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_p1_orig_inst);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_ORIG_INSTIT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_orig_instit;

    /** @headcom
    * Public Function. Get P1 Origin Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      o_p1_dest                  Cursor with the P1 destination institutions list 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/14
    */
    FUNCTION get_p1_all_dest
    (
        i_lang    IN language.id_language%TYPE,
        o_p1_dest OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_p1_dest FOR
            SELECT DISTINCT p1_di.id_inst_dest,
                            pk_translation.get_translation(i_lang, i.code_institution) inst_dest,
                            i.ext_code
              FROM p1_dest_institution p1_di, institution i
             WHERE p1_di.id_inst_dest = i.id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_p1_dest);
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_ALL_DEST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_all_dest;

    /** @headcom
    * Public Function. Get P1 (Consult, Analysis, Exams, Interventions) Destination Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_ORIG_INSTIT           Origin institution identification
    * @param      O_CONSULT                  Cursor with a list of the P1 destination institutions for consult 
    * @param      O_ANALYSIS                 Cursor with a list of the P1 destination institutions for analysis
    * @param      O_EXAMS                    Cursor with a list of the P1 destination institutions for exams
    * @param      O_INTERV                   Cursor with a list of the P1 destination institutions for interventions
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/14
    */
    FUNCTION get_p1_dest
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        o_consult        OUT pk_types.cursor_type,
        o_analysis       OUT pk_types.cursor_type,
        o_exams          OUT pk_types.cursor_type,
        o_interv         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_consult FOR
            SELECT p1_di.id_inst_dest,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT i1.code_institution
                                                     FROM institution i1
                                                    WHERE i1.id_institution = p1_di.id_inst_dest)) inst_dest,
                   p1_di.flg_default
              FROM p1_dest_institution p1_di
             WHERE p1_di.id_inst_orig = i_id_orig_instit
               AND p1_di.flg_type = 'C';
    
        OPEN o_analysis FOR
            SELECT p1_di.id_inst_dest,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT i1.code_institution
                                                     FROM institution i1
                                                    WHERE i1.id_institution = p1_di.id_inst_dest)) inst_dest,
                   p1_di.flg_default
              FROM p1_dest_institution p1_di
             WHERE p1_di.id_inst_orig = i_id_orig_instit
               AND p1_di.flg_type = 'A';
    
        OPEN o_exams FOR
            SELECT p1_di.id_inst_dest,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT i1.code_institution
                                                     FROM institution i1
                                                    WHERE i1.id_institution = p1_di.id_inst_dest)) inst_dest,
                   p1_di.flg_default
              FROM p1_dest_institution p1_di
             WHERE p1_di.id_inst_orig = i_id_orig_instit
               AND p1_di.flg_type = 'E';
    
        OPEN o_interv FOR
            SELECT p1_di.id_inst_dest,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT i1.code_institution
                                                     FROM institution i1
                                                    WHERE i1.id_institution = p1_di.id_inst_dest)) inst_dest,
                   p1_di.flg_default
              FROM p1_dest_institution p1_di
             WHERE p1_di.id_inst_orig = i_id_orig_instit
               AND p1_di.flg_type = 'I';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                pk_types.open_my_cursor(o_consult);
                pk_types.open_my_cursor(o_analysis);
                pk_types.open_my_cursor(o_exams);
                pk_types.open_my_cursor(o_interv);
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_DEST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_dest;

    /** @headcom
    * Public Function. Get P1 (Consult, Analysis, Exams, Interventions) Destination Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_ORIG_INSTIT           Origin institution identification
    * @param      O_CONSULT                  Cursor with a list of the P1 destination institutions for consult
    * @param      O_ANALYSIS                 Cursor with a list of the P1 destination institutions for analysis
    * @param      O_EXAMS                    Cursor with a list of the P1 destination institutions for exams
    * @param      O_INTERV                   Cursor with a list of the P1 destination institutions for interventions
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/14
    */

    FUNCTION get_p1_resume
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        o_consult        OUT VARCHAR2,
        o_analysis       OUT VARCHAR2,
        o_exams          OUT VARCHAR2,
        o_interv         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sql_c   VARCHAR2(2000);
        l_sql_a   VARCHAR2(2000);
        l_sql_e   VARCHAR2(2000);
        l_sql_i   VARCHAR2(2000);
        l_linha_c pk_types.cursor_type;
        l_temp_c  VARCHAR2(2000) := NULL;
        l_linha_a pk_types.cursor_type;
        l_temp_a  VARCHAR2(2000) := NULL;
        l_linha_e pk_types.cursor_type;
        l_temp_e  VARCHAR2(2000) := NULL;
        l_linha_i pk_types.cursor_type;
        l_temp_i  VARCHAR2(2000) := NULL;
    
    BEGIN
        l_sql_c := 'SELECT decode(p1_di.flg_default,
                      ''Y'',
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''('' ||
                      pk_sysdomain.get_domain(''P1_DEST_INSTITUTION.FLG_DEFAULT'',
                                               p1_di.flg_default,@I_LANG) || ''); ''),
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''; ''))
          FROM p1_dest_institution p1_di
         WHERE p1_di.id_inst_orig = @ID_ORIG_INST
           AND p1_di.flg_type = ''C''';
    
        l_sql_a := 'SELECT decode(p1_di.flg_default,
                      ''Y'',
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''('' ||
                      pk_sysdomain.get_domain(''P1_DEST_INSTITUTION.FLG_DEFAULT'',
                                               p1_di.flg_default,@I_LANG) || ''); ''),
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''; ''))
          FROM p1_dest_institution p1_di
         WHERE p1_di.id_inst_orig = @ID_ORIG_INST
           AND p1_di.flg_type = ''A''';
    
        l_sql_e := 'SELECT decode(p1_di.flg_default,
                      ''Y'',
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''('' ||
                      pk_sysdomain.get_domain(''P1_DEST_INSTITUTION.FLG_DEFAULT'',
                                               p1_di.flg_default,@I_LANG) || ''); ''),
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''; ''))
          FROM p1_dest_institution p1_di
         WHERE p1_di.id_inst_orig = @ID_ORIG_INST
           AND p1_di.flg_type = ''E''';
    
        l_sql_i := 'SELECT decode(p1_di.flg_default,
                      ''Y'',
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''('' ||
                      pk_sysdomain.get_domain(''P1_DEST_INSTITUTION.FLG_DEFAULT'',
                                               p1_di.flg_default,@I_LANG) || ''); ''),
                      (pk_translation.get_translation(@I_LANG,
                                                      (SELECT i1.code_institution
                                                         FROM institution i1
                                                        WHERE i1.id_institution = p1_di.id_inst_dest)) || ''; ''))
          FROM p1_dest_institution p1_di
         WHERE p1_di.id_inst_orig = @ID_ORIG_INST
           AND p1_di.flg_type = ''I''';
    
        l_sql_c := REPLACE(l_sql_c, '@I_LANG', i_lang);
        l_sql_c := REPLACE(l_sql_c, '@ID_ORIG_INST', i_id_orig_instit);
        l_sql_a := REPLACE(l_sql_a, '@I_LANG', i_lang);
        l_sql_a := REPLACE(l_sql_a, '@ID_ORIG_INST', i_id_orig_instit);
        l_sql_e := REPLACE(l_sql_e, '@I_LANG', i_lang);
        l_sql_e := REPLACE(l_sql_e, '@ID_ORIG_INST', i_id_orig_instit);
        l_sql_i := REPLACE(l_sql_i, '@I_LANG', i_lang);
        l_sql_i := REPLACE(l_sql_i, '@ID_ORIG_INST', i_id_orig_instit);
    
        OPEN l_linha_c FOR l_sql_c;
        LOOP
            FETCH l_linha_c
                INTO l_temp_c;
            EXIT WHEN l_linha_c%NOTFOUND;
        
            IF l_temp_c IS NOT NULL
            THEN
                o_consult := o_consult || l_temp_c;
            END IF;
        END LOOP;
    
        OPEN l_linha_a FOR l_sql_a;
        LOOP
            FETCH l_linha_a
                INTO l_temp_a;
            EXIT WHEN l_linha_a%NOTFOUND;
        
            IF l_temp_a IS NOT NULL
            THEN
                o_analysis := o_analysis || l_temp_a;
            END IF;
        END LOOP;
    
        OPEN l_linha_e FOR l_sql_e;
        LOOP
            FETCH l_linha_e
                INTO l_temp_e;
            EXIT WHEN l_linha_e%NOTFOUND;
        
            IF l_temp_e IS NOT NULL
            THEN
                o_exams := o_exams || l_temp_e;
            END IF;
        END LOOP;
    
        OPEN l_linha_i FOR l_sql_i;
        LOOP
            FETCH l_linha_i
                INTO l_temp_i;
            EXIT WHEN l_linha_i%NOTFOUND;
        
            IF l_temp_i IS NOT NULL
            THEN
                o_interv := o_interv || l_temp_i;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_RESUME');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_resume;

    /** @headcom
    * Public Function. Get P1 Destination Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_id_orig_instit           Origin institution 
    * @param      I_flg_type                 Flag Type: C - Consultation, A - Analysis, E - Exam, P - Procedure
    * @param      O_P1_DEST_INST             Cursor with a list of the P1 institutions destination
    * @param      O_ERROR                    Error
    *
    * @value      I_flg_type                 {*} 'C' Consultation {*} 'A' Analysis  {*} 'E' Exam {*} 'P' Procedure {*} Null
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/04/13
    */
    FUNCTION get_p1_dest_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_orig_instit IN p1_dest_institution.id_inst_orig%TYPE,
        i_flg_type       IN p1_dest_institution.flg_type%TYPE,
        o_p1_dest_inst   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF i_flg_type IS NULL
        THEN
            g_error := 'GET P1_DEST_INSTITUTION CURSOR';
            OPEN o_p1_dest_inst FOR
                SELECT DISTINCT p1_di.flg_type,
                                pk_translation.get_translation(i_lang,
                                                               (SELECT code_institution
                                                                  FROM institution
                                                                 WHERE id_institution = p1_di.id_inst_dest)) instit_dest,
                                p1_di.flg_default
                  FROM p1_dest_institution p1_di;
        
        ELSE
            g_error := 'GET P1_DEST_INSTITUTION CURSOR';
            OPEN o_p1_dest_inst FOR
                SELECT DISTINCT pk_translation.get_translation(i_lang,
                                                               (SELECT code_institution
                                                                  FROM institution
                                                                 WHERE id_institution = p1_di.id_inst_dest)) instit_dest,
                                p1_di.flg_default
                  FROM p1_dest_institution p1_di;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_dest_inst);
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_DEST_INSTITUTION');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_dest_institution;

    /** @headcom
    * Public Function. Insert Or Remove Relation(P1 Specialities For Department/Clinical Service) 
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_ID_INSTITUTION                     Institution
    * @param      I_ID_SPECIALITY                      Speciality identification
    * @param      I_ID_DEP_CLIN_SERV                   Department/clinical service identification
    * @param      I_FLG_VALUE                          Flag Value: 'Y' Add, 'N' Remove
    * @param      I_FLG_DEFAULT                       Flag Value: 'Y' Default, 'N' Not default
    * @param      O_ERROR                              Error 
    *
    * @value      I_FLG_VALUE                          {*} 'Y' Add {*} 'N' Remove
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/03/23
    */
    FUNCTION set_p1_spec_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_speciality    IN speciality.id_speciality%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg_value        IN table_varchar,
        i_flg_default      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_speciality         NUMBER;
        l_id_dep_clin_serv      NUMBER;
        l_flg_value             VARCHAR2(1);
        l_id_spec_dep_clin_serv NUMBER;
        l_id_dest_institution   p1_dest_institution.id_dest_institution%TYPE;
        l_flg_inside_ref_area   ref_dest_institution_spec.flg_inside_ref_area%TYPE;
    
        CURSOR c_p1_spec_dep_clin_serv IS
            SELECT p1_sdcs.id_spec_dep_clin_serv
              FROM p1_spec_dep_clin_serv p1_sdcs
             WHERE p1_sdcs.id_dep_clin_serv = l_id_dep_clin_serv
               AND p1_sdcs.id_speciality = l_id_speciality;
    
        CURSOR c_p1_dest_institution IS
            SELECT pdi.id_dest_institution, rdi.flg_inside_ref_area
              FROM p1_dest_institution pdi
              JOIN ref_dest_institution_spec rdi
                ON pdi.id_dest_institution = rdi.id_dest_institution
             WHERE pdi.id_inst_dest = i_id_institution
               AND rdi.id_speciality = l_id_speciality
               AND flg_available = pk_alert_constant.g_yes;
    BEGIN
    
        l_id_speciality := i_id_speciality;
    
        IF i_flg_default IS NOT NULL
        THEN
            l_id_dep_clin_serv := i_flg_default;
        
            UPDATE p1_spec_dep_clin_serv p
               SET p.flg_default = pk_alert_constant.g_no
             WHERE p.id_speciality = l_id_speciality
               AND p.id_dep_clin_serv IN
                   (SELECT dcs.id_dep_clin_serv
                      FROM dep_clin_serv dcs
                     WHERE dcs.id_department IN (SELECT d.id_department
                                                   FROM department d
                                                  WHERE d.id_institution = i_id_institution));
        
            g_error := 'SELECT FROM P1_SPEC_DEP_CLIN_SERV';
            OPEN c_p1_spec_dep_clin_serv;
            FETCH c_p1_spec_dep_clin_serv
                INTO l_id_spec_dep_clin_serv;
            g_found := c_p1_spec_dep_clin_serv%FOUND;
            CLOSE c_p1_spec_dep_clin_serv;
        
            IF g_found
            THEN
                g_error := 'UPDATE p1_spec_dep_clin_serv';
                UPDATE p1_spec_dep_clin_serv p1_sdcs
                   SET p1_sdcs.flg_default = pk_alert_constant.g_yes
                 WHERE p1_sdcs.id_spec_dep_clin_serv = l_id_spec_dep_clin_serv;
            END IF;
        END IF;
    
        IF i_id_dep_clin_serv.count > 0
        THEN
            FOR i IN 1 .. i_id_dep_clin_serv.count
            LOOP
                l_id_dep_clin_serv := i_id_dep_clin_serv(i);
                l_flg_value        := i_flg_value(i);
            
                g_error := 'SELECT FROM P1_SPEC_DEP_CLIN_SERV';
                OPEN c_p1_spec_dep_clin_serv;
                FETCH c_p1_spec_dep_clin_serv
                    INTO l_id_spec_dep_clin_serv;
                g_found := c_p1_spec_dep_clin_serv%FOUND;
                CLOSE c_p1_spec_dep_clin_serv;
            
                IF g_found
                THEN
                    IF l_flg_value = 'N'
                    THEN
                        g_error := 'DELETE from p1_spec_dep_clin_serv';
                        DELETE p1_spec_dep_clin_serv p1_sdcs
                         WHERE p1_sdcs.id_spec_dep_clin_serv = l_id_spec_dep_clin_serv;
                    
                        OPEN c_p1_dest_institution;
                        LOOP
                            g_error := 'FETCH c_p1_dest_institution';
                            FETCH c_p1_dest_institution
                                INTO l_id_dest_institution, l_flg_inside_ref_area;
                        
                            g_found := c_p1_dest_institution%FOUND;
                        
                            -- JB 2011-01-07 (New configurations
                            IF g_found
                            THEN
                                g_error := 'DELETE ref_dest_institution_spec id_dest_institution=' ||
                                           l_id_dest_institution || ' id_speciality=' || l_id_speciality ||
                                           ' flg_inside_ref_area=' || l_flg_inside_ref_area;
                            
                                DELETE FROM ref_dest_institution_spec
                                 WHERE id_speciality = l_id_speciality
                                   AND id_dest_institution = l_id_dest_institution
                                   AND flg_inside_ref_area = l_flg_inside_ref_area;
                            ELSE
                                CLOSE c_p1_dest_institution;
                                EXIT;
                            
                            END IF;
                        END LOOP;
                    
                    ELSIF l_flg_value = 'Y'
                          AND l_id_dep_clin_serv = i_flg_default
                    THEN
                        g_error := 'UPDATE p1_spec_dep_clin_serv';
                        UPDATE p1_spec_dep_clin_serv p1_sdcs
                           SET p1_sdcs.flg_default = pk_alert_constant.g_yes
                         WHERE p1_sdcs.id_spec_dep_clin_serv = l_id_spec_dep_clin_serv;
                    END IF;
                ELSE
                    IF l_flg_value = 'Y'
                       AND l_id_dep_clin_serv = i_flg_default
                    THEN
                        g_error := 'INSERT INTO P1_SPEC_DEP_CLIN_SERV';
                        INSERT INTO p1_spec_dep_clin_serv
                            (id_spec_dep_clin_serv,
                             id_dep_clin_serv,
                             id_speciality,
                             triage_style,
                             flg_default,
                             flg_availability)
                        VALUES
                            (seq_dep_clin_serv.nextval,
                             l_id_dep_clin_serv,
                             l_id_speciality,
                             '1',
                             pk_alert_constant.g_yes,
                             pk_ref_constant.g_flg_availability_a);
                    
                    ELSIF l_flg_value = 'Y'
                          AND (l_id_dep_clin_serv != i_flg_default OR i_flg_default IS NULL)
                    THEN
                        g_error := 'INSERT INTO P1_SPEC_DEP_CLIN_SERV';
                        INSERT INTO p1_spec_dep_clin_serv
                            (id_spec_dep_clin_serv,
                             id_dep_clin_serv,
                             id_speciality,
                             triage_style,
                             flg_default,
                             flg_availability)
                        VALUES
                            (seq_dep_clin_serv.nextval,
                             l_id_dep_clin_serv,
                             l_id_speciality,
                             '1',
                             pk_alert_constant.g_no,
                             pk_ref_constant.g_flg_availability_a);
                    END IF;
                
                    OPEN c_p1_dest_institution;
                    LOOP
                        g_error := 'FETCH c_p1_dest_institution';
                        FETCH c_p1_dest_institution
                            INTO l_id_dest_institution, l_flg_inside_ref_area;
                    
                        g_found := c_p1_dest_institution%FOUND;
                    
                        -- JB 2011-01-07 (New configurations)
                        IF g_found
                        THEN
                            g_error := 'INSERT into ref_dest_institution_spec id_dest_institution=' ||
                                       l_id_dest_institution || ' id_speciality=' || l_id_speciality ||
                                       ' flg_inside_ref_area=' || l_flg_inside_ref_area;
                        
                            INSERT INTO ref_dest_institution_spec
                                (id_dest_institution_spec,
                                 id_dest_institution,
                                 id_speciality,
                                 flg_available,
                                 flg_inside_ref_area)
                            VALUES
                                (seq_ref_dest_institution_spec.nextval,
                                 l_id_dest_institution,
                                 l_id_speciality,
                                 pk_alert_constant.g_yes,
                                 l_flg_inside_ref_area);
                        ELSE
                            CLOSE c_p1_dest_institution;
                            EXIT;
                        
                        END IF;
                    END LOOP;
                
                END IF;
            
            END LOOP;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'SET_P1_SPEC_DEP_CLIN_SERV');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_p1_spec_dep_clin_serv;

    /** @headcom
    * Public Function. Get P1 Speciality List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      i_id_prof                  Professional id
    * @param      O_P1_SPEC_LIST             Cursor with a list of P1 Specialitys
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/03/22
    */
    FUNCTION get_p1_spec_list
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_p1_spec_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_market market.id_market%TYPE;
    
    BEGIN
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_id_inst_orig);
    
        g_error := 'GET P1_SPEC_LIST CURSOR';
    
        OPEN o_p1_spec_list FOR
            SELECT p1s.id_speciality,
                   pk_translation.get_translation(i_lang, p1s.code_speciality) spec,
                   (decode((SELECT DISTINCT id_speciality
                             FROM p1_spec_dep_clin_serv p1sdcs
                            WHERE p1sdcs.id_speciality = p1s.id_speciality
                              AND p1sdcs.id_dep_clin_serv IN
                                  (SELECT dcs.id_dep_clin_serv
                                     FROM dep_clin_serv dcs
                                    WHERE dcs.id_department IN
                                          (SELECT d.id_department
                                             FROM department d
                                            WHERE d.id_institution = i_id_inst_orig))),
                           NULL,
                           'I',
                           'A')) flg_select,
                   (SELECT COUNT(p1sdcs.id_spec_dep_clin_serv)
                      FROM p1_spec_dep_clin_serv p1sdcs
                     WHERE p1sdcs.id_speciality = p1s.id_speciality
                       AND p1sdcs.id_dep_clin_serv IN
                           (SELECT dcs.id_dep_clin_serv
                              FROM dep_clin_serv dcs
                             WHERE dcs.id_department IN
                                   (SELECT d.id_department
                                      FROM department d
                                     WHERE d.id_institution IN (i_id_inst_orig)))) assoc_number
              FROM p1_speciality p1s
              JOIN ref_spec_market rsm
                ON (rsm.id_speciality = p1s.id_speciality)
             WHERE rsm.flg_available = pk_alert_constant.g_yes
               AND rsm.id_market = l_id_market
               AND i_id_inst_orig NOT IN (SELECT rsi.id_institution
                                            FROM ref_spec_institution rsi
                                           WHERE rsi.id_institution = i_id_inst_orig
                                             AND rsi.flg_available = pk_alert_constant.g_no
                                             AND rsi.id_speciality = p1s.id_speciality)
            
             ORDER BY spec;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_spec_list);
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_SPEC_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_spec_list;

    /** @headcom
    * Public Function. Get P1 Institution List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      i_id_prof                  Professional id
    * @param      O_CUR                      Cursor with institutions list
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_p1_inst_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_cur     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1_SPEC_LIST CURSOR';
        OPEN o_cur FOR
            SELECT i.id_institution, pk_translation.get_translation(i_lang, i.code_institution) desc_institution
              FROM institution i, prof_soft_inst psi
             WHERE (i.id_institution = psi.id_institution OR i.id_parent = psi.id_institution)
               AND psi.id_professional = i_id_prof
               AND psi.id_software = 26
               AND i.flg_type = 'H'
             ORDER BY desc_institution;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_INST_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_inst_list;

    /** @headcom
    * Public Function. Get P1 Triage Type List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      O_TRIAGE_TYPE_LIST         Cursor with a list of the triage types
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/04/13
    */
    FUNCTION get_p1_triage_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_triage_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET TRIAGE_TYPE_LIST CURSOR';
        OPEN o_triage_type_list FOR
            SELECT DISTINCT pk_sysdomain.get_domain('P1_SPEC_DEP_CLIN_SERV.TRIAGE_STYLE',
                                                    nvl(p1.triage_style, NULL),
                                                    i_lang) triage
              FROM p1_spec_dep_clin_serv p1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_triage_type_list);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_TRIAGE_TYPE_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_triage_type_list;

    /** @headcom
    * Public Function. Insert New P1 Specialities Destinations
    *                  OR Update P1 Specialities Destinations
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_ID_INST_ORIG                       Origin Institutions
    * @param      I_ID_INST_DEST                       Destination Institutions
    * @param      I_FLG_TYPE                           Flag Type
    * @param      I_flg_value                          Flag Value
    * @param      O_ERROR                              Error 
    *
    * @value      i_flg_value                          {*} 'D' Default institution {*} 'N' Delete record {*} 'Y' Not a default institution
    * @value      i_flg_type                           {*} 'C' Consultation {*} 'A' Analysis {*} 'E' Exam {*} 'P' Procedure
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION set_p1_dest_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst_orig IN table_number,
        i_id_inst_dest IN table_number,
        i_flg_type     IN table_varchar,
        i_flg_value    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_inst_orig        NUMBER;
        l_id_inst_dest        NUMBER;
        l_id_dest_institution NUMBER;
        l_flg_type            VARCHAR2(1);
        l_flg_type_value      VARCHAR2(1);
    
        CURSOR c_p1_dest_institution IS
            SELECT p1_di.id_dest_institution
              FROM p1_dest_institution p1_di
             WHERE p1_di.id_inst_orig = l_id_inst_orig
               AND p1_di.id_inst_dest = l_id_inst_dest
               AND p1_di.flg_type = l_flg_type;
    
    BEGIN
        FOR i IN 1 .. i_id_inst_orig.count
        LOOP
            l_id_inst_orig   := i_id_inst_orig(i);
            l_id_inst_dest   := i_id_inst_dest(i);
            l_flg_type       := i_flg_type(i);
            l_flg_type_value := i_flg_value(i);
        
            g_error := 'SELECT FROM P1_DEST_INSTITUTION';
            OPEN c_p1_dest_institution;
            FETCH c_p1_dest_institution
                INTO l_id_dest_institution;
            g_found := c_p1_dest_institution%FOUND;
            CLOSE c_p1_dest_institution;
        
            IF g_found
            THEN
                IF l_flg_type_value = 'D'
                THEN
                    g_error := 'UPDATE p1_dest_institution SET p1_di.flg_default = Y';
                    UPDATE p1_dest_institution p1_di
                       SET p1_di.flg_default = 'Y'
                     WHERE p1_di.id_dest_institution = l_id_dest_institution;
                ELSIF l_flg_type_value = 'N'
                THEN
                    g_error := 'DELETE p1_dest_institution';
                    DELETE ref_dest_institution_spec_hist rdish
                     WHERE rdish.id_dest_institution = l_id_dest_institution;
                
                    DELETE ref_dest_institution_spec rdis
                     WHERE rdis.id_dest_institution = l_id_dest_institution;
                
                    DELETE p1_dest_institution p1_di
                     WHERE p1_di.id_dest_institution = l_id_dest_institution;
                ELSIF l_flg_type_value = 'Y'
                THEN
                    g_error := 'UPDATE p1_dest_institution SET p1_di.flg_default = N';
                    UPDATE p1_dest_institution p1_di
                       SET p1_di.flg_default = 'N'
                     WHERE p1_di.id_dest_institution = l_id_dest_institution;
                END IF;
            ELSE
                IF l_flg_type_value = 'D'
                THEN
                    g_error := 'INSERT INTO p1_dest_institution';
                    INSERT INTO p1_dest_institution
                        (id_dest_institution,
                         id_inst_orig,
                         id_inst_dest,
                         flg_default,
                         flg_type,
                         --flg_inside_ref_area,
                         --flg_ref_line,
                         flg_type_ins,
                         flg_net_type)
                    VALUES
                        (seq_p1_dest_institution.nextval,
                         l_id_inst_orig,
                         l_id_inst_dest,
                         pk_alert_constant.g_yes,
                         l_flg_type,
                         --pk_alert_constant.g_yes,
                         --'1',
                         'SNS',
                         'A');
                ELSIF l_flg_type_value = 'Y'
                THEN
                    g_error := 'INSERT INTO p1_dest_institution';
                    INSERT INTO p1_dest_institution
                        (id_dest_institution,
                         id_inst_orig,
                         id_inst_dest,
                         flg_default,
                         flg_type,
                         --flg_inside_ref_area,
                         --flg_ref_line,
                         flg_type_ins,
                         flg_net_type)
                    VALUES
                        (seq_p1_dest_institution.nextval,
                         l_id_inst_orig,
                         l_id_inst_dest,
                         pk_alert_constant.g_no,
                         l_flg_type,
                         --pk_alert_constant.g_yes,
                         --'1',
                         'SNS',
                         'A');
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
        COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'SET_P1_DEST_INSTITUTION');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_p1_dest_institution;

    /** @headcom
    * Public Function. Get P1 Destination Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      i_prof                     Object
    * @param      i_task                     Task
    * @param      i_purpose                  Purpose
    * @param      O_P1_TASK                  Cursor with a list of the P1 Administrative Tasks
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION get_p1_task
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_task    IN p1_task.desc_task%TYPE,
        i_purpose IN p1_task.flg_purpose%TYPE,
        o_p1_task OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1_TASK CURSOR';
        OPEN o_p1_task FOR
        
            SELECT p.desc_task task,
                   pk_translation.get_translation(i_lang, p.code_task) desc_task,
                   p.rank rank,
                   p.flg_purpose,
                   pk_sysdomain.get_domain('P1_TASK.FLG_PURPOSE', p.flg_purpose, i_lang) desc_purpose,
                   p.adw_last_update,
                   pk_date_utils.date_time_chr(i_lang, p.adw_last_update, i_prof) desc_adw_last_update
              FROM p1_task p,
                   (SELECT MAX(p.adw_last_update) adw_last_update
                      FROM p1_task p
                     WHERE p.desc_task = i_task
                       AND p.flg_purpose = i_purpose
                     GROUP BY p.desc_task, p.flg_purpose) data
             WHERE p.adw_last_update = data.adw_last_update
               AND p.desc_task = i_task
               AND p.flg_purpose = i_purpose;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_TASK');
                pk_utils.undo_changes;
                pk_types.open_my_cursor(o_p1_task);
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_task;

    /** @headcom
    * Public Function. Get P1 Destination Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      O_P1_TASK                  Cursor with a list of the P1 Administrative Task
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION get_p1_task_list
    (
        i_lang    IN language.id_language%TYPE,
        o_p1_task OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1_TASK CURSOR';
        OPEN o_p1_task FOR
            SELECT dados.desc_task task,
                   dados.desc_task_tr desc_task,
                   dados.rank,
                   decode(dados.consultation, 'Y', 'A', 'I') consultation,
                   decode(dados.consultation, 'Y', 'CheckIcon', NULL) consultation_icon,
                   decode(dados.analysis, 'Y', 'A', 'I') analysis,
                   decode(dados.analysis, 'Y', 'CheckIcon', NULL) analysis_icon,
                   decode(dados.exams, 'Y', 'A', 'I') exams,
                   decode(dados.exams, 'Y', 'CheckIcon', NULL) exams_icon,
                   decode(dados.procedures, 'Y', 'A', 'I') procedures,
                   decode(dados.procedures, 'Y', 'CheckIcon', NULL) procedures_icon,
                   dados.flg_purpose,
                   dados.desc_purpose
              FROM (SELECT DISTINCT p1t.desc_task,
                                    pk_translation.get_translation(i_lang, code_task) desc_task_tr,
                                    p1t.rank,
                                    decode((SELECT flg_type
                                             FROM p1_task p1t2
                                            WHERE p1t2.desc_task = p1t.desc_task
                                              AND p1t2.flg_purpose = p1t.flg_purpose
                                              AND p1t2.flg_type = 'C'),
                                           NULL,
                                           'N',
                                           'Y') consultation,
                                    decode((SELECT flg_type
                                             FROM p1_task p1t2
                                            WHERE p1t2.desc_task = p1t.desc_task
                                              AND p1t2.flg_purpose = p1t.flg_purpose
                                              AND p1t2.flg_type = 'A'),
                                           NULL,
                                           'N',
                                           'Y') analysis,
                                    decode((SELECT flg_type
                                             FROM p1_task p1t2
                                            WHERE p1t2.desc_task = p1t.desc_task
                                              AND p1t2.flg_purpose = p1t.flg_purpose
                                              AND p1t2.flg_type = 'E'),
                                           NULL,
                                           'N',
                                           'Y') exams,
                                    decode((SELECT flg_type
                                             FROM p1_task p1t2
                                            WHERE p1t2.desc_task = p1t.desc_task
                                              AND p1t2.flg_purpose = p1t.flg_purpose
                                              AND p1t2.flg_type = 'I'),
                                           NULL,
                                           'N',
                                           'Y') procedures,
                                    p1t.flg_purpose,
                                    pk_sysdomain.get_domain('P1_TASK.FLG_PURPOSE', p1t.flg_purpose, i_lang) desc_purpose
                      FROM p1_task p1t
                     WHERE p1t.desc_task IN (SELECT DISTINCT desc_task
                                               FROM p1_task)) dados
             ORDER BY rank, desc_task;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_task);
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_TASK_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_task_list;

    /** @headcom
    * Public Function. Get P1 Type List
    *
    * @param      I_LANG                     Prefered language ID
    * @param      I_TASK                     Task identification
    * @param      I_FLG_PURPOSE              Purpose identification
    * @param      O_P1_TYPE                  Cursor with a list of the P1 Administrative Task
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/27
    */
    FUNCTION get_p1_type_list
    (
        i_lang        IN language.id_language%TYPE,
        i_task        IN p1_task.desc_task%TYPE,
        i_flg_purpose IN p1_task.flg_purpose%TYPE,
        o_p1_type     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1 TYPE CURSOR';
        OPEN o_p1_type FOR
            SELECT sd.val,
                   sd.desc_val,
                   sd.img_name,
                   decode((SELECT p1t.flg_type
                            FROM p1_task p1t
                           WHERE p1t.desc_task = i_task
                             AND p1t.flg_purpose = i_flg_purpose
                             AND p1t.flg_type = sd.val),
                          NULL,
                          'N',
                          'Y') flg_select
              FROM sys_domain sd
             WHERE code_domain = 'P1_TASK.FLG_TYPE'
               AND flg_available = g_flg_available
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND sd.val != 'P'
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_type);
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_TYPE_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_type_list;

    /** @headcom
    * Public Function. Get P1 Purpose List
    *
    * @param      I_LANG                     Prefered language ID
    * @param      O_P1_PURPOSE               Cursor with a list of the Purposes of the P1 Adm tasks
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/05/03
    */
    FUNCTION get_p1_purpose_list
    (
        i_lang       IN language.id_language%TYPE,
        o_p1_purpose OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1 PURPOSE CURSOR';
        OPEN o_p1_purpose FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = 'P1_TASK.FLG_PURPOSE'
               AND id_language = i_lang
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_purpose);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_PURPOSE_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_purpose_list;

    /** @headcom
    * Public Function. Insert New P1 Adm Task
    *                  OR P1 Adm Task
    *
    * @param      I_LANG                            Prefered language ID
    * @param      I_task                            Task description
    * @param      I_old_flg_purpose                 Old Purpose
    * @param      I_new_title                       New Title
    * @param      I_new_order                       New Rank
    * @param      I_new_flg_purpose                 New Purpose
    * @param      I_flg_type                        Flag type
    * @param      I_flg_value                       Flag value
    * @param      O_ERROR                           Error 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/04/12
    */
    FUNCTION set_p1_task
    (
        i_lang            IN language.id_language%TYPE,
        i_task            IN p1_task.desc_task%TYPE,
        i_old_flg_purpose IN p1_task.flg_purpose%TYPE,
        i_new_title       IN pk_translation.t_desc_translation,
        i_new_order       IN p1_task.rank%TYPE,
        i_new_flg_purpose IN p1_task.flg_purpose%TYPE,
        i_flg_type        IN table_varchar,
        i_flg_value       IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_task   p1_task.id_task%TYPE;
        l_flg_type  p1_task.flg_type%TYPE;
        l_flg_value VARCHAR(1);
        c_task      pk_types.cursor_type;
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_yes;
        l_tab table_varchar;
    BEGIN
        g_sysdate := SYSDATE;
    
        IF i_old_flg_purpose IS NULL
        THEN
            FOR i IN 1 .. i_flg_type.count
            LOOP
                l_flg_type  := i_flg_type(i);
                l_flg_value := i_flg_value(i);
            
                g_error := 'GET SEQ_P1_TASK.NEXTVAL';
                SELECT seq_p1_task.nextval
                  INTO l_id_task
                  FROM dual;
            
                g_error := 'INSERT INTO P1_TASK';
                INSERT INTO p1_task
                    (id_task, desc_task, rank, flg_type, flg_purpose)
                VALUES
                    (l_id_task, i_new_title, i_new_order, l_flg_type, i_new_flg_purpose);
            
                g_error := 'GET LANGUAGES';
                OPEN c_language;
                LOOP
                    FETCH c_language
                        INTO l_id_lang;
                    EXIT WHEN c_language%NOTFOUND;
                
                    g_error := 'INSERT_INTO_TRANSLATION P1_TASK';
                    pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                           i_code_trans => 'P1_TASK.CODE_TASK.' || l_id_task,
                                                           i_desc_trans => i_new_title);
                
                END LOOP;
            
                CLOSE c_language;
            
            END LOOP;
        
        ELSE
        
            g_error := 'UPDATE P1_TASK';
            UPDATE p1_task p1t
               SET flg_purpose = i_new_flg_purpose, rank = i_new_order
             WHERE p1t.desc_task = i_task
               AND p1t.flg_purpose = i_old_flg_purpose;
        
            IF i_new_title IS NOT NULL
            THEN
            
                OPEN c_task FOR
                    SELECT p1t.id_task
                      FROM p1_task p1t
                     WHERE p1t.desc_task = i_task
                       AND p1t.flg_purpose = i_old_flg_purpose;
                LOOP
                    FETCH c_task
                        INTO l_id_task;
                    EXIT WHEN c_task%NOTFOUND;
                
                    g_error := 'GET LANGUAGES';
                    OPEN c_language;
                    LOOP
                        FETCH c_language
                            INTO l_id_lang;
                        EXIT WHEN c_language%NOTFOUND;
                    
                        g_error := 'INSERT_INTO_TRANSLATION P1_TASK';
                        pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                               i_code_trans => 'P1_TASK.CODE_TASK.' || l_id_task,
                                                               i_desc_trans => i_new_title);
                    
                    END LOOP;
                
                    CLOSE c_language;
                
                END LOOP;
            
            END IF;
        
            FOR i IN 1 .. i_flg_type.count
            LOOP
                l_flg_type  := i_flg_type(i);
                l_flg_value := i_flg_value(i);
            
                IF l_flg_value = 'Y'
                THEN
                    g_error := 'GET SEQ_P1_TASK.NEXTVAL';
                    SELECT seq_p1_task.nextval
                      INTO l_id_task
                      FROM dual;
                
                    g_error := 'INSERT INTO P1_TASK';
                    INSERT INTO p1_task
                        (id_task, desc_task, rank, flg_type, flg_purpose)
                    VALUES
                        (l_id_task, i_task, i_new_order, l_flg_type, i_new_flg_purpose);
                
                    g_error := 'GET LANGUAGES';
                    OPEN c_language;
                    LOOP
                        FETCH c_language
                            INTO l_id_lang;
                        EXIT WHEN c_language%NOTFOUND;
                    
                        g_error := 'INSERT_INTO_TRANSLATION P1_TASK';
                        pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                               i_code_trans => 'P1_TASK.CODE_TASK.' || l_id_task,
                                                               i_desc_trans => i_new_title);
                    
                    END LOOP;
                
                    CLOSE c_language;
                
                ELSE
                
                    g_error := 'SELECT p1t.code_task BULK COLLECT INTO l_tab / flg_purpose=' || i_old_flg_purpose ||
                               ' flg_type=' || l_flg_type;
                    SELECT p1t.code_task
                      BULK COLLECT
                      INTO l_tab
                      FROM p1_task p1t
                     WHERE p1t.desc_task = i_task
                       AND p1t.flg_purpose = i_old_flg_purpose
                       AND p1t.flg_type = l_flg_type;
                
                    pk_translation.delete_code_translation(l_tab);
                
                    DELETE FROM p1_task p1t
                     WHERE p1t.desc_task = i_task
                       AND p1t.flg_purpose = i_old_flg_purpose
                       AND p1t.flg_type = l_flg_type;
                END IF;
            END LOOP;
        
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'SET_P1_TASK');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_p1_task;

    /** @headcom
    * Public Function. Get P1 Possible Task List 
    *
    * @param      I_LANG                     Prefered language ID
    * @param      O_CUR                      Cursor with a list of possible tasks
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_p1_possible_task_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1 POSSIBLE TASK LIST CURSOR';
        OPEN o_cur FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = 'P1_TASK'
               AND flg_available = g_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_POSSIBLE_TASK_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_possible_task_list;

    /** @headcom
    * Public Function. Get P1 Speciality Institutions
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_id_prof                  Professional identification
    * @param      I_SPEC                     Speciality P1 identification
    * @param      O_p1_dest                  Cursor with a list of the P1 institutions origin
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_p1_inst_dest_spec
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_spec         IN p1_speciality.id_speciality%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_p1_dest      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_id_inst_orig);
    
        OPEN o_p1_dest FOR
        
            SELECT DISTINCT p1_di.id_inst_dest,
                            pk_translation.get_translation(i_lang, i.code_institution) inst_dest,
                            i.ext_code,
                            (decode((SELECT DISTINCT d.id_institution
                                      FROM dep_clin_serv dcs2, department s, dept d
                                     WHERE d.id_institution = p1_di.id_inst_dest
                                       AND s.id_dept = d.id_dept
                                       AND dcs2.id_department = s.id_department
                                       AND dcs2.id_dep_clin_serv IN
                                           (SELECT dcs.id_dep_clin_serv
                                              FROM p1_speciality p1_s
                                              JOIN p1_spec_dep_clin_serv p1_sdcs
                                                ON (p1_sdcs.id_speciality = p1_s.id_speciality)
                                              JOIN dep_clin_serv dcs
                                                ON (dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv)
                                              JOIN ref_spec_market rsm
                                                ON (rsm.id_speciality = p1_s.id_speciality)
                                             WHERE p1_s.id_speciality = i_spec
                                               AND rsm.id_market IN (l_id_market, 0)
                                               AND rsm.flg_available = pk_alert_constant.g_yes
                                               AND d.id_institution NOT IN
                                                   (SELECT rsi.id_institution
                                                      FROM ref_spec_institution rsi
                                                     WHERE rsi.id_speciality = p1_s.id_speciality
                                                       AND rsi.id_institution = d.id_institution
                                                       AND rsi.flg_available = pk_alert_constant.g_no))),
                                    NULL,
                                    'I',
                                    'A')) flg_select
              FROM p1_dest_institution p1_di, institution i
             WHERE p1_di.id_inst_dest = i.id_institution
               AND p1_di.id_inst_orig = i_id_inst_orig;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_p1_dest);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_INST_DEST_SPEC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_inst_dest_spec;

    /** @headcom
    * Public Function. Get Department Information List
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_INSTITUTION           Institution identification
    * @param      I_SPEC                     Specialiality P1 identification
    * @param      O_DEPT_LIST                Cursor with the Departments Information
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_dept_spec_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_spec           IN p1_speciality.id_speciality%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_market market.id_market%TYPE;
    
    BEGIN
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_id_institution);
    
        g_error := 'GET DEPT CURSOR';
        OPEN o_dept_list FOR
            SELECT d.id_dept id,
                   pk_translation.get_translation(i_lang, d.code_dept) name,
                   (decode((SELECT DISTINCT s.id_dept
                             FROM department s
                            WHERE s.id_dept = d.id_dept
                              AND s.id_department IN
                                  (SELECT dcs.id_department
                                     FROM p1_speciality p1_s
                                     JOIN p1_spec_dep_clin_serv p1_sdcs
                                       ON (p1_sdcs.id_speciality = p1_s.id_speciality)
                                     JOIN dep_clin_serv dcs
                                       ON (dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv)
                                     JOIN ref_spec_market rsm
                                       ON (p1_s.id_speciality = rsm.id_speciality)
                                    WHERE p1_s.id_speciality = i_spec
                                      AND rsm.id_market IN (l_id_market, 0)
                                      AND rsm.flg_available = pk_alert_constant.g_yes
                                      AND i_id_institution NOT IN
                                          (SELECT rsi.id_institution
                                             FROM ref_spec_institution rsi
                                            WHERE rsi.id_institution = i_id_institution
                                              AND rsi.flg_available = pk_alert_constant.g_no
                                              AND rsi.id_speciality = p1_s.id_speciality))),
                           NULL,
                           'I',
                           'A')) flg_select
              FROM dept d
             WHERE d.id_institution = i_id_institution
               AND d.flg_available = g_flg_available
             ORDER BY adw_last_update DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_dept_list);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_DEPT_SPEC_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dept_spec_list;

    /** @headcom
    * Public Function. Get Department Service List 
    * 
    * @param      I_LANG                     Prefered language ID
    * @param      I_ID_DEPT                  Department identification
    * @param      I_SPEC                     P1 Speciality identification
    * @param      O_DEPARTMENT_LIST          Cursor with a list of the Department/clinical services
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_serv_spec_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        i_spec            IN p1_speciality.id_speciality%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEPARTMENT_LIST CURSOR';
        OPEN o_department_list FOR
            SELECT dcs.id_dep_clin_serv,
                   dcs.id_department id_service,
                   pk_translation.get_translation(i_lang, s.code_department) service,
                   dcs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) clinical_serv,
                   (decode((SELECT DISTINCT p1_sdcs.id_speciality
                             FROM p1_speciality p1_s
                             JOIN p1_spec_dep_clin_serv p1_sdcs
                               ON (p1_sdcs.id_speciality = p1_s.id_speciality)
                             JOIN ref_spec_market rsm
                               ON (rsm.id_speciality = p1_s.id_speciality)
                            WHERE dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv
                              AND p1_s.id_speciality = i_spec
                              AND dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv
                              AND rsm.flg_available = pk_alert_constant.g_yes
                              AND rsm.id_market IN (0,
                                                    (SELECT pk_utils.get_institution_market(i_lang, s.id_institution)
                                                       FROM dual))
                              AND s.id_institution NOT IN
                                  (SELECT rsi.id_institution
                                     FROM ref_spec_institution rsi
                                    WHERE rsi.id_speciality = i_spec
                                      AND rsi.flg_available = pk_alert_constant.g_no
                                      AND rsi.id_institution = s.id_institution)),
                           NULL,
                           'I',
                           'A')) flg_select,
                   (decode((SELECT DISTINCT p1_sdcs.flg_default
                             FROM p1_speciality p1_s
                             JOIN p1_spec_dep_clin_serv p1_sdcs
                               ON (p1_sdcs.id_speciality = p1_s.id_speciality)
                             JOIN ref_spec_market rsm
                               ON (rsm.id_speciality = p1_s.id_speciality)
                            WHERE dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv
                              AND p1_s.id_speciality = i_spec
                              AND dcs.id_dep_clin_serv = p1_sdcs.id_dep_clin_serv
                              AND rsm.flg_available = pk_alert_constant.g_yes
                              AND rsm.id_market IN (0,
                                                    (SELECT pk_utils.get_institution_market(i_lang, s.id_institution)
                                                       FROM dual))
                              AND s.id_institution NOT IN
                                  (SELECT rsi.id_institution
                                     FROM ref_spec_institution rsi
                                    WHERE rsi.id_speciality = i_spec
                                      AND rsi.flg_available = pk_alert_constant.g_no
                                      AND rsi.id_institution = s.id_institution)),
                           'Y',
                           'A',
                           'I')) flg_default
              FROM dep_clin_serv dcs
              JOIN department s
                ON (s.id_department = dcs.id_department)
              JOIN clinical_service cs
                ON (cs.id_clinical_service = dcs.id_clinical_service)
             WHERE s.id_dept = i_id_dept
               AND s.flg_available = pk_alert_constant.g_yes
             ORDER BY service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_department_list);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_SERV_SPEC_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_serv_spec_list;

    /** @headcom
    * Public Function. Get Admission Criteria Docs 
    *
    * @param      I_LANG                     Prefered language ID
    * @param      I_PROF                     Professional identification
    * @param      O_CUR                      Cursor with a list of documents as criteria for admission
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_admission_criteria_docs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_cur          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET ADMISSION CRITERIA DOCS CURSOR';
        OPEN o_cur FOR
        
            SELECT list.id_speciality,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT s.code_speciality
                                                     FROM p1_speciality s
                                                     JOIN ref_spec_market rsm
                                                       ON (rsm.id_speciality = s.id_speciality)
                                                    WHERE s.id_speciality = list.id_speciality
                                                      AND rsm.flg_available = pk_alert_constant.get_yes
                                                      AND rsm.id_market IN
                                                          (0,
                                                           (SELECT pk_utils.get_institution_market(i_lang, i_id_inst_orig)
                                                              FROM dual))
                                                      AND i_id_inst_orig NOT IN
                                                          (SELECT rsi.id_institution
                                                             FROM ref_spec_institution rsi
                                                            WHERE rsi.id_institution = i_id_inst_orig
                                                              AND rsi.id_speciality = s.id_speciality
                                                              AND rsi.flg_available = pk_alert_constant.g_no))) desc_speciality,
                   list.id_institution,
                   pk_translation.get_translation(i_lang,
                                                  (SELECT i.code_institution
                                                     FROM institution i
                                                    WHERE i.id_institution = list.id_institution)) desc_institution,
                   
                   list.adw_last_update,
                   pk_date_utils.date_time_chr(i_lang, list.adw_last_update, i_prof) desc_adw_last_update,
                   (SELECT p.name
                      FROM professional p
                     WHERE p.id_professional = (SELECT DISTINCT id_professional
                                                  FROM p1_spec_help
                                                 WHERE id_speciality = list.id_speciality
                                                   AND id_institution = list.id_institution
                                                   AND adw_last_update = list.adw_last_update
                                                   AND flg_available = 'Y')) desc_professional
            
              FROM (SELECT p1sh.id_speciality, p1sh.id_institution, MAX(p1sh.adw_last_update) adw_last_update
                      FROM p1_spec_help p1sh, p1_dest_institution pdi
                     WHERE p1sh.flg_available = 'Y'
                       AND pdi.id_inst_dest = p1sh.id_institution
                       AND pdi.id_inst_orig = i_id_inst_orig
                     GROUP BY p1sh.id_speciality, p1sh.id_institution) list;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_ADMISSION_CRITERIA_DOCS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_admission_criteria_docs;

    /** @headcom
    * Public Function. Get Destiny Institution Parameters 
    *
    * @param      I_LANG                     Prefered language ID
    * @param      I_id_prof                  Professional Identification
    * @param      I_id_inst_orig             Origin Institution identification
    * @param      O_CUR                      Cursor with a list of destination institutions and its parameters
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/21
    */
    FUNCTION get_dest_inst_params
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_id_inst_orig IN p1_dest_institution.id_inst_orig%TYPE,
        o_cur          OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET DEST INST PARAMS CURSOR';
        OPEN o_cur FOR
            SELECT data.id_inst_dest,
                   data.desc_institution,
                   data.consultations,
                   decode(data.consultations, 'Y', 'CheckIcon', 'N', NULL) consultations_icon,
                   decode(data.consultations, 'D', 'Pref.', 'N', NULL) consultations_text,
                   data.analysis,
                   decode(data.analysis, 'Y', 'CheckIcon', 'N', NULL) analysis_icon,
                   decode(data.analysis, 'D', 'Pref.', 'N', NULL) analysis_text,
                   data.exams,
                   decode(data.exams, 'Y', 'CheckIcon', 'N', NULL) exams_icon,
                   decode(data.exams, 'D', 'Pref.', 'N', NULL) exams_text,
                   data.procedures,
                   decode(data.procedures, 'Y', 'CheckIcon', 'N', NULL) procedures_icon,
                   decode(data.procedures, 'D', 'Pref.', 'N', NULL) procedures_text
              FROM (SELECT DISTINCT p1di.id_inst_dest,
                                    pk_translation.get_translation(i_lang,
                                                                   (SELECT i.code_institution
                                                                      FROM institution i
                                                                     WHERE i.id_institution = p1di.id_inst_dest)) desc_institution,
                                    (SELECT i.ext_code
                                       FROM institution i
                                      WHERE i.id_institution = p1di.id_inst_dest) ext_code,
                                    nvl((SELECT decode(p1di2.flg_default, 'Y', 'D', 'N', 'Y')
                                          FROM p1_dest_institution p1di2
                                         WHERE p1di2.id_inst_orig = i_id_inst_orig
                                           AND p1di2.id_inst_dest = p1di.id_inst_dest
                                           AND p1di2.flg_type = 'C'),
                                        'N') consultations,
                                    nvl((SELECT decode(p1di2.flg_default, 'Y', 'D', 'N', 'Y')
                                          FROM p1_dest_institution p1di2
                                         WHERE p1di2.id_inst_orig = i_id_inst_orig
                                           AND p1di2.id_inst_dest = p1di.id_inst_dest
                                           AND p1di2.flg_type = 'A'),
                                        'N') analysis,
                                    nvl((SELECT decode(p1di2.flg_default, 'Y', 'D', 'N', 'Y')
                                          FROM p1_dest_institution p1di2
                                         WHERE p1di2.id_inst_orig = i_id_inst_orig
                                           AND p1di2.id_inst_dest = p1di.id_inst_dest
                                           AND p1di2.flg_type = 'E'),
                                        'N') exams,
                                    nvl((SELECT decode(p1di2.flg_default, 'Y', 'D', 'N', 'Y')
                                          FROM p1_dest_institution p1di2
                                         WHERE p1di2.id_inst_orig = i_id_inst_orig
                                           AND p1di2.id_inst_dest = p1di.id_inst_dest
                                           AND p1di2.flg_type = 'I'),
                                        'N') procedures
                      FROM p1_dest_institution p1di
                     WHERE id_inst_orig = i_id_inst_orig
                       AND id_inst_dest IN (SELECT DISTINCT id_inst_dest
                                              FROM p1_dest_institution p1di
                                             WHERE id_inst_orig = i_id_inst_orig)) data
            UNION ALL
            SELECT DISTINCT i.id_institution,
                            pk_translation.get_translation(i_lang, i.code_institution) desc_institution,
                            'N',
                            NULL,
                            NULL,
                            'N',
                            NULL,
                            NULL,
                            'N',
                            NULL,
                            NULL,
                            'N',
                            NULL,
                            NULL
              FROM institution i, prof_soft_inst psi
             WHERE psi.id_institution = i.id_institution
               AND psi.id_professional = i_id_prof
               AND i.flg_type IN ('H', 'CH')
               AND i.id_institution NOT IN
                   (SELECT DISTINCT p1di.id_inst_dest
                      FROM p1_dest_institution p1di
                     WHERE id_inst_orig = i_id_inst_orig
                       AND id_inst_dest IN (SELECT DISTINCT id_inst_dest
                                              FROM p1_dest_institution p1di
                                             WHERE id_inst_orig = i_id_inst_orig));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_DEST_INST_PARAMS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_dest_inst_params;

    /** @headcom
    * Public Function. Get P1 Destiny Resume Task List
    *
    * @param      I_LANG                     Prefered language ID
    * @param      O_P1_TYPE                  Cursor with a list of possible tasks on the summaries screen of P1 destinations 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION get_p1_destiny_resume_tasks
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET P1 DESTINY RESUME TASKS CURSOR';
        OPEN o_cur FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = 'P1_DESTINY_RESUME_TASKS'
               AND flg_available = g_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_DESTINY_RESUME_TASKS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_destiny_resume_tasks;

    /** @headcom
    * Public Function. Insert New P1 Specialities Destinations
    *                  OR Update P1 Specialities Destinations
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_TASK                               Task Description
    * @param      I_flg_purpose                        Flag Purpose
    * @param      I_flg_type                           Flag Type
    * @param      I_flg_value                          Flag Value 
    * @param      O_error                              Error 
    *
    * @param      I_flg_value                          {*} 'N' Remove {*} 'Y' Add
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION update_p1_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_task        IN table_varchar,
        i_flg_purpose IN table_varchar,
        i_flg_type    IN table_varchar,
        i_flg_value   IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_task      p1_task.id_task%TYPE;
        l_desc_task    p1_task.desc_task%TYPE;
        l_desc_task_tr p1_task.desc_task%TYPE;
        l_flg_value    VARCHAR2(1);
        l_flg_type     VARCHAR2(1);
        l_rank         p1_task.rank%TYPE;
        l_flg_purpose  p1_task.flg_purpose%TYPE;
    
        CURSOR c_p1_task IS
            SELECT p1_t.id_task
              FROM p1_task p1_t
             WHERE p1_t.desc_task = l_desc_task
               AND p1_t.flg_purpose = l_flg_purpose
               AND p1_t.flg_type = l_flg_type;
    
        e_child_remaining EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_child_remaining, -2292);
    
        --TRANSLATION
        l_id_lang language.id_language%TYPE;
    
        CURSOR c_language IS
            SELECT l.id_language
              FROM LANGUAGE l
             WHERE l.flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        FOR i IN 1 .. i_task.count
        LOOP
            g_error       := 'ASSIGNING VARIABLES';
            l_desc_task   := i_task(i);
            l_flg_purpose := i_flg_purpose(i);
            l_flg_type    := i_flg_type(i);
            l_flg_value   := i_flg_value(i);
        
            g_error := 'SELECT FROM P1_TASK';
            OPEN c_p1_task;
            FETCH c_p1_task
                INTO l_id_task;
            g_found := c_p1_task%FOUND;
            CLOSE c_p1_task;
        
            IF g_found
            THEN
                IF l_flg_value = 'N'
                THEN
                    g_error := 'DELETE from p1_task';
                    DELETE p1_task p1_t
                     WHERE p1_t.id_task = l_id_task;
                END IF;
            ELSE
            
                IF l_flg_value = 'Y'
                THEN
                    g_error := 'SELECT FROM P1_TASK';
                    SELECT DISTINCT p1_t.id_task, p1_t.rank
                      INTO l_id_task, l_rank
                      FROM p1_task p1_t
                     WHERE p1_t.desc_task = l_desc_task
                       AND rownum = 1;
                
                    g_error        := 'SELECT FROM translation';
                    l_desc_task_tr := pk_translation.get_translation(i_lang, 'P1_TASK.CODE_TASK.' || l_id_task);
                
                    g_error := 'GET SEQ_P1_TASK.NEXTVAL';
                    SELECT seq_p1_task.nextval
                      INTO l_id_task
                      FROM dual;
                
                    g_error := 'INSERT INTO p1_task';
                    INSERT INTO p1_task
                        (id_task, desc_task, rank, flg_type, flg_purpose)
                    VALUES
                        (l_id_task, l_desc_task, l_rank, l_flg_type, l_flg_purpose);
                
                    IF l_desc_task_tr IS NULL
                    THEN
                        l_desc_task_tr := l_desc_task;
                    END IF;
                
                    g_error := 'GET LANGUAGES';
                    OPEN c_language;
                    LOOP
                        FETCH c_language
                            INTO l_id_lang;
                        EXIT WHEN c_language%NOTFOUND;
                    
                        g_error := 'INSERT_INTO_TRANSLATION P1_TASK';
                        pk_translation.insert_into_translation(i_lang       => l_id_lang,
                                                               i_code_trans => 'P1_TASK.CODE_TASK.' || l_id_task,
                                                               i_desc_trans => l_desc_task_tr);
                    
                    END LOOP;
                
                    CLOSE c_language;
                
                END IF;
            END IF;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_child_remaining THEN
            DECLARE
                l_error_message VARCHAR2(4000);
            BEGIN
                l_error_message := pk_message.get_message(i_lang, 'ADMINISTRATOR_P1_T045');
                pk_alert_exceptions.process_error(i_lang,
                                                  'ADM_P1_T045',
                                                  l_error_message,
                                                  g_error,
                                                  'ALERT',
                                                  'PK_BACKOFFICE_P1',
                                                  'UPDATE_P1_TASKS',
                                                  'U',
                                                  o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'UPDATE_P1_TASKS');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END update_p1_tasks;

    /** @headcom
    * Public Function. Get P1 Document Tasks
    *
    * @param      I_LANG                     Prefered language ID
    * @param      o_cur                      Cursor with a list of possible tasks on the documents list screen 
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION get_p1_document_tasks
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_P1_DOCUMENT_TASKS CURSOR';
        OPEN o_cur FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE code_domain = 'P1_DOCUMENT_TASKS'
               AND flg_available = g_flg_available
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                pk_types.open_my_cursor(o_cur);
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_BACKOFFICE_P1',
                                   'GET_P1_DOCUMENT_TASKS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_document_tasks;

    /** @headcom
    * Public Function. Get Doc Details
    *
    * @param      I_LANG                     Prefered language ID
    * @param      I_id_speciality            Speciality Id
    * @param      I_id_institution           Institution Id
    * @param      O_CUR                      Cursor with a list of criteria
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/22
    */
    FUNCTION get_doc_details
    (
        i_lang           IN language.id_language%TYPE,
        i_id_speciality  IN speciality.id_speciality%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_cur            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_DOC_DETAILS CURSOR';
        OPEN o_cur FOR
            SELECT p1sh.id_spec_help,
                   pk_translation.get_translation(i_lang, p1sh.code_title) desc_title,
                   pk_translation.get_translation(i_lang, p1sh.code_text) desc_text,
                   p1sh.rank
              FROM p1_spec_help p1sh
             WHERE p1sh.id_institution = i_id_institution
               AND p1sh.id_speciality = i_id_speciality
               AND p1sh.flg_available = g_flg_avail
             ORDER BY p1sh.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                pk_types.open_my_cursor(o_cur);
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_DOC_DETAILS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_doc_details;

    /** @headcom
    * Public Function. Set Document Details
    *
    * @param      I_LANG                               Prefered language ID
    * @param      I_PROF                               Professional identification: Object 
    * @param      I_ID_SPECIALITY                      Speciality identification
    * @param      I_ID_INSTITUTION                     Institution identification
    * @param      I_ID_SPEC_HELP                       Document criteria identification
    * @param      I_TITLE                              Title
    * @param      I_RANK                               Rank
    * @param      I_TEXT                               Text
    * @param      I_FLG_VALUE                          Flag value: Y - Insert or Update; N - Remove
    * @param      O_ERROR                              Error 
    *
    * @value      I_FLG_VALUE                          {*} 'Y' Insert or Update {*} 'N' Remove
    *
    * @return     boolean
    * @author     Eduardo Lourenco
    * @version    0.1
    * @since      2007/08/24
    */
    FUNCTION set_doc_details
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_speciality  IN speciality.id_speciality%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_spec_help   IN table_number,
        i_title          IN table_varchar,
        i_rank           IN table_number,
        i_text           IN table_varchar,
        i_flg_value      IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_spec_help p1_spec_help.id_spec_help%TYPE;
        l_title        pk_translation.t_desc_translation;
        l_rank         p1_spec_help.rank%TYPE;
        l_text         pk_translation.t_desc_translation;
        l_flg_value    VARCHAR(1);
    
        CURSOR c_lang IS
            SELECT *
              FROM LANGUAGE
             WHERE flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        g_sysdate := SYSDATE;
    
        FOR i IN 1 .. i_title.count
        LOOP
            g_error        := 'ASSIGNING VARIABLES';
            l_id_spec_help := i_id_spec_help(i);
            l_title        := i_title(i);
            l_rank         := i_rank(i);
            l_text         := i_text(i);
            l_flg_value    := i_flg_value(i);
        
            IF l_flg_value = 'Y'
            THEN
                IF l_id_spec_help = -1
                   OR l_id_spec_help IS NULL
                THEN
                    g_error := 'SELECT SEQ_P1_SPEC_HELP.NEXTVAL';
                    SELECT seq_p1_spec_help.nextval
                      INTO l_id_spec_help
                      FROM dual;
                
                    g_error := 'INSERT INTO P1_SPEC_HELP';
                    INSERT INTO p1_spec_help
                        (id_spec_help, rank, id_institution, id_speciality, flg_available, id_professional)
                    VALUES
                        (l_id_spec_help, l_rank, i_id_institution, i_id_speciality, 'Y', i_prof.id);
                
                    FOR lang IN c_lang
                    LOOP
                    
                        pk_translation.insert_into_translation(i_lang       => lang.id_language,
                                                               i_code_trans => 'P1_SPEC_HELP.CODE_TITLE.' ||
                                                                               l_id_spec_help,
                                                               i_desc_trans => l_title);
                    
                        pk_translation.insert_into_translation(i_lang       => lang.id_language,
                                                               i_code_trans => 'P1_SPEC_HELP.CODE_TEXT.' ||
                                                                               l_id_spec_help,
                                                               i_desc_trans => l_text);
                    
                    END LOOP;
                    CLOSE c_lang;
                ELSE
                    g_error := 'UPDATE P1_SPEC_HELP';
                    UPDATE p1_spec_help
                       SET rank = l_rank
                     WHERE id_spec_help = l_id_spec_help;
                
                    FOR lang IN c_lang
                    LOOP
                    
                        pk_translation.insert_into_translation(i_lang       => lang.id_language,
                                                               i_code_trans => 'P1_SPEC_HELP.CODE_TITLE.' ||
                                                                               l_id_spec_help,
                                                               i_desc_trans => l_title);
                        pk_translation.insert_into_translation(i_lang       => lang.id_language,
                                                               i_code_trans => 'P1_SPEC_HELP.CODE_TEXT.' ||
                                                                               l_id_spec_help,
                                                               i_desc_trans => l_text);
                    END LOOP;
                    CLOSE c_lang;
                END IF;
            ELSE
                g_error := 'UPDATE TRANSLATION';
                UPDATE p1_spec_help
                   SET flg_available = 'N'
                 WHERE id_spec_help = l_id_spec_help;
            END IF;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
            
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'SET_DOC_DETAILS');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END set_doc_details;

    /** @headcom
    * Public Function. Get P1 Funcionality List
    *
    * @param      I_LANG                     Prefered language ID
    * @param      O_P1_FUNC_LIST             Cursor with a list of possible features
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     Tércio Soares
    * @version    0.1
    * @since      2007/10/11
    */
    FUNCTION get_p1_func_list
    (
        i_lang         IN language.id_language%TYPE,
        o_p1_func_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_P1_DOCUMENT_TASKS CURSOR';
        OPEN o_p1_func_list FOR
            SELECT pk_translation.get_translation(i_lang, sf.code_functionality) func
              FROM sys_functionality sf
             WHERE sf.id_software = 4;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
            
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            
            BEGIN
                pk_types.open_my_cursor(o_p1_func_list);
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'GET_P1_FUNC_LIST');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_p1_func_list;

    /**
    * Set sys_functionalities available for P1
    *
    * @param   I_LANG                   language associated to the professional executing the request 
    * @param   I_PROF                   Object: professional, institution and software ids
    * @param   i_id_professional        Professional id        
    * @param   i_id_institution         Institution id
    * @param   i_dep_clin_serv          Department / Clinical service 
    * @param   i_func                   prof funcionality                    
    * @param   i_args                   Argument: 'N' Remove                     
    * @param   O_ERROR                  an error message, set when return=false
    *
    *  
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Tércio Soares
    * @version 1.0 
    * @since   2007/10/11
    */
    FUNCTION set_prof_func_internal
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_dep_clin_serv   IN table_number,
        i_func            IN table_number,
        i_args            IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_func NUMBER;
    
    BEGIN
    
        FOR i IN 1 .. i_dep_clin_serv.count
        LOOP
            IF i_args(i) = 'N'
            THEN
                g_error := 'DELETE FROM PROF_FUNC';
                DELETE FROM prof_func pf
                 WHERE pf.id_professional = i_id_professional
                   AND pf.id_institution = i_id_institution
                   AND pf.id_dep_clin_serv = i_dep_clin_serv(i)
                   AND pf.id_functionality = i_func(i);
            ELSE
                g_error := 'SELECT SEQ_P1_SPEC_HELP.NEXTVAL';
                SELECT seq_prof_func.nextval
                  INTO l_id_prof_func
                  FROM dual;
            
                g_error := 'INSERT INTO PROF_FUNC';
                INSERT INTO prof_func
                    (id_prof_func, id_functionality, id_professional, id_dep_clin_serv, id_institution)
                VALUES
                    (l_id_prof_func, i_func(i), i_id_professional, i_dep_clin_serv(i), i_id_institution);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'SET_PROF_FUNC');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END set_prof_func_internal;

    /**
    * Set sys_functionalities available for P1
    *
    * @param   I_LANG                   language associated to the professional executing the request 
    * @param   I_PROF                   Object: professional, institution and software ids
    * @param   i_id_professional        Professional id        
    * @param   i_id_institution         Institution id
    * @param   i_dep_clin_serv          Department / Clinical service 
    * @param   i_func                   prof funcionality                    
    * @param   i_args                   Argument: 'N' Remove                     
    * @param   O_ERROR                  an error message, set when return=false
    *
    *  
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Tércio Soares
    * @version 1.0 
    * @since   2007/10/11
    */
    FUNCTION set_prof_func
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_dep_clin_serv   IN table_number,
        i_func            IN table_number,
        i_args            IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_prof_func NUMBER;
    BEGIN
    
        IF NOT set_prof_func_internal(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_professional => i_id_professional,
                                      i_id_institution  => i_id_institution,
                                      i_dep_clin_serv   => i_dep_clin_serv,
                                      i_func            => i_func,
                                      i_args            => i_args,
                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BACKOFFICE_P1', 'SET_PROF_FUNC');
                pk_utils.undo_changes;
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
    END set_prof_func;

BEGIN

    g_exam_freq := 'M';
    g_diag_freq := 'M';
    g_drug_freq := 'M';
    g_flg_avail := 'Y';
    g_active    := 'A';

    g_cat_type_doc  := 'D';
    g_cat_type_nurs := 'N';
    g_cat_type_tec  := 'T';
    g_cat_type_adm  := 'A';
    g_cat_type_farm := 'P';
    g_cat_type_oth  := 'O';

    g_flg_avail := 'Y';

    g_status_pdcs_s := 'S';
    g_flg_available := 'Y';

    g_selected              := 'S';
    g_exam_avail            := 'Y';
    g_prof_flg_state_active := 'A';

    g_id_portugal := 620;

    g_flg_icon_active   := 'A';
    g_flg_icon_inactive := 'I';

    g_bulk_fetch_rows := 100;

END pk_backoffice_p1;
/
