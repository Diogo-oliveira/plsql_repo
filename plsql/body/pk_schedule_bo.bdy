/*-- Last Change Revision: $Rev: 2027669 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:57 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_schedule_bo IS

    -- This package provides the logic for ALERT Scheduler backoffice.
    -- @author  Telmo Castro
    -- @version 2.4.3
    -- @date    22-04-2008

    ------------------------ PRIVATE FUNCTIONS AND VARS ---------------------

    -- lista dos tipos de agendamentos excluidos 
    g_exc_sch_types table_varchar := table_varchar(pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_nut,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_as,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_oexams,
                                                   pk_schedule_common.g_sch_dept_flg_dep_type_cr);

    -- TYPE t_table_permissions IS TABLE OF sch_permission%ROWTYPE;

    /*
    * return rowtype of sch_permission with flg_permission and id_consult_permission filled.
    * if no row is found the resulting rowtype gets 
    * id_consult_permission = null
    * flg_permission = N
    */
    FUNCTION get_permission_prv(i_row IN t_rec_sch_permission) RETURN t_rec_sch_permission IS
        l_ret t_rec_sch_permission;
    BEGIN
        l_ret := i_row;
        -- permissao prof1-prof2-dcs-event
        IF i_row.id_prof_agenda IS NOT NULL
           AND i_row.id_dep_clin_serv IS NOT NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO l_ret.id_consult_permission, l_ret.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_prof_agenda = i_row.id_prof_agenda
               AND s.id_dep_clin_serv = i_row.id_dep_clin_serv
               AND s.id_sch_event = i_row.id_sch_event;
            -- permissao prof1-prof2-event. Para compatibilidade com versoes < 2.4.3
        ELSIF i_row.id_prof_agenda IS NOT NULL
              AND i_row.id_dep_clin_serv IS NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO l_ret.id_consult_permission, l_ret.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_prof_agenda = i_row.id_prof_agenda
               AND s.id_sch_event = i_row.id_sch_event;
            -- permissao prof1-dcs-event. Para compatibilidade com versoes < 2.4.3
        ELSIF i_row.id_prof_agenda IS NULL
              AND i_row.id_dep_clin_serv IS NOT NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO l_ret.id_consult_permission, l_ret.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_dep_clin_serv = i_row.id_dep_clin_serv
               AND s.id_sch_event = i_row.id_sch_event
               AND s.id_prof_agenda IS NULL;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            l_ret.id_consult_permission := NULL;
            l_ret.flg_permission        := pk_schedule.g_permission_none;
            RETURN l_ret;
    END get_permission_prv;

    /*
    * versao economica da funcao com o mesmo nome 
    */
    PROCEDURE get_permission_prv(i_row IN OUT t_rec_sch_permission) IS
    BEGIN
        IF i_row.id_prof_agenda IS NOT NULL
           AND i_row.id_dep_clin_serv IS NOT NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO i_row.id_consult_permission, i_row.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_prof_agenda = i_row.id_prof_agenda
               AND s.id_dep_clin_serv = i_row.id_dep_clin_serv
               AND s.id_sch_event = i_row.id_sch_event;
            -- permissao prof1-prof2-event. Para compatibilidade com versoes < 2.4.3
        ELSIF i_row.id_prof_agenda IS NOT NULL
              AND i_row.id_dep_clin_serv IS NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO i_row.id_consult_permission, i_row.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_prof_agenda = i_row.id_prof_agenda
               AND s.id_sch_event = i_row.id_sch_event;
            -- permissao prof1-dcs-event. Para compatibilidade com versoes < 2.4.3
        ELSIF i_row.id_prof_agenda IS NULL
              AND i_row.id_dep_clin_serv IS NOT NULL
        THEN
            SELECT s.id_consult_permission, s.flg_permission
              INTO i_row.id_consult_permission, i_row.flg_permission
              FROM sch_permission s
             WHERE s.id_institution = i_row.id_institution
               AND s.id_professional = i_row.id_professional
               AND s.id_dep_clin_serv = i_row.id_dep_clin_serv
               AND s.id_sch_event = i_row.id_sch_event
               AND s.id_prof_agenda IS NULL;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            i_row.id_consult_permission := NULL;
            i_row.flg_permission        := pk_schedule.g_permission_none;
    END get_permission_prv;

    /*
    * same as get_permission_prv but for a set of sch_permission%ROWTYPE
    */
    FUNCTION get_permissions_prv(i_rows IN t_table_rec_sch_permission) RETURN t_table_rec_sch_permission IS
        l_ret t_table_rec_sch_permission;
    BEGIN
        l_ret := i_rows;
    
        FOR idx IN 1 .. l_ret.count
        LOOP
            l_ret(idx) := get_permission_prv(l_ret(idx));
        END LOOP;
        RETURN l_ret;
    END get_permissions_prv;

    /*
    * fetch events given to i_to_prof for a given subtype.
    * Aceita i_id_subtype = g_all. Nesse caso devolve os eventos para todos os subtypes
    * O subtype vai sempre no output mesmo quando se trata de uma permissao prof-prof.
    * Isto para que na grelha pre-gravacao se veja o evento em todos os dcs que seleccionou,
    * apesar de na pratica a sch_permission nao receba o dcs
    * permissoes prof-prof
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_subtype_prv
    (
        i_id_inst    IN sch_permission.id_institution%TYPE,
        i_to_prof    IN sch_permission.id_professional%TYPE,
        i_on_prof    IN sch_permission.id_prof_agenda%TYPE,
        i_schtype    IN sch_department.id_department%TYPE,
        i_deptype    IN sch_department.flg_dep_type%TYPE,
        i_id_subtype IN sch_permission.id_dep_clin_serv%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes      VARCHAR2,
            idinst    sch_permission.id_institution%TYPE,
            idschtype sch_department.id_department%TYPE,
            deptype   sch_department.flg_dep_type%TYPE,
            idsubtype sch_permission.id_dep_clin_serv%TYPE,
            idprof    sch_permission.id_prof_agenda%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_dep_clin_serv
              FROM (SELECT DISTINCT sed.id_sch_event, sed.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON d.id_department = sd.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND se.dep_type = sd.flg_dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     WHERE dcs.id_dep_clin_serv = decode(idsubtype, pk_schedule.g_all, dcs.id_dep_clin_serv, idsubtype)
                       AND pdcs.id_professional = idprof
                       AND d.id_institution = idinst
                       AND d.flg_available = gyes
                       AND se.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND se.flg_target_professional = gyes
                       AND sd.id_department = idschtype
                       AND sd.flg_dep_type = deptype
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
        -- fetch events for this subtype (i_id_dcs)
        OPEN lc(g_yes, i_id_inst, i_schtype, i_deptype, i_id_subtype, i_on_prof);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         i_on_prof,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_subtype_prv;

    /*
    * fetch permissions given to i_to_prof for a given sub type and NO destination professional.
    * So in this case the inner cursor must return all pairs id_event | id_prof_agenda.
    * This is for page 24 of Permissions design document.
    * Aceita i_id_subtype = g_all. Nesse caso devolve os eventos para todos os sch types
    * O subtype vai sempre no output mesmo quando se trata de uma permissao prof-prof.
    * Isto para que na grelha pre-gravacao se veja o evento em todos os dcs que seleccionou,
    * apesar de na pratica a sch_permission nao receba o dcs
    * permissoes prof1-prof2-dcs e prof-dcs
    * target_dep_clin_serv ready
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_subtype_prv
    (
        i_id_inst    IN sch_permission.id_institution%TYPE,
        i_to_prof    IN sch_permission.id_professional%TYPE,
        i_schtype    IN sch_department.id_department%TYPE,
        i_deptype    IN sch_department.flg_dep_type%TYPE,
        i_id_subtype IN sch_permission.id_dep_clin_serv%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_prof_agenda     sch_permission.id_prof_agenda%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes      VARCHAR2,
            gno       VARCHAR2,
            idinst    sch_permission.id_institution%TYPE,
            idschtype sch_department.id_department%TYPE,
            deptype   sch_department.flg_dep_type%TYPE,
            idsubtype sch_permission.id_dep_clin_serv%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_professional, t.id_dep_clin_serv
              FROM (SELECT DISTINCT sed.id_sch_event, pdcs.id_professional, idsubtype id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON d.id_department = sd.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND se.dep_type = sd.flg_dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                     WHERE dcs.id_dep_clin_serv = decode(idsubtype, pk_schedule.g_all, dcs.id_dep_clin_serv, idsubtype)
                       AND d.id_institution = idinst
                       AND d.flg_available = gyes
                       AND se.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND se.flg_target_professional = gyes
                       AND sd.id_department = idschtype
                       AND sd.flg_dep_type = deptype
                       AND rownum > 0
                    UNION
                    SELECT DISTINCT sed.id_sch_event, NULL id_professional, dcs.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON d.id_department = sd.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND se.dep_type = sd.flg_dep_type
                     WHERE dcs.id_dep_clin_serv = decode(idsubtype, pk_schedule.g_all, dcs.id_dep_clin_serv, idsubtype)
                       AND d.id_institution = idinst
                       AND d.flg_available = gyes
                       AND se.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND se.flg_target_professional = gno
                       AND se.flg_target_dep_clin_serv = gyes
                       AND sd.id_department = idschtype
                       AND sd.flg_dep_type = deptype
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
    
        -- fetch events for this subtype (i_id_dcs)
        OPEN lc(g_yes, g_no, i_id_inst, i_schtype, i_deptype, i_id_subtype);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_prof_agenda, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         l_id_prof_agenda,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_subtype_prv;

    /*
    * fetch permissions given to i_to_prof for a given sch type and destination professional.
    * Aceita i_id_schtype = g_all. Nesse caso devolve os eventos para todos os sch types
    * O subtype vai sempre no output mesmo quando se trata de uma permissao prof-prof.
    * Isto para que na grelha pre-gravacao se veja o evento em todos os dcs que seleccionou,
    * apesar de na pratica a sch_permission nao receba o dcs
    * permissoes prof1-prof2-dcs
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_schtype_prv
    (
        i_id_inst    IN sch_permission.id_institution%TYPE,
        i_to_prof    IN sch_permission.id_professional%TYPE,
        i_on_prof    IN sch_permission.id_prof_agenda%TYPE,
        i_id_schtype IN sch_department.id_department%TYPE,
        i_deptype    IN sch_department.flg_dep_type%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes      VARCHAR2,
            idinst    sch_permission.id_institution%TYPE,
            idprof    sch_permission.id_prof_agenda%TYPE,
            idschtype sch_department.id_department%TYPE,
            deptype   sch_department.flg_dep_type%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_dep_clin_serv
              FROM (SELECT DISTINCT se.id_sch_event, sed.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND pdcs.id_professional = idprof
                       AND sd.id_department = decode(idschtype, pk_schedule.g_all, sd.id_department, idschtype)
                       AND sd.flg_dep_type = decode(idschtype, pk_schedule.g_all, sd.flg_dep_type, deptype)
                       AND se.flg_target_professional = gyes
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
    
        OPEN lc(g_yes, i_id_inst, i_on_prof, i_id_schtype, i_deptype);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         i_on_prof,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_schtype_prv;

    /*
    * OVERLOAD
    * fetch permissions given to i_to_prof for a given sch type and NO destination professional.
    * So in this case the inner cursor must return all pairs id_event | id_prof_agenda.
    * This is for page 23 of Permissions design document.
    * Aceita i_id_schtype = g_all. Nesse caso devolve os eventos para todos os sch types
    * target_dep_clin_serv ready
    * O subtype vai sempre no output mesmo quando se trata de uma permissao prof-prof.
    * Isto para que na grelha pre-gravacao se veja o evento em todos os dcs que seleccionou,
    * apesar de na pratica a sch_permission nao receba o dcs
    * permissoes prof1-prof2-dcs e prof-dcs
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_schtype_prv
    (
        i_id_inst    IN sch_permission.id_institution%TYPE,
        i_to_prof    IN sch_permission.id_professional%TYPE,
        i_id_schtype IN sch_department.id_department%TYPE,
        i_deptype    IN sch_department.flg_dep_type%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_prof_agenda     sch_permission.id_prof_agenda%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes      VARCHAR2,
            gno       VARCHAR2,
            idinst    sch_permission.id_institution%TYPE,
            idschtype sch_department.id_department%TYPE,
            deptype   sch_department.flg_dep_type%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_professional, t.id_dep_clin_serv
              FROM (SELECT DISTINCT se.id_sch_event, pdcs.id_professional, sed.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND sd.id_department = decode(idschtype, pk_schedule.g_all, sd.id_department, idschtype)
                       AND sd.flg_dep_type = decode(idschtype, pk_schedule.g_all, sd.flg_dep_type, deptype)
                       AND se.flg_target_professional = gyes
                       AND rownum > 0
                    UNION
                    SELECT DISTINCT se.id_sch_event, NULL id_professional, dcs.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND sd.id_department = decode(idschtype, pk_schedule.g_all, sd.id_department, idschtype)
                       AND sd.flg_dep_type = decode(idschtype, pk_schedule.g_all, sd.flg_dep_type, deptype)
                       AND se.flg_target_professional = gno
                       AND se.flg_target_dep_clin_serv = gyes
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
    
        OPEN lc(g_yes, g_no, i_id_inst, i_id_schtype, i_deptype);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_prof_agenda, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         l_id_prof_agenda,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_schtype_prv;

    /*
    * 
    * fetch permissions given to i_to_prof for a given sub type and event and NO destination professional.
    * So in this case the inner cursor must return all pairs id_event | id_prof_agenda and 
    * the pairs id_event | id_dep_clin_serv para os eventos cujo target seja o dcs.
    * This is for page 25 of Permissions design document.
    * Aceita i_id_schtype = g_all. Nesse caso devolve os eventos para todos os sch types
    * target_dep_clin_serv ready
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_event_prv
    (
        i_id_inst    IN sch_permission.id_institution%TYPE,
        i_to_prof    IN sch_permission.id_professional%TYPE,
        i_schtype    IN sch_department.id_department%TYPE,
        i_deptype    IN sch_department.flg_dep_type%TYPE,
        i_id_subtype IN sch_permission.id_dep_clin_serv%TYPE,
        i_id_event   IN sch_permission.id_sch_event%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_prof_agenda     sch_permission.id_prof_agenda%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes      VARCHAR2,
            gno       VARCHAR2,
            idinst    sch_permission.id_institution%TYPE,
            idsubtype sch_permission.id_dep_clin_serv%TYPE,
            idevent   sch_permission.id_sch_event%TYPE,
            idschtype sch_department.id_department%TYPE,
            deptype   sch_department.flg_dep_type%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_professional, t.id_dep_clin_serv
              FROM (SELECT DISTINCT se.id_sch_event, pdcs.id_professional, idsubtype id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND dcs.id_dep_clin_serv = decode(idsubtype, pk_schedule.g_all, dcs.id_dep_clin_serv, idsubtype)
                       AND se.id_sch_event = idevent
                       AND se.flg_target_professional = gyes
                       AND sd.id_department = idschtype
                       AND sd.flg_dep_type = deptype
                       AND rownum > 0
                    UNION
                    SELECT DISTINCT se.id_sch_event, NULL id_professional, dcs.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND dcs.id_dep_clin_serv = decode(idsubtype, pk_schedule.g_all, dcs.id_dep_clin_serv, idsubtype)
                       AND se.id_sch_event = idevent
                       AND se.flg_target_professional = gno
                       AND se.flg_target_dep_clin_serv = gyes
                       AND sd.id_department = idschtype
                       AND sd.flg_dep_type = deptype
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
    
        OPEN lc(g_yes, g_no, i_id_inst, i_id_subtype, i_id_event, i_schtype, i_deptype);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_prof_agenda, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         l_id_prof_agenda,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_event_prv;

    /*
    * fetch all possible permissions given to i_to_prof upon i_on_prof
    * O subtype vai sempre no output mesmo quando se trata de uma permissao prof-prof.
    * Isto para que na grelha pre-gravacao se veja o evento em todos os dcs que seleccionou,
    * apesar de na pratica a sch_permission nao receba o dcs
    * permissoes prof-prof
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    */
    FUNCTION get_perm_from_zero_prv
    (
        i_id_inst IN sch_permission.id_institution%TYPE,
        i_to_prof IN sch_permission.id_professional%TYPE,
        i_on_prof IN sch_permission.id_prof_agenda%TYPE
    ) RETURN t_table_rec_sch_permission IS
    
        l_return             t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_id_event           sch_permission.id_sch_event%TYPE;
        l_id_dep_clin_serv   sch_permission.id_dep_clin_serv%TYPE;
        l_rec_sch_permission t_rec_sch_permission;
    
        CURSOR lc
        (
            gyes   VARCHAR2,
            idinst sch_permission.id_institution%TYPE,
            idprof sch_permission.id_prof_agenda%TYPE
        ) IS
            SELECT t.id_sch_event, t.id_dep_clin_serv
              FROM (SELECT DISTINCT se.id_sch_event, sed.id_dep_clin_serv
                      FROM department d
                     INNER JOIN sch_department sd
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE d.flg_available = gyes
                       AND sdt.flg_available = gyes
                       AND dcs.flg_available = gyes
                       AND sed.flg_available = gyes
                       AND se.flg_available = gyes
                       AND d.id_institution = idinst
                       AND pdcs.id_professional = idprof
                       AND se.flg_target_professional = g_yes
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
    BEGIN
    
        OPEN lc(g_yes, i_id_inst, i_on_prof);
        LOOP
            FETCH lc
                INTO l_id_event, l_id_dep_clin_serv;
            EXIT WHEN lc%NOTFOUND;
        
            l_rec_sch_permission := t_rec_sch_permission(NULL,
                                                         i_id_inst,
                                                         i_to_prof,
                                                         i_on_prof,
                                                         l_id_dep_clin_serv,
                                                         l_id_event,
                                                         NULL);
            l_return.extend;
            l_return(l_return.last) := l_rec_sch_permission;
        END LOOP;
    
        CLOSE lc;
    
        RETURN get_permissions_prv(l_return);
    
    END get_perm_from_zero_prv;

    /*
    * fetch all possible permissions given to each i_to_prof upon each i_on_profs
    */
    FUNCTION get_perms_from_zero_prv
    (
        i_id_inst  IN sch_permission.id_institution%TYPE,
        i_to_profs IN table_number,
        i_on_profs IN table_number
    ) RETURN t_table_rec_sch_permission IS
    
        l_return t_table_rec_sch_permission := t_table_rec_sch_permission();
        l_tmp    t_table_rec_sch_permission := t_table_rec_sch_permission();
    
    BEGIN
        -- validations
        IF i_to_profs IS NULL
           OR i_to_profs.count < 1
        THEN
            RETURN NULL;
        END IF;
    
        IF i_on_profs IS NULL
           OR i_on_profs.count < 1
        THEN
            RETURN NULL;
        END IF;
    
        -- cycle on i_to_profs
        FOR idx0 IN 1 .. i_to_profs.count
        LOOP
            -- cycle i_on_profs
            FOR idx IN 1 .. i_on_profs.count
            LOOP
                l_tmp := get_perm_from_zero_prv(i_id_inst, i_to_profs(idx0), i_on_profs(idx));
                -- append iteration result to output
                FOR ind IN 1 .. l_tmp.count
                LOOP
                    l_return.extend;
                    l_return(l_return.last) := l_tmp(ind);
                END LOOP;
            END LOOP;
        END LOOP;
    
        -- obtain permissions for this events
        RETURN get_permissions_prv(l_return);
    
    END get_perms_from_zero_prv;

    /*
    * testing. delete this
    */
    FUNCTION get_test(o_rs OUT pk_types.cursor_type) RETURN BOOLEAN IS
        lt t_table_rec_sch_permission;
    BEGIN
    
        lt := get_perm_from_zero_prv(100, 606, 606);
    
        OPEN o_rs FOR
            SELECT *
              FROM TABLE(CAST(lt AS t_table_rec_sch_permission));
    
        RETURN TRUE;
    END;

    /*
    * funcao comum para:
    * converter um t_table_rec_sch_permission para um sys_refcursor
    * embelezar o resultado com as designacoes
    */
    FUNCTION get_nice_perms_prv
    (
        i_lang IN language.id_language%TYPE,
        i_coll IN t_table_rec_sch_permission
    ) RETURN pk_types.cursor_type IS
        l_perms             pk_types.cursor_type;
        l_msg_noaccess      sys_config.value%TYPE;
        l_msg_viewonly      sys_config.value%TYPE;
        l_msg_sched         sys_config.value%TYPE;
        l_msg_no_desig_prof sys_config.value%TYPE;
    BEGIN
        -- obter messages
        l_msg_noaccess      := pk_message.get_message(i_lang, g_msg_noaccess);
        l_msg_viewonly      := pk_message.get_message(i_lang, g_msg_viewonly);
        l_msg_sched         := pk_message.get_message(i_lang, g_msg_viewandsched);
        l_msg_no_desig_prof := pk_message.get_message(i_lang, g_msg_no_desig_prof_grid);
    
        OPEN l_perms FOR
            SELECT /*+opt_estimate(table t rows=1)*/
            DISTINCT t.*,
                     p1.name to_name,
                     p1.title to_title,
                     p2.name on_name,
                     p2.title on_title,
                     (SELECT pk_schedule_common.get_translation_alias(i_lang,
                                                                      profissional(0, 0, 0),
                                                                      se.id_sch_event,
                                                                      se.code_sch_event)
                        FROM dual) event_name,
                     CASE t.flg_permission
                         WHEN pk_schedule.g_permission_none THEN
                          l_msg_noaccess
                         WHEN pk_schedule.g_permission_read THEN
                          l_msg_viewonly
                         WHEN pk_schedule.g_permission_schedule THEN
                          l_msg_sched
                         ELSE
                          t.flg_permission
                     END accesslevel,
                     (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                        FROM dual) subtype_name,
                     CASE
                          WHEN t.id_prof_agenda IS NULL THEN
                           l_msg_no_desig_prof
                          ELSE
                           NULL
                      END permtype,
                     (SELECT pk_translation.get_translation(i_lang, d.code_department)
                        FROM dual) department_name
              FROM TABLE(CAST(i_coll AS t_table_rec_sch_permission)) t
             INNER JOIN professional p1
                ON t.id_professional = p1.id_professional
              LEFT JOIN professional p2
                ON t.id_prof_agenda = p2.id_professional
             INNER JOIN sch_event se
                ON t.id_sch_event = se.id_sch_event
              LEFT JOIN dep_clin_serv dcs
                ON t.id_dep_clin_serv = dcs.id_dep_clin_serv
              LEFT JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
              LEFT JOIN department d
                ON dcs.id_department = d.id_department
             ORDER BY accesslevel;
    
        RETURN l_perms;
    
    END get_nice_perms_prv;

    --------------------------- PUBLIC FUNCTIONS -------------------------
    /*
    * returns the total number of events for a given sch type kind.
    * Can be used in a select clause.
    *
    * @param i_flg_dep_type sch type kind
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    */
    FUNCTION get_sch_type_events_count(i_flg_dep_type IN sch_event.dep_type%TYPE) RETURN NUMBER IS
    
        l_out NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_out
          FROM sch_event se
         WHERE se.dep_type = i_flg_dep_type
           AND se.flg_available = g_yes;
    
        RETURN l_out;
    END get_sch_type_events_count;

    /*
    * returns the total number of events linked to a given dcs.
    * Can be used in a select clause.
    *
    * @param i_id_dep_clin_serv  dcs id
    * @param i_id_sch_type       sch type id
    * @param i_flg_dep_type      dep type 
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * CORRECTED
    * added parameter i_flg_dep_type in order to properly query sch_department
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     08-07-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    */
    FUNCTION get_dcs_events_count
    (
        i_id_dep_clin_serv IN sch_event_dcs.id_dep_clin_serv%TYPE,
        i_id_sch_type      IN sch_department.id_department%TYPE,
        i_flg_dep_type     IN sch_department.flg_dep_type%TYPE
    ) RETURN NUMBER IS
    
        l_out     NUMBER;
        l_id_inst department.id_institution%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_INSTITUTION FROM department TABLE';
        SELECT d.id_institution
          INTO l_id_inst
          FROM department d
          JOIN dep_clin_serv dcs
            ON d.id_department = dcs.id_department
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
    
        SELECT COUNT(1)
          INTO l_out
          FROM (SELECT se.id_sch_event
                  FROM sch_event_dcs sed
                 INNER JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                 INNER JOIN sch_event se
                    ON sed.id_sch_event = se.id_sch_event
                 INNER JOIN sch_dep_type sdt
                    ON se.dep_type = sdt.dep_type
                 INNER JOIN sch_department sd
                    ON sdt.dep_type = sd.flg_dep_type
                 WHERE sed.id_dep_clin_serv = i_id_dep_clin_serv
                   AND se.flg_available = g_yes
                   AND sed.flg_available = g_yes
                   AND sdt.flg_available = g_yes
                   AND sd.id_department = i_id_sch_type
                   AND sd.flg_dep_type = i_flg_dep_type
                   AND (sdt.dep_type_group != pk_schedule_common.g_sch_dept_flg_dep_type_cons OR EXISTS
                        (SELECT 1
                           FROM appointment a
                          WHERE a.id_clinical_service = dcs.id_clinical_service
                            AND a.id_sch_event = se.id_sch_event
                            AND a.flg_available = g_yes))
                   AND rownum > 0) t
         WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, l_id_inst, 0)
                  FROM dual) = pk_alert_constant.g_yes;
    
        RETURN l_out;
    
    END get_dcs_events_count;

    /*
    * returns the total number of dcs in a sch type, in a institution
    * Can be used in a select clause.
    *
    * @param i_institution    inst. id
    * @param i_sch_type       sch type id
    * @param i_flg_dep_type   dep type 
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * CORRECTED
    * added parameter i_flg_dep_type in order to properly query sch_department
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     08-07-2008
    */
    FUNCTION get_dep_dcs_count
    (
        i_institution  IN department.id_institution%TYPE,
        i_id_sch_type  IN sch_department.id_department%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE
    ) RETURN NUMBER IS
    
        l_out NUMBER;
    BEGIN
    
        SELECT COUNT(1)
          INTO l_out
          FROM department d
         INNER JOIN sch_department sd
            ON d.id_department = sd.id_department
         INNER JOIN sch_dep_type sdt
            ON sd.flg_dep_type = sdt.dep_type
         INNER JOIN dep_clin_serv dcs
            ON d.id_department = dcs.id_department
         INNER JOIN clinical_service cs
            ON dcs.id_clinical_service = cs.id_clinical_service
         WHERE d.id_institution = i_institution
           AND d.id_department = i_id_sch_type
           AND sd.flg_dep_type = i_flg_dep_type
           AND dcs.flg_available = g_yes
           AND d.flg_available = g_yes
           AND cs.flg_available = g_yes
           AND (sdt.dep_type_group != pk_schedule_common.g_sch_dept_flg_dep_type_cons OR EXISTS
                (SELECT 1
                   FROM appointment a
                  WHERE a.id_clinical_service = cs.id_clinical_service
                    AND a.flg_available = g_yes));
    
        RETURN l_out;
    
    END get_dep_dcs_count;

    /*
    * get list with candidate departments to become scheduling types.
    * There is a column which tells if department is already a sch. type. 
    * Only department with a recognized flg_type are selected.
    * Used in Agendamentos disponiveis.
    *
    * @param i_lang     Language identifier
    * @param i_prof     professional
    * @param o_depts    department list
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     22-04-2008
    *
    * UPDATED
    * column is_sch_type moved to function get_dep_types. Also, the validation for existence in sch_dep_type_map 
    * is removed
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    04-07-2008
    */

    FUNCTION get_departments
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_inst IN department.id_institution%TYPE,
        o_depts   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'GET_DEPARTMENTS';
    BEGIN
        g_error := 'OPEN o_depts';
        -- Open cursor
        OPEN o_depts FOR
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, dt.code_dept) || ' (' ||
                   pk_translation.get_translation(i_lang, d.code_department) || ')' dep_name,
                   d.flg_type
              FROM department d
              JOIN dept dt
                ON d.id_dept = dt.id_dept
             WHERE d.id_institution = i_id_inst
               AND d.flg_available = g_yes
             ORDER BY dep_name, d.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_depts);
            RETURN FALSE;
        
    END get_departments;

    /*
    * get list of Available scheduling types to be coupled with the given department.
    * There is a column indicating if the sch. type is already coupled (determined from table sch_department)
    * Used in Agendamentos disponiveis.
    *
    * @param i_lang     Language identifier
    * @param i_id_dept  department id
    * @param o_dep_types department list
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     04-07-2008
    */
    FUNCTION get_dep_types
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dept   IN department.id_institution%TYPE,
        o_dep_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEP_TYPES';
    BEGIN
        g_error := 'OPEN o_dep_types';
        -- Open cursor
        OPEN o_dep_types FOR
            SELECT dep_type,
                   pk_translation.get_translation(i_lang, d.code_dep_type) dep_type_name,
                   CASE
                        WHEN (SELECT 1
                                FROM dual
                               WHERE EXISTS (SELECT 1
                                        FROM sch_department
                                       WHERE id_department = i_id_dept
                                         AND flg_dep_type = d.dep_type)) = 1 THEN
                         g_status_active
                        ELSE
                         g_status_inactive
                    END is_sch_type
              FROM sch_dep_type d
             WHERE d.flg_available = g_yes
               AND d.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons -- só mostra eventos de consultas e derivados
             ORDER BY dep_type_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_dep_types);
            RETURN FALSE;
        
    END get_dep_types;

    /*
    * saves list of departments to sch. types table (sch_department)
    * Both cases are dealt with: those which are set and those which are unset.
    *
    * @param i_lang     Language identifier
    * @param i_prof     professional
    * @param i_ids      list of (id_department, flg_dep_type)
    * @param i_values   A=set  I=unset
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     22-04-2008
    *
    * UPDATED
    * alteracoes para o remake do deepnav Tipos de agendamento disponiveis
    *
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    04-07-2008
    */
    FUNCTION set_sch_types
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_ids    IN table_table_varchar,
        i_values IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        e_bad_arguments EXCEPTION;
        e_no_map        EXCEPTION;
        l_func_name     VARCHAR2(32) := 'SET_SCH_TYPES';
        l_id_dep        sch_department.id_department%TYPE;
        l_dep_type      sch_department.flg_dep_type%TYPE;
        l_innertable    table_varchar;
    BEGIN
        g_error := 'CHECK DEP. COUNT AGAINST VALUES COUNT';
        IF i_ids.count != i_values.count
        THEN
            RAISE e_bad_arguments;
        END IF;
    
        -- processar lista dos ids
        FOR idx IN 1 .. i_ids.count
        LOOP
            g_error      := 'NEW ITERATION';
            l_innertable := i_ids(idx);
            -- verificar existencia de registo 
            BEGIN
                SELECT id_department, flg_dep_type
                  INTO l_id_dep, l_dep_type
                  FROM sch_department sd
                 WHERE sd.id_department = l_innertable(1)
                   AND sd.flg_dep_type = l_innertable(2);
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_dep   := NULL;
                    l_dep_type := NULL;
            END;
        
            -- ja existe registo, vai updatar
            IF l_id_dep IS NOT NULL
               AND l_dep_type IS NOT NULL
            THEN
                -- apagar se registo existe e o value vem com N
                IF nvl(i_values(idx), g_status_inactive) = g_status_inactive
                THEN
                    g_error := 'DELETE SCH. TYPE';
                    DELETE FROM sch_department
                     WHERE id_department = l_id_dep
                       AND flg_dep_type = l_dep_type;
                END IF;
            ELSE
                -- inserir se nao existe e o value vem com Y
                IF nvl(i_values(idx), g_status_inactive) = g_status_active
                THEN
                    g_error := 'INSERT SCH. TYPE';
                    INSERT INTO sch_department
                        (id_department, flg_dep_type)
                        SELECT l_innertable(1), l_innertable(2)
                          FROM sch_dep_type s
                         WHERE s.dep_type = l_innertable(2)
                           AND s.flg_available = g_yes;
                    -- se nao inseriu e' porque nao encontrou mapeamento na sch_dep_type (novo tipo de departamento?)
                    IF SQL%ROWCOUNT = 0
                    THEN
                        RAISE e_no_map;
                    END IF;
                END IF;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_bad_arguments THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Attribute count does not match value count',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN e_no_map THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'No dep. type found in sch_dep_type (' || l_dep_type || ')',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_sch_types;

    /*
    * returns scheduling types list for given institution
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang       Language identifier
    * @param i_id_inst    institution id
    * @param o_sch_types  sch. types list
    * @param o_error      Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * added Total line to the beggining so that this function can be reused in Permissions
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     07-05-2008 
    */
    FUNCTION get_sch_types
    (
        i_lang      IN language.id_language%TYPE,
        i_id_inst   IN department.id_institution%TYPE,
        o_sch_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_SCH_TYPES';
        l_linecount    PLS_INTEGER;
        l_message      sys_config.value%TYPE;
        l_replacements table_varchar;
        l_tokens       table_varchar;
    BEGIN
    
        -- get sys_message
        g_error   := 'get sys_message ' || g_msg_todosschtypes;
        l_message := pk_message.get_message(i_lang, g_msg_todosschtypes);
        IF l_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todosschtypes ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
        ELSE
            SELECT COUNT(1)
              INTO l_linecount
              FROM department d
             INNER JOIN sch_department sd
                ON d.id_department = sd.id_department
             INNER JOIN sch_dep_type sdt
                ON sd.flg_dep_type = sdt.dep_type
             WHERE d.id_institution = i_id_inst
               AND d.flg_available = g_yes
               AND sdt.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons; -- só mostra eventos de consultas e derivados
        
            -- finalize message that goes like this: all types of scheduling (x)
            -- this message is inserted in the 1st line of the output
            g_error        := 'replace tokens';
            l_replacements := table_varchar(l_linecount);
            l_tokens       := table_varchar('@1');
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => l_message,
                                              i_tokens       => l_tokens,
                                              i_replacements => l_replacements,
                                              o_string       => l_message,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        -- Open cursor
        g_error := 'OPEN o_sch_types';
        OPEN o_sch_types FOR
            SELECT pk_schedule.g_all id_department,
                   l_message         sch_type_name,
                   NULL              flg_dep_type,
                   NULL              dep_type_name,
                   1                 order_field
              FROM dual
            UNION
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) sch_type_name,
                   sd.flg_dep_type,
                   pk_translation.get_translation(i_lang, sdt.code_dep_type) dep_type_name,
                   2
              FROM department d
             INNER JOIN sch_department sd
                ON d.id_department = sd.id_department
             INNER JOIN sch_dep_type sdt
                ON sd.flg_dep_type = sdt.dep_type
             WHERE d.id_institution = i_id_inst
               AND d.flg_available = g_yes
               AND sdt.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons -- só mostra eventos de consultas e derivados
             ORDER BY order_field, dep_type_name; -- sch_type_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sch_types);
            RETURN FALSE;
        
    END get_sch_types;

    /*
    * returns scheduling types list for given institution. This function originated from get_sch_types.
    * Because get_sch_types was used in 2 diferent places.
    * Used in alert backoffice -> scheduler -> permissions (option = by scheduling type)
    *
    * @param i_lang       Language identifier
    * @param i_prof       professional data
    * @param i_id_inst    institution id
    * @param o_sch_types  sch. types list
    * @param o_error      Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.6
    * @date     09-04-2010
    */
    FUNCTION get_sch_types_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_inst   IN department.id_institution%TYPE,
        o_sch_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_SCH_TYPES_BY_TYPE';
        l_linecount      PLS_INTEGER;
        l_message        sys_config.value%TYPE;
        l_replacements   table_varchar;
        l_tokens         table_varchar;
        l_exclude_c_type sys_config.value%TYPE;
    BEGIN
    
        -- get sys_config parameter that tells us if Physician appointments and look alikes must be excluded.
        -- If so, those permissions are taken care of in scheduler 3
        SELECT nvl(pk_sysconfig.get_config(g_cfg_exclude_phys_app_type, i_prof), pk_alert_constant.g_yes)
          INTO l_exclude_c_type
          FROM dual;
    
        -- get sys_message
        g_error   := 'get sys_message ' || g_msg_todosschtypes;
        l_message := pk_message.get_message(i_lang, g_msg_todosschtypes);
        IF l_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todosschtypes ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
        ELSE
            SELECT COUNT(1)
              INTO l_linecount
              FROM department d
             INNER JOIN sch_department sd
                ON d.id_department = sd.id_department
             WHERE d.id_institution = i_id_inst
               AND d.flg_available = g_yes
               AND (l_exclude_c_type = pk_alert_constant.g_no OR
                   sd.flg_dep_type NOT IN (SELECT column_value
                                              FROM TABLE(g_exc_sch_types)));
        
            -- finalize message that goes like this: all types of scheduling (x)
            -- this message is inserted in the 1st line of the output
            g_error        := 'replace tokens';
            l_replacements := table_varchar(l_linecount);
            l_tokens       := table_varchar('@1');
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => l_message,
                                              i_tokens       => l_tokens,
                                              i_replacements => l_replacements,
                                              o_string       => l_message,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- Open cursor
        g_error := 'OPEN o_sch_types';
        OPEN o_sch_types FOR
            SELECT pk_schedule.g_all id_department,
                   l_message         sch_type_name,
                   NULL              flg_dep_type,
                   NULL              dep_type_name,
                   1                 order_field
              FROM dual
            UNION
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) sch_type_name,
                   sd.flg_dep_type,
                   pk_translation.get_translation(i_lang, sdt.code_dep_type) dep_type_name,
                   2
              FROM department d
             INNER JOIN sch_department sd
                ON d.id_department = sd.id_department
             INNER JOIN sch_dep_type sdt
                ON sd.flg_dep_type = sdt.dep_type
             WHERE d.id_institution = i_id_inst
               AND d.flg_available = g_yes
               AND (l_exclude_c_type = pk_alert_constant.g_no OR
                   sdt.dep_type NOT IN (SELECT column_value
                                           FROM TABLE(g_exc_sch_types)))
             ORDER BY order_field, dep_type_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sch_types);
            RETURN FALSE;
    END get_sch_types_by_type;

    /*
    * returns scheduling sub types list for given institution and given sch. type.
    * Also returns designation of that subtype.
    * Included is a column with the event count for such sch_type
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang         Language identifier
    * @param i_id_inst      institution id
    * @param i_id_sch_type  sch type id
    * @param i_flg_dep_type dep type 
    * @param o_sch_types    sch. sub types list
    * @param o_subtype      subtype designation
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * incluido novo parametro i_flg_dep_type para filtrar correctamente a sch_department
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    07-07-2008
    */
    FUNCTION get_sch_subtypes
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst      IN department.id_institution%TYPE,
        i_id_sch_type  IN department.id_department%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE,
        o_sch_stypes   OUT pk_types.cursor_type,
        o_subtype      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_SCH_SUBTYPES';
        e_no_translation EXCEPTION;
    BEGIN
        g_error := 'OPEN o_sch_stypes';
        -- Open cursor
        OPEN o_sch_stypes FOR
            SELECT pk_schedule.g_all id_dcs,
                   pk_message.get_message(i_lang, 'SCH_T631') sch_subtype_name,
                   pk_schedule_bo.get_dep_dcs_count(i_id_inst, i_id_sch_type, i_flg_dep_type) total_events,
                   0 checked_events,
                   1 order_field
              FROM dual
            UNION
            SELECT dcs.id_dep_clin_serv,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) sch_subtype_name,
                   pk_schedule_bo.get_sch_type_events_count(sd.flg_dep_type) total_events,
                   pk_schedule_bo.get_dcs_events_count(dcs.id_dep_clin_serv, i_id_sch_type, i_flg_dep_type) checked_events,
                   2
              FROM department d
             INNER JOIN sch_department sd
                ON d.id_department = sd.id_department
             INNER JOIN sch_dep_type sdt
                ON sd.flg_dep_type = sdt.dep_type
             INNER JOIN dep_clin_serv dcs
                ON d.id_department = dcs.id_department
             INNER JOIN clinical_service cs
                ON dcs.id_clinical_service = cs.id_clinical_service
             WHERE d.id_institution = i_id_inst
               AND d.id_department = i_id_sch_type
               AND sd.flg_dep_type = i_flg_dep_type
               AND dcs.flg_available = g_yes
               AND d.flg_available = g_yes
               AND cs.flg_available = g_yes
             ORDER BY order_field, sch_subtype_name;
    
        -- get subtype designation
        g_error := 'GET subtype';
        SELECT pk_translation.get_translation(i_lang, code_sched_subtype)
          INTO o_subtype
          FROM sch_dep_type sdt
         INNER JOIN sch_department sd
            ON sdt.dep_type = sd.flg_dep_type
         INNER JOIN department d
            ON sd.id_department = d.id_department
         WHERE d.id_institution = i_id_inst
           AND d.id_department = i_id_sch_type
           AND sd.flg_dep_type = i_flg_dep_type
           AND d.flg_available = g_yes
           AND sdt.flg_available = g_yes;
    
        -- se chegou aqui existe registo na sch_dep_type
        IF o_subtype IS NULL
        THEN
            RAISE e_no_translation;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_no_translation THEN
            o_subtype := '';
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || '(code_sched_subtype): lang=' ||
                                                i_lang || '  id_department=' || i_id_sch_type,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            RETURN TRUE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sch_stypes);
            RETURN FALSE;
        
    END get_sch_subtypes;

    /*
    * return list of events for a given sch. subtype.
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang         Language identifier
    * @param i_id_inst      institution id
    * @param i_id_sch_Type  sch_type id
    * @param i_id_sch_stype sch subtype id
    * @param i_flg_dep_type dep type
    * @param o_sch_events   sch. sub types list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * incluido novo parametro i_flg_dep_type para filtrar correctamente a sch_department
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    07-07-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    */
    FUNCTION get_sch_subtype_events
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst      IN department.id_institution%TYPE,
        i_id_sch_type  IN department.id_department%TYPE,
        i_id_sch_stype IN sch_event_dcs.id_dep_clin_serv%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE,
        o_sch_events   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'get_sch_subtype_events';
    BEGIN
        g_error := 'OPEN o_sch_events';
        -- Open cursor
        OPEN o_sch_events FOR
            SELECT pk_schedule.g_all id_event,
                   pk_message.get_message(i_lang, g_msg_todoseventos) event_name,
                   NULL checked,
                   pk_schedule_bo.get_dcs_events_count(i_id_sch_stype, i_id_sch_type, i_flg_dep_type) count_checked,
                   1 order_field
              FROM dual
            UNION
            SELECT t.id_sch_event id_event,
                   pk_schedule_common.get_translation_alias(i_lang,
                                                            profissional(0, i_id_inst, 0),
                                                            t.id_sch_event,
                                                            t.code_sch_event) event_name,
                   t.checked,
                   NULL count_checked,
                   2 order_field
              FROM (SELECT se.id_sch_event,
                           se.code_sch_event,
                           CASE
                                WHEN (SELECT COUNT(1)
                                        FROM sch_event_dcs
                                       WHERE id_sch_event = se.id_sch_event
                                         AND id_dep_clin_serv = dcs.id_dep_clin_serv
                                         AND flg_available = g_yes) = 0 THEN
                                 g_status_inactive
                                ELSE
                                 g_status_active
                            END checked
                      FROM dep_clin_serv dcs
                     INNER JOIN department d
                        ON dcs.id_department = d.id_department
                     INNER JOIN sch_department sd
                        ON d.id_department = sd.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN sch_event se
                        ON se.dep_type = sd.flg_dep_type
                     WHERE d.id_institution = i_id_inst
                       AND dcs.id_dep_clin_serv = i_id_sch_stype
                       AND d.flg_available = g_yes
                       AND dcs.flg_available = g_yes
                       AND se.flg_available = g_yes
                       AND d.id_department = i_id_sch_type
                       AND sd.flg_dep_type = i_flg_dep_type
                       AND sdt.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_sch_events);
            RETURN FALSE;
        
    END get_sch_subtype_events;

    /*
    * saves associations dcs - event to the database, table sch_event_dcs
    * Used in Configuracao dos tipos de agendamento.
    *
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_data         table with attribute pairs id_sch_event | id_dep_clin_serv 
    * @param i_values       table with values (Y, N)
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     24-04-2008
    *
    * UPDATED 
    * agora aceita pares null | id_dep_clin_serv. Nesse caso e' preciso encontrar todos os eventos desse
    * dep_clin_serv e settar em todos o valor respectivo em i_values
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     07-05-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    */
    FUNCTION set_sch_events_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_ids    IN table_table_number,
        i_values IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_bad_arguments EXCEPTION;
        l_func_name     VARCHAR2(32) := 'set_sch_events_dcs';
        l_teibel        table_number;
        l_config        sys_config.id_sys_config%TYPE := g_search_default_duration;
        l_defdur        sys_config.value%TYPE;
    
        CURSOR c_events(i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT t.id_sch_event
              FROM (SELECT se.id_sch_event
                      FROM dep_clin_serv dcs
                     INNER JOIN department d
                        ON dcs.id_department = d.id_department
                     INNER JOIN sch_department sd
                        ON d.id_department = sd.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN sch_event se
                        ON se.dep_type = sdt.dep_type
                     WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
                       AND d.flg_available = pk_alert_constant.g_yes
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND se.flg_available = pk_alert_constant.g_yes
                       AND sdt.flg_available = pk_alert_constant.g_yes
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_prof.institution, i_prof.software)
                      FROM dual) = pk_alert_constant.g_yes;
    
        FUNCTION inner_save
        (
            i_id_sch_event     IN sch_event.id_sch_event%TYPE,
            i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
            i_value            IN VARCHAR2,
            i_defdur           IN sys_config.value%TYPE,
            i_prof             IN profissional
        ) RETURN BOOLEAN IS
            l_fname            VARCHAR2(32) := 'SET_SCH_EVENTS_DCS - INNER_SAVE';
            l_id_sch_event_dcs sch_event_dcs.id_sch_event_dcs%TYPE;
            l_flg_available    sch_event_dcs.flg_available%TYPE;
            l_newid            sch_event_dcs.id_sch_event_dcs%TYPE;
            l_old_id_event     sch_event_dcs.id_sch_event%TYPE;
            l_old_id_dcs       sch_event_dcs.id_dep_clin_serv%TYPE;
            l_newvalue         VARCHAR2(1);
            l_id_app           appointment.id_appointment%TYPE;
            l_id_cs            dep_clin_serv.id_clinical_service%TYPE;
            l_id_inst          department.id_institution%TYPE;
        BEGIN
            g_error := l_fname || ' - CHECK EXISTENCE IN SCH_EVENT_DCS id_sch_event=' || i_id_sch_event ||
                       ', id_dep_clin_serv=' || i_id_dep_clin_serv;
            -- ver se registo ja existe
            BEGIN
                SELECT sed.id_sch_event_dcs, sed.flg_available, sed.id_sch_event, sed.id_dep_clin_serv
                  INTO l_id_sch_event_dcs, l_flg_available, l_old_id_event, l_old_id_dcs
                  FROM sch_event_dcs sed
                  LEFT JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                 WHERE sed.id_sch_event = i_id_sch_event
                   AND sed.id_dep_clin_serv = i_id_dep_clin_serv;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_sch_event_dcs := NULL;
            END;
        
            -- pegar o id_clinical_service e id_institution do dcs
            g_error := l_fname || ' - GET ID_CLINICAL_SERVICE FROM DEP_CLIN_SERV id_dep_clin_serv=' ||
                       i_id_dep_clin_serv;
            SELECT dcs.id_clinical_service, d.id_institution
              INTO l_id_cs, l_id_inst
              FROM dep_clin_serv dcs
              JOIN department d
                ON dcs.id_department = d.id_department
             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
        
            -- ver se esta combo tem appointment. Influencia a chamada ao pk_ia_event_backoffice.
            g_error := l_fname || ' - CHECK APPOINTMENT EXISTENCE id_sch_event=' || i_id_sch_event ||
                       ', id_dep_clin_serv=' || i_id_dep_clin_serv;
            BEGIN
                SELECT a.id_appointment
                  INTO l_id_app
                  FROM appointment a
                 WHERE a.id_sch_event = i_id_sch_event
                   AND a.id_clinical_service = l_id_cs
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_app := NULL;
            END;
        
            -- se nao existe e o value e' A insere
            IF l_id_sch_event_dcs IS NULL
            THEN
                IF nvl(i_value, g_status_inactive) = g_status_active
                THEN
                    g_error := l_fname || ' - INSERT sch_event_dcs id_sch_event=' || i_id_sch_event ||
                               ', id_dep_clin_serv=' || i_id_dep_clin_serv;
                    INSERT INTO sch_event_dcs
                        (id_sch_event_dcs,
                         id_sch_event,
                         id_dep_clin_serv,
                         duration,
                         id_prof_created,
                         dt_created,
                         flg_available)
                    VALUES
                        (seq_sch_event_dcs.nextval,
                         i_id_sch_event,
                         i_id_dep_clin_serv,
                         i_defdur,
                         i_prof.id,
                         current_timestamp,
                         g_yes)
                    RETURNING id_sch_event_dcs INTO l_newid;
                
                    g_error := l_fname || ' - INSERT/UPDATE APPOINTMENT';
                    IF NOT pk_schedule_tools.generate_appointment(i_lang          => i_lang,
                                                                  i_id_sch_event  => i_id_sch_event,
                                                                  i_id_cs         => l_id_cs,
                                                                  i_id_inst       => l_id_inst,
                                                                  i_upd_lb_transl => TRUE,
                                                                  i_flg_avail     => pk_alert_constant.g_yes,
                                                                  o_error         => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    g_error := l_fname || ' - CALL PK_IA_EVENT_BACKOFFICE.SCH_EVENT_DCS_NEW i_id_sch_event_dcs=' ||
                               l_newid;
                    pk_ia_event_backoffice.sch_event_dcs_new(l_newid);
                END IF;
            ELSE
                -- registo na sch_event_dcs existe, vai apenas alterar estado
                -- converter i_value para Y/N
                l_newvalue := CASE i_value
                                  WHEN g_status_inactive THEN
                                   g_no
                                  WHEN g_status_active THEN
                                   g_yes
                                  ELSE
                                   g_yes
                              END;
            
                -- so faz update se o estado mudou mesmo
                IF l_flg_available != l_newvalue
                THEN
                    -- se existe faz update
                    g_error := l_fname || ' - UPDATE SCH_EVENT_DCS set flg_available=' || l_newvalue ||
                               ' where id_sch_event_dcs=' || l_id_sch_event_dcs;
                    UPDATE sch_event_dcs
                       SET flg_available = l_newvalue, dt_updated = current_timestamp, id_prof_updated = i_prof.id
                     WHERE id_sch_event_dcs = l_id_sch_event_dcs;
                
                    IF l_id_app IS NOT NULL
                    THEN
                        -- ALERT-307415 only update appointment.flg_available if other DCS with this id_clinical_service do not exist. 
                        -- Otherwise, all scheduler 3 procedures of this appointment would be disabled.
                        g_error := l_fname || ' - UPDATE APPOINTMENT set flg_available=' || l_newvalue ||
                                   ' where id_appointment=' || l_id_app;
                    
                        -- faz sempre um delete...
                        g_error := l_fname || ' - CALL PK_IA_EVENT_BACKOFFICE.SCH_EVENT_DCS_DELETE';
                        pk_ia_event_backoffice.sch_event_dcs_delete(l_id_sch_event_dcs, l_old_id_event, l_old_id_dcs);
                    
                        -- ... e eventualmente um insert se o novo estado e' Y (active)
                        IF l_newvalue = g_yes
                        THEN
                            g_error := l_fname || ' - CALL PK_IA_EVENT_BACKOFFICE.SCH_EVENT_DCS_NEW';
                            pk_ia_event_backoffice.sch_event_dcs_new(l_id_sch_event_dcs);
                        END IF;
                        UPDATE appointment a
                           SET a.flg_available = l_newvalue
                         WHERE a.id_appointment = l_id_app
                           AND NOT EXISTS (SELECT 1
                                  FROM sch_event_dcs sed
                                  JOIN dep_clin_serv dcs
                                    ON sed.id_dep_clin_serv = dcs.id_dep_clin_serv
                                 WHERE sed.id_sch_event = i_id_sch_event
                                   AND dcs.id_clinical_service = l_id_cs
                                   AND sed.flg_available = pk_alert_constant.g_yes
                                   AND sed.id_sch_event_dcs != l_id_sch_event_dcs);
                    
                        -- EMR-18502           
                        IF SQL%ROWCOUNT = 0
                        THEN
                            IF l_newvalue = g_yes
                            THEN
                                pk_ia_event_backoffice.appointment_enable_for_inst(l_id_cs, i_id_sch_event, l_id_inst);
                            ELSIF l_newvalue = g_no
                            THEN
                                pk_ia_event_backoffice.appointment_disable_for_inst(l_id_cs, i_id_sch_event, l_id_inst);
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            RETURN TRUE;
        
        END inner_save;
    
    BEGIN
    
        g_error := 'CHECK IDS COUNT';
        IF i_ids.count != i_values.count
        THEN
            RAISE e_bad_arguments;
        END IF;
    
        -- obter default duration from sys_config
        IF NOT (pk_sysconfig.get_config(g_search_default_duration, i_prof, l_defdur))
           OR l_defdur IS NULL
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => pk_schedule.g_missing_config || ' ' || l_config ||
                                                            ' (Institution: ' || i_prof.institution || ')',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        END IF;
    
        -- processar lista dos pares
        FOR idx IN 1 .. i_ids.count
        LOOP
            g_error  := 'NEW ITERATION';
            l_teibel := i_ids(idx);
        
            -- ver se e' uma gravacao de grupo (todos) ou uma individual
            IF l_teibel(1) IS NULL
               AND l_teibel(2) IS NOT NULL
            THEN
                -- gravacao de grupo
                FOR c_event IN c_events(l_teibel(2))
                LOOP
                    IF NOT inner_save(c_event.id_sch_event, l_teibel(2), i_values(idx), l_defdur, i_prof)
                    THEN
                        RETURN FALSE;
                    END IF;
                END LOOP;
            ELSIF l_teibel(1) IS NOT NULL
                  AND l_teibel(2) IS NOT NULL
            THEN
                -- par (id_sch_event, id_dep_clin_serv)  individual
                IF NOT inner_save(l_teibel(1), l_teibel(2), i_values(idx), l_defdur, i_prof)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN e_bad_arguments THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Attribute count does not match value count',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_sch_events_dcs;

    /*
    * return list of options for permission's right panel initial option
    * Used in Permissions
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param o_prof         output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    */
    FUNCTION get_sch_selection
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCH_SELECTION';
    BEGIN
        g_error := 'OPEN o_list';
        -- Open cursor
        OPEN o_list FOR
            SELECT code_message, desc_message
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message IN (SELECT *
                                        FROM TABLE(g_perm_by_list))
               AND s.id_software = i_prof.software
               AND s.id_institution = i_prof.institution
            UNION
            SELECT code_message, desc_message
              FROM sys_message s
             WHERE s.id_language = i_lang
               AND s.code_message IN (SELECT *
                                        FROM TABLE(g_perm_by_list))
               AND s.id_software = 0
               AND s.id_institution = 0;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
    END get_sch_selection;

    /*
    * return list scheduling types available to ALL members of input list of professionals.
    * Used in Permissions. The output is the intersection of sch types available to all professionals
    * in i_profs. That is, if a single profissional does not have access to a sch type, that type
    * is not part of the output
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_profs        list of professionals Ids 
    * @param i_inst         institutuion id. Common to all i_profs members
    * @param o_schtypes     output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    */
    FUNCTION get_prof_sch_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_profs    IN table_number,
        i_inst     IN NUMBER,
        o_schtypes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_PROF_SCH_TYPES';
        l_profcount      PLS_INTEGER;
        l_message        sys_message.desc_message%TYPE;
        l_linecount      PLS_INTEGER;
        l_replacements   table_varchar;
        l_tokens         table_varchar;
        l_exclude_c_type sys_config.value%TYPE;
    BEGIN
        -- get i_profs count to be used in the main query. this value must equal the line count of a 
        -- particular pair (prof, schtype) in order to the sch type entering the output
        g_error     := 'get prof list count';
        l_profcount := i_profs.count;
    
        -- get sys_config parameter that tells us if Physician appointments and look alikes must be excluded.
        -- If so, those permissions are taken care of in scheduler 3
        SELECT nvl(pk_sysconfig.get_config(g_cfg_exclude_phys_app_type, i_prof), pk_alert_constant.g_yes)
          INTO l_exclude_c_type
          FROM dual;
    
        -- get sys_message
        g_error   := 'get sys_message ' || g_msg_todosschtypes;
        l_message := pk_message.get_message(i_lang, g_msg_todosschtypes);
        IF l_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todosschtypes ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
        ELSE
            SELECT COUNT(1)
              INTO l_linecount
              FROM (SELECT t1.id_department, t1.flg_dep_type, COUNT(1)
                      FROM (SELECT DISTINCT sd.id_department, sd.flg_dep_type, pdcs.id_professional
                              FROM sch_department sd
                             INNER JOIN department d
                                ON sd.id_department = d.id_department
                             INNER JOIN sch_dep_type sdt
                                ON sd.flg_dep_type = sdt.dep_type
                             INNER JOIN dep_clin_serv dcs
                                ON sd.id_department = dcs.id_department
                             INNER JOIN prof_dep_clin_serv pdcs
                                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                             INNER JOIN (SELECT *
                                          FROM TABLE(i_profs)) t
                                ON pdcs.id_professional = t.column_value
                             WHERE d.flg_available = g_yes
                               AND sdt.flg_available = g_yes
                               AND dcs.flg_available = g_yes
                               AND d.id_institution = i_inst
                               AND (l_exclude_c_type = pk_alert_constant.g_no OR
                                   sdt.dep_type NOT IN (SELECT column_value
                                                           FROM TABLE(g_exc_sch_types)))) t1
                     GROUP BY t1.id_department, t1.flg_dep_type
                    HAVING COUNT(1) = l_profcount);
        
            -- finalize message that goes like this: all types of scheduling (x)
            -- this message is inserted in the 1st position of the output
            g_error        := 'replace tokens';
            l_replacements := table_varchar(l_linecount);
            l_tokens       := table_varchar('@1');
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => l_message,
                                              i_tokens       => l_tokens,
                                              i_replacements => l_replacements,
                                              o_string       => l_message,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        -- Open cursor
        g_error := 'OPEN o_schtypes';
        OPEN o_schtypes FOR
            SELECT pk_schedule.g_all id_department,
                   NULL              flg_dep_type,
                   l_message         depname,
                   NULL              deptype,
                   NULL              conta,
                   1                 order_field
              FROM dual
            UNION
            SELECT t1.id_department, t1.flg_dep_type, t1.depname, t1.deptype, COUNT(1), 2
              FROM (SELECT DISTINCT sd.id_department,
                                    sd.flg_dep_type,
                                    pk_translation.get_translation(i_lang, d.code_department) depname,
                                    pk_translation.get_translation(i_lang, sdt.code_dep_type) deptype,
                                    pdcs.id_professional
                      FROM sch_department sd
                     INNER JOIN department d
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     INNER JOIN (SELECT *
                                  FROM TABLE(i_profs)) t
                        ON pdcs.id_professional = t.column_value
                     WHERE d.flg_available = g_yes
                       AND sdt.flg_available = g_yes
                       AND dcs.flg_available = g_yes
                       AND d.id_institution = i_inst
                       AND (l_exclude_c_type = pk_alert_constant.g_no OR
                           sdt.dep_type NOT IN (SELECT column_value
                                                   FROM TABLE(g_exc_sch_types)))) t1
             GROUP BY t1.id_department, t1.flg_dep_type, t1.depname, t1.deptype
            HAVING COUNT(1) = l_profcount
             ORDER BY order_field, depname;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_schtypes);
            RETURN FALSE;
        
    END get_prof_sch_types;

    /*
    * return list of scheduling subtypes available to ALL members of input list of professionals.
    * Used in Permissions. The output is the intersection of all sch sub types belonging to 
    * sch types in i_schtypes and available to all professionals in i_profs. 
    * That is, if a single professional does not have access to a subtype, it does not 
    * leave the house
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_profid       list of professionals Ids
    * @param i_sch_type     sch type
    * @param i_dep_type     corresponding dep type
    * @param i_inst         institution id
    * @param o_subtypes     output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    *
    * UPDATED
    * change of behavior. From now on this accepts only one prof and one schtype. The possibility to 
    * throw several pairs was not being used, so, for the sake of simplicity this was removed. Another
    * reason to do this is the introduction of a new parameter, i_flg_dep_type, in order to 
    * properly query the sch_department table. 
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    09-07-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author   Telmo Castro
    * @version  2.4.3.x
    * @date     09-10-2008
    */
    FUNCTION get_prof_sch_subtypes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_profid   IN sch_permission.id_professional%TYPE,
        i_sch_type IN sch_department.id_department%TYPE,
        i_dep_type IN sch_department.flg_dep_type%TYPE,
        i_inst     IN NUMBER,
        o_subtypes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_PROF_SCH_SUBTYPES';
        l_noschtypes   EXCEPTION;
        l_message      sys_message.desc_message%TYPE;
        l_linecount    PLS_INTEGER;
        l_replacements table_varchar;
        l_tokens       table_varchar;
        l_subtypename  sch_dep_type.code_sched_subtype%TYPE;
    BEGIN
        -- get sys_message
        g_error   := 'get sys_message ' || g_msg_todossubtypes;
        l_message := pk_message.get_message(i_lang, g_msg_todossubtypes);
    
        IF l_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todossubtypes ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
        ELSE
            -- get subtype label. Uses first schtype from i_schtypes
            g_error := 'get subtype name';
            SELECT pk_translation.get_translation(i_lang, code_sched_subtype)
              INTO l_subtypename
              FROM sch_dep_type sdt
             INNER JOIN sch_department sd
                ON sd.flg_dep_type = sdt.dep_type
             WHERE sd.id_department = i_sch_type
               AND sd.flg_dep_type = i_dep_type;
        
            IF l_subtypename IS NULL
            THEN
                pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || '(code_sched_subtype): lang=' ||
                                                    i_lang || '  id_department=' || i_sch_type || '  flg_dep_type=' ||
                                                    i_dep_type,
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
            END IF;
        
            -- get line count to insert into summary line
            SELECT COUNT(DISTINCT t.id_dep_clin_serv)
              INTO l_linecount
              FROM (SELECT se.id_sch_event, dcs.id_dep_clin_serv
                      FROM sch_department sd
                     INNER JOIN department d
                        ON sd.id_department = d.id_department
                     INNER JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                     INNER JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                     INNER JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                       AND sdt.dep_type = se.dep_type
                     INNER JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                     WHERE d.flg_available = g_yes
                       AND sdt.flg_available = g_yes
                       AND dcs.flg_available = g_yes
                       AND sed.flg_available = g_yes
                       AND se.flg_available = g_yes
                       AND d.id_institution = i_inst
                       AND sd.id_department = i_sch_type
                       AND sd.flg_dep_type = i_dep_type
                       AND pdcs.id_professional = i_profid
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes;
        
            -- finalize message that goes like this: all types of <subtype> (<count>)
            -- this message is inserted in the 1st position of the output
            g_error        := 'replace tokens';
            l_replacements := table_varchar(nvl(l_subtypename, ' '), l_linecount);
            l_tokens       := table_varchar('@1', '@2');
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => l_message,
                                              i_tokens       => l_tokens,
                                              i_replacements => l_replacements,
                                              o_string       => l_message,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        -- Open cursor
        g_error := 'OPEN o_schtypes';
        OPEN o_subtypes FOR
            SELECT pk_schedule.g_all id_dep_clin_serv, l_message subtypename, l_linecount conta, 1 order_field
              FROM dual
            UNION
            SELECT t.id_dep_clin_serv, t.subtypename, COUNT(1) conta, 2 order_field
              FROM (SELECT DISTINCT id_dep_clin_serv,
                                    pk_translation.get_translation(i_lang, code_clinical_service) subtypename,
                                    id_professional
                      FROM (SELECT se.id_sch_event, dcs.id_dep_clin_serv, cs.code_clinical_service, pdcs.id_professional
                              FROM sch_department sd
                             INNER JOIN department d
                                ON sd.id_department = d.id_department
                             INNER JOIN sch_dep_type sdt
                                ON sd.flg_dep_type = sdt.dep_type
                             INNER JOIN dep_clin_serv dcs
                                ON sd.id_department = dcs.id_department
                             INNER JOIN clinical_service cs
                                ON dcs.id_clinical_service = cs.id_clinical_service
                             INNER JOIN sch_event_dcs sed
                                ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                             INNER JOIN sch_event se
                                ON sed.id_sch_event = se.id_sch_event
                               AND sdt.dep_type = se.dep_type
                             INNER JOIN prof_dep_clin_serv pdcs
                                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                             WHERE d.flg_available = g_yes
                               AND sdt.flg_available = g_yes
                               AND dcs.flg_available = g_yes
                               AND sed.flg_available = g_yes
                               AND se.flg_available = g_yes
                               AND d.id_institution = i_inst
                               AND sd.id_department = i_sch_type
                               AND sd.flg_dep_type = i_dep_type
                               AND pdcs.id_professional = i_profid
                               AND rownum > 0) t
                     WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_inst, 0)
                              FROM dual) = pk_alert_constant.g_yes) t
             GROUP BY t.id_dep_clin_serv, t.subtypename
             ORDER BY order_field, subtypename;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_noschtypes THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'empty input parameter - i_schtypes',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_subtypes);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_subtypes);
            RETURN FALSE;
        
    END get_prof_sch_subtypes;

    /*
    * return list of events available for the given list of subtypes (dcs)
    * Used in Permissions. The output is the intersection of all events belonging to 
    * each subtype. 
    * That is, an event must be assigned to all subtypes in i_subtypes to be part of 
    * the output.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_subtypes     list of sub types
    * @param o_events       output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     06-05-2008
    */
    FUNCTION get_prof_events
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subtypes IN table_number,
        o_events   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'GET_PROF_EVENTS';
        l_subtypecount   PLS_INTEGER;
        l_message        sys_message.desc_message%TYPE;
        l_linecount      PLS_INTEGER;
        l_replacements   table_varchar;
        l_tokens         table_varchar;
        l_exclude_c_type sys_config.value%TYPE;
    BEGIN
        -- get i_subtypes count to be used in the main query. this value must equal the line count of a 
        -- particular pair (subtype, event) in order for the event to enter the output
        -- the .COUNT also protects against null i_subtypes
        g_error        := 'get subtype count';
        l_subtypecount := i_subtypes.count;
    
        -- get sys_config parameter that tells us if Physician appointments and look alikes must be excluded.
        -- If so, those permissions are taken care of in scheduler 3
        SELECT nvl(pk_sysconfig.get_config(g_cfg_exclude_phys_app_type, i_prof), pk_alert_constant.g_yes)
          INTO l_exclude_c_type
          FROM dual;
    
        -- get sys_message
        g_error   := 'get sys_message ' || g_msg_todoseventos2;
        l_message := pk_message.get_message(i_lang, g_msg_todoseventos2);
    
        IF l_message IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todoseventos2 ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            l_message := ' ';
        ELSE
            -- get line count to append to message in the first row
            SELECT COUNT(1)
              INTO l_linecount
              FROM (SELECT t.id_sch_event, COUNT(1)
                      FROM (SELECT DISTINCT sed.id_sch_event, sed.id_dep_clin_serv
                              FROM dep_clin_serv dcs
                             INNER JOIN sch_event_dcs sed
                                ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                             INNER JOIN sch_event se
                                ON sed.id_sch_event = se.id_sch_event
                             INNER JOIN (SELECT *
                                          FROM TABLE(i_subtypes)) t
                                ON dcs.id_dep_clin_serv = t.column_value
                             WHERE se.flg_available = g_yes
                               AND sed.flg_available = g_yes
                               AND dcs.flg_available = g_yes
                               AND (l_exclude_c_type = pk_alert_constant.g_no OR
                                   se.dep_type NOT IN (SELECT column_value
                                                          FROM TABLE(g_exc_sch_types)))
                               AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_prof.institution, 0) =
                                   pk_alert_constant.g_yes) t
                     GROUP BY t.id_sch_event
                    HAVING COUNT(1) = l_subtypecount);
        
            -- finalize message that goes like this: all types of scheduling (x)
            -- this message is inserted in the 1st position of the output
            g_error        := 'replace tokens';
            l_replacements := table_varchar(l_linecount);
            l_tokens       := table_varchar('@1');
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => l_message,
                                              i_tokens       => l_tokens,
                                              i_replacements => l_replacements,
                                              o_string       => l_message,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        -- open cursor
        g_error := 'OPEN o_events';
        OPEN o_events FOR
            SELECT pk_schedule.g_all id_sch_event, l_message eventname, NULL conta, 1 order_field
              FROM dual
            UNION
            SELECT t.id_sch_event, t.eventname, COUNT(1) conta, 2 order_field
              FROM (SELECT DISTINCT sed.id_sch_event,
                                    pk_schedule_common.get_translation_alias(i_lang,
                                                                             i_prof,
                                                                             sed.id_sch_event,
                                                                             se.code_sch_event) eventname,
                                    sed.id_dep_clin_serv
                      FROM dep_clin_serv dcs
                     INNER JOIN sch_event_dcs sed
                        ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                     INNER JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                     INNER JOIN (SELECT *
                                  FROM TABLE(i_subtypes)) t
                        ON dcs.id_dep_clin_serv = t.column_value
                     WHERE se.flg_available = g_yes
                       AND sed.flg_available = g_yes
                       AND dcs.flg_available = g_yes
                       AND (l_exclude_c_type = pk_alert_constant.g_no OR
                           se.dep_type NOT IN (SELECT column_value
                                                  FROM TABLE(g_exc_sch_types)))
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_prof.institution, 0)
                      FROM dual) = pk_alert_constant.g_yes
             GROUP BY id_sch_event, eventname
            HAVING COUNT(1) = l_subtypecount
             ORDER BY order_field, eventname;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_events);
            RETURN FALSE;
        
    END get_prof_events;

    /*
    * return list of professional available for given event.
    * If the event is targeted to professionals, a list of professionals is returned.
    * If the event is targeted to dep_clin_serv, a single line saying No designated 
    * professional is returned.
    * Used in Permissions. 
    * target_dep_clin_serv ready.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_subtypes     list of sub types
    * @param o_events       output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     13-05-2008
    */
    FUNCTION get_event_profs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subtype IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_event   IN sch_event.id_sch_event%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name    VARCHAR2(32) := 'GET_EVENT_PROFS';
        l_message      sys_message.desc_message%TYPE;
        l_linecount    PLS_INTEGER;
        l_replacements table_varchar;
        l_tokens       table_varchar;
        l_target_dcs   sch_event.flg_target_dep_clin_serv%TYPE;
        l_target_prof  sch_event.flg_target_professional%TYPE;
        l_no_event     EXCEPTION;
        l_id_inst      department.id_institution%TYPE;
    BEGIN
        -- get event data
        g_error := 'get event data';
        BEGIN
            SELECT se.flg_target_professional, se.flg_target_dep_clin_serv
              INTO l_target_prof, l_target_dcs
              FROM sch_event se
             WHERE se.id_sch_event = i_event
               AND se.flg_available = g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE l_no_event;
        END;
    
        -- open cursor
        g_error := 'OPEN o_profs';
        IF l_target_prof = g_no
           AND l_target_dcs = g_yes
        THEN
            -- get sys_message
            g_error   := 'get sys_message ' || g_msg_no_desig_prof;
            l_message := pk_message.get_message(i_lang, g_msg_no_desig_prof);
            IF l_message IS NULL
            THEN
                pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_no_desig_prof ||
                                                    ' : lang=' || i_lang,
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
                l_message := ' ';
            END IF;
        
            OPEN o_profs FOR
                SELECT NULL id_prof, l_message profname, 1 total
                  FROM dep_clin_serv dcs
                 INNER JOIN sch_event_dcs sed
                    ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                 INNER JOIN sch_event se
                    ON sed.id_sch_event = se.id_sch_event
                 WHERE dcs.flg_available = g_yes
                   AND sed.flg_available = g_yes
                   AND se.id_sch_event = i_event
                   AND dcs.id_dep_clin_serv = i_subtype;
        
        ELSIF l_target_prof = g_yes
        THEN
            -- get sys_message
            g_error   := 'get sys_message ' || g_msg_todosprofs;
            l_message := pk_message.get_message(i_lang, g_msg_todosprofs);
        
            IF l_message IS NULL
            THEN
                pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_todosprofs ||
                                                    ' : lang=' || i_lang,
                                     object_name => g_package_name,
                                     owner       => g_package_owner);
                l_message := ' ';
            ELSE
                -- get id_inst
                g_error := 'GET id_institution FROM department TABLE';
                SELECT d.id_institution
                  INTO l_id_inst
                  FROM department d
                  JOIN dep_clin_serv dcs
                    ON d.id_department = dcs.id_department
                 WHERE dcs.id_dep_clin_serv = i_subtype;
            
                -- get line count to append to message in the first row
                SELECT COUNT(1)
                  INTO l_linecount
                  FROM (SELECT se.id_sch_event
                          FROM department d
                         INNER JOIN sch_department sd
                            ON d.id_department = sd.id_department
                         INNER JOIN dep_clin_serv dcs
                            ON sd.id_department = dcs.id_department
                         INNER JOIN sch_event_dcs sed
                            ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                         INNER JOIN sch_event se
                            ON sed.id_sch_event = se.id_sch_event
                         INNER JOIN prof_dep_clin_serv pdcs
                            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                         INNER JOIN professional p
                            ON pdcs.id_professional = p.id_professional
                         WHERE d.flg_available = g_yes
                           AND dcs.flg_available = g_yes
                           AND sed.flg_available = g_yes
                           AND se.flg_available = g_yes
                           AND se.id_sch_event = i_event
                           AND dcs.id_dep_clin_serv = i_subtype
                           AND rownum > 0) t
                 WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, l_id_inst, 0)
                          FROM dual) = pk_alert_constant.g_yes;
            
                -- finalize message that goes like this: all professionals (x)
                -- this message is inserted in the 1st position of the output
                g_error        := 'replace tokens';
                l_replacements := table_varchar(l_linecount);
                l_tokens       := table_varchar('@1');
                IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                                  i_string       => l_message,
                                                  i_tokens       => l_tokens,
                                                  i_replacements => l_replacements,
                                                  o_string       => l_message,
                                                  o_error        => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                OPEN o_profs FOR
                    SELECT pk_schedule.g_all id_prof, l_message profname, l_linecount total, 1 order_field
                      FROM dual
                    UNION
                    SELECT t.id_professional id_prof, t.name profname, NULL total, 2 order_field
                      FROM (SELECT se.id_sch_event, pdcs.id_professional, p.name
                              FROM department d
                             INNER JOIN sch_department sd
                                ON d.id_department = sd.id_department
                             INNER JOIN dep_clin_serv dcs
                                ON sd.id_department = dcs.id_department
                             INNER JOIN sch_event_dcs sed
                                ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                             INNER JOIN sch_event se
                                ON sed.id_sch_event = se.id_sch_event
                             INNER JOIN prof_dep_clin_serv pdcs
                                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                             INNER JOIN professional p
                                ON pdcs.id_professional = p.id_professional
                             WHERE d.flg_available = g_yes
                               AND dcs.flg_available = g_yes
                               AND sed.flg_available = g_yes
                               AND se.flg_available = g_yes
                               AND se.id_sch_event = i_event
                               AND dcs.id_dep_clin_serv = i_subtype
                               AND rownum > 0) t
                     WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, l_id_inst, 0)
                              FROM dual) = pk_alert_constant.g_yes
                     ORDER BY order_field, profname;
            
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_event THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'event not found or not available',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
        
    END get_event_profs;

    /*
    * Gets a professional's permission to access a given professional's schedule.
    *
    * @param    i_lang                 Language identifier.
    * @param    i_prof                 Professional.
    * @param    i_id_dep_clin_serv     Department-Clinical service identifier.
    * @param    i_id_sch_event         Event identifier.
    * @param    i_id_prof              Professsional identifier (target professional).
    * @param    o_error                Error message if something goes wrong
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/15
    *
    * IMPORTED FROM PK_SCHEDULE
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    09-05-2008
    */
    FUNCTION get_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        o_permission       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PERMISSION';
    BEGIN
        BEGIN
            SELECT sp.flg_permission
              INTO o_permission
              FROM sch_permission sp, sch_event se
             WHERE sp.id_institution = i_prof.institution
               AND sp.id_professional = i_prof.id
               AND sp.id_sch_event = i_id_sch_event
               AND se.id_sch_event = sp.id_sch_event
               AND ((se.flg_target_professional = g_yes AND sp.id_prof_agenda = i_id_prof AND
                   sp.id_dep_clin_serv IS NULL) OR
                   (se.flg_target_professional = g_no AND se.flg_target_dep_clin_serv = g_yes AND
                   sp.id_dep_clin_serv = i_id_dep_clin_serv AND sp.id_prof_agenda IS NULL) OR
                   (sp.id_prof_agenda = i_id_prof AND sp.id_dep_clin_serv = i_id_dep_clin_serv AND
                   sp.id_prof_agenda IS NOT NULL AND sp.id_dep_clin_serv IS NOT NULL));
        EXCEPTION
            WHEN no_data_found THEN
                o_permission := NULL;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_permission;

    /*
    * Returns decomposition of this combinations
    * i_to_profs | i_on_profs | i_schtypes | i_subtypes | i_events
    *    Y       |    Y 
    *    Y       |    Y       |    Y
    *    Y       |    Y       |    Y       |     Y
    *    Y       |    Y       |    Y       |     Y      |    Y
    * 
    * into a cursor_type with this columns
    *   id_prof | id_prof_agenda ou id_dep_clin_serv | id_event | flg_permission
    * 
    * Used in Permissions to breakdown all user choices into all possible 
    * combinations to be shown in summary screen before saving.
    * All parameters of type table_number must have equal total members, because
    * pairing is done through collection index.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_inst         institution id
    * @param i_to_profs     list of professional ids that are being given permissions
    * @param i_on_profs     list of professional ids whose agendas are being granted/revoked permission
    * @param i_schtypes     list of pairs sch_type + dep_type
    * @param i_subtypes     list of sch subtypes 
    * @param i_events       list of events
    * @param o_perms        output list
    * @param o_error        Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     12-05-2008
    *
    * UPDATED
    * alteracao para equiparar i_schtypes(null) a i_schtypes(table_varchar(null, null))
    * @author   Telmo Castro
    * @version  2.4.3.2
    * @date     22-09-2008
    * 
    */
    FUNCTION get_permissions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN sch_permission.id_institution%TYPE,
        i_to_profs     IN table_number,
        i_on_profs     IN table_number,
        i_schtypes     IN table_table_varchar,
        i_subtypes     IN table_number,
        i_events       IN table_number,
        o_perms        OUT pk_types.cursor_type,
        o_msg_max_rows OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_bad_arguments EXCEPTION;
        l_func_name     VARCHAR2(32) := 'GET_PERMISSIONS';
        l_rec           t_rec_sch_permission;
        l_ret_table     t_table_rec_sch_permission;
        l_max_rows      NUMBER;
    
        -- append de 1 record a' table do resultado
        PROCEDURE inner_appendrec(i_rec IN t_rec_sch_permission) IS
        BEGIN
            IF i_rec IS NOT NULL
            THEN
                l_ret_table.extend;
                l_ret_table(l_ret_table.last) := i_rec;
            END IF;
        END inner_appendrec;
    
        -- append de 1 table a' table do resultado. Sao do mesmo tipo
        PROCEDURE inner_appendtable(i_table IN t_table_rec_sch_permission) IS
        BEGIN
            IF i_table IS NOT NULL
            THEN
                l_ret_table := l_ret_table MULTISET UNION i_table;
            END IF;
        END inner_appendtable;
    
    BEGIN
        l_max_rows := pk_sysconfig.get_config(i_code_cf => g_num_max_rows, i_prof => i_prof);
    
        -- validacao dos parametros de entrada. Os table_number devem estar inicializados e terem igual comprimento
        IF i_to_profs IS NULL
           OR i_on_profs IS NULL
           OR i_schtypes IS NULL
           OR i_subtypes IS NULL
           OR i_events IS NULL
           OR i_to_profs.count != i_on_profs.count
           OR i_to_profs.count != i_schtypes.count
           OR i_to_profs.count != i_subtypes.count
           OR i_to_profs.count != i_events.count
        THEN
            RAISE e_bad_arguments;
        END IF;
    
        -- init output
        l_ret_table := t_table_rec_sch_permission();
    
        -- ciclo principal
        FOR idx IN 1 .. i_to_profs.count
        LOOP
            -- prof1 + prof2 + schtype + subtype + event = permissao para especialidade OU prof ok
            -- este caso e' especial. Ja' temos todos os valores para obter o valor da permissao 
            -- directamente da sch_permission
            IF i_to_profs(idx) IS NOT NULL
               AND i_on_profs(idx) IS NOT NULL
               AND i_schtypes(idx) IS NOT NULL
               AND i_subtypes(idx) IS NOT NULL
               AND i_events(idx) IS NOT NULL
            THEN
                l_rec                  := t_rec_sch_permission(NULL, NULL, NULL, NULL, NULL, NULL, NULL);
                l_rec.id_institution   := i_inst;
                l_rec.id_professional  := i_to_profs(idx);
                l_rec.id_prof_agenda   := i_on_profs(idx);
                l_rec.id_dep_clin_serv := i_subtypes(idx);
                l_rec.id_sch_event     := i_events(idx);
                get_permission_prv(l_rec);
                inner_appendrec(l_rec);
                -- prof1 + prof2 + schtype + subtype = permissao para prof - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NOT NULL
                  AND i_schtypes(idx) IS NOT NULL
                  AND i_schtypes(idx) (1) IS NOT NULL
                  AND i_schtypes(idx) (2) IS NOT NULL
                  AND i_subtypes(idx) IS NOT NULL
                  AND i_events(idx) IS NULL
            THEN
                inner_appendtable(get_perm_from_subtype_prv(i_inst,
                                                            i_to_profs(idx),
                                                            i_on_profs(idx),
                                                            i_schtypes(idx) (1),
                                                            i_schtypes(idx) (2),
                                                            i_subtypes(idx)));
                -- prof1 + prof2 + schtype = permissao para prof - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NOT NULL
                  AND i_schtypes(idx) IS NOT NULL
                  AND i_schtypes(idx) (1) IS NOT NULL
                  AND i_schtypes(idx) (2) IS NOT NULL
                  AND i_subtypes(idx) IS NULL
                  AND i_events(idx) IS NULL
            THEN
                inner_appendtable(get_perm_from_schtype_prv(i_inst,
                                                            i_to_profs(idx),
                                                            i_on_profs(idx),
                                                            i_schtypes(idx) (1),
                                                            i_schtypes(idx) (2)));
                -- prof1 + prof2 = permissao para prof - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NOT NULL
                  AND (i_schtypes(idx) IS NULL OR i_schtypes(idx) (1) IS NULL OR i_schtypes(idx) (2) IS NULL)
                  AND i_subtypes(idx) IS NULL
                  AND i_events(idx) IS NULL
            THEN
                inner_appendtable(get_perm_from_zero_prv(i_inst, i_to_profs(idx), i_on_profs(idx)));
                -- prof1 + schtype = permissao para especialidade e prof - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NULL
                  AND i_schtypes(idx) IS NOT NULL
                  AND i_schtypes(idx) (1) IS NOT NULL
                  AND i_schtypes(idx) (2) IS NOT NULL
                  AND i_subtypes(idx) IS NULL
                  AND i_events(idx) IS NULL
            THEN
                inner_appendtable(get_perm_from_schtype_prv(i_inst,
                                                            i_to_profs(idx),
                                                            i_schtypes(idx) (1),
                                                            i_schtypes(idx) (2)));
                -- prof1 + subtype = permissao para especialidade e prof - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NULL
                  AND i_schtypes(idx) IS NOT NULL
                  AND i_schtypes(idx) (1) IS NOT NULL
                  AND i_schtypes(idx) (2) IS NOT NULL
                  AND i_subtypes(idx) IS NOT NULL
                  AND i_events(idx) IS NULL
            THEN
                inner_appendtable(get_perm_from_subtype_prv(i_inst,
                                                            i_to_profs(idx),
                                                            i_schtypes(idx) (1),
                                                            i_schtypes(idx) (2),
                                                            i_subtypes(idx)));
                -- prof1 + schtype + subtype + event = permissao para especialidade - ok
            ELSIF i_to_profs(idx) IS NOT NULL
                  AND i_on_profs(idx) IS NULL
                  AND i_schtypes(idx) IS NOT NULL
                  AND i_schtypes(idx) (1) IS NOT NULL
                  AND i_schtypes(idx) (2) IS NOT NULL
                  AND i_subtypes(idx) IS NOT NULL
                  AND i_events(idx) IS NOT NULL
            THEN
                inner_appendtable(get_perm_from_event_prv(i_inst,
                                                          i_to_profs(idx),
                                                          i_schtypes(idx) (1),
                                                          i_schtypes(idx) (2),
                                                          i_subtypes(idx),
                                                          i_events(idx)));
            END IF;
        
        END LOOP;
    
        -- ALERT-234544 redline limiter
        IF l_ret_table.count > nvl(l_max_rows, 2000)
        THEN
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => pk_message.get_message(i_lang, g_msg_max_rows),
                                              i_tokens       => table_varchar('@1'),
                                              i_replacements => table_varchar(l_max_rows),
                                              o_string       => o_msg_max_rows,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- limpar o que passa do limite
            l_ret_table.delete(l_max_rows + 1, l_ret_table.count);
        END IF;
    
        -- beautifier, limpa-repetidos e conversor para syscursor
        o_perms := get_nice_perms_prv(i_lang, l_ret_table);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_bad_arguments THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Array parameter is null or non-equal array lengths',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_perms);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_perms);
            RETURN FALSE;
    END get_permissions;

    /*
    * returns all possible permissions given to i_to_profs upon i_on_profs.
    * This is a cartesian product: i_to_profs x i_on_profs.
    * Used in Permissions to decompose selections of the kind 
    * i_to_prof - i_on_prof
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_inst         institution id
    * @param i_to_profs     professionals being configured
    * @param i_on_profs     professionals being granted access
    * @param o_perm         output
    * @param o_error        Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     09-05-2008
    */
    FUNCTION get_perms_from_zero
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_permission.id_institution%TYPE,
        i_to_profs IN table_number,
        i_on_profs IN table_number,
        o_perms    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_return    t_table_rec_sch_permission;
        l_func_name VARCHAR2(32) := 'GET_PERMS_FROM_ZERO';
    BEGIN
        --obter collection
        g_error  := 'get collection';
        l_return := get_perms_from_zero_prv(i_id_inst, i_to_profs, i_on_profs);
    
        -- convert to ref_syscursor
        o_perms := get_nice_perms_prv(i_lang, l_return);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_perms);
            RETURN FALSE;
        
    END get_perms_from_zero;

    /*
    * permissions master set function. It accepts multiple permissions, in which all columns are
    * separated in nested tables. So all this tables must have equal length, even if all or some of
    * its values are null.
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id, common to all permissions being set
    * @param i_to_profs       list of professional ids that are being given permissions
    * @param i_on_profs       list of professional ids whose agendas are being granted/revoked permission
    * @param i_on_subtypes    list of sub types
    * @param i_events         list of events 
    * @param i_perms          list of access level being set
    * @param o_error          Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     14-05-2008
    */
    FUNCTION set_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN sch_permission.id_institution%TYPE,
        i_to_profs    IN table_number,
        i_on_profs    IN table_number,
        i_on_subtypes IN table_number,
        i_events      IN table_number,
        i_perms       IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_bad_arguments EXCEPTION;
        l_func_name     VARCHAR2(32) := 'SET_PERMISSIONS';
        l_retval        BOOLEAN;
    
        FUNCTION inner_save
        (
            i_prof                  IN profissional,
            i_id_consult_permission IN sch_permission.id_consult_permission%TYPE,
            i_id_inst               IN sch_permission.id_institution%TYPE,
            i_id_prof               IN sch_permission.id_professional%TYPE,
            i_id_prof_agenda        IN sch_permission.id_prof_agenda%TYPE,
            i_id_dep_clin_serv      IN sch_permission.id_dep_clin_serv%TYPE,
            i_id_event              IN sch_permission.id_sch_event%TYPE,
            i_flg_permission        IN sch_permission.flg_permission%TYPE
        ) RETURN BOOLEAN IS
            l_trec t_rec_sch_permission;
        BEGIN
            g_error := 'set_permissions.inner_save';
            -- pegar registo 
            l_trec := t_rec_sch_permission(NULL,
                                           i_id_inst,
                                           i_id_prof,
                                           i_id_prof_agenda,
                                           i_id_dep_clin_serv,
                                           i_id_event,
                                           i_flg_permission);
            get_permission_prv(l_trec);
        
            -- se nao existe e o value e' A insere
            IF l_trec.id_consult_permission IS NULL
            THEN
                -- so insere se nao existe registo e a nova permissao nao e' none
                IF nvl(i_flg_permission, pk_schedule.g_permission_none) != pk_schedule.g_permission_none
                THEN
                    INSERT INTO sch_permission
                        (id_consult_permission,
                         id_institution,
                         id_professional,
                         id_prof_agenda,
                         id_dep_clin_serv,
                         id_sch_event,
                         flg_permission,
                         id_prof_created,
                         dt_created)
                    VALUES
                        (seq_sch_permission.nextval,
                         i_id_inst,
                         i_id_prof,
                         i_id_prof_agenda,
                         i_id_dep_clin_serv,
                         i_id_event,
                         i_flg_permission,
                         i_prof.id,
                         current_timestamp);
                END IF;
            ELSE
                -- se existe faz update
                UPDATE sch_permission
                   SET flg_permission  = nvl(i_flg_permission, pk_schedule.g_permission_none),
                       dt_updated      = current_timestamp,
                       id_prof_updated = i_prof.id
                 WHERE id_consult_permission = l_trec.id_consult_permission;
            END IF;
            RETURN TRUE;
        END inner_save;
    
    BEGIN
        -- validacoes
        g_error := 'CHECK COUNTS';
        IF i_to_profs IS NULL
           OR (i_on_profs IS NOT NULL AND i_to_profs.count != i_on_profs.count)
           OR (i_on_subtypes IS NOT NULL AND i_to_profs.count != i_on_subtypes.count)
           OR (i_events IS NOT NULL AND i_to_profs.count != i_events.count)
           OR (i_perms IS NOT NULL AND i_to_profs.count != i_perms.count)
        THEN
            RAISE e_bad_arguments;
        END IF;
    
        -- ciclo principal. O pivot e' a i_to_profs
        FOR idx IN 1 .. i_to_profs.count
        LOOP
            g_error  := 'NEW ITERATION';
            l_retval := inner_save(i_prof,
                                   NULL,
                                   i_inst,
                                   i_to_profs(idx),
                                   CASE
                                       WHEN i_on_profs IS NULL THEN
                                        NULL
                                       ELSE
                                        i_on_profs(idx)
                                   END,
                                   CASE
                                       WHEN i_on_subtypes IS NULL THEN
                                        NULL
                                       ELSE
                                        i_on_subtypes(idx)
                                   END,
                                   CASE
                                       WHEN i_events IS NULL THEN
                                        NULL
                                       ELSE
                                        i_events(idx)
                                   END,
                                   CASE
                                       WHEN i_perms IS NULL THEN
                                        NULL
                                       ELSE
                                        i_perms(idx)
                                   END);
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_bad_arguments THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => 'Attribute count does not match value count',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END set_permissions;

    /*
    * obter <profilename> para ser usado no get_details
    * foi necessario tornar publico para nao dar o PLS-00231.
    * To be used inside a SELECT statement.
    *
    * @param i_lang         language id
    * @param i_id_prof      id do profissional
    * @param i_id_inst      id instituticao
    * @param i_msg          mensagem a devolver quando i_id_prof e' nulo (caso das permissoes prof1-dcs)
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     20-05-2008
    */
    FUNCTION get_profile
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN sch_permission.id_prof_agenda%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        i_msg     IN sys_config.value%TYPE
    ) RETURN VARCHAR2 IS
        l_retval VARCHAR2(400);
    BEGIN
        IF i_id_prof IS NULL
        THEN
            RETURN nvl(i_msg, ' ');
        ELSE
            SELECT pk_message.get_message(i_lang, pt.code_profile_template)
              INTO l_retval
              FROM professional p
             INNER JOIN prof_profile_template ppt
                ON p.id_professional = ppt.id_professional
             INNER JOIN profile_template pt
                ON ppt.id_profile_template = pt.id_profile_template
             WHERE p.id_professional = i_id_prof
               AND ppt.id_institution = i_id_inst
               AND rownum = 1;
        
            RETURN l_retval;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN ' ';
    END get_profile;

    /*
    * 
    *
    * @param i_id_prof      id do profissional
    * @param i_id_inst      id instituticao
    * @param i_msg          mensagem a devolver quando i_id_prof e' nulo (caso das permissoes prof1-dcs)
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     20-05-2008
    */
    FUNCTION get_inline_events
    (
        i_lang           IN language.id_language%TYPE,
        i_id_inst        IN sch_permission.id_institution%TYPE,
        i_id_prof        IN sch_permission.id_professional%TYPE,
        i_id_prof_agenda IN sch_permission.id_prof_agenda%TYPE,
        i_id_dcs         IN sch_permission.id_dep_clin_serv%TYPE,
        i_flg_perm       IN sch_permission.flg_permission%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_id_prof_agenda IS NULL
        THEN
            RETURN pk_utils.query_to_string('SELECT pk_schedule_common.get_translation_alias(' || i_lang ||
                                            ', profissional(0,' || i_id_inst ||
                                            ',0), se.id_sch_event, se.code_sch_event)' ||
                                            ' FROM sch_event se INNER JOIN sch_permission sp ' ||
                                            ' ON se.id_sch_event = sp.id_sch_event ' || ' WHERE sp.id_institution = ' ||
                                            i_id_inst || ' AND sp.id_professional = ' || i_id_prof ||
                                            ' AND sp.id_prof_agenda IS NULL ' || ' AND sp.id_dep_clin_serv = ' ||
                                            i_id_dcs || 'AND sp.flg_permission = ''' || i_flg_perm || '''',
                                            ', ');
        ELSE
            RETURN pk_utils.query_to_string('SELECT pk_schedule_common.get_translation_alias(' || i_lang ||
                                            ', profissional(0,' || i_id_inst ||
                                            ',0), se.id_sch_event, se.code_sch_event)' ||
                                            ' FROM sch_event se INNER JOIN sch_permission sp ' ||
                                            ' ON se.id_sch_event = sp.id_sch_event ' || ' WHERE sp.id_institution = ' ||
                                            i_id_inst || ' AND sp.id_professional = ' || i_id_prof ||
                                            ' AND sp.id_prof_agenda = ' || i_id_prof_agenda ||
                                            ' AND sp.id_dep_clin_serv = ' || i_id_dcs || 'AND sp.flg_permission = ''' ||
                                            i_flg_perm || '''',
                                            ', ');
        END IF;
    
    END get_inline_events;

    /*
    * details of permissions assigned to professionals in i_to_profs. Used with the detail button
    * ATTENTION: order1 and order2 are important columns because the flash layer runs through
    * this rows sequentially and displays results as such. 
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id, common to all permissions being set
    * @param i_to_profs       list of professionals to fetch details
    * @param o_perm           output list
    * @param o_error          Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     16-05-2008
    *
    * UPDATED
    * faltava uma coluna com o perfil do to professional.
    * @author  Telmo castro
    * @date    17-06-2008
    * @version 2.4.3
    */
    FUNCTION get_details
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_to_profs IN table_number,
        o_perms    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := 'GET_DETAILS';
        l_msg_no_desig_prof sys_config.value%TYPE;
        l_msg_no_access     sys_config.value%TYPE;
    
    BEGIN
        -- get messages
        g_error             := 'get messages';
        l_msg_no_desig_prof := pk_message.get_message(i_lang, g_msg_no_desif_prof_det);
        IF l_msg_no_desig_prof IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_no_desif_prof_det ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            l_msg_no_desig_prof := ' ';
        END IF;
    
        l_msg_no_access := pk_message.get_message(i_lang, g_msg_no_access);
        IF l_msg_no_access IS NULL
        THEN
            pk_alertlog.log_warn(text        => pk_schedule.g_missing_translation || ' ' || g_msg_no_access ||
                                                ' : lang=' || i_lang,
                                 object_name => g_package_name,
                                 owner       => g_package_owner);
            l_msg_no_access := ' ';
        END IF;
    
        --open cursor
        g_error := 'open cursor';
    
        OPEN o_perms FOR
            SELECT nvl(id_professional, t3.column_value) id_professional,
                   id_prof_agenda,
                   id_dep_clin_serv,
                   flg_permission,
                   order2,
                   subtype_name,
                   events,
                   order1,
                   CASE
                        WHEN id_professional IS NULL THEN
                         (SELECT name
                            FROM professional
                           WHERE id_professional = t3.column_value)
                        ELSE
                         t2.to_name
                    END to_name,
                   CASE
                        WHEN id_professional IS NULL THEN
                         pk_schedule_bo.get_profile(i_lang, t3.column_value, i_inst, l_msg_no_desig_prof)
                        ELSE
                         t2.to_profile
                    END to_profile,
                   t2.on_name,
                   t2.on_profile
              FROM (SELECT DISTINCT t1.*,
                                    p.name to_name,
                                    pk_schedule_bo.get_profile(i_lang, t1.id_professional, i_inst, l_msg_no_desig_prof) to_profile,
                                    pk_translation.get_translation(i_lang, cs.code_clinical_service) || ':' subtype_name,
                                    CASE
                                         WHEN t1.id_prof_agenda IS NULL THEN
                                          l_msg_no_desig_prof
                                         ELSE
                                          p2.name
                                     END on_name,
                                    CASE
                                         WHEN t1.id_prof_agenda IS NULL THEN
                                          NULL
                                         ELSE
                                          ' (' || pk_schedule_bo.get_profile(i_lang,
                                                                             t1.id_prof_agenda,
                                                                             i_inst,
                                                                             l_msg_no_desig_prof) || ')'
                                     END on_profile,
                                    pk_schedule_bo.get_inline_events(i_lang,
                                                                     i_inst,
                                                                     t1.id_professional,
                                                                     t1.id_prof_agenda,
                                                                     t1.id_dep_clin_serv,
                                                                     t1.flg_permission) events,
                                    CASE t1.flg_permission
                                        WHEN pk_schedule.g_permission_schedule THEN
                                         1
                                        ELSE
                                         2
                                    END order1
                      FROM (SELECT sp.id_professional,
                                   sp.id_prof_agenda,
                                   sp.id_dep_clin_serv,
                                   sp.flg_permission,
                                   CASE
                                        WHEN sp.id_prof_agenda IS NULL THEN
                                         1
                                        ELSE
                                         2
                                    END order2
                              FROM sch_permission sp
                             WHERE sp.id_institution = i_inst
                               AND sp.id_professional IN (SELECT *
                                                            FROM TABLE(i_to_profs))
                               AND sp.flg_permission IN
                                   (pk_schedule.g_permission_schedule, pk_schedule.g_permission_read)) t1
                     INNER JOIN professional p
                        ON t1.id_professional = p.id_professional
                      LEFT JOIN professional p2
                        ON t1.id_prof_agenda = p2.id_professional
                     INNER JOIN dep_clin_serv dcs
                        ON t1.id_dep_clin_serv = dcs.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service) t2
             RIGHT JOIN (SELECT column_value
                           FROM TABLE(i_to_profs)) t3
                ON t2.id_professional = t3.column_value
             ORDER BY order1, order2, on_name, subtype_name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_details;

    /*
    * funcao auxiliar da get_month_vacancies. Serve para calcular as datas efectivas de inicio e fim da
    * vaga, isto e' considerando eventuais indisponibilidades.
    * Quando o resultado e' negativo significa que é um dia sem unavs. 'E necessario devolver essa info
    * na query final
    */
    FUNCTION calc_vac_dur
    (
        i_id_prof     IN professional.id_professional%TYPE,
        vac_dt_begin  IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        vac_dt_end    IN sch_consult_vacancy.dt_end_tstz%TYPE,
        unav_dt_begin IN sch_absence.dt_begin_tstz%TYPE,
        unav_dt_end   IN sch_absence.dt_end_tstz%TYPE
    ) RETURN NUMBER IS
    
    BEGIN
        g_error := 'CALC VACANCY DURATION';
        IF (vac_dt_begin BETWEEN unav_dt_begin AND unav_dt_end)
           AND vac_dt_end >= unav_dt_end
        THEN
            -- U1
            RETURN pk_date_utils.get_timestamp_diff(vac_dt_end, unav_dt_end);
        
        ELSIF (vac_dt_end BETWEEN unav_dt_begin AND unav_dt_end)
              AND vac_dt_begin < unav_dt_begin
        THEN
            -- U2
            RETURN pk_date_utils.get_timestamp_diff(unav_dt_begin, vac_dt_begin);
        
        ELSIF unav_dt_begin > vac_dt_end
        THEN
            -- U3
            RETURN pk_date_utils.get_timestamp_diff(vac_dt_end, vac_dt_begin);
        
        ELSIF (vac_dt_begin BETWEEN unav_dt_begin AND unav_dt_end)
              AND (vac_dt_end BETWEEN unav_dt_begin AND unav_dt_end)
        THEN
            -- U4
            RETURN 0;
        
        ELSIF unav_dt_begin > vac_dt_begin
              AND unav_dt_end < vac_dt_end
        THEN
            -- U5
            RETURN pk_date_utils.get_timestamp_diff(unav_dt_begin, vac_dt_begin) + pk_date_utils.get_timestamp_diff(unav_dt_end,
                                                                                                                    vac_dt_end);
        
        ELSIF unav_dt_end < vac_dt_begin
        THEN
            -- U6
            RETURN pk_date_utils.get_timestamp_diff(vac_dt_end, vac_dt_begin);
        
        ELSE
            RETURN 0;
        END IF;
    END calc_vac_dur;

    FUNCTION get_prof_depts
    (
        i_id_inst IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs  IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room IN sch_consult_vacancy.id_room%TYPE,
        i_dt_day1 IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_day     IN INTEGER
    ) RETURN VARCHAR2 IS
        res VARCHAR2(2000);
    BEGIN
        g_error := 'GET PROF DEPARTMENTS FOR SPECIFIC DAY';
    
        SELECT t.abbreviation
          INTO res
          FROM (SELECT DISTINCT d.abbreviation, se.id_sch_event
                  FROM sch_consult_vacancy scv
                  JOIN sch_event se
                    ON scv.id_sch_event = se.id_sch_event
                  JOIN dep_clin_serv dcs
                    ON scv.id_dep_clin_serv = dcs.id_dep_clin_serv
                  JOIN sch_department sd
                    ON se.dep_type = sd.flg_dep_type
                  JOIN department d
                    ON sd.id_department = d.id_department
                 WHERE scv.id_institution = i_id_inst
                   AND dcs.id_department = sd.id_department
                   AND scv.flg_status = g_status_active
                   AND (i_id_prof IS NULL OR scv.id_prof = i_id_prof)
                   AND (i_id_dcs IS NULL OR scv.id_dep_clin_serv = i_id_dcs)
                   AND (i_id_room IS NULL OR scv.id_room = i_id_room)
                   AND scv.dt_begin_tstz BETWEEN
                       CAST(to_char(i_dt_day1, 'YYYY') || to_char(i_dt_day1, 'MM') || lpad(to_char(i_day), 2, '0') ||
                            '000000' AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                       CAST(to_char(i_dt_day1, 'YYYY') || to_char(i_dt_day1, 'MM') || lpad(to_char(i_day), 2, '0') ||
                            '235959' AS TIMESTAMP WITH LOCAL TIME ZONE)
                   AND rownum > 0) t
         WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                  FROM dual) = pk_alert_constant.g_yes;
    
    END get_prof_depts;

    FUNCTION get_unav_dt_begin(i_dia PLS_INTEGER) RETURN sch_absence.dt_begin_tstz%TYPE IS
    BEGIN
        RETURN table_unavs(i_dia).dt_begin;
    END get_unav_dt_begin;

    FUNCTION get_unav_dt_end(i_dia PLS_INTEGER) RETURN sch_absence.dt_end_tstz%TYPE IS
    BEGIN
        RETURN table_unavs(i_dia).dt_end;
    END get_unav_dt_end;

    /** @headcom
    * Public Function. Get vacancy information
    *
    * @param      I_LANG                     Language identification
    * @param      i_sch_consult_vacancy      Vacancy identification
    * @param      o_data                     Data cursor 
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.5
    * @since      2008/07/28
    */

    FUNCTION get_vacancy_inf
    (
        i_lang                IN language.id_language%TYPE,
        i_sch_consult_vacancy IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_data                OUT sch_consult_vacancy%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        my_exception EXCEPTION;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_sch_consult_vacancy IS NOT NULL
        THEN
        
            g_error := 'O_DATA';
            BEGIN
                SELECT *
                  INTO o_data
                  FROM sch_consult_vacancy scv
                 WHERE scv.id_sch_consult_vacancy = i_sch_consult_vacancy;
            EXCEPTION
                WHEN no_data_found THEN
                
                    RETURN NULL;
            END;
        
            RETURN TRUE;
        ELSE
        
            g_error := 'i_lang/i_sch_consult_vacancy NULL';
        
            RAISE my_exception;
        END IF;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'GET_VACANCY_INF',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'GET_VACANCY_INF',
                                              o_error    => o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;

    /* INLINE FUNCTION. To be used in get_month_vacancies.
    * Tells if a given day has at least one unavailability.
    * 
    * i_day     day of month. 1..31
    * 
    * @return Y/N
    * @author Telmo
    * @date   31-08-2009
    * @version 2.5.0.5
    */
    FUNCTION has_unavs(i_day IN PLS_INTEGER) RETURN VARCHAR2 IS
    BEGIN
        IF table_unavs.exists(i_day)
        THEN
            RETURN g_yes;
        ELSE
            RETURN g_no;
        END IF;
    END has_unavs;

    /*
    * ALERT-12189. funcao para o calendario mensal de vagas e indisponibilidades 
    * de um prof, dcs ou room. O cursor tem um registo por cada dia do mes pedido.
    * Por cada dia tem as seguintes colunas: day number, dep names, flg_unav, total hours 
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id
    * @param i_id_prof        professional id. optional      
    * @param i_id_dcs         dep clin serv id. optional
    * @param i_id_room        room id. optional
    * @param i_dt_begin       first day of wanted month,  yyyymm01000000
    * @param o_date           header date string
    * @param o_data           output list
    * @param o_depnames       cursor with: day number | <depname1>,<depname2>,...
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_month_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_date     OUT VARCHAR2,
        o_data     OUT pk_types.cursor_type,
        o_depnames OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_MONTH_VACANCIES';
        l_dt_begin   TIMESTAMP WITH TIME ZONE;
        l_dt_end     TIMESTAMP WITH TIME ZONE;
        l_start_day  PLS_INTEGER;
        l_end_day    PLS_INTEGER;
        l_start_time VARCHAR2(10);
        l_end_time   VARCHAR2(10);
        i            PLS_INTEGER;
        l_alldays    table_number := table_number();
        l_month      VARCHAR2(2);
    
        CURSOR c_unavs IS
            SELECT dt_begin_tstz,
                   dt_end_tstz,
                   to_number(to_char(dt_begin_tstz, 'DD')) begin_day,
                   lpad(to_char(dt_begin_tstz, 'HH24'), 2, '0') begin_hour,
                   lpad(to_char(dt_begin_tstz, 'MI'), 2, '0') begin_minute,
                   lpad(to_char(dt_begin_tstz, 'SS'), 2, '0') begin_second,
                   to_number(to_char(dt_end_tstz, 'DD')) end_day,
                   lpad(to_char(dt_end_tstz, 'HH24'), 2, '0') end_hour,
                   lpad(to_char(dt_end_tstz, 'MI'), 2, '0') end_minute,
                   lpad(to_char(dt_end_tstz, 'SS'), 2, '0') end_second
              FROM sch_absence sa
             WHERE sa.id_institution = i_id_inst
               AND sa.id_professional = i_id_prof
               AND sa.flg_status = g_status_active
               AND ((sa.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end) OR
                   (sa.dt_end_tstz BETWEEN l_dt_begin AND l_dt_end));
    
        c_rec c_unavs%ROWTYPE;
    
    BEGIN
    
        pk_date_utils.set_dst_time_check_off;
    
        -- Get start date in tstz form
        g_error := 'GET START DATE';
        IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => i_dt_begin,
                                                   o_timestamp => l_dt_begin,
                                                   o_error     => o_error)
        THEN
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
    
        -- calc end date - add 1 month
        g_error := 'CALC END DATE';
        -- tive de complicar as coisas usando o last_day porque o INTERVAL 'x' MONTH e o add_to_tstz 
        --  nao funcionam para alguns meses
        SELECT pk_date_utils.add_to_ltstz(l_dt_begin, to_number(to_char(last_day(l_dt_begin), 'DD')))
          INTO l_dt_end
          FROM dual;
    
        -- fill l_alldays
        g_error := 'FILL L_ALLDAYS';
        FOR i IN 1 .. (to_number(to_char(l_dt_end - 1, 'DD')))
        LOOP
            l_alldays.extend;
            l_alldays(l_alldays.last) := i;
        END LOOP;
    
        -- clean table_unavs
        table_unavs.delete;
    
        -- fill table_unavs with all unavailabilities for this month
        g_error := 'FILL TABLE_UNAVS';
        IF i_id_prof IS NOT NULL
        THEN
            OPEN c_unavs;
            LOOP
                FETCH c_unavs
                    INTO c_rec;
                EXIT WHEN c_unavs%NOTFOUND;
            
                g_error := 'CALC UNAV BEGIN DAY';
                IF c_rec.dt_begin_tstz < l_dt_begin
                THEN
                    l_start_day  := 1;
                    l_start_time := '000000';
                ELSE
                    l_start_day  := c_rec.begin_day;
                    l_start_time := c_rec.begin_hour || c_rec.begin_minute || c_rec.begin_second;
                END IF;
            
                g_error := 'CALC UNAV END DAY';
                IF c_rec.dt_end_tstz > l_dt_end
                THEN
                    l_end_day  := to_number(to_char(l_dt_end, 'DD'));
                    l_end_time := '235959';
                ELSE
                    l_end_day  := c_rec.end_day;
                    l_end_time := c_rec.end_hour || c_rec.end_minute || c_rec.end_second;
                END IF;
            
                i := l_start_day;
                WHILE i <= l_end_day
                LOOP
                    g_error := 'SET DAY UNAV DT_BEGIN';
                    IF i = c_rec.begin_day
                    THEN
                    
                        SELECT to_timestamp(to_char(l_dt_begin, 'YYYY') || lpad(to_char(l_dt_begin, 'MM'), 2, '0') ||
                                            lpad(to_char(i), 2, '0') || l_start_time,
                                            'yyyymmddhh24miss')
                          INTO table_unavs(i).dt_begin
                          FROM dual;
                    ELSE
                        SELECT to_timestamp(to_char(l_dt_begin, 'YYYY') || lpad(to_char(l_dt_begin, 'MM'), 2, '0') ||
                                            lpad(to_char(i), 2, '0') || '000000',
                                            'yyyymmddhh24miss')
                          INTO table_unavs(i).dt_begin
                          FROM dual;
                    END IF;
                    g_error := 'SET DAY UNAV DT_END';
                    IF i = c_rec.end_day
                    THEN
                        SELECT to_timestamp(to_char(l_dt_begin, 'YYYY') || lpad(to_char(l_dt_begin, 'MM'), 2, '0') ||
                                            lpad(to_char(i), 2, '0') || l_end_time,
                                            'yyyymmddhh24miss')
                          INTO table_unavs(i).dt_end
                          FROM dual;
                    ELSE
                        SELECT to_timestamp(to_char(l_dt_begin, 'YYYY') || lpad(to_char(l_dt_begin, 'MM'), 2, '0') ||
                                            lpad(to_char(i), 2, '0') || '235959',
                                            'yyyymmddhh24miss')
                          INTO table_unavs(i).dt_end
                          FROM dual;
                    END IF;
                
                    i := i + 1;
                END LOOP;
            
            END LOOP;
            CLOSE c_unavs;
        END IF;
    
        --open cursor
        g_error := 'OPEN DATA CURSOR';
        OPEN o_data FOR
            SELECT pk_utils.to_str(round(nvl(abs(t1.duration), 0) * 24, 1)) ||
                   pk_message.get_message(i_lang, g_msg_hour_indicator) duration,
                   t2.column_value dia,
                   CASE
                        WHEN i_id_prof IS NULL THEN
                         g_no -- para especialidades e' sempre NO
                        ELSE
                         has_unavs(t2.column_value)
                    END has_unavs
              FROM (SELECT dia, SUM(duration) duration
                      FROM (SELECT dt_begin_tstz,
                                   dia,
                                   CASE
                                        WHEN i_id_prof IS NULL THEN
                                         -1 * pk_date_utils.get_timestamp_diff(dt_end_tstz, dt_begin_tstz)
                                        WHEN get_unav_dt_begin(dia) IS NULL THEN
                                         -1 * pk_date_utils.get_timestamp_diff(dt_end_tstz, dt_begin_tstz)
                                        ELSE
                                         calc_vac_dur(i_id_prof,
                                                      dt_begin_tstz,
                                                      nvl(dt_end_tstz,
                                                          pk_date_utils.add_to_ltstz(dt_begin_tstz, 30, 'MINUTE')),
                                                      get_unav_dt_begin(dia), -- tem de ser obtido por funcao porque as index-by nao gostam de ser usadas em queries
                                                      get_unav_dt_end(dia))
                                    END duration
                            
                              FROM (SELECT scv.dt_begin_tstz,
                                           scv.dt_end_tstz,
                                           to_number(to_char(scv.dt_begin_tstz, 'DD')) dia
                                      FROM sch_consult_vacancy scv
                                     WHERE scv.id_institution = i_id_inst
                                       AND scv.flg_status = g_status_active
                                       AND (i_id_prof IS NULL OR scv.id_prof = i_id_prof)
                                       AND (i_id_dcs IS NULL OR scv.id_dep_clin_serv = i_id_dcs)
                                       AND (i_id_room IS NULL OR scv.id_room = i_id_room)
                                       AND scv.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end)
                            
                            )
                     GROUP BY dia) t1
             RIGHT JOIN TABLE(l_alldays) t2
                ON t1.dia = t2.column_value;
    
        -- open cursor 2
        g_error := 'OPEN DEPNAMES CURSOR';
        OPEN o_depnames FOR
            SELECT dia, dia dia2, abbs
              FROM (SELECT dia, abbs, SUM(diavazio) over(PARTITION BY dia ORDER BY 1) somasum
                      FROM (SELECT dd.dia2 dia, dd.abbs, 2 diavazio
                              FROM (WITH data AS (SELECT to_number(to_char(scv.dt_begin_tstz, 'DD')) dia2,
                                                         d.abbreviation,
                                                         row_number() over(PARTITION BY to_number(to_char(scv.dt_begin_tstz, 'DD')) ORDER BY abbreviation) rn,
                                                         COUNT(*) over(PARTITION BY to_number(to_char(scv.dt_begin_tstz, 'DD'))) cnt
                                                    FROM sch_consult_vacancy scv
                                                    JOIN sch_event se
                                                      ON scv.id_sch_event = se.id_sch_event
                                                    JOIN sch_department sd
                                                      ON se.dep_type = sd.flg_dep_type
                                                    JOIN department d
                                                      ON sd.id_department = d.id_department
                                                    JOIN dep_clin_serv dcs
                                                      ON d.id_department = dcs.id_department
                                                     AND dcs.id_dep_clin_serv = scv.id_dep_clin_serv
                                                   WHERE scv.id_institution = i_id_inst
                                                     AND scv.id_prof = i_id_prof
                                                     AND d.id_institution = i_id_inst
                                                     AND scv.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
                                                     AND scv.flg_status = g_status_active
                                                   GROUP BY to_number(to_char(scv.dt_begin_tstz, 'DD')), d.abbreviation)
                                       SELECT dia2, ltrim(sys_connect_by_path(abbreviation, ','), ',') abbs
                                         FROM data
                                        WHERE rn = cnt
                                        START WITH rn = 1
                                       CONNECT BY PRIOR dia2 = dia2
                                              AND PRIOR rn = rn - 1
                                        ORDER BY dia2) dd
                                       UNION
                                       SELECT t2.column_value, NULL, 1
                                         FROM TABLE(l_alldays) t2
                            ))
             WHERE (abbs IS NOT NULL AND somasum = 3)
                OR somasum = 1
             ORDER BY dia;
    
        -- build nice date string
        g_error := 'BUILD HEADER';
        o_date  := pk_message.get_message(i_lang, 'SCH_MONTH_' || to_number(to_char(l_dt_begin, 'MM')));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_types.open_my_cursor(o_depnames);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_month_vacancies;

    /*
    * ALERT-12189. funcao para a grelha com as vagas e indisponibilidades para um dia,
    * para um profissional ou dcs ou room. O cursor devolve: hora inicio, hora fim, servico, dcs, 
    * prof name, room name, dcs name, sch type, event name, num. of schedules, event icon
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id
    * @param i_id_prof        professional id. optional      
    * @param i_id_dcs         dep clin serv id. optional
    * @param i_id_room        room id. optional
    * @param i_dt_begin       required day, yyyymmdd000000
    * @param o_date           header date string
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_day_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_date     OUT VARCHAR2,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DAY_VACANCIES';
        l_dt_begin  TIMESTAMP WITH TIME ZONE;
        l_dt_end    TIMESTAMP WITH TIME ZONE;
        l_hi        sys_message.desc_message%TYPE;
        l_year      NUMBER(4);
        l_month     NUMBER(2);
        l_day       NUMBER(2);
    BEGIN
    
        -- Get start date in tstz form
        g_error := 'GET START DATE';
        pk_date_utils.set_dst_time_check_off;
        IF NOT pk_date_utils.get_string_trunc_tstz(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_timestamp => i_dt_begin,
                                                   o_timestamp => l_dt_begin,
                                                   o_error     => o_error)
        THEN
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        -- calc end date - add 1 month
        g_error := 'CALC END DATE';
        SELECT l_dt_begin + INTERVAL '1' DAY
          INTO l_dt_end
          FROM dual;
    
        -- get hour indicator symbol'
        g_error := 'GET HOUR INDICATOR SYMBOL';
        l_hi    := pk_message.get_message(i_lang, g_msg_hour_indicator);
    
        --OPEN CURSOR
        g_error := 'OPEN CURSOR O_DATA';
        OPEN o_data FOR
        --vagas
            SELECT scv.id_sch_consult_vacancy id,
                   scv.used_vacancies,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) hour_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software) hour_end,
                   extract(hour FROM dt_end_tstz - dt_begin_tstz) || 'h ' ||
                   extract(minute FROM dt_end_tstz - dt_begin_tstz) || 'm ' desc_duration,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, scv.id_prof) nick_prof,
                   pk_schedule.string_service(i_lang, scv.id_dep_clin_serv) desc_service,
                   pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs,
                   pk_schedule.string_room(i_lang, scv.id_room) desc_room,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   pk_schedule.string_sch_type(i_lang, se.dep_type) desc_sch_type,
                   CASE scv.flg_status
                       WHEN g_status_active THEN
                        decode(flg_img,
                               ' ',
                               NULL,
                               pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img))
                       WHEN g_status_blocked THEN
                        decode(flg_img_blocked,
                               NULL,
                               NULL,
                               pk_sysdomain.get_img(i_lang, g_dom_flg_img_blocked, flg_img_blocked))
                   END img_event,
                   'V' tipo,
                   scv.dt_begin_tstz dtbegintstz,
                   NULL reason,
                   scv.flg_status
              FROM sch_consult_vacancy scv
              JOIN sch_event se
                ON scv.id_sch_event = se.id_sch_event
             WHERE scv.id_institution = i_id_inst
               AND (scv.flg_status IS NULL OR scv.flg_status IN (g_status_active, g_status_blocked))
               AND (i_id_prof IS NULL OR scv.id_prof = i_id_prof)
               AND (i_id_dcs IS NULL OR scv.id_dep_clin_serv = i_id_dcs)
               AND (i_id_room IS NULL OR scv.id_room = i_id_room)
               AND scv.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
            
            UNION ALL
            --unavs
            SELECT t.id_sch_absence id,
                   NULL,
                   pk_date_utils.date_char_hour_tsz(i_lang, hour_begin, i_prof.institution, i_prof.software) hour_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, hour_end, i_prof.institution, i_prof.software) hour_end,
                   extract(hour FROM hour_end - hour_begin) || 'h ' || extract(minute FROM hour_end - hour_begin) || 'm ' desc_duration,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) nick_prof,
                   pk_message.get_message(i_lang, g_msg_unavailability) desc_service,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   g_unav_icon img_event,
                   'U' tipo,
                   t.dt_begin_tstz dtbegintstz,
                   t.desc_absence,
                   NULL
              FROM (SELECT sa.id_sch_absence,
                           sa.dt_begin_tstz,
                           sa.dt_end_tstz,
                           sa.id_professional,
                           desc_absence,
                           CASE
                                WHEN sa.dt_begin_tstz < l_dt_begin THEN
                                 l_dt_begin
                                ELSE
                                 sa.dt_begin_tstz
                            END hour_begin,
                           CASE
                                WHEN sa.dt_end_tstz >= (l_dt_begin + INTERVAL '1' DAY) THEN
                                 (l_dt_begin + INTERVAL '1' DAY) - INTERVAL '1' SECOND
                                ELSE
                                 sa.dt_end_tstz
                            END hour_end
                      FROM sch_absence sa
                     WHERE i_id_prof IS NOT NULL
                       AND sa.id_professional = i_id_prof
                       AND sa.id_institution = i_id_inst
                       AND sa.flg_status = g_status_active
                       AND (l_dt_begin = pk_date_utils.trunc_insttimezone(i_prof, sa.dt_begin_tstz) OR
                           l_dt_begin >= sa.dt_begin_tstz AND l_dt_begin < sa.dt_end_tstz)) t
             ORDER BY dtbegintstz;
    
        --BUILD HEADER DATE
        g_error := 'BUILD HEADER DATE';
        l_year  := pk_date_utils.date_year_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software);
        l_month := pk_date_utils.date_month_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software);
        l_day   := pk_date_utils.date_day_tsz(i_lang, l_dt_begin, i_prof.institution, i_prof.software);
        o_date  := pk_message.get_message(i_lang, 'SCH_MONTH_' || l_month) || ' ' || l_day || ', ' || l_year;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_day_vacancies;

    /*
    * ALERT-12189. retrieve vacancy data
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_vac         vacancy id. If null only retrieves flg_status with status Normal
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    *
    * UPDATED alert-8202. table sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION get_vacancy_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_VACANCY_DATA';
    BEGIN
    
        -- open cursor
        OPEN o_data FOR
            SELECT scv.id_sch_consult_vacancy id,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) hour_begin,
                   CASE
                        WHEN dt_end_tstz IS NOT NULL THEN
                         pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software)
                        ELSE
                         NULL
                    END hour_end,
                   pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, dt_end_tstz, i_prof) dt_end,
                   pk_schedule.string_duration(i_lang, dt_begin_tstz, dt_end_tstz) desc_duration,
                   dcs.id_department,
                   pk_schedule.string_department(i_lang, dcs.id_department) desc_service,
                   dcs.id_dep_clin_serv,
                   pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs,
                   scv.id_room,
                   pk_schedule.string_room(i_lang, scv.id_room) desc_room,
                   scv.id_sch_event,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                   se.dep_type sch_type,
                   pk_schedule.string_sch_type(i_lang, se.dep_type) desc_sch_type,
                   scv.flg_status,
                   pk_sysdomain.get_domain(g_dom_flg_status, scv.flg_status, i_lang) desc_status,
                   scv.max_vacancies,
                   scv.used_vacancies,
                   scvo.flg_urgency,
                   scvm.id_physiatry_area
              FROM sch_consult_vacancy scv
              JOIN sch_event se
                ON scv.id_sch_event = se.id_sch_event
              JOIN dep_clin_serv dcs
                ON scv.id_dep_clin_serv = dcs.id_dep_clin_serv
              LEFT JOIN sch_consult_vac_oris scvo
                ON scv.id_sch_consult_vacancy = scvo.id_sch_consult_vacancy
              LEFT JOIN sch_consult_vac_mfr scvm
                ON scv.id_sch_consult_vacancy = scvm.id_sch_consult_vacancy
             WHERE i_id_vac IS NOT NULL
               AND scv.id_sch_consult_vacancy = i_id_vac
            UNION
            -- quando nao se trata de edicao apenas devolve o status
            SELECT NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   g_status_active,
                   pk_sysdomain.get_domain(g_dom_flg_status, g_status_active, i_lang),
                   1,
                   NULL,
                   NULL,
                   NULL
              FROM dual
             WHERE i_id_vac IS NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vacancy_data;

    /*
    * ALERT-12189. list of possible services for a given professional, dcs or room.
    * see function get_sch_types
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        institution id
    * @param i_id_prof        prof id (opt)
    * @param i_id_dcs         dcs id (opt)
    * @param i_id_room        room id (opt)
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_services
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_sch_type IN sch_dep_type.dep_type%TYPE DEFAULT NULL,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SERVICES';
    BEGIN
        IF i_id_prof IS NOT NULL
        THEN
            -- services for professional
            g_error := 'FETCH SERVICES FOR PROFESSIONAL';
            OPEN o_data FOR
                SELECT DISTINCT d.id_department,
                                pk_translation.get_translation(i_lang, d.code_department) desc_department
                  FROM department d
                  JOIN sch_department sd
                    ON d.id_department = sd.id_department
                  JOIN dep_clin_serv dcs
                    ON sd.id_department = dcs.id_department
                  JOIN prof_dep_clin_serv pdcs
                    ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                  JOIN sch_dep_type sdt
                    ON sd.flg_dep_type = sdt.dep_type
                 WHERE pdcs.id_institution = i_id_inst
                   AND d.flg_available = g_yes
                   AND dcs.flg_available = g_yes
                   AND pdcs.id_professional = i_id_prof
                   AND pdcs.flg_status = pk_backoffice.g_status_pdcs_s
                   AND (i_sch_type IS NULL OR sdt.dep_type = i_sch_type)
                -- o sch type C e' equiparado a N (consultas enfermagem) e U (nutricao)
                UNION
                SELECT d.id_department, pk_translation.get_translation(i_lang, d.code_department) desc_department
                  FROM department d
                  JOIN sch_department sd
                    ON d.id_department = sd.id_department
                  JOIN sch_dep_type sdt
                    ON sd.flg_dep_type = sdt.dep_type
                  JOIN dep_clin_serv dcs
                    ON sd.id_department = dcs.id_department
                  JOIN prof_dep_clin_serv pdcs
                    ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                 WHERE pdcs.id_institution = i_id_inst
                   AND d.flg_available = g_yes
                   AND dcs.flg_available = g_yes
                   AND pdcs.id_professional = i_id_prof
                   AND pdcs.flg_status = pk_backoffice.g_status_pdcs_s
                   AND i_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
                   AND sdt.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons;
        
        ELSIF i_id_dcs IS NOT NULL
        THEN
            -- services for dcs
            g_error := 'FETCH SERVICES FOR DCS';
            OPEN o_data FOR
                SELECT DISTINCT d.id_department,
                                pk_translation.get_translation(i_lang, d.code_department) desc_department
                  FROM department d
                  JOIN sch_department sd
                    ON d.id_department = sd.id_department
                  JOIN sch_dep_type sdt
                    ON sd.flg_dep_type = sdt.dep_type
                  JOIN dep_clin_serv dcs
                    ON sd.id_department = dcs.id_department
                 WHERE d.id_institution = i_id_inst
                   AND d.flg_available = g_yes
                   AND dcs.flg_available = g_yes
                   AND dcs.id_dep_clin_serv = i_id_dcs
                   AND (i_sch_type IS NULL OR sdt.dep_type = i_sch_type);
        
        ELSIF i_id_room IS NOT NULL
        THEN
            -- services for room
            g_error := 'FETCH SERVICES FOR ROOM';
            OPEN o_data FOR
                SELECT DISTINCT d.id_department,
                                pk_translation.get_translation(i_lang, d.code_department) desc_department
                  FROM department d
                  JOIN sch_department sd
                    ON d.id_department = sd.id_department
                  JOIN sch_dep_type sdt
                    ON sd.flg_dep_type = sdt.dep_type
                  JOIN room r
                    ON sd.id_department = r.id_department
                 WHERE d.id_institution = i_id_inst
                   AND d.flg_available = g_yes
                   AND r.id_room = i_id_room
                   AND r.flg_available = g_yes
                   AND (i_sch_type IS NULL OR sdt.dep_type = i_sch_type);
        
        ELSE
            pk_types.open_my_cursor(o_data);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_services;

    /*
    * ALERT-12189. list of possible services for a given professional, dcs or room.
    * see function get_sch_types
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        institution id
    * @param i_id_prof        prof id (opt)
    * @param i_id_dcs         dcs id (opt)
    * @param i_id_room        room id (opt)
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @data     24-07-2009
    */
    FUNCTION get_bo_sch_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_dep   IN sch_consult_vacancy.id_prof%TYPE,
        i_sch_type IN sch_dep_type.dep_type%TYPE DEFAULT NULL,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_SCH_TYPES';
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT DISTINCT sd.flg_dep_type sch_type,
                            pk_translation.get_translation(i_lang, sdt.code_dep_type) desc_sch_type
              FROM sch_department sd
              JOIN department d
                ON sd.id_department = d.id_department
              JOIN sch_dep_type sdt
                ON sdt.dep_type = sd.flg_dep_type
             WHERE d.flg_available = g_yes
               AND d.id_institution = i_id_inst
               AND d.id_department = i_id_dep
               AND (i_sch_type IS NULL OR sdt.dep_type = i_sch_type)
            UNION
            SELECT sd.flg_dep_type, pk_translation.get_translation(i_lang, sdt.code_dep_type)
              FROM sch_department sd
              JOIN department d
                ON sd.id_department = d.id_department
              JOIN sch_dep_type sdt
                ON sdt.dep_type = sd.flg_dep_type
             WHERE d.flg_available = g_yes
               AND d.id_institution = i_id_inst
               AND d.id_department = i_id_dep
               AND i_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
               AND sdt.dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_bo_sch_types;
    /*
    * ALERT-12189. list of possible dcs for a given service and sch type
    * see function get_sch_types. cursor gives id_dcs and dcs_name
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        institution id
    * @param i_id_dep         service id (or department id)
    * @param i_sch_type       sch type
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_dep_clin_serv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_id_dep   IN sch_department.id_department%TYPE,
        i_sch_type IN sch_department.flg_dep_type%TYPE,
        i_id_event IN sch_event.id_sch_event%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_DEP_CLIN_SERV';
    BEGIN
    
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT t.id_dep_clin_serv, pk_translation.get_translation(i_lang, t.code_clinical_service) desc_dcs
              FROM (SELECT DISTINCT se.id_sch_event, dcs.id_dep_clin_serv, cs.code_clinical_service
                      FROM department d
                      JOIN sch_department sd
                        ON d.id_department = sd.id_department
                      JOIN sch_dep_type sdt
                        ON sd.flg_dep_type = sdt.dep_type
                      JOIN dep_clin_serv dcs
                        ON sd.id_department = dcs.id_department
                      JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                      JOIN sch_event_dcs sed
                        ON pdcs.id_dep_clin_serv = sed.id_dep_clin_serv
                      JOIN sch_event se
                        ON sed.id_sch_event = se.id_sch_event
                      JOIN clinical_service cs
                        ON dcs.id_clinical_service = cs.id_clinical_service
                     WHERE d.id_institution = i_id_inst
                       AND d.id_department = i_id_dep
                       AND sdt.dep_type = i_sch_type
                       AND se.dep_type = i_sch_type
                       AND d.flg_available = g_yes
                       AND dcs.flg_available = g_yes
                       AND pdcs.id_professional = i_id_prof
                       AND pdcs.flg_status = pk_backoffice.g_status_pdcs_s
                       AND se.id_sch_event = i_id_event
                       AND se.flg_available = g_yes
                       AND sed.flg_available = g_yes
                       AND rownum > 0) t
             WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                      FROM dual) = pk_alert_constant.g_yes
             ORDER BY desc_dcs;
    
        -- nao preciso de query para as vagas de especialidade porque o id_dcs ja e' conhecido de tras, e' unico e read-only
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dep_clin_serv;

    /*
    * ALERT-12189. list of possible events for a given service and sch type and dcs.
    * see function get_sch_subtype_events. cursor gives id_dcs and dcs_name
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        institution id
    * @param i_id_dep         service id (or department id)
    * @param i_sch_type       sch type
    * @param i_id_dcs         dcs id choosen in previous multichoice
    * @param o_data           output list
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_events
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_dep   IN sch_department.id_department%TYPE,
        i_sch_type IN sch_department.flg_dep_type%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_EVENTS';
    BEGIN
        g_error := 'OPEN CURSOR';
    
        IF i_id_prof IS NOT NULL
        THEN
            OPEN o_data FOR
                SELECT t.id_sch_event,
                       pk_schedule_common.get_translation_alias(i_lang, i_prof, t.id_sch_event, t.code_sch_event) desc_event
                  FROM (SELECT DISTINCT se.id_sch_event, se.code_sch_event
                          FROM department d
                          JOIN sch_department sd
                            ON d.id_department = sd.id_department
                          JOIN sch_dep_type sdt
                            ON sd.flg_dep_type = sdt.dep_type
                          JOIN dep_clin_serv dcs
                            ON sd.id_department = dcs.id_department
                          JOIN prof_dep_clin_serv pdcs
                            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                          JOIN sch_event_dcs sed
                            ON pdcs.id_dep_clin_serv = sed.id_dep_clin_serv
                          JOIN sch_event se
                            ON sed.id_sch_event = se.id_sch_event
                         WHERE d.id_institution = i_id_inst
                           AND d.id_department = i_id_dep
                           AND sdt.dep_type = i_sch_type
                           AND se.dep_type = i_sch_type
                           AND d.flg_available = g_yes
                           AND dcs.flg_available = g_yes
                           AND sed.flg_available = g_yes
                           AND pdcs.id_professional = i_id_prof
                           AND pdcs.flg_status = pk_backoffice.g_status_pdcs_s
                           AND se.flg_available = g_yes
                           AND se.flg_target_professional = g_yes
                           AND se.id_sch_event != pk_schedule.g_event_single
                           AND se.dep_type != pk_schedule_common.g_sch_dept_flg_dep_type_cm
                           AND rownum > 0) t
                 WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                          FROM dual) = pk_alert_constant.g_yes;
        
        ELSIF i_id_dcs IS NOT NULL
        THEN
            OPEN o_data FOR
                SELECT t.id_sch_event,
                       pk_schedule_common.get_translation_alias(i_lang, i_prof, t.id_sch_event, t.code_sch_event) desc_event
                  FROM (SELECT DISTINCT se.id_sch_event, se.code_sch_event
                          FROM department d
                          JOIN sch_department sd
                            ON d.id_department = sd.id_department
                          JOIN sch_dep_type sdt
                            ON sd.flg_dep_type = sdt.dep_type
                          JOIN dep_clin_serv dcs
                            ON sd.id_department = dcs.id_department
                          JOIN sch_event_dcs sed
                            ON dcs.id_dep_clin_serv = sed.id_dep_clin_serv
                          JOIN sch_event se
                            ON sed.id_sch_event = se.id_sch_event
                         WHERE d.id_institution = i_id_inst
                           AND d.id_department = i_id_dep
                           AND sdt.dep_type = i_sch_type
                           AND se.dep_type = i_sch_type
                           AND d.flg_available = g_yes
                           AND dcs.flg_available = g_yes
                           AND se.flg_available = g_yes
                           AND sed.flg_available = g_yes
                           AND se.flg_target_professional = g_no
                           AND se.flg_target_dep_clin_serv = g_yes
                           AND se.id_sch_event != pk_schedule.g_event_single
                           AND se.dep_type != pk_schedule_common.g_sch_dept_flg_dep_type_cm
                           AND sed.id_dep_clin_serv = i_id_dcs
                           AND rownum > 0) t
                 WHERE (SELECT pk_schedule_common.get_sch_event_avail(t.id_sch_event, i_id_inst, 0)
                          FROM dual) = pk_alert_constant.g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_events;

    /*
    * ALERT-12189. saves a new/edited vacancy. For an edit to happen the 
    * i_id_vac must be supplied.
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_vac         vacancy id used when editing
    * @param i_id_inst        vacancy institution id
    * @param i_id_prof        vacancy destination professional
    * @param i_maxvacs        number of slots
    * @param i_id_dcs         dcs id choosen in previous multichoice
    * @param i_id_event       vacancy destination event
    * @param i_id_room        vacancy destination room
    * @param i_dtbegin        vacancy begin date
    * @param i_dtend          vacancy end date
    * @param i_id_exam        vacancy exam id in case this is a exam vacancy
    * @param i_flg_urg        urgency vacancy (Y/N) for oris vacancies
    * @param i_flg_status     vacancy status level (normal = active = A)
    * @param i_id_phys_area   physiatry area for mfr vacancies
    * @param o_flg_show       validation error popup order to show the popup
    * @param o_msg            validation error popup message
    * @param o_msg_title      validation error popup header title
    * @param o_button         validation error popup window buttons
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    *
    * UPDATED alert-8202. table sch_consult_vac_exam demise. Parametro i_id_exam obsoleto
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION set_vacancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vac       IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_inst      IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof      IN sch_consult_vacancy.id_prof%TYPE,
        i_maxvacs      IN sch_consult_vacancy.max_vacancies%TYPE,
        i_id_dcs       IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_event     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_room      IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin     IN VARCHAR2,
        i_dt_end       IN VARCHAR2,
        i_id_exam      IN schedule_exam.id_exam%TYPE DEFAULT NULL,
        i_flg_urg      IN sch_consult_vac_oris.flg_urgency%TYPE DEFAULT NULL,
        i_flg_status   IN sch_consult_vacancy.flg_status%TYPE DEFAULT 'A',
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        o_id_vac       OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_flg_show2    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'SET_VACANCY';
        l_dt_begin     TIMESTAMP WITH TIME ZONE;
        l_dt_end       TIMESTAMP WITH TIME ZONE;
        l_message      VARCHAR2(2000);
        l_vacancy      sch_consult_vacancy%ROWTYPE;
        l_vac_colision EXCEPTION;
        l_used_vac     EXCEPTION;
        l_vacs         table_number := table_number();
        l_hi           sys_message.desc_message%TYPE;
        l_sessaovaga   VARCHAR2(200);
        l_t566         sys_message.desc_message%TYPE;
        l_status       sch_consult_vacancy.flg_status%TYPE;
    
        CURSOR c_vacs IS
            SELECT dt_begin_tstz,
                   dt_end_tstz,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) hour_begin,
                   --                   lpad(to_char(dt_begin_tstz, 'HH24'), 2, '0') || ':' || lpad(to_char(dt_begin_tstz, 'MI'), 2, '0') || l_hi hour_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software) hour_end,
                   --                   lpad(to_char(dt_end_tstz, 'HH24'), 2, '0') || ':' || lpad(to_char(dt_end_tstz, 'MI'), 2, '0') || l_hi hour_end,
                   pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy IN (SELECT *
                                                    FROM TABLE(l_vacs))
             ORDER BY dt_begin_tstz;
        l_rec c_vacs%ROWTYPE;
    
        -- decide between vacancy and session naming        
        FUNCTION inner_vacancy_session RETURN VARCHAR2 IS
        BEGIN
            IF i_id_event IN (g_surg_sch_event, pk_schedule.g_event_mfr, g_inp_sch_event)
            THEN
                g_error := 'DECIDE BETWEEN SESSION OR VACANCY';
                IF l_vacs.count = 1
                THEN
                    RETURN pk_message.get_message(i_lang, g_msg_sessao);
                ELSE
                    RETURN pk_message.get_message(i_lang, g_msg_sessoes);
                END IF;
            ELSE
                IF l_vacs.count = 1
                THEN
                    RETURN pk_message.get_message(i_lang, g_msg_vaga);
                ELSE
                    RETURN pk_message.get_message(i_lang, g_msg_vagas);
                END IF;
            END IF;
        END inner_vacancy_session;
    
    BEGIN
        o_flg_show2 := g_no;
    
        -- Get begin date in tstz form        
        g_error := 'GET BEGIN DATE';
        pk_date_utils.set_dst_time_check_off;
    
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => profissional(i_id_prof, i_id_inst, i_prof.software),
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get end date in tstz form
        g_error := 'GET END DATE';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => profissional(i_id_prof, i_id_inst, i_prof.software),
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
    
        -- regra: verificar colisao com outras vagas. Insert/edit. So para vagas com profissional
        IF i_id_prof IS NOT NULL
        THEN
            BEGIN
                g_error := 'COUNT VACANCY COLLISIONS';
                SELECT scv.id_sch_consult_vacancy
                  BULK COLLECT
                  INTO l_vacs
                  FROM sch_consult_vacancy scv
                 WHERE scv.id_institution = i_id_inst
                   AND scv.id_prof = i_id_prof
                   AND scv.flg_status = g_status_active
                   AND (i_id_vac IS NULL OR scv.id_sch_consult_vacancy != i_id_vac)
                   AND ((scv.dt_begin_tstz >= l_dt_begin AND scv.dt_begin_tstz < l_dt_end) OR
                       (scv.dt_end_tstz IS NOT NULL AND scv.dt_end_tstz > l_dt_begin AND scv.dt_end_tstz <= l_dt_end));
            
                IF l_vacs.count > 0
                THEN
                    -- get hour indicator symbol'
                    g_error := 'GET HOUR INDICATOR SYMBOL';
                    l_hi    := pk_message.get_message(i_lang, g_msg_hour_indicator);
                
                    g_error := 'BUILD COLLISIONS ERROR MESSAGE';
                    IF NOT pk_schedule.get_validation_msgs(i_lang         => i_lang,
                                                           i_code_msg     => g_msg_vac_overlap_2,
                                                           i_pkg_name     => g_package_name,
                                                           i_replacements => table_varchar(l_vacs.count),
                                                           o_message      => l_t566,
                                                           o_error        => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    g_error := 'VAC OVERLAP 1';
                    IF l_vacs.count = 1
                    THEN
                        -- singular
                        o_msg := pk_message.get_message(i_lang, g_msg_vac_overlap_1) || ' ' ||
                                 pk_message.get_message(i_lang, g_msg_desta) || ' ' || inner_vacancy_session || ' ' ||
                                 l_t566;
                    ELSE
                        --plural
                        o_msg := pk_message.get_message(i_lang, g_msg_vac_overlap_1) || ' ' ||
                                 pk_message.get_message(i_lang, g_msg_destas) || ' ' || inner_vacancy_session || ' ' ||
                                 l_t566;
                    END IF;
                
                    g_error := 'VAC OVERLAP 2';
                    OPEN c_vacs;
                    LOOP
                        FETCH c_vacs
                            INTO l_rec;
                        EXIT WHEN c_vacs%NOTFOUND;
                    
                        o_msg := o_msg || '@' || l_rec.hour_begin || ' - ' || l_rec.hour_end || '; ' || l_rec.desc_dcs || '.';
                    END LOOP;
                    CLOSE c_vacs;
                
                    g_error := 'VAC OVERLAP 3';
                    o_msg   := o_msg || '@@' || pk_message.get_message(i_lang, g_msg_vac_overlap_3);
                
                    RAISE l_vac_colision;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        END IF;
    
        -- calcular status. Se a vaga coincidir ccom uma unav fica com estado blocked
        IF i_id_prof IS NOT NULL
        THEN
            BEGIN
                SELECT g_status_blocked
                  INTO l_status
                  FROM sch_absence sa
                 WHERE sa.id_professional = i_id_prof
                   AND sa.flg_status = g_status_active
                   AND sa.id_institution = i_id_inst
                   AND ((l_dt_begin >= sa.dt_begin_tstz AND l_dt_begin < sa.dt_end_tstz) OR
                       (l_dt_end > sa.dt_begin_tstz AND l_dt_end <= sa.dt_end_tstz) OR
                       (sa.dt_begin_tstz > l_dt_begin AND dt_begin_tstz < l_dt_end));
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT decode(i_flg_status, g_status_blocked, g_status_blocked, g_status_active)
                      INTO l_status
                      FROM dual;
            END;
        END IF;
    
        -- update
        IF i_id_vac IS NOT NULL
        THEN
            g_error := 'GET VACANCY DATA';
            IF NOT get_vacancy_inf(i_lang                => i_lang,
                                   i_sch_consult_vacancy => i_id_vac,
                                   o_data                => l_vacancy,
                                   o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- regra: validar se ja tem agendamentos
            IF l_vacancy.used_vacancies > 0
            THEN
                g_error := 'BUILD USED VACANCY ERROR MESSAGE';
                o_msg   := pk_message.get_message(i_lang, g_msg_esta) || ' ' || inner_vacancy_session || ' ' ||
                           pk_message.get_message(i_lang, g_msg_tem) || ' ' || to_char(l_vacancy.used_vacancies) ||
                           CASE l_vacancy.used_vacancies
                               WHEN 1 THEN
                                pk_message.get_message(i_lang, g_msg_marcacao)
                               ELSE
                                pk_message.get_message(i_lang, g_msg_marcacoes)
                           END || '@' || pk_message.get_message(i_lang, g_msg_used_vac_2) || '@@' ||
                           pk_message.get_message(i_lang, g_msg_editar_canc) || ' ' ||
                           pk_message.get_message(i_lang, g_msg_esta) || ' ' || inner_vacancy_session ||
                           pk_message.get_message(i_lang, g_msg_cancele) || ' ' ||
                           CASE l_vacancy.used_vacancies
                               WHEN 1 THEN
                                pk_message.get_message(i_lang, g_msg_a) || ' ' ||
                                pk_message.get_message(i_lang, g_msg_marcacao)
                               ELSE
                                pk_message.get_message(i_lang, g_msg_as) ||
                                pk_message.get_message(i_lang, g_msg_marcacoes)
                           END || '.';
            
                RAISE l_used_vac;
            END IF;
        
            -- update sch_consult_vacancy
            g_error := 'UPDATE SCH_CONSULT_VACANCY';
            UPDATE sch_consult_vacancy scv
               SET scv.id_prof          = nvl(i_id_prof, scv.id_prof),
                   scv.max_vacancies    = nvl(i_maxvacs, scv.max_vacancies),
                   scv.id_dep_clin_serv = nvl(i_id_dcs, scv.id_dep_clin_serv),
                   scv.id_room          = nvl(i_id_room, scv.id_room),
                   scv.id_sch_event     = nvl(i_id_event, scv.id_sch_event),
                   scv.dt_begin_tstz    = l_dt_begin,
                   scv.dt_end_tstz      = l_dt_end,
                   scv.flg_status       = nvl(l_status, nvl(i_flg_status, scv.flg_status))
             WHERE scv.id_sch_consult_vacancy = i_id_vac;
        
            IF i_flg_urg IS NOT NULL
            THEN
                g_error := 'UPDATE SCH_CONSULT_VAC_ORIS';
                UPDATE sch_consult_vac_oris o
                   SET o.flg_urgency = i_flg_urg
                 WHERE o.id_sch_consult_vacancy = i_id_vac;
            END IF;
        
            IF i_id_phys_area IS NOT NULL
            THEN
                g_error := 'UPDATE SCH_CONSULT_VAC_MFR';
                UPDATE sch_consult_vac_mfr m
                   SET m.id_physiatry_area = i_id_phys_area
                 WHERE m.id_sch_consult_vacancy = i_id_vac;
            END IF;
        ELSE
            -- insert
            g_error := 'INSERT INTO SCH_CONSULT_VACANCY';
            INSERT INTO sch_consult_vacancy
                (id_sch_consult_vacancy,
                 id_institution,
                 id_prof,
                 max_vacancies,
                 used_vacancies,
                 id_dep_clin_serv,
                 id_room,
                 id_sch_event,
                 dt_begin_tstz,
                 dt_end_tstz,
                 flg_status)
            VALUES
                (seq_sch_consult_vacancy.nextval,
                 i_id_inst,
                 i_id_prof,
                 i_maxvacs,
                 0,
                 i_id_dcs,
                 i_id_room,
                 i_id_event,
                 l_dt_begin,
                 l_dt_end,
                 nvl(l_status, nvl(i_flg_status, g_status_active)))
            RETURNING id_sch_consult_vacancy INTO o_id_vac;
        
            IF i_flg_urg IS NOT NULL
            THEN
                g_error := 'INSERT INTO SCH_CONSULT_VAC_ORIS';
                INSERT INTO sch_consult_vac_oris
                    (id_sch_consult_vacancy, flg_urgency)
                VALUES
                    (o_id_vac, i_flg_urg);
            END IF;
        
            IF i_id_phys_area IS NOT NULL
            THEN
                g_error := 'INSERT INTO SCH_CONSULT_VAC_MFR';
                INSERT INTO sch_consult_vac_mfr
                    (id_sch_consult_vacancy, id_physiatry_area)
                VALUES
                    (o_id_vac, i_id_phys_area);
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_vac_colision THEN
            o_msg_title := pk_message.get_message(i_lang, g_msg_popupheadertitle);
            -- o_msg foi ja construida acima
            o_button    := pk_schedule.g_check_button;
            o_flg_show2 := g_yes;
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN l_used_vac THEN
            o_msg_title := pk_message.get_message(i_lang, g_msg_popupheadertitle);
            o_button    := pk_schedule.g_check_button;
            o_flg_show2 := g_yes;
            -- resto da o_msg 
            o_msg := o_msg || '@' || pk_message.get_message(i_lang, g_msg_used_vac_2) || '@@' ||
                     pk_message.get_message(i_lang, g_msg_used_vac_3);
            pk_utils.undo_changes;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_vacancy;

    /*
    * ALERT-12189. saves a series of vacancies, defined by the recurrence parameters
    * i_id_rep_pat, i_weekdays, i_rep_every, i_startdate, i_enddate.
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        vacancy institution id
    * @param i_id_prof        vacancy destination professional
    * @param i_maxvacs        number of max schedules allowed in each vacancy
    * @param i_id_dcs         dcs id choosen in previous multichoice
    * @param i_id_event       vacancy destination event
    * @param i_id_room        vacancy destination room
    * @param i_dtbegin        vacancy begin date
    * @param i_dtend          vacancy end date
    * @param i_id_exam        (optional) vacancy exam id in case this is a exam vacancy
    * @param i_flg_urg        (optional) urgency vacancy (Y/N) for oris vacancies
    * @param i_flg_status     (optional) vacancy status level (normal = active = A)
    
    * @param i_weekdays       list of week days numbers
    * @param i_rep_every      repeat every X *rep. pattern* 
    * @param i_startdate      repetition begin date
    * @param i_enddate        repetition end date
    * @param o_flg_show       validation error popup order to show the popup
    * @param o_msg            validation error popup message
    * @param o_msg_title      validation error popup header title
    * @param o_button         validation error popup window buttons
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    *
    * UPDATED alert-8202. table sch_consult_vac_exam demise. Parametro i_id_exam obsoleto
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */
    FUNCTION set_vacancies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst      IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof      IN sch_consult_vacancy.id_prof%TYPE,
        i_maxvacs      IN sch_consult_vacancy.max_vacancies%TYPE,
        i_id_dcs       IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_event     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_room      IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin     IN VARCHAR2,
        i_dt_end       IN VARCHAR2,
        i_id_exam      IN schedule_exam.id_exam%TYPE,
        i_flg_urg      IN sch_consult_vac_oris.flg_urgency%TYPE,
        i_flg_status   IN sch_consult_vacancy.flg_status%TYPE,
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        i_flg_timeunit IN VARCHAR2 DEFAULT NULL,
        i_flg_end_by   IN VARCHAR2 DEFAULT NULL,
        i_nr_events    IN NUMBER DEFAULT NULL,
        i_repeat_every IN NUMBER DEFAULT NULL,
        i_weekday      IN NUMBER DEFAULT NULL,
        i_day_of_month IN NUMBER DEFAULT NULL,
        i_week         IN NUMBER DEFAULT NULL,
        i_month        IN NUMBER DEFAULT NULL,
        i_rep_dt_begin IN VARCHAR2,
        i_rep_dt_end   IN VARCHAR2,
        o_flg_show2    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'SET_VACANCIES';
        l_fi             VARCHAR2(2);
        l_dates          table_timestamp_tz := table_timestamp_tz();
        l_dt_begin       TIMESTAMP WITH TIME ZONE;
        l_dt_end         TIMESTAMP WITH TIME ZONE;
        l_rep_dt_begin   TIMESTAMP;
        l_rep_dt_end     TIMESTAMP;
        i                INTEGER;
        l_time_begin     VARCHAR2(6);
        l_time_end       VARCHAR2(6);
        l_durtostarttime NUMBER;
        l_dummy          NUMBER;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_begin';
        pk_date_utils.set_dst_time_check_off;
    
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_end';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_on;
    
        -- extract start and end time 
        g_error      := 'EXTRACT START AND END TIME';
        l_time_begin := to_char(l_dt_begin, 'hh24miss');
        l_time_end   := to_char(l_dt_end, 'hh24miss');
    
        -- get dates from repetition parameters
        g_error        := 'CALC VACANCIES DATES FROM REPETITION INPUT DATA';
        l_rep_dt_begin := to_timestamp(i_rep_dt_begin, 'yyyymmddhh24miss');
        l_rep_dt_end   := to_timestamp(i_rep_dt_end, 'yyyymmddhh24miss');
    
        IF NOT pk_schedule.get_sch_series_computed_dates(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_flg_timeunit   => i_flg_timeunit,
                                                         i_flg_end_by     => i_flg_end_by,
                                                         i_nr_events      => i_nr_events,
                                                         i_repeat_every   => i_repeat_every,
                                                         i_weekday        => i_weekday,
                                                         i_day_of_month   => i_day_of_month,
                                                         i_week           => i_week,
                                                         i_sch_start_date => l_rep_dt_begin,
                                                         i_sch_end_date   => l_rep_dt_end,
                                                         i_month          => i_month,
                                                         o_flg_irregular  => l_fi,
                                                         o_dates          => l_dates,
                                                         o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- cycle through dates
        FOR i IN l_dates.first .. l_dates.last
        LOOP
            IF l_dates(i) IS NOT NULL
            THEN
                IF NOT set_vacancy(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_id_vac       => NULL,
                                   i_id_inst      => i_id_inst,
                                   i_id_prof      => i_id_prof,
                                   i_maxvacs      => i_maxvacs,
                                   i_id_dcs       => i_id_dcs,
                                   i_id_event     => i_id_event,
                                   i_id_room      => i_id_room,
                                   i_dt_begin     => to_char(l_dates(i), 'yyyymmdd') || l_time_begin,
                                   i_dt_end       => to_char(l_dates(i), 'yyyymmdd') || l_time_end,
                                   i_id_exam      => i_id_exam,
                                   i_flg_urg      => i_flg_urg,
                                   i_flg_status   => i_flg_status,
                                   i_id_phys_area => i_id_phys_area,
                                   o_id_vac       => l_dummy,
                                   o_flg_show2    => o_flg_show2,
                                   o_msg          => o_msg,
                                   o_msg_title    => o_msg_title,
                                   o_button       => o_button,
                                   o_error        => o_error)
                THEN
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_vacancies;

    /*
    * ALERT-12189. cancel one or several vacancies
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_vacs        list of id vacancies 
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Susana Silva
    * @version  2.5.0.5
    * @date     28-07-2009
    */
    FUNCTION cancel_vacancies
    (
        i_lang    IN language.id_language%TYPE,
        i_id_vacs IN table_number,
        o_count   OUT NUMBER,
        o_flag    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_VACANCIES';
    
        CURSOR c_scv(id sch_consult_vacancy.id_sch_consult_vacancy%TYPE) IS
            SELECT COUNT(*)
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy = id
               AND scv.used_vacancies = 0;
    
        l_count_used NUMBER;
        g_found      BOOLEAN;
        l_count_slot NUMBER;
    
    BEGIN
    
        BEGIN
        
            g_error := 'l_count_slot';
        
            SELECT SUM(scv.used_vacancies)
              INTO l_count_slot
              FROM sch_consult_vacancy scv
             WHERE scv.id_sch_consult_vacancy IN
                   (SELECT column_value
                      FROM TABLE(CAST(i_id_vacs AS table_number)));
        EXCEPTION
            WHEN no_data_found THEN
            
                l_count_slot := 0;
        END;
    
        IF i_lang IS NOT NULL
           AND i_id_vacs IS NOT NULL
        THEN
        
            IF l_count_slot > 0
            THEN
                g_error := 'l_count_slot > 0';
            
                o_count := l_count_slot;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            ELSE
                FOR i IN i_id_vacs.first .. i_id_vacs.last
                LOOP
                
                    g_error := 'OPEN c_scv';
                
                    OPEN c_scv(i_id_vacs(i));
                    FETCH c_scv
                        INTO l_count_used;
                    g_found := c_scv%FOUND;
                    CLOSE c_scv;
                
                    IF l_count_used = 1
                       AND g_found
                    THEN
                        g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                        DELETE FROM sch_consult_vac_mfr_slot scvms
                         WHERE scvms.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        g_error := 'DELETE FROM sch_consult_vac_mfr';
                        DELETE FROM sch_consult_vac_mfr scvm
                         WHERE scvm.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                        DELETE FROM sch_consult_vac_oris_slot scvos
                         WHERE scvos.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        g_error := 'DELETE FROM sch_consult_vac_oris';
                        DELETE FROM sch_consult_vac_oris scvo
                         WHERE scvo.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        g_error := 'DELETE FROM sch_consult_vac_oris';
                        DELETE FROM sch_consult_vac_oris scvo
                         WHERE scvo.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        g_error := 'DELETE FROM sch_consult_vacancy';
                        DELETE FROM sch_consult_vacancy scv
                         WHERE scv.id_sch_consult_vacancy = i_id_vacs(i);
                    
                        COMMIT;
                    
                    END IF;
                
                END LOOP;
            
                o_count := l_count_slot;
                o_flag  := pk_alert_constant.g_no;
            
                RETURN TRUE;
            
            END IF;
        ELSE
            g_error := 'I_LANG/I_ID_VACS NULL';
            pk_alertlog.log_debug(text        => 'PK_SCHEDULE_BO.GET_VACANCY_INF ' || g_error,
                                  object_name => g_package_name,
                                  owner       => g_package_owner);
        
            RAISE my_exception;
        END IF;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'l_func_name',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_vacancies;

    /*
    * ALERT-12189. cancel one interval full of vacancies belonging to the supplied prof, dcs or room
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        target institution id
    * @param i_id_prof        target prof id (optional)
    * @param i_id_dcs         target clinical service (optional)
    * @param i_id_room        target room id (optional)
    * @param i_dt_begin       start date
    * @param i_dt_end         end date
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Tércio Soares
    * @version  2.5.0.5
    * @date     28-07-2009
    */
    FUNCTION cancel_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_count    OUT NUMBER,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'CANCEL_VACANCIES';
    
        l_vacancies_count NUMBER(6) := 0;
        l_dt_begin_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_dt_begin_tstz := to_timestamp(i_dt_begin, 'YYYYMMDDHH24MISS');
        l_dt_end_tstz   := to_timestamp(i_dt_end, 'YYYYMMDDHH24MISS');
    
        IF i_id_prof IS NOT NULL
           AND i_id_dcs IS NULL
           AND i_id_room IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.dt_end_tstz <= l_dt_end_tstz
               AND scv.id_institution = i_id_inst
               AND scv.id_prof = i_id_prof;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.dt_end_tstz <= l_dt_end_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.dt_end_tstz <= l_dt_end_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.dt_end_tstz <= l_dt_end_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.dt_end_tstz <= l_dt_end_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.dt_end_tstz <= l_dt_end_tstz
                   AND scv.id_institution = i_id_inst
                   AND scv.id_prof = i_id_prof;
            
            ELSE
            
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            END IF;
        
        ELSIF i_id_dcs IS NOT NULL
              AND i_id_prof IS NULL
              AND i_id_room IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.dt_end_tstz <= l_dt_end_tstz
               AND scv.id_dep_clin_serv = i_id_dcs;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.dt_end_tstz <= l_dt_end_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.dt_end_tstz <= l_dt_end_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.dt_end_tstz <= l_dt_end_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.dt_end_tstz <= l_dt_end_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.dt_end_tstz <= l_dt_end_tstz
                   AND scv.id_dep_clin_serv = i_id_dcs;
            
            ELSE
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            END IF;
        
        ELSIF i_id_room IS NOT NULL
              AND i_id_prof IS NULL
              AND i_id_dcs IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.dt_end_tstz <= l_dt_end_tstz
               AND scv.id_institution = i_id_inst
               AND scv.id_room = i_id_room;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.dt_end_tstz <= l_dt_end_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.dt_end_tstz <= l_dt_end_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.dt_end_tstz <= l_dt_end_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.dt_end_tstz <= l_dt_end_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.dt_end_tstz <= l_dt_end_tstz
                   AND scv.id_institution = i_id_inst
                   AND scv.id_room = i_id_room;
            
            ELSE
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            END IF;
        
        END IF;
    
        o_count := l_vacancies_count;
        o_flag  := pk_alert_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_vacancies;

    /*
    * ALERT-12189. cancel all starting today belonging to the supplied prof, dcs or room
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        target institution id
    * @param i_id_prof        target prof id (optional)
    * @param i_id_dcs         target clinical service (optional)
    * @param i_id_room        target room id (optional)
    * @param i_dt_begin       start date
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Tércio Soares
    * @version  2.5.0.5
    * @date     28-07-2009
    */
    FUNCTION cancel_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_count    OUT NUMBER,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANCEL_VACANCIES';
    
        l_vacancies_count NUMBER(6) := 0;
        l_dt_begin_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_dt_begin_tstz := to_timestamp(i_dt_begin, 'YYYYMMDDHH24MISS');
    
        IF i_id_prof IS NOT NULL
           AND i_id_dcs IS NULL
           AND i_id_room IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.id_institution = i_id_inst
               AND scv.id_prof = i_id_prof;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_prof = i_id_prof);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.id_institution = i_id_inst
                   AND scv.id_prof = i_id_prof;
            
            ELSE
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            END IF;
        
        ELSIF i_id_dcs IS NOT NULL
              AND i_id_prof IS NULL
              AND i_id_room IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.id_dep_clin_serv = i_id_dcs;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN
                       (SELECT scv.id_sch_consult_vacancy
                          FROM sch_consult_vacancy scv
                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                           AND scv.id_dep_clin_serv = i_id_dcs);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.id_dep_clin_serv = i_id_dcs;
            
            ELSE
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            END IF;
        
        ELSIF i_id_room IS NOT NULL
              AND i_id_prof IS NULL
              AND i_id_dcs IS NULL
        THEN
            g_error := 'SUM used_vacancies';
            SELECT nvl(SUM(scv.used_vacancies), 0)
              INTO l_vacancies_count
              FROM sch_consult_vacancy scv
             WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
               AND scv.id_institution = i_id_inst
               AND scv.id_room = i_id_room;
        
            IF l_vacancies_count = 0
            THEN
            
                g_error := 'DELETE FROM sch_consult_vac_oris_slot';
                DELETE FROM sch_consult_vac_oris_slot scvos
                 WHERE scvos.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_oris';
                DELETE FROM sch_consult_vac_oris scvo
                 WHERE scvo.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr_slot';
                DELETE FROM sch_consult_vac_mfr_slot scvms
                 WHERE scvms.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                          FROM sch_consult_vacancy scv
                                                         WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                           AND scv.id_institution = i_id_inst
                                                           AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vac_mfr';
                DELETE FROM sch_consult_vac_mfr scvm
                 WHERE scvm.id_sch_consult_vacancy IN (SELECT scv.id_sch_consult_vacancy
                                                         FROM sch_consult_vacancy scv
                                                        WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                                                          AND scv.id_institution = i_id_inst
                                                          AND scv.id_room = i_id_room);
            
                g_error := 'DELETE FROM sch_consult_vacancy';
                DELETE FROM sch_consult_vacancy scv
                 WHERE scv.dt_begin_tstz >= l_dt_begin_tstz
                   AND scv.id_institution = i_id_inst
                   AND scv.id_room = i_id_room;
            
            ELSE
                o_count := l_vacancies_count;
                o_flag  := pk_alert_constant.g_yes;
            
                RAISE my_exception;
            
            END IF;
        
        END IF;
    
        o_count := l_vacancies_count;
        o_flag  := pk_alert_constant.g_no;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_vacancies;

    /*
    * returns list of vacancy ids that are caught in a specific period for a given prof.
    * this is to be used inside set_unav and get_unblocked vacancies.
    * That is, functions that handle with creation/updates of unavailabilities.
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_inst        vacancy institution id
    * @param i_id_prof        vacancy destination professional
    * @param i_u_dt_begin     unav start date
    * @param i_u_dt_end       unav end date
    * @param i_all_vacs       Y = all vacancies  N = only non-blocked vacancies
    * @param i_sch_type       NULL= all kinds of vacancies.  NOT NULL=vacancies with id_sch_event of that dep type
    * @param o_id_vacs        output list
    * @param o_error          error data
    *
    * @author  Telmo
    * @version 2.5.0.5
    * @date    28-07-2009
    */
    FUNCTION get_affected_vacancies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_inst    IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof    IN sch_consult_vacancy.id_prof%TYPE,
        i_u_dt_begin IN TIMESTAMP WITH TIME ZONE,
        i_u_dt_end   IN TIMESTAMP WITH TIME ZONE,
        i_status     IN VARCHAR2 DEFAULT NULL,
        i_sch_type   IN sch_event.dep_type%TYPE DEFAULT NULL,
        o_id_vacs    OUT table_number,
        o_num_scheds OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_AFFECTED_VACANCIES';
    
    BEGIN
        IF i_u_dt_begin IS NULL
           AND i_u_dt_end IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'GET LIST';
        SELECT id_sch_consult_vacancy
          BULK COLLECT
          INTO o_id_vacs
          FROM sch_consult_vacancy scv
          JOIN sch_event se
            ON scv.id_sch_event = se.id_sch_event
         WHERE scv.id_institution = i_id_inst
           AND scv.id_prof = i_id_prof
           AND scv.id_prof IS NOT NULL
           AND (i_status IS NULL OR scv.flg_status = i_status)
              --           AND (i_all_vacs = g_yes OR scv.flg_status = g_status_active)
           AND (i_sch_type IS NULL OR se.dep_type = i_sch_type)
           AND ((scv.dt_begin_tstz >= i_u_dt_begin AND scv.dt_begin_tstz < i_u_dt_end) OR
               (scv.dt_end_tstz IS NOT NULL AND scv.dt_end_tstz > i_u_dt_begin AND scv.dt_end_tstz <= i_u_dt_end) OR
               (scv.dt_end_tstz IS NOT NULL AND scv.dt_begin_tstz < i_u_dt_begin AND scv.dt_end_tstz > i_u_dt_end));
    
        g_error := 'CHECK LIST COUNT';
        IF o_id_vacs IS NULL
           OR o_id_vacs.count = 0
        THEN
            o_num_scheds := 0;
        ELSE
            g_error := 'CALC SUM OF APPOINTMENTS ATTACHED TO THIS VACANCY LIST';
            SELECT SUM(scv.used_vacancies)
              INTO o_num_scheds
              FROM sch_consult_vacancy scv
             WHERE id_sch_consult_vacancy IN (SELECT *
                                                FROM TABLE(o_id_vacs));
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_affected_vacancies;

    /*
    * returns list of vacancy ids that are affected by at least one of the unavs in i_id_unavs.
    * this is to be used inside get_blocked_vacancies
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_unavs       unavs id list
    * @param o_id_vacs        output list
    * @param o_error          error data
    *
    * @author  Telmo
    * @version 2.5.0.5
    * @date    28-07-2009
    */
    FUNCTION get_affected_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_unavs IN table_number,
        i_status   IN VARCHAR2 DEFAULT NULL,
        i_sch_type IN sch_event.dep_type%TYPE DEFAULT NULL,
        o_id_vacs  OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_AFFECTED_VACANCIES';
        l_list       table_number := table_number();
        l_id_inst    sch_absence.id_institution%TYPE;
        l_id_prof    sch_absence.id_professional%TYPE;
        l_dt_begin   sch_absence.dt_begin_tstz%TYPE;
        l_dt_end     sch_absence.dt_end_tstz%TYPE;
        l_num_scheds NUMBER;
    BEGIN
        o_id_vacs := table_number();
    
        IF i_id_unavs IS NULL
           OR i_id_unavs.count = 0
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'LOOP UNAVS';
        FOR idx IN 1 .. i_id_unavs.count
        LOOP
            g_error := 'FETCH DATA FOR UNAV ID ' || i_id_unavs(idx);
            SELECT sa.id_institution, sa.id_professional, sa.dt_begin_tstz, sa.dt_end_tstz
              INTO l_id_inst, l_id_prof, l_dt_begin, l_dt_end
              FROM sch_absence sa
             WHERE sa.id_sch_absence = i_id_unavs(idx)
               AND sa.flg_status = g_status_active;
        
            g_error := 'CALL PARENT GET_AFFECTED_VACANCIES';
            IF NOT get_affected_vacancies(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_inst    => l_id_inst,
                                          i_id_prof    => l_id_prof,
                                          i_u_dt_begin => l_dt_begin,
                                          i_u_dt_end   => l_dt_end,
                                          i_status     => i_status,
                                          i_sch_type   => i_sch_type,
                                          o_id_vacs    => l_list,
                                          o_num_scheds => l_num_scheds,
                                          o_error      => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- send to common list 
            g_error   := 'SEND FOUND VACANCIES TO COMMON POOL';
            o_id_vacs := o_id_vacs MULTISET UNION l_list;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_affected_vacancies;

    /** @headcom
    * Public Function. Get Unavailability information
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_unav                     Unavailability identification
    * @param      o_unav                     Unavailability information
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/07/24
    */
    FUNCTION get_unav
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_unav  IN sch_absence.id_sch_absence%TYPE,
        o_unav  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof IS NOT NULL
           AND i_unav IS NOT NULL
        THEN
        
            g_error := 'OPEN o_unav FOR';
        
            OPEN o_unav FOR
                SELECT pk_date_utils.dt_chr(i_lang, sa.dt_begin_tstz, i_prof) dt_begin_tstz_desc,
                       pk_date_utils.dt_chr(i_lang, sa.dt_end_tstz, i_prof) dt_end_tstz_desc,
                       to_char(sa.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_begin_s,
                       to_char(sa.dt_end_tstz, 'YYYYMMDDHH24MISS') dt_end_s,
                       lpad(extract(hour FROM(sa.dt_begin_tstz)), 2, '0') || ':' ||
                       lpad(extract(minute FROM(sa.dt_begin_tstz)), 2, '0') || 'h' starting_hour_desc,
                       lpad(extract(hour FROM(sa.dt_end_tstz)), 2, '0') || ':' ||
                       lpad(extract(minute FROM(sa.dt_end_tstz)), 2, '0') || 'h' ending_hour_desc,
                       sa.desc_absence reason
                  FROM sch_absence sa
                 WHERE sa.id_sch_absence = i_unav;
        
            RETURN TRUE;
        
        ELSE
        
            g_error := 'I_LANG/I_PROF/I_UNAV NULL';
        
            RAISE my_exception;
        
        END IF;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'GET_UNAV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_unav);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'GET_UNAV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_unav;

    /** @headcom
    * Public Function. Set Unavailability information
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_unav                     Unavailability identification
    * @param      i_start_date               Start date
    * @param      i_end_date                 End date
    * @param      i_start_hour               Start hour
    * @param      i_end_hour                 End hour
    * @param      i_desc                     Description    
    * @param      o_id_unav                  Unavailability identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/07/24
    */

    FUNCTION set_unav
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_prof    IN professional.id_professional%TYPE,
        i_unav       IN sch_absence.id_sch_absence%TYPE,
        i_start_date VARCHAR2,
        i_end_date   VARCHAR2,
        i_start_hour VARCHAR2,
        i_end_hour   VARCHAR2,
        i_desc       IN sch_absence.desc_absence%TYPE,
        o_id_unav    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sch_absence sch_absence.id_sch_absence%TYPE;
        l_start_date     sch_absence.dt_begin_tstz%TYPE;
        l_end_date       sch_absence.dt_end_tstz%TYPE;
        l_start_concat   VARCHAR2(200);
        l_end_concat     VARCHAR2(200);
        l_rows_out       table_varchar;
        l_error          t_error_out;
        l_vacs           table_number := table_number();
        l_num_scheds     NUMBER;
        l_count          INTEGER;
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof IS NOT NULL
           AND i_start_date IS NOT NULL
           AND i_end_date IS NOT NULL
           AND i_start_hour IS NOT NULL
           AND i_end_hour IS NOT NULL
        
        THEN
        
            IF i_unav IS NULL
            THEN
            
                g_error := 'CONVERT START DATE';
                pk_date_utils.set_dst_time_check_off;
            
                IF NOT
                    pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => substr(i_start_date, 1, 8) || substr(i_start_hour, 9, 14),
                                                  i_timezone  => NULL,
                                                  o_timestamp => l_start_date,
                                                  o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'CONVERT END DATE';
                IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => substr(i_end_date, 1, 8) || substr(i_end_hour, 9, 14),
                                                     i_timezone  => NULL,
                                                     o_timestamp => l_end_date,
                                                     o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                pk_date_utils.set_dst_time_check_on;
            
                BEGIN
                    SELECT COUNT(*)
                      INTO l_count
                      FROM sch_absence sa
                     WHERE sa.id_professional = i_id_prof
                       AND sa.id_institution = i_prof.institution
                       AND sa.dt_begin_tstz = l_start_date
                       AND sa.dt_end_tstz = l_end_date;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_count := 0;
                END;
            
                IF l_count > 0
                THEN
                
                    BEGIN
                        SELECT sa.id_sch_absence
                          INTO l_id_sch_absence
                          FROM sch_absence sa
                         WHERE sa.id_professional = i_id_prof
                           AND sa.id_institution = i_prof.institution
                           AND sa.dt_begin_tstz = l_start_date
                           AND sa.dt_end_tstz = l_end_date;
                    EXCEPTION
                        WHEN no_data_found THEN
                            RETURN FALSE;
                    END;
                
                ELSE
                    g_error := 'SEQ_SCH_ABSENCE.NEXTVAL';
                
                    SELECT seq_sch_absence.nextval
                      INTO l_id_sch_absence
                      FROM dual;
                
                END IF;
            
            ELSE
                g_error := 'L_ID_SCH_ABSENCE=' || i_unav;
            
                l_id_sch_absence := i_unav;
            
                --Telmo 30-07-2009. sendo um update, tem de desbloquear as vagas que estavam bloqueadas antes da edicao
                g_error := 'GET AFFECTED VACANCIES';
                IF NOT get_affected_vacancies(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_id_unavs => table_number(l_id_sch_absence),
                                              i_status   => g_status_blocked,
                                              i_sch_type => NULL,
                                              o_id_vacs  => l_vacs,
                                              o_error    => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_vacs IS NOT NULL
                   AND l_vacs.count > 0
                THEN
                    g_error := 'UNBLOCK AFFECTED VACANCIES';
                    UPDATE sch_consult_vacancy
                       SET flg_status = g_status_active
                     WHERE id_sch_consult_vacancy IN (SELECT *
                                                        FROM TABLE(l_vacs));
                END IF;
            
            END IF;
        
            --            g_error := 'CALCULATE l_start_concat/l_end_concat/l_start_date/l_end_date';
            --            pk_alertlog.log_debug('PK_SCHEDULE_BO.SET_UNAV ' || g_error);
            --            l_start_concat := substr(i_start_date, 1, 8) || substr(i_start_hour, 9, 14);
            --            l_end_concat   := substr(i_end_date, 1, 8) || substr(i_end_hour, 9, 14);
            --            l_start_date   := to_timestamp(l_start_concat, 'YYYYMMDDHH24MISS');
            --            l_end_date     := to_timestamp(l_end_concat, 'YYYYMMDDHH24MISS');
        
            -- Get begin date in tstz form
            g_error := 'CALC l_start_date';
            pk_date_utils.set_dst_time_check_off;
        
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => substr(i_start_date, 1, 8) || substr(i_start_hour, 9, 14),
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- Get end date in tstz form
            g_error := 'CALC l_end_date';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => substr(i_end_date, 1, 8) || substr(i_end_hour, 9, 14),
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
            pk_date_utils.set_dst_time_check_on;
        
            g_error := 'ts_sch_absence.upd_ins';
        
            ts_sch_absence.upd_ins(id_sch_absence_in  => l_id_sch_absence,
                                   id_professional_in => i_id_prof,
                                   id_institution_in  => i_prof.institution,
                                   dt_begin_tstz_in   => l_start_date,
                                   dt_end_tstz_in     => l_end_date,
                                   desc_absence_in    => i_desc,
                                   flg_type_in        => g_flg_type_sch_absence,
                                   flg_status_in      => g_flg_status_sch_absence,
                                   rows_out           => l_rows_out);
        
            -- telmo 28-07-2009 - bloquear vagas afectadas pela unav
            g_error := 'EMPTY TABLE_NUMBER';
            l_vacs.delete;
        
            g_error := 'GET AFFECTED VACANCIES';
            IF NOT get_affected_vacancies(i_lang,
                                          i_prof,
                                          i_prof.institution,
                                          i_id_prof,
                                          l_start_date,
                                          l_end_date,
                                          g_status_active,
                                          NULL,
                                          l_vacs,
                                          l_num_scheds,
                                          o_error)
            THEN
                RETURN FALSE;
            END IF;
            IF l_vacs IS NOT NULL
               AND l_vacs.count > 0
            THEN
                g_error := 'BLOCK AFFECTED VACANCIES';
                UPDATE sch_consult_vacancy
                   SET flg_status = g_status_blocked
                 WHERE id_sch_consult_vacancy IN (SELECT *
                                                    FROM TABLE(l_vacs));
            END IF;
        
            IF i_unav IS NULL
            THEN
                g_error := 'PROCESS INSERT SCH_ABSENCE';
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SCH_ABSENCE',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
                o_id_unav := l_id_sch_absence;
            
            ELSE
                g_error := 'PROCESS UPDATE SCH_ABSENCE';
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'SCH_ABSENCE',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            
            END IF;
        
            COMMIT;
        
            RETURN TRUE;
        ELSE
            g_error := 'i_lang/i_prof/i_start_date/i_end_date/i_start_hour/i_end_hour  NULL';
        
            RAISE my_exception;
        END IF;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'SET_UNAV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'SET_UNAV',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_unav;

    /** @headcom
    * Public Function. Cancel Unavailability
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_unav                     Unavailability identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.4
    * @since      2008/07/24
    */

    FUNCTION cancel_unav
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_unav  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out   table_varchar;
        l_error      t_error_out;
        l_vacs       table_number := table_number();
        l_start_date sch_absence.dt_begin_tstz%TYPE;
        l_end_date   sch_absence.dt_end_tstz%TYPE;
        l_num_scheds NUMBER;
        l_id_prof    sch_absence.id_professional%TYPE;
        l_id_inst    sch_absence.id_institution%TYPE;
    BEGIN
        IF i_lang IS NOT NULL
           AND i_prof IS NOT NULL
           AND i_unav IS NOT NULL
        THEN
        
            g_error := 'FOR i_unav.FIRST .. i_unav.LAST';
        
            FOR i IN i_unav.first .. i_unav.last
            LOOP
            
                g_error := 'UPDATE SCH_ABSENCE WHERE id_sch_absence=' || i_unav(i);
            
                ts_sch_absence.upd(flg_status_in  => pk_alert_constant.g_inactive,
                                   flg_status_nin => FALSE,
                                   where_in       => 'id_sch_absence=' || i_unav(i),
                                   rows_out       => l_rows_out);
            
                -- telmo 28-07-2009 - desbloquear vagas afectadas pela unav
                g_error := 'GET DATA FOR UNAV ' || i_unav(i);
                SELECT sa.dt_begin_tstz, sa.dt_end_tstz, sa.id_professional, sa.id_institution
                  INTO l_start_date, l_end_date, l_id_prof, l_id_inst
                  FROM sch_absence sa
                 WHERE sa.id_sch_absence = i_unav(i);
            
                g_error := 'GET AFFECTED VACANCIES';
                IF NOT get_affected_vacancies(i_lang,
                                              i_prof,
                                              l_id_inst,
                                              l_id_prof,
                                              l_start_date,
                                              l_end_date,
                                              g_status_blocked,
                                              NULL,
                                              l_vacs,
                                              l_num_scheds,
                                              o_error)
                THEN
                    RETURN FALSE;
                END IF;
                IF l_vacs IS NOT NULL
                   AND l_vacs.count > 0
                THEN
                    g_error := 'UNBLOCK AFFECTED VACANCIES';
                    UPDATE sch_consult_vacancy
                       SET flg_status = g_status_active
                     WHERE id_sch_consult_vacancy IN (SELECT *
                                                        FROM TABLE(l_vacs));
                END IF;
            
                g_error := 'PROCESS_UPDATE SCH_ABSENCE';
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CANCEL_UNAV',
                                              i_rowids     => l_rows_out,
                                              o_error      => l_error);
            END LOOP;
            RETURN TRUE;
        
        ELSE
        
            g_error := 'I_LANG/I_PROF/I_UNAV NULL';
        
            RAISE my_exception;
        
        END IF;
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'CANCEL_UNAV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'CANCEL_UNAV',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_unav;

    /*
        * ALERT-12189. calculate list of vacancies affected by the creation/update of this unavailability
        * 
        * @param i_lang           Language identifier
        * @param i_prof           professional. Used to set up the audit fields
    --    * @param i_id_unav        not null if this is an update. 
        * @param i_id_prof        target professional
        * @param i_id_inst        in this institution
        * @param i_dt_begin       starting date
        * @param i_dt_end         end date
        * @param o_data           output list
        * @param o_num_scheds     sum of schedules attached to those vacancies
        
        * @param o_error          Error data
        *
        * @return True if successful, false otherwise.
        *
        * @author   Telmo Castro
        * @version  2.5.0.5
        * @date     21-07-2009
        */
    FUNCTION get_unblocked_vacancies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_prof    IN sch_absence.id_professional%TYPE,
        i_id_inst    IN sch_absence.id_institution%TYPE,
        i_dt_begin   IN VARCHAR2,
        i_dt_end     IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_num_scheds OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(32) := 'GET_UNBLOCKED_VACANCIES';
        l_start_date sch_absence.dt_begin_tstz%TYPE;
        l_end_date   sch_absence.dt_end_tstz%TYPE;
        l_vacs       table_number := table_number();
    BEGIN
    
        -- Get begin date in tstz form
        g_error := 'GET BEGIN DATE';
        pk_date_utils.set_dst_time_check_off;
    
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Get end date in tstz form
        g_error := 'GET END DATE';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'CALL GET_AFFECTED_VACANCIES';
        IF NOT get_affected_vacancies(i_lang,
                                      i_prof,
                                      i_id_inst,
                                      i_id_prof,
                                      l_start_date,
                                      l_end_date,
                                      g_status_active,
                                      NULL,
                                      l_vacs,
                                      o_num_scheds,
                                      o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH DATA OF AFFECTED VACANCIES AND DOWN THE PIPE IT GOES';
        OPEN o_data FOR
            SELECT
            
             pk_message.get_message(i_lang,
                                    CASE pk_schedule_oris.week_day_standard(scv.dt_begin_tstz)
                                        WHEN 1 THEN
                                         g_msg_seg
                                        WHEN 2 THEN
                                         g_msg_ter
                                        WHEN 3 THEN
                                         g_msg_qua
                                        WHEN 4 THEN
                                         g_msg_qui
                                        WHEN 5 THEN
                                         g_msg_sex
                                        WHEN 6 THEN
                                         g_msg_sab
                                        WHEN 7 THEN
                                         g_msg_dom
                                    END) weekday,
             pk_schedule_oris.get_month_abrev(i_lang,
                                              pk_date_utils.date_month_tsz(i_lang,
                                                                           scv.dt_begin_tstz,
                                                                           i_prof.institution,
                                                                           i_prof.software)) month_abrev,
             pk_date_utils.date_day_tsz(i_lang, scv.dt_begin_tstz, i_prof.institution, i_prof.software) dia,
             pk_date_utils.date_year_tsz(i_lang, scv.dt_begin_tstz, i_prof.institution, i_prof.software) ano,
             pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) begin_time,
             pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software) end_time,
             pk_schedule.string_service(i_lang, scv.id_dep_clin_serv) desc_service,
             pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs,
             pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
             pk_schedule.string_sch_type(i_lang, se.dep_type) desc_sch_type
              FROM sch_consult_vacancy scv
              JOIN sch_event se
                ON scv.id_sch_event = se.id_sch_event
             WHERE scv.id_sch_consult_vacancy IN (SELECT *
                                                    FROM TABLE(l_vacs));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_unblocked_vacancies;

    /*
    * ALERT-12189. calculate list of vacancies affected by the cancelation of this unavailability
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_id_unavs       list of unavs being cancelled
    
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     21-07-2009
    */
    FUNCTION get_blocked_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_unavs IN table_number,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_BLOCKED_VACANCIES';
        l_vacs      table_number := table_number();
    BEGIN
        g_error := 'CALL GET_AFFECTED_VACANCIES';
        IF NOT get_affected_vacancies(i_lang, i_prof, i_id_unavs, g_status_blocked, NULL, l_vacs, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'FETCH DATA OF AFFECTED VACANCIES AND DOWN THE PIPE IT GOES';
        OPEN o_data FOR
            SELECT
            
             pk_message.get_message(i_lang,
                                    CASE pk_schedule_oris.week_day_standard(scv.dt_begin_tstz)
                                        WHEN 1 THEN
                                         g_msg_seg
                                        WHEN 2 THEN
                                         g_msg_ter
                                        WHEN 3 THEN
                                         g_msg_qua
                                        WHEN 4 THEN
                                         g_msg_qui
                                        WHEN 5 THEN
                                         g_msg_sex
                                        WHEN 6 THEN
                                         g_msg_sab
                                        WHEN 7 THEN
                                         g_msg_dom
                                    END) weekday,
             pk_schedule_oris.get_month_abrev(i_lang,
                                              pk_date_utils.date_month_tsz(i_lang,
                                                                           scv.dt_begin_tstz,
                                                                           i_prof.institution,
                                                                           i_prof.software)) month_abrev,
             pk_date_utils.date_day_tsz(i_lang, scv.dt_begin_tstz, i_prof.institution, i_prof.software) dia,
             pk_date_utils.date_year_tsz(i_lang, scv.dt_begin_tstz, i_prof.institution, i_prof.software) ano,
             pk_date_utils.date_char_hour_tsz(i_lang, dt_begin_tstz, i_prof.institution, i_prof.software) begin_time,
             pk_date_utils.date_char_hour_tsz(i_lang, dt_end_tstz, i_prof.institution, i_prof.software) end_time,
             pk_schedule.string_service(i_lang, scv.id_dep_clin_serv) desc_service,
             pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs,
             pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
             pk_schedule.string_sch_type(i_lang, se.dep_type) desc_sch_type
              FROM sch_consult_vacancy scv
              JOIN sch_event se
                ON scv.id_sch_event = se.id_sch_event
             WHERE scv.id_sch_consult_vacancy IN (SELECT *
                                                    FROM TABLE(l_vacs));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_blocked_vacancies;

    /*
    * check if this dcs is among those configured in sch_event_dcs and sch_deparment
    *    
    * @param i_id_dcs       dep clin serv id
    * @param i_id_inst      institution id
    * @param o_config       Y=configured  N=not configured
    *
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.5.0.5
    * @date     22-07-2009
    */
    FUNCTION check_dcs_config
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_inst IN department.id_institution%TYPE,
        o_config  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CHECK_DCS_CONFIG';
    BEGIN
        g_error := 'CHECK IF DCS IS CONFIGURED';
        SELECT g_yes
          INTO o_config
          FROM dep_clin_serv dcs
          JOIN department d
            ON dcs.id_department = d.id_department
          JOIN sch_department sd
            ON d.id_department = sd.id_department
         WHERE sd.flg_dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cons
           AND d.id_institution = i_id_inst
           AND dcs.id_dep_clin_serv = i_id_dcs
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_config := g_no;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_dcs_config;

    /** @headcom
    * Public Function. Copy paste after slot
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_slot                     Unavailability identification
    * @param      o_id_scv                     Unavailability identification
    * @param      o_id_scve                     Unavailability identification
    * @param      o_id_scvos                     Unavailability identification
    * @param      o_flg_show                     Unavailability identification
    * @param      o_msg                     Unavailability identification
    * @param      o_msg_title                     Unavailability identification
    * @param      o_button                     Unavailability identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.5
    * @since      2008/07/28
    *
    * UPDATED alert-8202. table sch_consult_vac_exam demise
    * @author  Telmo Castro
    * @version 2.5.0.7
    * @date    19-10-2009
    */

    FUNCTION copy_paste_after
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_slot      IN NUMBER,
        o_id_scv    OUT NUMBER,
        o_id_scve   OUT NUMBER,
        o_id_scvos  OUT NUMBER,
        o_flg_show2 OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_institution_scv sch_consult_vacancy.id_institution%TYPE;
        l_id_prof_scv        sch_consult_vacancy.id_prof%TYPE;
        l_max_vacancies_scv  sch_consult_vacancy.max_vacancies%TYPE;
        l_id_dcs_scv         sch_consult_vacancy.id_dep_clin_serv%TYPE;
        l_id_room_scv        sch_consult_vacancy.id_room%TYPE;
        l_id_sch_event_scv   sch_consult_vacancy.id_sch_event%TYPE;
        l_dt_begin_tstz_scv  sch_consult_vacancy.dt_begin_tstz%TYPE;
        l_dt_end_tstz_scv    sch_consult_vacancy.dt_end_tstz%TYPE;
        l_flg_status_scv     sch_consult_vacancy.flg_status%TYPE;
        l_end_dt_diff        NUMBER;
        l_begin_dt           VARCHAR2(200);
        l_end_dt             TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date           VARCHAR2(200);
        l_id_vac             NUMBER;
        l_count_oris         NUMBER;
        l_flg_urgent         VARCHAR2(200);
    
        CURSOR c_sch_consult_vac_oris(id sch_consult_vac_oris.id_sch_consult_vacancy%TYPE) IS
            SELECT scvo.flg_urgency
              FROM sch_consult_vac_oris scvo
             WHERE scvo.id_sch_consult_vacancy = id;
    
        CURSOR c_sch_consult_vac_oris_slot(id sch_consult_vac_oris_slot.id_sch_consult_vacancy%TYPE) IS
            SELECT COUNT(*)
              FROM sch_consult_vac_oris_slot scvos
             WHERE scvos.id_sch_consult_vacancy = id;
    
        g_found_oris      BOOLEAN;
        l_slot_next       NUMBER;
        g_found_oris_slot BOOLEAN;
        l_scve            NUMBER;
        l_scvos           NUMBER;
        l_vacancy         sch_consult_vacancy%ROWTYPE;
    
    BEGIN
    
        IF i_lang IS NOT NULL
           AND i_prof IS NOT NULL
           AND i_slot IS NOT NULL
        THEN
        
            g_error := 'IF NOT pk_schedule_common.get_vacancy_data';
        
            IF NOT get_vacancy_inf(i_lang                => i_lang,
                                   i_sch_consult_vacancy => i_slot,
                                   o_data                => l_vacancy,
                                   o_error               => o_error)
            
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'L_VACANCY: ROWTYPE VALUES';
        
            l_id_institution_scv := l_vacancy.id_institution;
            l_id_prof_scv        := l_vacancy.id_prof;
            l_max_vacancies_scv  := l_vacancy.max_vacancies;
            l_id_dcs_scv         := l_vacancy.id_dep_clin_serv;
            l_id_room_scv        := l_vacancy.id_room;
            l_id_sch_event_scv   := l_vacancy.id_sch_event;
            l_dt_begin_tstz_scv  := l_vacancy.dt_begin_tstz;
            l_dt_end_tstz_scv    := l_vacancy.dt_end_tstz;
            l_flg_status_scv     := l_vacancy.flg_status;
        
            g_error := 'CALCULATE l_end_dt_diff/l_begin_dt/l_end_dt/l_end_date';
        
            l_end_dt_diff := pk_date_utils.diff_timestamp(l_dt_end_tstz_scv, l_dt_begin_tstz_scv);
            l_begin_dt    := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                         i_date => l_dt_end_tstz_scv,
                                                         i_prof => i_prof);
            l_end_dt      := pk_date_utils.add_to_ltstz(l_dt_end_tstz_scv, l_end_dt_diff);
            l_end_date    := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_end_dt, i_prof => i_prof);
        
            g_error := 'OPEN c_sch_consult_vac_oris';
        
            OPEN c_sch_consult_vac_oris(i_slot);
            FETCH c_sch_consult_vac_oris
                INTO l_flg_urgent;
            g_found_oris := c_sch_consult_vac_oris%FOUND;
            CLOSE c_sch_consult_vac_oris;
        
            g_error := 'seq_sch_consult_vacancy.NEXTVAL';
        
            SELECT seq_sch_consult_vacancy.nextval
              INTO l_slot_next
              FROM dual;
        
            g_error := 'IF NOT pk_schedule_bo.set_vacancy';
        
            IF NOT pk_schedule_bo.set_vacancy(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_vac       => NULL,
                                              i_id_inst      => l_id_institution_scv,
                                              i_id_prof      => l_id_prof_scv,
                                              i_maxvacs      => l_max_vacancies_scv,
                                              i_id_dcs       => l_id_dcs_scv,
                                              i_id_event     => l_id_sch_event_scv,
                                              i_id_room      => l_id_room_scv,
                                              i_dt_begin     => l_begin_dt,
                                              i_dt_end       => l_end_date,
                                              i_id_exam      => NULL,
                                              i_flg_urg      => nvl(l_flg_urgent, NULL),
                                              i_flg_status   => l_flg_status_scv,
                                              i_id_phys_area => NULL,
                                              o_id_vac       => l_id_vac,
                                              o_flg_show2    => o_flg_show2,
                                              o_msg          => o_msg,
                                              o_msg_title    => o_msg_title,
                                              o_button       => o_button,
                                              o_error        => o_error)
            THEN
                RETURN TRUE;
            ELSE
            
                o_id_scv := l_id_vac;
            
                IF g_found_oris
                THEN
                
                    g_error := 'INSERT INTO sch_consult_vac_oris';
                
                    INSERT INTO sch_consult_vac_oris
                        (id_sch_consult_vacancy, flg_urgency)
                    VALUES
                        (l_id_vac, l_flg_urgent);
                
                    COMMIT;
                
                END IF;
            
                g_error := 'OPEN c_sch_consult_vac_oris_slot';
            
                OPEN c_sch_consult_vac_oris_slot(i_slot);
                FETCH c_sch_consult_vac_oris_slot
                    INTO l_count_oris;
                g_found_oris_slot := c_sch_consult_vac_oris_slot%FOUND;
                CLOSE c_sch_consult_vac_oris_slot;
            
                IF g_found_oris_slot
                   AND l_count_oris > 0
                THEN
                
                    g_error := 'seq_sch_consult_vac_oris_slot.NEXTVAL';
                
                    SELECT seq_sch_consult_vac_oris_slot.nextval
                      INTO l_scvos
                      FROM dual;
                
                    g_error := 'INSERT INTO sch_consult_vac_oris_slot';
                
                    INSERT INTO sch_consult_vac_oris_slot
                        (id_sch_consult_vac_oris_slot, id_sch_consult_vacancy, dt_begin, dt_end)
                    VALUES
                        (l_scvos, l_id_vac, l_begin_dt, l_end_dt);
                
                    COMMIT;
                
                    o_id_scvos := l_scvos;
                
                END IF;
            
                RETURN TRUE;
            END IF;
        ELSE
            RAISE my_exception;
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'COPY_PASTE_AFTER',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'COPY_PASTE_AFTER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END copy_paste_after;

    /*
    * ALERT-34830. Group cancellation
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional login. 
    * @param i_id_prof        target prof id (optional)
    * @param i_dt_begin       start date
    * @param i_dt_begin       end date
    * @param i_id_dcs         target clinical service
    * @param i_id_room        target room id (optional)
    * @param i_sch_event      schedule events
    * @param o_data           data output
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Susana Silva
    * @version  2.5.0.6
    * @date     27-08-2009
    */
    FUNCTION get_events_cancelled
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_prof   IN sch_consult_vacancy.id_prof%TYPE,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_id_dcs    IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room   IN sch_consult_vacancy.id_room%TYPE,
        i_sch_event IN sch_consult_vacancy.id_sch_event%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_error := 'READ INPUTS: i_lang=' || i_lang || ', i_prof= profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), i_id_prof=' || i_id_prof || ', i_dt_begin=' ||
                   i_dt_begin || ', i_dt_end=' || i_dt_end || ', i_id_dcs=' || i_id_dcs || ', i_id_room=' || i_id_room ||
                   ', i_sch_event=' || i_sch_event;
    
        /* If the group cancellations fields are in the speciality context then the inputs professional identification and room identification can be null 
        If the group cancellation fields are in the professional context then the input room can be null
        If the group cancellation fields are in the room context then the input professional identification can be null*/
    
        IF i_lang IS NOT NULL
           AND i_prof.id IS NOT NULL
           AND i_prof.institution IS NOT NULL
           AND i_prof.software IS NOT NULL
           AND i_dt_begin IS NOT NULL
           AND i_dt_end IS NOT NULL
           AND i_id_dcs IS NOT NULL
           AND i_sch_event IS NOT NULL
        THEN
        
            g_error := 'CALCULATE l_date_begin AND l_date_end';
        
            pk_date_utils.set_dst_time_check_off;
        
            l_date_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
            l_date_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
            pk_date_utils.set_dst_time_check_on;
        
            g_error := 'DATE_BEGIN=' || l_date_begin || ', DATE_END=' || l_date_end || ' OPEN O_DATA:';
        
            OPEN o_data FOR
                SELECT scv.id_sch_consult_vacancy,
                       pk_date_utils.dt_chr(i_lang, scv.dt_begin_tstz, i_prof) date_str,
                       pk_date_utils.date_char_hour_tsz(i_lang, scv.dt_begin_tstz, i_prof.institution, i_prof.software) hour_begin,
                       pk_date_utils.date_char_hour_tsz(i_lang, scv.dt_end_tstz, i_prof.institution, i_prof.software) hour_end,
                       extract(hour FROM scv.dt_end_tstz - scv.dt_begin_tstz) || 'h ' ||
                       extract(minute FROM scv.dt_end_tstz - scv.dt_begin_tstz) || 'm ' desc_duration,
                       pk_schedule.string_service(i_lang, scv.id_dep_clin_serv) desc_service,
                       pk_schedule.string_dep_clin_serv(i_lang, scv.id_dep_clin_serv) desc_dcs,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, scv.id_prof) nick_prof,
                       pk_schedule.string_room(i_lang, scv.id_room) desc_room,
                       pk_schedule.string_sch_type(i_lang, se.dep_type) desc_sch_type,
                       pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) desc_event,
                       scv.used_vacancies,
                       CASE scv.flg_status
                           WHEN g_status_active THEN
                            decode(flg_img,
                                   ' ',
                                   NULL,
                                   pk_sysdomain.get_img(i_lang, pk_schedule.g_sch_event_flg_img_domain, flg_img))
                           WHEN g_status_blocked THEN
                            decode(flg_img_blocked,
                                   NULL,
                                   NULL,
                                   pk_sysdomain.get_img(i_lang, g_dom_flg_img_blocked, flg_img_blocked))
                       END img_event,
                       scv.flg_status
                
                  FROM sch_consult_vacancy scv, sch_event se
                 WHERE scv.id_institution = i_prof.institution
                   AND (i_id_prof IS NULL OR scv.id_prof = i_id_prof)
                   AND scv.id_dep_clin_serv = i_id_dcs
                   AND (i_id_room IS NULL OR scv.id_room = i_id_room)
                   AND scv.id_sch_event = i_sch_event
                   AND (scv.dt_begin_tstz >= l_date_begin AND scv.dt_begin_tstz <= l_date_end)
                   AND (scv.dt_end_tstz <= l_date_end AND scv.dt_end_tstz >= l_date_begin)
                   AND scv.id_sch_event = se.id_sch_event;
        
            g_error := 'END O_DATA:';
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SCHEDULE_BO',
                                              i_function => 'GET_EVENTS_CANCELLED',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_events_cancelled;

--------------------------- PACKAGE INITIALIZATION ------------------------
BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
    -- Message stack.
    g_msg_stack := table_varchar(NULL);
END pk_schedule_bo;
/
