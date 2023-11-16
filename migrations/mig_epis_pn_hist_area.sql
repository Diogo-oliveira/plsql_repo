
-- CHANGED BY: António Neto
-- CHANGE DATE: 28/02/2012
-- CHANGE REASON: [ALERT-220775] Change database model - EDIS restructuring - Present Illness
DECLARE

    l_pn_area pn_area.id_pn_area%TYPE;

    FUNCTION get_prof_profile_template(i_prof IN alert.profissional) RETURN profile_template.id_profile_template%TYPE IS
        l_ptempl profile_template.id_profile_template%TYPE;
    BEGIN
    
        SELECT pt.id_profile_template
          INTO l_ptempl
          FROM prof_profile_template ppt, profile_template pt
         WHERE ppt.id_professional = i_prof.id
           AND ppt.id_institution = i_prof.institution
           AND ppt.id_software = i_prof.software
           AND ppt.id_profile_template = pt.id_profile_template
           AND ppt.id_software = pt.id_software
           AND pt.flg_available = 'Y'
           AND rownum = 1;
    
        RETURN l_ptempl;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END;

    FUNCTION get_id_category(i_prof IN alert.profissional) RETURN NUMBER IS
    
        CURSOR c_cat IS
            SELECT cat.id_category
              FROM category cat, professional prf, prof_cat prc
             WHERE prf.id_professional = i_prof.id
               AND prc.id_professional = prf.id_professional
               AND prc.id_institution = i_prof.institution
               AND cat.id_category = prc.id_category
               AND rownum = 1;
    
        l_cat category.id_category%TYPE;
    BEGIN
    
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        RETURN l_cat;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_id_category;

    FUNCTION get_pn_area
    (
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_market           IN market.id_market%TYPE DEFAULT 2,
        i_id_department       IN department.id_department%TYPE DEFAULT NULL,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_area                IN pn_area.internal_name%TYPE DEFAULT NULL,
        i_id_note_type        IN pn_note_type.id_pn_note_type%TYPE DEFAULT NULL,
        i_flg_scope           IN VARCHAR2
    ) RETURN pn_area.id_pn_area%TYPE IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE := i_id_profile_template;
        l_id_market           market.id_market%TYPE := i_id_market;
        l_id_department       department.id_department%TYPE := i_id_department;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_id_category         category.id_category%TYPE := i_id_category;
    
        l_pn_note_type_count PLS_INTEGER;
    
        l_id_pn_area pn_area.id_pn_area%TYPE;
    BEGIN
    
        IF l_id_profile_template IS NULL
        THEN
            l_id_profile_template := get_prof_profile_template(i_prof => i_prof);
        END IF;
    
        IF l_id_category IS NULL
        THEN
            l_id_category := get_id_category(i_prof => i_prof);
        END IF;
    
        BEGIN
            SELECT id_pn_area
              INTO l_id_pn_area
              FROM (SELECT nts.id_pn_area,
                           row_number() over(PARTITION BY nts.id_pn_area, nts.id_pn_note_type ORDER BY nts.id_software DESC NULLS LAST, nts.id_institution DESC NULLS LAST, nts.id_department DESC NULLS LAST, nts.id_dep_clin_serv DESC NULLS LAST, nts.id_profile_template DESC NULLS LAST, nts.id_category DESC NULLS LAST, nts.rank ASC NULLS LAST) rn
                    
                      FROM pn_note_type_soft_inst nts
                     INNER JOIN pn_area pna
                        ON nts.id_pn_area = pna.id_pn_area
                     WHERE nvl(nts.id_institution, 0) IN (0, i_prof.institution)
                       AND ((nvl(nts.id_software, 0) IN (0, i_prof.software) AND nts.flg_config_type = 'S') OR
                            nts.flg_config_type <> 'S')
                       AND (nvl(nts.id_department, 0) IN (0, l_id_department) OR l_id_department IS NULL)
                       AND (nvl(nts.id_dep_clin_serv, 0) IN (0, l_id_dep_clin_serv) OR l_id_dep_clin_serv IS NULL)
                       AND ((nvl(nts.id_profile_template, 0) IN (0, l_id_profile_template) AND nts.flg_config_type = 'P') OR
                            nts.flg_config_type <> 'P')
                       AND ((nvl(nts.id_category, -1) IN (-1, l_id_category) AND nts.flg_config_type = 'C') OR
                            nts.flg_config_type <> 'C')
                       AND nts.flg_available = 'Y'
                       AND ((pna.internal_name = i_area AND i_flg_scope = 'A') OR
                            (nts.id_pn_note_type = i_id_note_type AND i_flg_scope = 'N'))) t
             WHERE t.rn = 1
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_pn_area := NULL;
        END;
    
        IF l_id_pn_area IS NULL
        THEN
        
            SELECT id_pn_area
              INTO l_id_pn_area
              FROM (SELECT ntm.id_pn_area,
                           row_number() over(PARTITION BY ntm.id_pn_area, ntm.id_pn_note_type ORDER BY ntm.id_software DESC NULLS LAST, ntm.id_market DESC NULLS LAST, ntm.id_profile_template DESC NULLS LAST, ntm.id_category DESC NULLS LAST, ntm.rank ASC NULLS LAST) rn
                    
                      FROM pn_note_type_mkt ntm
                     INNER JOIN pn_area pna
                        ON ntm.id_pn_area = pna.id_pn_area
                     WHERE ((nvl(ntm.id_software, 0) IN (0, i_prof.software) AND ntm.flg_config_type = 'S') OR
                           ntm.flg_config_type <> 'S')
                       AND (nvl(ntm.id_market, 0) IN (0, l_id_market) OR l_id_market IS NULL)
                       AND ((nvl(ntm.id_profile_template, 0) IN (0, l_id_profile_template) AND ntm.flg_config_type = 'P') OR
                           ntm.flg_config_type <> 'P')
                       AND ((nvl(ntm.id_category, -1) IN (-1, l_id_category) AND ntm.flg_config_type = 'C') OR
                           ntm.flg_config_type <> 'C')
                       AND ((pna.internal_name = i_area AND i_flg_scope = 'A') OR
                           (ntm.id_pn_note_type = i_id_note_type AND i_flg_scope = 'N'))) t
             WHERE t.rn = 1
               AND rownum = 1;
        END IF;
    
        RETURN l_id_pn_area;
    END get_pn_area;
