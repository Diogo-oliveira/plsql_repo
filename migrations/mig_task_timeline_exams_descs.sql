-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
DECLARE
    l_rank        task_timeline_ea.rank%TYPE;
    l_alias       exam_alias.code_exam_alias%TYPE;
    l_code_desc   exam_alias.code_exam_alias%TYPE;
    l_id_exam_cat exam.id_exam_cat%TYPE;
    l_alias_cat   exam_alias.code_exam_alias%TYPE;
    l_id_lang     language.id_language%TYPE;
    l_dt_harvest  harvest.dt_harvest_tstz%TYPE;

    FUNCTION get_alias_code_translation_ex
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN exam_alias.code_exam_alias%TYPE IS
    
        c_exam_alias pk_types.cursor_type;
        l_exam_alias exam_alias.code_exam_alias%TYPE;
    
    BEGIN
        OPEN c_exam_alias FOR
            SELECT (SELECT code_exam_alias
                      FROM exam_alias ea
                      JOIN exam e
                        ON ea.id_exam = e.id_exam
                     WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                           nvl(i_prof.institution, 0)
                       AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                       AND decode(nvl(id_professional, 0), 0, nvl(i_prof.id, 0), id_professional) = nvl(i_prof.id, 0)
                       AND decode(nvl(id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), id_dep_clin_serv) =
                           nvl(i_dep_clin_serv, 0)
                       AND e.code_exam = i_code_exam)
              FROM dual;
    
        FETCH c_exam_alias
            INTO l_exam_alias;
        CLOSE c_exam_alias;
    
        RETURN l_exam_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation_ex;

    FUNCTION get_alias_code_translation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_analysis IN analysis.code_analysis%TYPE,
        i_dep_clin_serv IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN analysis_alias.code_analysis_alias%TYPE IS
    
        c_analysis_alias pk_types.cursor_type;
        l_analysis_alias analysis_alias.code_analysis_alias%TYPE;
    BEGIN
    
        OPEN c_analysis_alias FOR
            SELECT (SELECT code_analysis_alias
                      FROM analysis_alias aa
                      JOIN analysis a
                        ON aa.id_analysis = a.id_analysis
                     WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                           nvl(i_prof.institution, 0)
                       AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                       AND decode(nvl(id_professional, 0), 0, nvl(i_prof.id, 0), id_professional) = nvl(i_prof.id, 0)
                       AND decode(nvl(id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), id_dep_clin_serv) =
                           nvl(i_dep_clin_serv, 0)
                       AND a.code_analysis = i_code_analysis)
              FROM dual;
    
        FETCH c_analysis_alias
            INTO l_analysis_alias;
        CLOSE c_analysis_alias;
    
        RETURN l_analysis_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation_an;

