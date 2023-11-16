/*-- Last Change Revision: $Rev: 2049318 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-11-08 08:27:45 +0000 (ter, 08 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_links IS

    FUNCTION set_link
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_link    IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_LINK',
                                              o_error);
            RETURN FALSE;
    END set_link;

    FUNCTION get_links
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_parent  IN external_link.id_parent%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_type   IN table_varchar,
        o_links      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_institution      institution.id_institution%TYPE;
        l_id_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_google_map_link VARCHAR2(1000 CHAR);
    
    BEGIN
    
        IF i_id_episode IS NOT NULL
        THEN
            SELECT id_institution
              INTO l_id_institution
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        ELSE
            l_id_institution := i_prof.institution;
        END IF;
    
        IF NOT get_google_map_link(i_lang, i_prof, i_id_patient, l_id_institution, l_google_map_link, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'get o_links';
        OPEN o_links FOR
            SELECT *
              FROM (SELECT elsi.id_external_link id_links,
                           pk_translation.get_translation(i_lang, el.code_external_link) label,
                           (SELECT el1.id_parent
                              FROM external_link el1
                             WHERE el1.id_external_link = el.id_parent) id_back,
                           substr(el.flg_type, 1, 1) flg_type,
                           decode(el.flg_type, 'LAPI', l_google_map_link, nvl(elsi.context_link, elsi.normal_link)) link,
                           decode(elsi.flg_visible,
                                  pk_alert_constant.g_yes,
                                  decode(el.flg_type, 'LAPI', l_google_map_link, nvl(elsi.context_link, elsi.normal_link)),
                                  '') link_description,
                           decode(elsi.context_link, NULL, g_normal_link, g_context_link) link_type,
                           CASE
                                WHEN elsi.context_link IS NULL
                                     AND elsi.normal_link IS NOT NULL THEN
                                 pk_alert_constant.g_yes
                                WHEN elsi.flg_context = 'E'
                                     AND i_id_patient IS NOT NULL THEN
                                 pk_alert_constant.g_yes
                                WHEN elsi.flg_context = 'P'
                                     AND i_id_episode IS NOT NULL THEN
                                 pk_alert_constant.g_yes
                                WHEN elsi.flg_context = 'B'
                                     AND i_id_episode IS NOT NULL
                                     AND i_id_patient IS NOT NULL THEN
                                 pk_alert_constant.g_yes
                                ELSE
                                 pk_alert_constant.g_no
                            END is_active,
                           CASE
                                WHEN substr(el.flg_type, 1, 1) = g_flg_folder THEN
                                 (SELECT COUNT(1)
                                    FROM external_link el1
                                   WHERE el1.flg_available = pk_alert_constant.g_available
                                     AND el1.id_parent = el.id_external_link)
                                ELSE
                                 NULL
                            END nr_elements,
                           decode(instr(el.flg_type, 'IA'), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_iav3,
                           elsi.rank
                      FROM external_link el, external_link_soft_inst elsi
                     WHERE el.flg_type IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            *
                                             FROM TABLE(i_flg_type) t)
                       AND nvl(el.id_parent, 0) = nvl(i_id_parent, 0)
                       AND el.flg_available = pk_alert_constant.g_available
                       AND el.id_external_link = elsi.id_external_link
                       AND elsi.id_institution = i_prof.institution
                       AND elsi.id_software = i_prof.software
                       AND elsi.id_profile_template IN (0, l_id_profile_template)
                       AND elsi.flg_available = pk_alert_constant.g_available)
             ORDER BY rank, upper(label);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LINKS',
                                              o_error);
            pk_types.open_my_cursor(o_links);
            RETURN FALSE;
    END get_links;

    FUNCTION get_links
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_parent  IN external_link.id_parent%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_links      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'get o_links';
        IF NOT get_links(i_lang       => i_lang,
                         i_prof       => i_prof,
                         i_id_parent  => i_id_parent,
                         i_id_patient => i_id_patient,
                         i_id_episode => i_id_episode,
                         i_flg_type   => table_varchar(pk_alert_constant.g_link_flg_f,
                                                       pk_alert_constant.g_link_flg_l,
                                                       g_flg_link_api,
                                                       g_flg_link_ia),
                         o_links      => o_links,
                         o_error      => o_error)
        THEN
            RETURN FALSE;
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
                                              'GET_LINKS',
                                              o_error);
            pk_types.open_my_cursor(o_links);
            RETURN FALSE;
    END get_links;

    FUNCTION get_google_map_link
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_link           OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_address VARCHAR2(1000 CHAR);
        l_person  patient.id_person%TYPE;
    
    BEGIN
    
        IF i_id_patient IS NOT NULL
        THEN
            SELECT id_person
              INTO l_person
              FROM patient p
             WHERE p.id_patient = i_id_patient;
        
            IF NOT pk_adt_api_out.get_complete_patient_address(i_lang, l_person, l_address)
            THEN
                IF NOT pk_backoffice.get_inst_adress(i_lang, i_prof, i_id_institution, l_address, o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        ELSE
            IF NOT pk_backoffice.get_inst_adress(i_lang, i_prof, i_id_institution, l_address, o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        l_address := REPLACE(l_address, ' ', '+');
    
        o_link := g_google_maps_url || l_address;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GOOGLE_MAP_LINK',
                                              o_error);
            RETURN FALSE;
    END get_google_map_link;

    FUNCTION get_links_label
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_links IN external_link.id_external_link%TYPE,
        i_sep      IN VARCHAR2 DEFAULT '<br>'
    ) RETURN VARCHAR2 IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_label VARCHAR2(1000 CHAR);
        l_sep   VARCHAR2(10 CHAR) DEFAULT '<br>';
    
    BEGIN
    
        IF i_sep IS NOT NULL
        THEN
            l_sep := i_sep;
        END IF;
    
        BEGIN
            g_error := 'get GET_LINKS_LABEL';
            SELECT pk_translation.get_translation(i_lang, 'EXTERNAL_LINK.CODE_EXTERNAL_LINK.' || elsi.id_external_link) ||
                   l_sep || elsi.normal_link label
              INTO l_label
              FROM external_link_soft_inst elsi
             WHERE elsi.id_external_link = i_id_links
               AND elsi.id_institution = i_prof.institution
               AND elsi.id_software = i_prof.software
               AND elsi.id_profile_template IN (0, l_id_profile_template)
               AND elsi.flg_available = pk_alert_constant.g_available;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    
        RETURN l_label;
    
    END get_links_label;

    FUNCTION get_links_val
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_content IN external_link.id_content%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_normal_link external_link_soft_inst.normal_link%TYPE;
    
    BEGIN
    
        g_error := 'GET_LINKS_LABEL';
        BEGIN
            SELECT elsi.context_link
              INTO l_normal_link
              FROM external_link el, external_link_soft_inst elsi
             WHERE el.id_content = i_id_content
               AND el.flg_available = pk_alert_constant.g_available
               AND el.id_external_link = elsi.id_external_link
               AND elsi.id_institution = i_prof.institution
               AND elsi.id_software = i_prof.software
               AND elsi.id_profile_template IN (0, l_id_profile_template)
               AND elsi.flg_available = pk_alert_constant.g_available;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    
        RETURN l_normal_link;
    
    END get_links_val;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_links;
/