BEGIN

    FOR item IN (SELECT DISTINCT epnh.id_pn_note_type, --
                                 epnh.id_epis_pn,
                                 epnh.id_prof_create, --
                                 ei.id_dep_clin_serv, --
                                 e.id_episode, --
                                 e.id_institution, --
                                 ei.id_software, --
                                 e.id_department --
                   FROM epis_pn_hist epnh
                  INNER JOIN episode e
                     ON epnh.id_episode = e.id_episode
                  INNER JOIN epis_info ei
                     ON e.id_episode = ei.id_episode
                  INNER JOIN pn_note_type pnnt
                     ON epnh.id_pn_note_type = pnnt.id_pn_note_type
                  WHERE epnh.id_pn_area IS NULL)
    LOOP
    
        l_pn_area := get_pn_area(i_prof                => profissional(item.id_prof_create,
                                                                       item.id_institution,
                                                                       item.id_software),
                                 i_id_episode          => item.id_episode,
                                 i_id_profile_template => NULL,
                                 i_id_market           => 2,
                                 i_id_department       => item.id_department,
                                 i_id_dep_clin_serv    => item.id_dep_clin_serv,
                                 i_id_category         => NULL,
                                 i_area                => NULL,
                                 i_id_note_type        => item.id_pn_note_type,
                                 i_flg_scope           => 'N');
    
        UPDATE epis_pn_hist epnh
           SET epnh.id_pn_area = l_pn_area
         WHERE epnh.id_pn_area IS NULL
           AND epnh.id_epis_pn = item.id_epis_pn;
    END LOOP;

END;
/
--CHANGE END: António Neto