BEGIN
    FOR rec IN (SELECT *
                  FROM task_timeline_ea ttea
                 WHERE ttea.id_tl_task = 4)
    LOOP
        l_rank  := NULL;
        l_alias := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT ttea.code_description, e.id_exam_cat, il.id_language
              INTO l_code_desc, l_id_exam_cat, l_id_lang
              FROM exam_req_det erd
              JOIN task_timeline_ea ttea
                ON ttea.id_task_refid = erd.id_exam_req_det
               AND ttea.id_tl_task = 4
             INNER JOIN exam_req er
                ON (erd.id_exam_req = er.id_exam_req)
             INNER JOIN exam e
                ON (erd.id_exam = e.id_exam)
              LEFT JOIN institution_language il
                ON il.id_institution = ttea.id_institution
             WHERE erd.id_exam_req_det = rec.id_task_refid
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_code_desc   := NULL;
                l_id_exam_cat := NULL;
        END;
    
        l_alias := nvl(get_alias_code_translation_ex(nvl(l_id_lang, 1),
                                                     profissional(NULL, NULL, NULL),
                                                     l_code_desc,
                                                     NULL),
                       l_code_desc);
    
        l_alias_cat := nvl(get_alias_code_translation_ex(nvl(l_id_lang, 1),
                                                         profissional(NULL, NULL, NULL),
                                                         'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat,
                                                         NULL),
                           'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat);
    
        IF (l_alias IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_description = l_alias
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
        IF (l_alias_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_desc_group = l_alias_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
        IF (l_id_exam_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.id_group_import = l_id_exam_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
    END LOOP;

    FOR rec IN (SELECT *
                  FROM task_timeline_ea ttea
                 WHERE ttea.id_tl_task = 5)
    LOOP
        l_rank  := NULL;
        l_alias := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT ttea.code_description, ard.id_exam_cat, il.id_language, h.dt_harvest_tstz
              INTO l_code_desc, l_id_exam_cat, l_id_lang, l_dt_harvest
              FROM analysis_req_det ard
              JOIN task_timeline_ea ttea
                ON ttea.id_task_refid = ard.id_analysis_req_det
               AND ttea.id_tl_task = 5
             INNER JOIN analysis_req ar
                ON (ard.id_analysis_req = ar.id_analysis_req)
             INNER JOIN analysis a
                ON (ard.id_analysis = a.id_analysis)
              LEFT OUTER JOIN analysis_harvest ah
                ON ah.id_analysis_req_det = ard.id_analysis_req_det
              LEFT OUTER JOIN harvest h
                ON h.id_harvest = ah.id_harvest
              LEFT JOIN institution_language il
                ON il.id_institution = ttea.id_institution
             WHERE ard.id_analysis_req_det = rec.id_task_refid
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_code_desc   := NULL;
                l_id_exam_cat := NULL;
        END;
    
        l_alias := nvl(get_alias_code_translation_an(nvl(l_id_lang, 1),
                                                     profissional(NULL, NULL, NULL),
                                                     l_code_desc,
                                                     NULL),
                       l_code_desc);
    
        l_alias_cat := nvl(get_alias_code_translation_an(nvl(l_id_lang, 1),
                                                         profissional(NULL, NULL, NULL),
                                                         'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat,
                                                         NULL),
                           'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat);
    
        IF (l_alias IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_description = l_alias
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_alias_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_desc_group = l_alias_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_id_exam_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.id_group_import = l_id_exam_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_dt_harvest IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.dt_execution = l_dt_harvest
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
    END LOOP;
END;
/


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/Set/2011
-- CHANGE REASON: ALERT-168848 H & P reformulation in INPATIENT (phase 2)
DECLARE
    l_rank        task_timeline_ea.rank%TYPE;
    l_alias       exam_alias.code_exam_alias%TYPE;
    l_code_desc   exam_alias.code_exam_alias%TYPE;
    l_id_exam_cat exam.id_exam_cat%TYPE;
    l_alias_cat   exam_alias.code_exam_alias%TYPE;
    l_id_lang     language.id_language%TYPE;
    l_dt_harvest  harvest.dt_harvest_tstz%TYPE;

    FUNCTION get_alias_code_translation_ex
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional DEFAULT profissional(NULL, NULL, NULL),
        i_code_exam     IN exam.code_exam%TYPE,
        i_dep_clin_serv IN exam_alias.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN exam_alias.code_exam_alias%TYPE IS
    
        c_exam_alias pk_types.cursor_type;
        l_exam_alias exam_alias.code_exam_alias%TYPE;
    
    BEGIN
        OPEN c_exam_alias FOR
            SELECT (SELECT code_exam_alias
                      FROM exam_alias ea
                      JOIN exam e
                        ON ea.id_exam = e.id_exam
                     WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                           nvl(i_prof.institution, 0)
                       AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                       AND decode(nvl(id_professional, 0), 0, nvl(i_prof.id, 0), id_professional) = nvl(i_prof.id, 0)
                       AND decode(nvl(id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), id_dep_clin_serv) =
                           nvl(i_dep_clin_serv, 0)
                       AND e.code_exam = i_code_exam)
              FROM dual;
    
        FETCH c_exam_alias
            INTO l_exam_alias;
        CLOSE c_exam_alias;
    
        RETURN l_exam_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation_ex;

    FUNCTION get_alias_code_translation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_code_analysis IN analysis.code_analysis%TYPE,
        i_dep_clin_serv IN analysis_alias.id_dep_clin_serv%TYPE
    ) RETURN analysis_alias.code_analysis_alias%TYPE IS
    
        c_analysis_alias pk_types.cursor_type;
        l_analysis_alias analysis_alias.code_analysis_alias%TYPE;
    BEGIN
    
        OPEN c_analysis_alias FOR
            SELECT (SELECT code_analysis_alias
                      FROM analysis_alias aa
                      JOIN analysis a
                        ON aa.id_analysis = a.id_analysis
                     WHERE decode(id_institution, 0, nvl(i_prof.institution, 0), id_institution) =
                           nvl(i_prof.institution, 0)
                       AND decode(id_software, 0, nvl(i_prof.software, 0), id_software) = nvl(i_prof.software, 0)
                       AND decode(nvl(id_professional, 0), 0, nvl(i_prof.id, 0), id_professional) = nvl(i_prof.id, 0)
                       AND decode(nvl(id_dep_clin_serv, 0), 0, nvl(i_dep_clin_serv, 0), id_dep_clin_serv) =
                           nvl(i_dep_clin_serv, 0)
                       AND a.code_analysis = i_code_analysis)
              FROM dual;
    
        FETCH c_analysis_alias
            INTO l_analysis_alias;
        CLOSE c_analysis_alias;
    
        RETURN l_analysis_alias;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_alias_code_translation_an;

BEGIN
    FOR rec IN (SELECT *
                  FROM task_timeline_ea ttea
                 WHERE ttea.id_tl_task = 4)
    LOOP
        l_rank  := NULL;
        l_alias := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT ttea.code_description, e.id_exam_cat, il.id_language
              INTO l_code_desc, l_id_exam_cat, l_id_lang
              FROM exam_req_det erd
              JOIN task_timeline_ea ttea
                ON ttea.id_task_refid = erd.id_exam_req_det
               AND ttea.id_tl_task = 4
             INNER JOIN exam_req er
                ON (erd.id_exam_req = er.id_exam_req)
             INNER JOIN exam e
                ON (erd.id_exam = e.id_exam)
              LEFT JOIN institution_language il
                ON il.id_institution = ttea.id_institution
             WHERE erd.id_exam_req_det = rec.id_task_refid
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_code_desc   := NULL;
                l_id_exam_cat := NULL;
        END;
    
        l_alias := nvl(get_alias_code_translation_ex(nvl(l_id_lang, 1),
                                                     profissional(NULL, NULL, NULL),
                                                     l_code_desc,
                                                     NULL),
                       l_code_desc);
    
        l_alias_cat := nvl(get_alias_code_translation_ex(nvl(l_id_lang, 1),
                                                         profissional(NULL, NULL, NULL),
                                                         'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat,
                                                         NULL),
                           'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat);
    
        IF (l_alias IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_description = l_alias
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
        IF (l_alias_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_desc_group = l_alias_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
        IF (l_id_exam_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.id_group_import = l_id_exam_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 4;
        END IF;
    
    END LOOP;

    FOR rec IN (SELECT *
                  FROM task_timeline_ea ttea
                 WHERE ttea.id_tl_task = 5)
    LOOP
        l_rank  := NULL;
        l_alias := NULL;
        --check if there is some data in the data block 65
        BEGIN
            SELECT ttea.code_description, ard.id_exam_cat, il.id_language, h.dt_harvest_tstz
              INTO l_code_desc, l_id_exam_cat, l_id_lang, l_dt_harvest
              FROM analysis_req_det ard
              JOIN task_timeline_ea ttea
                ON ttea.id_task_refid = ard.id_analysis_req_det
               AND ttea.id_tl_task = 5
             INNER JOIN analysis_req ar
                ON (ard.id_analysis_req = ar.id_analysis_req)
             INNER JOIN analysis a
                ON (ard.id_analysis = a.id_analysis)
              LEFT OUTER JOIN analysis_harvest ah
                ON ah.id_analysis_req_det = ard.id_analysis_req_det
              LEFT OUTER JOIN harvest h
                ON h.id_harvest = ah.id_harvest
              LEFT JOIN institution_language il
                ON il.id_institution = ttea.id_institution
             WHERE ard.id_analysis_req_det = rec.id_task_refid
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_code_desc   := NULL;
                l_id_exam_cat := NULL;
        END;
    
        l_alias := nvl(get_alias_code_translation_an(nvl(l_id_lang, 1),
                                                     profissional(NULL, NULL, NULL),
                                                     l_code_desc,
                                                     NULL),
                       l_code_desc);
    
        l_alias_cat := nvl(get_alias_code_translation_an(nvl(l_id_lang, 1),
                                                         profissional(NULL, NULL, NULL),
                                                         'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat,
                                                         NULL),
                           'EXAM_CAT.CODE_EXAM_CAT.' || l_id_exam_cat);
    
        IF (l_alias IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_description = l_alias
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_alias_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.code_desc_group = l_alias_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_id_exam_cat IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.id_group_import = l_id_exam_cat
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
        IF (l_dt_harvest IS NOT NULL)
        THEN
            UPDATE task_timeline_ea ttea
               SET ttea.dt_execution = l_dt_harvest
             WHERE ttea.id_task_refid = rec.id_task_refid
               AND ttea.id_tl_task = 5;
        END IF;
    
    END LOOP;
END;
/
