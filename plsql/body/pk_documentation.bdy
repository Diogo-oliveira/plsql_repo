/*-- Last Change Revision: $Rev: 2026987 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_documentation AS

    k_doc_area_hpi         CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_HPI';
    k_doc_area_review_sys  CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_REVIEW_SYS';
    k_doc_area_family_hist CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_FAMILY_HIST';
    k_doc_area_social_hist CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_SOCIAL_HIST';
    k_doc_area_phys_exam   CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_PHYSICAL_EXAM';
    k_doc_area_plan        CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_PLAN';
    k_doc_area_ml          CONSTANT VARCHAR2(0050 CHAR) := 'VWR_DOC_AREA_MED_DOC';

    FUNCTION set_epis_complaint
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_complaint         IN complaint.id_complaint%TYPE,
        i_patient_complaint IN epis_complaint.patient_complaint%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar a queixa selecionada
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_EPIS  - ID do episódio
                                 I_COMPLAINT - ID da queixa
                                 I_PATIENT_COMPLAINT -  Texto
        
                  Saida: O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          ALTERAÇÃO: SF 2006/09/26
          NOTAS:
        *********************************************************************************/
        l_next epis_complaint.id_epis_complaint%TYPE;
        l_char VARCHAR2(1);
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis
               AND flg_status = g_flg_status;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se o episodio já existe
        g_error := 'GET CURSOR C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%FOUND;
        CLOSE c_episode;
        --
        IF g_found
        THEN
            g_error := 'GET SEQ_EPIS_COMPLAINT.NEXTVAL';
        
            SELECT seq_epis_complaint.nextval
              INTO l_next
              FROM dual;
            --
        
            g_error := 'UPDATE EPIS_COMPLAINT';
        
            UPDATE epis_complaint
               SET flg_status = g_complaint_inact
             WHERE id_episode = i_epis;
        
            UPDATE epis_bartchart eb
               SET eb.flg_status = 'I'
             WHERE eb.id_episode = i_epis;
        
            g_error := 'INSERT EPIS_COMPLAINT';
            INSERT INTO epis_complaint
                (id_epis_complaint,
                 id_episode,
                 id_professional,
                 id_complaint,
                 adw_last_update_tstz,
                 patient_complaint,
                 flg_status)
            VALUES
                (l_next, i_epis, i_prof.id, i_complaint, g_sysdate_tstz, i_patient_complaint, g_complaint_act);
        
        END IF;
        --
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_epis_complaint',
                                              o_error);
        
            ROLLBACK;
            RETURN FALSE;
    END set_epis_complaint;

    FUNCTION get_epis_complaint
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_complaint OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Devolver a lista de  queixas selecionadas para o episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_EPIS - ID do episódio
        
                  Saida: O_COMPLAINT - array que devolve todas as queixas
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          ALTERAÇÃO: SF 2006/09/26
          NOTAS:  Rever a situação em que o ID_COMPLAINT não está preenchido, como tratar??????????
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_COMPLAINT';
        OPEN o_complaint FOR
            SELECT ec.id_epis_complaint,
                   ec.id_complaint,
                   pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                   ec.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_date_utils.dt_chr_tsz(i_lang, ec.adw_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    ec.adw_last_update_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target,
                   ec.flg_status,
                   pk_sysdomain.get_domain('COMPLAINT.FLG_STATUS', ec.flg_status, i_lang) desc_status
              FROM epis_complaint ec, complaint c, professional p
             WHERE ec.id_complaint = c.id_complaint
               AND ec.id_episode = i_epis
               AND p.id_professional = ec.id_professional
             ORDER BY ec.adw_last_update_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_complaint',
                                              o_error);
            pk_types.open_my_cursor(o_complaint);
            RETURN FALSE;
    END get_epis_complaint;

    FUNCTION get_complaint_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_epis      IN episode.id_episode%TYPE,
        o_complaint OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar todas as queixas existentes
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_EPIS - ID do episódio
        
                  Saida: O_COMPLAINT - array que devolve todas as queixas
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/07/10
          ALTERAÇÃO: SF 2006/09/26
          NOTAS:
        *********************************************************************************/
    
        l_gender VARCHAR2(1);
        l_age    NUMBER;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_patient_gender IS
            SELECT p.gender, (SYSDATE - p.dt_birth) / 365 age
              FROM episode e, patient p
             WHERE e.id_episode = i_epis
               AND e.id_patient = p.id_patient;
    
    BEGIN
        -- Verificar se uma queixa com template associado
        g_error := 'GET CURSOR C_PATIENT_GENDER';
        pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
        OPEN c_patient_gender;
        FETCH c_patient_gender
            INTO l_gender, l_age;
        CLOSE c_patient_gender;
    
        g_error := 'GET CURSOR O_COMPLAINT';
        -- José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        OPEN o_complaint FOR
            SELECT c.id_complaint,
                   dtc.id_doc_template,
                   pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
              FROM complaint            c,
                   doc_template         ct,
                   doc_template_context dtc,
                   --esta subquery é necessária para filtrar opções com
                   --software=i_prof.software e software=0, para evitar repetidos
                   (SELECT id_context, id_institution, MAX(id_software) id_software, id_profile_template
                      FROM doc_template_context d
                     WHERE id_institution IN (i_prof.institution, 0)
                       AND id_software = i_prof.software
                       AND d.flg_type = g_flg_type_c
                     GROUP BY id_context, id_institution, id_profile_template) dtc2
             WHERE c.flg_available = g_available
               AND c.id_complaint NOT IN (SELECT ecomp.id_complaint
                                            FROM epis_complaint ecomp
                                           WHERE ecomp.id_episode = i_epis
                                             AND ecomp.flg_status = g_complaint_act)
                  --
               AND c.id_complaint = dtc.id_context
               AND dtc.id_doc_template = ct.id_doc_template
                  --
               AND dtc.id_context = dtc2.id_context
               AND dtc.id_institution = dtc2.id_institution
               AND dtc.id_software = dtc2.id_software
               AND dtc.id_profile_template = dtc2.id_profile_template
               AND dtc.flg_type = g_flg_type_c
                  --
               AND dtc.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution)
               AND (ct.flg_gender IS NULL OR ct.flg_gender = l_gender)
               AND (nvl(l_age, 0) BETWEEN nvl(ct.age_min, 0) AND nvl(ct.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)
             ORDER BY 3;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_complaint_list',
                                              o_error);
            pk_types.open_my_cursor(o_complaint);
            RETURN FALSE;
    END get_complaint_list;

    FUNCTION get_epis_complain_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        i_epis_complaint    IN epis_complaint.id_epis_complaint%TYPE,
        o_complaint         OUT pk_types.cursor_type,
        o_patient_complaint OUT pk_types.cursor_type,
        o_historian         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Obter o detalhe de uma queixa associada a um episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                                 I_EPIS_COMPLAINT - ID do registo da queixa
        
                  Saida: O_COMPLAINT - devolve a queixa
                                 O_PATIENT_COMPLAINT  - devolve a queixa do pacient
                                 O_HISTORIAN - devolve a história do paciente
                             O_ERROR - Erro
        
          CRIAÇÃO: SF 2006/09/27
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR  O_COMPLAINT';
        OPEN o_complaint FOR
            SELECT ecomp.id_epis_complaint,
                   pk_message.get_message(i_lang, 'EDIS_CHIEF_COMPLAINT_M002') desc_title_complaint,
                   pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    p.id_professional,
                                                    ecomp.adw_last_update_tstz,
                                                    ecomp.id_episode) desc_spec,
                   pk_date_utils.dt_chr_tsz(i_lang, ecomp.adw_last_update_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    ecomp.adw_last_update_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_target
              FROM epis_complaint ecomp, complaint c, professional p, speciality s
             WHERE ecomp.id_epis_complaint = i_epis_complaint
               AND ecomp.id_complaint = c.id_complaint
               AND ecomp.id_professional = p.id_professional(+)
               AND p.id_speciality = s.id_speciality(+);
    
        --
        g_error := 'GET CURSOR O_PATIENT_COMPLAINT';
        OPEN o_patient_complaint FOR
            SELECT ecomp.id_epis_complaint,
                   pk_message.get_message(i_lang, 'EDIS_CHIEF_COMPLAINT_M003') desc_title_complaint,
                   ecomp.patient_complaint
              FROM epis_complaint ecomp
             WHERE ecomp.id_epis_complaint = i_epis_complaint;
    
        g_error := 'GET CURSOR O_HISTORIAN';
        --OPEN O_HISTORIAN FOR SELECT '' FROM DUAL;
        pk_types.open_my_cursor(o_historian);
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_complain_det',
                                              o_error);
            pk_types.open_my_cursor(o_complaint);
            pk_types.open_my_cursor(o_patient_complaint);
            pk_types.open_my_cursor(o_historian);
            RETURN FALSE;
    END get_epis_complain_det;

    FUNCTION set_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN identification_notes.id_patient%TYPE,
        i_prof          IN profissional,
        i_notes         IN identification_notes.notes%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar as notas do paciente por episódio/ paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS - ID do episódio
                     I_ID_PAT - ID do paciente
                 I_PROF - ID do profissional
                 I_NOTES - Notas
                                 I_DOCUMENT_AREA - Área do documentation
        
                  Saida: O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/09
          NOTAS:
        *********************************************************************************/
        l_next identification_notes.id_identification_notes%TYPE;
        l_char VARCHAR2(1);
        --
        CURSOR c_patient IS
            SELECT 'X'
              FROM patient
             WHERE id_patient = i_id_pat;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se o paciente já existe
        g_error := 'GET CURSOR C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_char;
        g_found := c_patient%FOUND; --NOTFOUND;
        CLOSE c_patient;
        --
        IF g_found
        THEN
            g_error := 'GET SEQ_IDENTIFICATION_NOTES.NEXTVAL';
            SELECT seq_identification_notes.nextval
              INTO l_next
              FROM dual;
            --
            g_error := 'INSERT NOTES';
            INSERT INTO identification_notes
                (id_identification_notes,
                 id_patient,
                 notes,
                 flg_available,
                 dt_notes_tstz,
                 id_professional,
                 id_episode,
                 id_doc_area)
            VALUES
                (l_next, i_id_pat, i_notes, g_available, g_sysdate_tstz, i_prof.id, i_epis, i_document_area);
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_notes',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_notes;

    FUNCTION get_notes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN identification_notes.id_patient%TYPE,
        i_document_area IN doc_area.id_doc_area%TYPE,
        o_notes         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar as notas do paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - ID do profissional
                                 I_EPIS - ID do episódio
                     I_ID_PAT - ID do paciente
                                 I_DOCUMENT_AREA - Área do documentation
        
                  Saida: O_NOTES - Listar as notas associadas ao apciente / episódio
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_NOTES';
        OPEN o_notes FOR
            SELECT n.id_identification_notes,
                   n.notes,
                   pk_date_utils.date_send_tsz(i_lang, n.dt_notes_tstz, i_prof) dt_notes,
                   pk_date_utils.date_char_tsz(i_lang, n.dt_notes_tstz, i_prof.institution, i_prof.software) date_notes,
                   n.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, n.dt_notes_tstz, n.id_episode) desc_speciality
              FROM identification_notes n, professional p, speciality s
             WHERE n.id_professional = p.id_professional(+)
               AND s.id_speciality(+) = p.id_speciality
               AND n.id_patient = i_id_pat
               AND n.id_episode = i_epis
               AND n.id_doc_area = i_document_area
               AND n.flg_available = g_available;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_notes',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            RETURN FALSE;
    END get_notes;

    FUNCTION get_component_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_id_epis_bartchart OUT epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint    OUT pk_types.cursor_type,
        o_id_epis_complaint OUT epis_complaint.id_epis_complaint%TYPE,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os DOC_COMPONENTes associados a uma área para um dada Queixa
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - ID do profissional
                                 I_DOC_AREA- ID da área
                                 I_EPIS - ID do episódio
                                 O_ID_EPIS_COMPLAINT - Registo na EPIS_COMPLAINT para o episódio
        
                  Saida: O_ID_EPIS_COMPLAINT -
                                 O_ID_EPIS_DOCUMENTATION -
                                 O_DOC_COMPONENT - Listar os DOC_COMPONENTes associados a uma área
                                 O_ELEMENT - Listar os elementos associados aos DOC_COMPONENTes de uma àrea
                                 O_ELEMNT_STATUS - Listar os estados possiveis para os elementos associados aos DOC_COMPONENTes de uma àrea
                                 O_ELEMNT_ACTION - Listar as accções de elementos sobre outros elementos associados aos DOC_COMPONENTes de uma àrea                        O_ERROR - erro
        
          CRIAÇÃO: SF 2006/10/02
          NOTAS:
        *********************************************************************************/
        l_doc_template doc_template.id_doc_template%TYPE;
        l_gender       VARCHAR2(1);
        l_age          NUMBER;
        l_outp         NUMBER;
        l_care         NUMBER;
        l_pp           NUMBER;
    
        l_doc_templ_serv_default doc_template.id_doc_template%TYPE;
    
        CURSOR c_doc_complaint IS
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act;
    
        -- José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_doc_template IS
            SELECT dtc.id_doc_template
              FROM epis_complaint ec, complaint c, doc_template_context dtc
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act
               AND ec.id_complaint = c.id_complaint
                  --
               AND c.id_complaint = dtc.id_context
               AND dtc.flg_type = g_flg_type_c
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution);
        --
    
        CURSOR c_doc_template_serv IS
            SELECT ct.id_doc_template
              FROM epis_info ei, dep_clin_serv dcs, dept_template dt, doc_template ct
             WHERE ei.id_episode = i_epis
               AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.id_department = dt.id_department
               AND dt.id_doc_template = ct.id_doc_template
               AND dt.flg_available = g_available;
    
        CURSOR c_doc_template_cipe IS
            SELECT ic.id_doc_template
              FROM icnp_epis_intervention iei, icnp_composition ic
             WHERE iei.id_episode = i_epis
               AND iei.id_composition = ic.id_composition
               AND ic.id_doc_template IS NOT NULL;
    
        --
        CURSOR c_epis_docum(l_epis_complaint epis_complaint.id_epis_complaint%TYPE) IS
            SELECT eb.id_epis_documentation
              FROM epis_documentation eb
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_complaint = l_epis_complaint;
        --
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_patient_gender IS
            SELECT p.gender, (SYSDATE - p.dt_birth) / 365 age
              FROM episode e, patient p
             WHERE e.id_episode = i_epis
               AND e.id_patient = p.id_patient;
        --
    BEGIN
    
        l_doc_templ_serv_default := 58;
    
        -- CRS 2007/02/06
        g_error := 'GET CONFIG DOCUMENTATION_COMPLAINT';
        IF pk_sysconfig.get_config('DOCUMENTATION_COMPLAINT', i_prof) = 'Y'
        THEN
            g_error := 'GET CURSOR C_DOC_COMPLAINT';
            OPEN c_doc_complaint;
            FETCH c_doc_complaint
                INTO o_id_epis_complaint;
            CLOSE c_doc_complaint;
        END IF;
    
        g_error := 'GET CONFIG DOCUMENTATION_TEMPLATE_SERVICE';
        IF pk_sysconfig.get_config('DOCUMENTATION_TEMPLATE_SERVICE', i_prof) = 'Y'
        THEN
            g_error := 'GET CURSOR C_DOC_TEMPLATE_SERV';
            OPEN c_doc_template_serv;
            FETCH c_doc_template_serv
                INTO l_doc_template;
            g_found := c_doc_template_serv%FOUND;
            CLOSE c_doc_template_serv;
        
            IF NOT g_found
            THEN
                l_doc_template := l_doc_templ_serv_default;
                g_found        := TRUE;
            END IF;
        
        ELSE
            g_error := 'GET CURSOR C_DOC_TEMPLATE';
            OPEN c_doc_template;
            FETCH c_doc_template
                INTO l_doc_template;
            g_found := c_doc_template%FOUND;
            CLOSE c_doc_template;
        END IF;
    
        /*  IF I_PROF.SOFTWARE=8 THEN
        G_ERROR := 'GET CURSOR C_DOC_TEMPLATE'; Pk_Inp_Util.DO_LOG( 'PK_DOCUMENTATION', G_ERROR|| ' SFT:'||I_PROF.SOFTWARE );
        OPEN C_DOC_TEMPLATE;
        FETCH C_DOC_TEMPLATE INTO L_DOC_TEMPLATE, O_ID_EPIS_COMPLAINT;
        G_FOUND := C_DOC_TEMPLATE%FOUND;
        CLOSE C_DOC_TEMPLATE;
        ELSIF I_PROF.SOFTWARE=11 THEN
        G_ERROR := 'GET CURSOR C_DOC_TEMPLATE'; Pk_Inp_Util.DO_LOG( 'PK_DOCUMENTATION', G_ERROR || ' SFT:'||I_PROF.SOFTWARE );
        OPEN C_DOC_TEMPLATE_SERV ;
        FETCH C_DOC_TEMPLATE_SERV  INTO L_DOC_TEMPLATE;
        G_FOUND := C_DOC_TEMPLATE_SERV%FOUND;
        CLOSE C_DOC_TEMPLATE_SERV ;
        END IF;*/
        -- CRS 2007/02/06
        /*
        IF I_PROF.SOFTWARE=11 THEN
        G_ERROR := 'GET CURSOR C_DOC_TEMPLATE'; Pk_Inp_Util.DO_LOG( 'PK_DOCUMENTATION', G_ERROR || ' SFT:'||I_PROF.SOFTWARE );
        OPEN C_DOC_TEMPLATE_SERV ;
        FETCH C_DOC_TEMPLATE_SERV  INTO L_DOC_TEMPLATE;
        G_FOUND := C_DOC_TEMPLATE_SERV%FOUND;
        CLOSE C_DOC_TEMPLATE_SERV ;
        END IF;
        */
        g_error := 'GET CURSOR C_DOC_TEMPLATE';
        pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
        OPEN c_epis_docum(o_id_epis_complaint);
        FETCH c_epis_docum
            INTO o_id_epis_bartchart;
        CLOSE c_epis_docum;
    
        g_error := 'GET CURSOR C_PATIENT_GENDER';
        pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
        OPEN c_patient_gender;
        FETCH c_patient_gender
            INTO l_gender, l_age;
        CLOSE c_patient_gender;
        --
    
        l_outp := pk_sysconfig.get_config('SOFTWARE_ID_OUTP', i_prof);
        l_care := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
        l_pp   := pk_sysconfig.get_config('SOFTWARE_ID_CLINICS', i_prof);
    
        IF i_doc_area NOT IN (33, 34, 37, 43, 50, 51)
        THEN
            -- Norton scale, Braden scale, INP Aspectos Gerais, CIPE
            IF g_found
            THEN
                --
                g_error := 'GET CURSOR O_EPIS_COMPLAINT';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_epis_complaint FOR
                -- José Brito 12/03/2008
                -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
                    SELECT dtc.id_doc_template,
                           ec.id_epis_complaint,
                           pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM epis_complaint ec, complaint c, doc_template_context dtc
                     WHERE ec.id_episode = i_epis
                       AND ec.flg_status = g_complaint_act
                       AND ec.id_complaint = c.id_complaint
                          --
                       AND c.id_complaint = dtc.id_context
                       AND dtc.flg_type = g_flg_type_c
                       AND dtc.id_institution IN (i_prof.institution, 0)
                       AND dtc.id_software IN (i_prof.software, 0)
                       AND dtc.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution);
            
                /*
                OPEN o_epis_complaint FOR
                SELECT dt.id_doc_template,
                       ec.id_epis_complaint,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                  FROM epis_complaint ec, complaint c, doc_template dt
                 WHERE ec.id_episode = i_epis
                   AND ec.flg_status = g_complaint_act
                   AND ec.id_complaint = c.id_complaint
                   AND c.id_doc_template = dt.id_doc_template;
                */
            
                --
                g_error := 'GET CURSOR O_COMPONENT';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_component FOR
                    SELECT d.id_documentation,
                           dcomp.id_doc_component,
                           pk_translation.get_translation(i_lang, dcomp.code_doc_component) desc_doc_component,
                           dcomp.flg_type,
                           dd.x_position,
                           dd.height,
                           dd.width,
                           --D.VALUE_DOCUMENT_TYPE,
                           nvl((SELECT SUM(dd1.width)
                                 FROM doc_element de, doc_dimension dd1
                                WHERE de.id_documentation = d.id_documentation
                                  AND de.position = g_position_out
                                  AND de.flg_available = g_available
                                  AND dd1.id_doc_dimension = de.id_doc_dimension),
                               0) element_external_width
                      FROM doc_component dcomp, documentation d, doc_dimension dd
                     WHERE dcomp.id_doc_component = d.id_doc_component
                       AND dcomp.flg_available = g_available
                       AND d.id_doc_area = i_doc_area
                       AND d.id_doc_template = l_doc_template
                       AND dcomp.flg_available = g_available
                       AND d.flg_available = g_available
                       AND d.id_doc_dimension = dd.id_doc_dimension
                       AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender)
                       AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR
                           nvl(l_age, 0) = 0)
                     ORDER BY d.rank;
                --
                g_error := 'GET CURSOR O_ELEMENT';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_element FOR
                    SELECT d.id_documentation,
                           dcomp.id_doc_component,
                           de.id_doc_element,
                           --E.ID_ELEMENT,
                           pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                           --AM 27 Aug, 2008 - Flag position (de.position) is independent of language. Don't use sys_domain
                           decode(de.position,
                                  g_position_out,
                                  g_position_desc_out,
                                  g_position_in,
                                  g_position_desc_in,
                                  g_position_desc_in) position,
                           dd.height,
                           dd.width,
                           de.flg_type -- E.FLG_TYPE
                      FROM doc_component dcomp,
                           documentation d,
                           doc_dimension dd,
                           doc_element   de,
                           --ELEMENT E ,
                           doc_element_crit decr
                     WHERE dcomp.id_doc_component = d.id_doc_component(+)
                       AND dcomp.flg_available = g_available
                       AND d.id_doc_area = i_doc_area
                       AND d.id_doc_template = l_doc_template
                       AND dcomp.flg_available = g_available
                       AND d.flg_available = g_available
                       AND d.id_documentation = de.id_documentation
                       AND de.id_doc_dimension = dd.id_doc_dimension
                       AND de.flg_available = g_available
                       AND de.id_doc_element = decr.id_doc_element
                       AND decr.flg_default = g_default
                       AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                       AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR
                           nvl(l_age, 0) = 0)
                     ORDER BY d.rank, de.rank;
            
                --
                g_error := 'GET CURSOR O_ELEMNT_STATUS';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_elemnt_status FOR
                    SELECT d.id_documentation,
                           dcomp.id_doc_component,
                           de.id_doc_element,
                           decr.id_doc_element_crit,
                           pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                           pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                           pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_doc_criteria,
                           de.position, -- E.POSITION,
                           dd.height,
                           dd.width,
                           dc.flg_criteria,
                           decr.flg_default,
                           dc.element_color,
                           dc.text_color
                      FROM doc_component dcomp,
                           documentation d,
                           doc_dimension dd,
                           doc_element   de,
                           --ELEMENT E ,
                           doc_element_crit decr,
                           doc_criteria     dc
                     WHERE dcomp.id_doc_component = d.id_doc_component(+)
                       AND dcomp.flg_available = g_available
                       AND d.id_doc_area = i_doc_area
                       AND d.id_doc_template = l_doc_template
                       AND d.flg_available = g_available
                       AND d.id_documentation = de.id_documentation
                       AND de.id_doc_dimension = dd.id_doc_dimension
                       AND de.id_doc_element = decr.id_doc_element
                       AND decr.id_doc_criteria = dc.id_doc_criteria
                       AND de.flg_available = g_available
                       AND decr.flg_available = g_available
                       AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                     ORDER BY d.rank, de.rank, dc.rank;
            
                --
                g_error := 'GET CURSOR O_ELEMNT_ACTION';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_elemnt_action FOR
                    SELECT dac.id_doc_action_criteria,
                           dec1.id_doc_element id_doc_element_crit,
                           dac.id_doc_element_crit action_element_crit,
                           pk_translation.get_translation(i_lang, dec1.code_element_open) desc_element_crit,
                           dac.flg_action,
                           dac.id_elem_crit_action action_elem_crit_action,
                           dec2.id_doc_element id_doc_element_crit_action,
                           pk_translation.get_translation(i_lang, dec2.code_element_open) desc_element_crit_action
                      FROM doc_action_criteria dac,
                           doc_element_crit    dec1,
                           doc_element_crit    dec2,
                           doc_element         de1,
                           doc_element         de2,
                           documentation       d1,
                           documentation       d2
                     WHERE d1.id_doc_template = l_doc_template
                       AND d2.id_doc_template = l_doc_template
                       AND d1.id_doc_area = i_doc_area
                       AND d2.id_doc_area = i_doc_area
                       AND d1.flg_available = g_available
                       AND d2.flg_available = g_available
                       AND de1.flg_available = g_available
                       AND de2.flg_available = g_available
                          --  AND SE1.ID_ELEMENT=E1.ID_ELEMENT
                          --  AND SE2.ID_ELEMENT=E2.ID_ELEMENT
                       AND de1.id_documentation = d1.id_documentation
                       AND de2.id_documentation = d2.id_documentation
                       AND dec1.flg_available = g_available
                       AND dec2.flg_available = g_available
                       AND dec1.id_doc_element = de1.id_doc_element
                       AND dec2.id_doc_element = de2.id_doc_element
                       AND dac.flg_available = g_available
                       AND dac.id_doc_area = i_doc_area
                       AND dac.id_doc_element_crit = dec1.id_doc_element_crit
                       AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                     ORDER BY dac.id_doc_action_criteria;
            
                --
                g_error := 'GET CURSOR O_ELEMENT_EXCLUSIVE';
                pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
                OPEN o_element_exclusive FOR
                    SELECT der.id_doc_element_rel,
                           der.id_group,
                           de.id_doc_element,
                           d.id_documentation,
                           der.flg_type,
                           der.id_doc_element_rel_parent,
                           (SELECT der1.id_doc_element
                              FROM doc_element_rel der1
                             WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
                      FROM doc_element_rel der, doc_element de, documentation d
                     WHERE d.id_doc_template = l_doc_template
                       AND d.id_doc_area = i_doc_area
                       AND d.flg_available = g_available
                          --  AND SD2.ID_INSTITUTION=I_PROF.INSTITUTION
                       AND de.flg_available = g_available
                       AND de.id_documentation = d.id_documentation
                       AND der.flg_available = g_available
                       AND der.id_doc_element = de.id_doc_element
                     ORDER BY der.id_doc_element_rel;
            
            ELSE
                -- G_FOUND NOT FOUND
                pk_types.open_my_cursor(o_component);
                pk_types.open_my_cursor(o_element);
                pk_types.open_my_cursor(o_elemnt_status);
                pk_types.open_my_cursor(o_elemnt_action);
                pk_types.open_my_cursor(o_epis_complaint);
                pk_types.open_my_cursor(o_element_exclusive);
            END IF;
        
        ELSIF i_doc_area IN (33, 34, 37, 50, 51)
        THEN
            -- I_DOC_AREA IN (33,34, 37)
        
            g_error := 'GET CURSOR O_EPIS_COMPLAINT(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_epis_complaint FOR
            -- José Brito 12/03/2008
            -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
                SELECT dtc.id_doc_template,
                       ec.id_epis_complaint,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                  FROM epis_complaint ec, complaint c, doc_template_context dtc
                 WHERE ec.id_episode = i_epis
                   AND ec.flg_status = g_complaint_act
                   AND ec.id_complaint = c.id_complaint
                      --
                   AND c.id_complaint = dtc.id_context
                   AND dtc.flg_type = g_flg_type_c
                   AND dtc.id_institution IN (i_prof.institution, 0)
                   AND dtc.id_software IN (i_prof.software, 0)
                   AND dtc.id_profile_template IN
                       (SELECT ppt.id_profile_template
                          FROM prof_profile_template ppt
                         WHERE ppt.id_professional = i_prof.id
                           AND ppt.id_software = i_prof.software
                           AND ppt.id_institution = i_prof.institution);
            /*
            OPEN o_epis_complaint FOR
            SELECT dt.id_doc_template,
                   ec.id_epis_complaint,
                   pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
              FROM epis_complaint ec, complaint c, doc_template dt
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act
               AND ec.id_complaint = c.id_complaint
               AND c.id_doc_template = dt.id_doc_template;
              */
        
            --
            g_error := 'GET CURSOR O_COMPONENT(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_component FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       pk_translation.get_translation(i_lang, dcomp.code_doc_component) desc_doc_component,
                       dcomp.flg_type,
                       dd.x_position,
                       dd.height,
                       dd.width,
                       --D.VALUE_DOCUMENT_TYPE,
                       nvl((SELECT SUM(dd1.width)
                             FROM doc_element de, doc_dimension dd1
                            WHERE de.id_documentation = d.id_documentation
                              AND de.position = g_position_out
                              AND de.flg_available = g_available
                              AND dd1.id_doc_dimension = de.id_doc_dimension),
                           0) element_external_width
                  FROM doc_component dcomp, documentation d, doc_dimension dd
                 WHERE dcomp.id_doc_component = d.id_doc_component
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) -- L_DOC_TEMPLATE
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_doc_dimension = dd.id_doc_dimension
                   AND (dcomp.flg_gender IS NULL OR dcomp.flg_gender = l_gender)
                   AND (nvl(l_age, 0) BETWEEN nvl(dcomp.age_min, 0) AND nvl(dcomp.age_max, nvl(l_age, 0)) OR
                       nvl(l_age, 0) = 0)
                 ORDER BY d.rank;
            --
            g_error := 'GET CURSOR O_ELEMENT(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_element FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       --E.ID_ELEMENT,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       --AM 27 Aug, 2008 - Flag position (de.position) is independent of language. Don't use sys_domain
                       decode(de.position,
                              g_position_out,
                              g_position_desc_out,
                              g_position_in,
                              g_position_desc_in,
                              g_position_desc_in) position,
                       dd.height,
                       dd.width,
                       de.flg_type -- E.FLG_TYPE
                  FROM doc_component dcomp,
                       documentation d,
                       doc_dimension dd,
                       doc_element   de,
                       --ELEMENT E ,
                       doc_element_crit decr
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) --L_DOC_TEMPLATE
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                      -- AND DE.ID_ELEMENT=E.ID_ELEMENT
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.flg_available = g_available
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.flg_default = g_default
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                   AND (nvl(l_age, 0) BETWEEN nvl(de.age_min, 0) AND nvl(de.age_max, nvl(l_age, 0)) OR
                       nvl(l_age, 0) = 0)
                 ORDER BY d.rank, de.rank;
        
            --
            g_error := 'GET CURSOR O_ELEMNT_STATUS(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_elemnt_status FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       decr.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_doc_criteria,
                       de.position, -- E.POSITION,
                       dd.height,
                       dd.width,
                       dc.flg_criteria,
                       decr.flg_default,
                       dc.element_color,
                       dc.text_color
                  FROM doc_component dcomp,
                       documentation d,
                       doc_dimension dd,
                       doc_element   de,
                       --ELEMENT E ,
                       doc_element_crit decr,
                       doc_criteria     dc
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) --L_DOC_TEMPLATE
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.id_doc_criteria = dc.id_doc_criteria
                   AND de.flg_available = g_available
                   AND decr.flg_available = g_available
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                 ORDER BY d.rank, de.rank, dc.rank;
        
            --
            g_error := 'GET CURSOR O_ELEMNT_ACTION(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_elemnt_action FOR
                SELECT dac.id_doc_action_criteria,
                       dec1.id_doc_element id_doc_element_crit,
                       dac.id_doc_element_crit action_element_crit,
                       pk_translation.get_translation(i_lang, dec1.code_element_open) desc_element_crit,
                       dac.flg_action,
                       dac.id_elem_crit_action action_elem_crit_action,
                       dec2.id_doc_element id_doc_element_crit_action,
                       pk_translation.get_translation(i_lang, dec2.code_element_open) desc_element_crit_action
                  FROM doc_action_criteria dac,
                       doc_element_crit    dec1,
                       doc_element_crit    dec2,
                       doc_element         de1,
                       doc_element         de2,
                       documentation       d1,
                       documentation       d2
                 WHERE d1.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) --L_DOC_TEMPLATE
                   AND d2.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) --L_DOC_TEMPLATE
                   AND d1.id_doc_area = i_doc_area
                   AND d2.id_doc_area = i_doc_area
                   AND d1.flg_available = g_available
                   AND d2.flg_available = g_available
                   AND de1.flg_available = g_available
                   AND de2.flg_available = g_available
                      --  AND SE1.ID_ELEMENT=E1.ID_ELEMENT
                      --  AND SE2.ID_ELEMENT=E2.ID_ELEMENT
                   AND de1.id_documentation = d1.id_documentation
                   AND de2.id_documentation = d2.id_documentation
                   AND dec1.flg_available = g_available
                   AND dec2.flg_available = g_available
                   AND dec1.id_doc_element = de1.id_doc_element
                   AND dec2.id_doc_element = de2.id_doc_element
                   AND dac.flg_available = g_available
                   AND dac.id_doc_area = i_doc_area
                   AND dac.id_doc_element_crit = dec1.id_doc_element_crit
                   AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                 ORDER BY dac.id_doc_action_criteria;
        
            --
            g_error := 'GET CURSOR O_ELEMENT_EXCLUSIVE(2)';
            pk_inp_util.do_log('PK_DOCUMENTATION II', g_error);
            OPEN o_element_exclusive FOR
                SELECT der.id_doc_element_rel,
                       der.id_group,
                       de.id_doc_element,
                       d.id_documentation,
                       der.flg_type,
                       der.id_doc_element_rel_parent,
                       (SELECT der1.id_doc_element
                          FROM doc_element_rel der1
                         WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
                  FROM doc_element_rel der, doc_element de, documentation d
                 WHERE d.id_doc_template = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) --L_DOC_TEMPLATE
                   AND d.id_doc_area = i_doc_area
                   AND d.flg_available = g_available
                      --  AND SD2.ID_INSTITUTION=I_PROF.INSTITUTION
                   AND de.flg_available = g_available
                   AND de.id_documentation = d.id_documentation
                   AND der.flg_available = g_available
                   AND der.id_doc_element = de.id_doc_element
                 ORDER BY der.id_doc_element_rel;
        ELSE
            g_error := 'GET CURSOR C_DOC_TEMPLATE';
            OPEN c_doc_template_cipe;
            FETCH c_doc_template_cipe
                INTO l_doc_template;
            g_found := c_doc_template_cipe%FOUND;
            CLOSE c_doc_template_cipe;
        
            g_error := 'GET CURSOR O_EPIS_COMPLAINT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_epis_complaint FOR
                SELECT dt.id_doc_template,
                       iei.id_icnp_epis_interv,
                       pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_complaint
                  FROM icnp_epis_intervention iei, icnp_composition ic, doc_template dt
                 WHERE iei.id_episode = i_epis
                      --AND ec.flg_status = g_complaint_act
                   AND iei.id_composition = ic.id_composition
                   AND ic.id_doc_template = dt.id_doc_template;
            --
            g_error := 'GET CURSOR O_COMPONENT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_component FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       pk_translation.get_translation(i_lang, dcomp.code_doc_component) desc_doc_component,
                       dcomp.flg_type,
                       dd.x_position,
                       dd.height,
                       dd.width,
                       --D.VALUE_DOCUMENT_TYPE,
                       nvl((SELECT SUM(dd1.width)
                             FROM doc_element de, doc_dimension dd1
                            WHERE de.id_documentation = d.id_documentation
                              AND de.position = g_position_out
                              AND de.flg_available = g_available
                              AND dd1.id_doc_dimension = de.id_doc_dimension),
                           0) element_external_width
                  FROM doc_component dcomp, documentation d, doc_dimension dd
                 WHERE dcomp.id_doc_component = d.id_doc_component
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_doc_dimension = dd.id_doc_dimension
                 ORDER BY d.rank;
            --
            g_error := 'GET CURSOR O_ELEMENT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_element FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       --E.ID_ELEMENT,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       --AM 27 Aug, 2008 - Flag position (de.position) is independent of language. Don't use sys_domain
                       decode(de.position,
                              g_position_out,
                              g_position_desc_out,
                              g_position_in,
                              g_position_desc_in,
                              g_position_desc_in) position,
                       dd.height,
                       dd.width,
                       de.flg_type -- E.FLG_TYPE
                  FROM doc_component dcomp,
                       documentation d,
                       doc_dimension dd,
                       doc_element   de,
                       --ELEMENT E ,
                       doc_element_crit decr
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                      -- AND DE.ID_ELEMENT=E.ID_ELEMENT
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.flg_available = g_available
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.flg_default = g_default
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                 ORDER BY d.rank, de.rank;
        
            --
            g_error := 'GET CURSOR O_ELEMNT_STATUS(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_elemnt_status FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       decr.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_doc_criteria,
                       de.position, -- E.POSITION,
                       dd.height,
                       dd.width,
                       dc.flg_criteria,
                       decr.flg_default,
                       dc.element_color,
                       dc.text_color
                  FROM doc_component dcomp,
                       documentation d,
                       doc_dimension dd,
                       doc_element   de,
                       --ELEMENT E ,
                       doc_element_crit decr,
                       doc_criteria     dc
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.id_doc_criteria = dc.id_doc_criteria
                   AND de.flg_available = g_available
                   AND decr.flg_available = g_available
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                 ORDER BY d.rank, de.rank, dc.rank;
        
            --
            g_error := 'GET CURSOR O_ELEMNT_ACTION(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_elemnt_action FOR
                SELECT dac.id_doc_action_criteria,
                       dec1.id_doc_element id_doc_element_crit,
                       dac.id_doc_element_crit action_element_crit,
                       pk_translation.get_translation(i_lang, dec1.code_element_open) desc_element_crit,
                       dac.flg_action,
                       dac.id_elem_crit_action action_elem_crit_action,
                       dec2.id_doc_element id_doc_element_crit_action,
                       pk_translation.get_translation(i_lang, dec2.code_element_open) desc_element_crit_action
                  FROM doc_action_criteria dac,
                       doc_element_crit    dec1,
                       doc_element_crit    dec2,
                       doc_element         de1,
                       doc_element         de2,
                       documentation       d1,
                       documentation       d2
                 WHERE d1.id_doc_template = l_doc_template
                   AND d2.id_doc_template = l_doc_template
                   AND d1.id_doc_area = i_doc_area
                   AND d2.id_doc_area = i_doc_area
                   AND d1.flg_available = g_available
                   AND d2.flg_available = g_available
                   AND de1.flg_available = g_available
                   AND de2.flg_available = g_available
                      --  AND SE1.ID_ELEMENT=E1.ID_ELEMENT
                      --  AND SE2.ID_ELEMENT=E2.ID_ELEMENT
                   AND de1.id_documentation = d1.id_documentation
                   AND de2.id_documentation = d2.id_documentation
                   AND dec1.flg_available = g_available
                   AND dec2.flg_available = g_available
                   AND dec1.id_doc_element = de1.id_doc_element
                   AND dec2.id_doc_element = de2.id_doc_element
                   AND dac.flg_available = g_available
                   AND dac.id_doc_area = i_doc_area
                   AND dac.id_doc_element_crit = dec1.id_doc_element_crit
                   AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                 ORDER BY dac.id_doc_action_criteria;
        
            --
            g_error := 'GET CURSOR O_ELEMENT_EXCLUSIVE(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_element_exclusive FOR
                SELECT der.id_doc_element_rel,
                       der.id_group,
                       de.id_doc_element,
                       d.id_documentation,
                       der.flg_type,
                       der.id_doc_element_rel_parent,
                       (SELECT der1.id_doc_element
                          FROM doc_element_rel der1
                         WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
                  FROM doc_element_rel der, doc_element de, documentation d
                 WHERE d.id_doc_template = l_doc_template
                   AND d.id_doc_area = i_doc_area
                   AND d.flg_available = g_available
                      --  AND SD2.ID_INSTITUTION=I_PROF.INSTITUTION
                   AND de.flg_available = g_available
                   AND de.id_documentation = d.id_documentation
                   AND der.flg_available = g_available
                   AND der.id_doc_element = de.id_doc_element
                 ORDER BY der.id_doc_element_rel;
        
        END IF;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_component_list',
                                              o_error);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_epis_complaint);
            pk_types.open_my_cursor(o_element_exclusive);
            RETURN FALSE;
    END get_component_list;

    FUNCTION get_component_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_id_epis_bartchart OUT epis_documentation.id_epis_documentation%TYPE,
        o_epis_complaint    OUT pk_types.cursor_type,
        o_id_epis_complaint OUT epis_complaint.id_epis_complaint%TYPE,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os DOC_COMPONENTes associados a uma área para um dada Queixa
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - ID do profissional
                                 I_DOC_AREA- ID da área
                                 I_EPIS - ID do episódio
                                 O_ID_EPIS_COMPLAINT - Registo na EPIS_COMPLAINT para o episódio
        
                  Saida: O_ID_EPIS_COMPLAINT -
                                 O_ID_EPIS_DOCUMENTATION -
                                 O_DOC_COMPONENT - Listar os DOC_COMPONENTes associados a uma área
                                 O_ELEMENT - Listar os elementos associados aos DOC_COMPONENTes de uma àrea
                                 O_ELEMNT_STATUS - Listar os estados possiveis para os elementos associados aos DOC_COMPONENTes de uma àrea
                                 O_ELEMNT_ACTION - Listar as accções de elementos sobre outros elementos associados aos DOC_COMPONENTes de uma àrea                        O_ERROR - erro
        
          CRIAÇÃO: SF 2006/10/02
          NOTAS:
        *********************************************************************************/
        l_doc_template doc_template.id_doc_template%TYPE;
        l_gender       VARCHAR2(1);
        l_age          NUMBER;
    
        l_doc_templ_serv_default doc_template.id_doc_template%TYPE;
    
        CURSOR c_doc_complaint IS
            SELECT ec.id_epis_complaint
              FROM epis_complaint ec
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act;
    
        -- José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_doc_template IS
            SELECT dtc.id_doc_template
              FROM epis_complaint ec, complaint c, doc_template_context dtc
             WHERE ec.id_episode = i_epis
               AND ec.flg_status = g_complaint_act
               AND ec.id_complaint = c.id_complaint
                  --
               AND c.id_complaint = dtc.id_context
               AND dtc.flg_type = g_flg_type_c
               AND dtc.id_institution IN (i_prof.institution, 0)
               AND dtc.id_software IN (i_prof.software, 0)
               AND dtc.id_profile_template IN
                   (SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution);
    
        CURSOR c_doc_template_serv IS
            SELECT ct.id_doc_template
              FROM epis_info ei, dep_clin_serv dcs, dept_template dt, doc_template ct
             WHERE ei.id_episode = i_epis
               AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.id_department = dt.id_department
               AND dt.id_doc_template = ct.id_doc_template
               AND dt.flg_available = g_available;
    
        CURSOR c_doc_template_cipe IS
            SELECT ic.id_doc_template
              FROM icnp_epis_intervention iei, icnp_composition ic
             WHERE iei.id_icnp_epis_interv = i_interv
               AND iei.id_composition = ic.id_composition
               AND ic.id_doc_template IS NOT NULL;
    
        CURSOR c_epis_docum(l_epis_complaint epis_complaint.id_epis_complaint%TYPE) IS
            SELECT eb.id_epis_documentation
              FROM epis_documentation eb
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_complaint = l_epis_complaint;
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_patient_gender IS
            SELECT p.gender, (SYSDATE - p.dt_birth) / 365 age
              FROM episode e, patient p
             WHERE e.id_episode = i_epis
               AND e.id_patient = p.id_patient;
    
    BEGIN
    
        l_doc_templ_serv_default := 58;
    
        -- CRS 2007/02/06
        g_error := 'GET CONFIG DOCUMENTATION_COMPLAINT';
        IF pk_sysconfig.get_config('DOCUMENTATION_COMPLAINT', i_prof) = 'Y'
        THEN
            g_error := 'GET CURSOR C_DOC_COMPLAINT';
            OPEN c_doc_complaint;
            FETCH c_doc_complaint
                INTO o_id_epis_complaint;
            CLOSE c_doc_complaint;
        END IF;
    
        g_error := 'GET CONFIG DOCUMENTATION_TEMPLATE_SERVICE';
        IF pk_sysconfig.get_config('DOCUMENTATION_TEMPLATE_SERVICE', i_prof) = 'Y'
        THEN
            g_error := 'GET CURSOR C_DOC_TEMPLATE_SERV';
            OPEN c_doc_template_serv;
            FETCH c_doc_template_serv
                INTO l_doc_template;
            g_found := c_doc_template_serv%FOUND;
            CLOSE c_doc_template_serv;
        
            IF NOT g_found
            THEN
                l_doc_template := l_doc_templ_serv_default;
                g_found        := TRUE;
            END IF;
        
        ELSE
            g_error := 'GET CURSOR C_DOC_TEMPLATE';
            OPEN c_doc_template;
            FETCH c_doc_template
                INTO l_doc_template;
            g_found := c_doc_template%FOUND;
            CLOSE c_doc_template;
        END IF;
    
        g_error := 'GET CURSOR C_DOC_TEMPLATE';
        pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
        OPEN c_epis_docum(o_id_epis_complaint);
        FETCH c_epis_docum
            INTO o_id_epis_bartchart;
        CLOSE c_epis_docum;
    
        g_error := 'GET CURSOR C_PATIENT_GENDER';
        pk_inp_util.do_log('PK_DOCUMENTATION', g_error);
        OPEN c_patient_gender;
        FETCH c_patient_gender
            INTO l_gender, l_age;
        CLOSE c_patient_gender;
    
        IF i_doc_area = 43
        THEN
            g_error := 'GET CURSOR C_DOC_TEMPLATE';
            OPEN c_doc_template_cipe;
            FETCH c_doc_template_cipe
                INTO l_doc_template;
            g_found := c_doc_template_cipe%FOUND;
            CLOSE c_doc_template_cipe;
        
            g_error := 'GET CURSOR O_EPIS_COMPLAINT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_epis_complaint FOR
                SELECT dt.id_doc_template,
                       iei.id_icnp_epis_interv,
                       pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_complaint
                  FROM icnp_epis_intervention iei, icnp_composition ic, doc_template dt
                 WHERE iei.id_icnp_epis_interv = i_interv
                   AND iei.id_composition = ic.id_composition
                   AND ic.id_doc_template = dt.id_doc_template;
        
            g_error := 'GET CURSOR O_COMPONENT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_component FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       pk_translation.get_translation(i_lang, dcomp.code_doc_component) desc_doc_component,
                       dcomp.flg_type,
                       dd.x_position,
                       dd.height,
                       dd.width,
                       nvl((SELECT SUM(dd1.width)
                             FROM doc_element de, doc_dimension dd1
                            WHERE de.id_documentation = d.id_documentation
                              AND de.position = g_position_out
                              AND de.flg_available = g_available
                              AND dd1.id_doc_dimension = de.id_doc_dimension),
                           0) element_external_width
                  FROM doc_component dcomp, documentation d, doc_dimension dd
                 WHERE dcomp.id_doc_component = d.id_doc_component
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_doc_dimension = dd.id_doc_dimension
                 ORDER BY d.rank;
        
            g_error := 'GET CURSOR O_ELEMENT(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_element FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       --AM 27 Aug, 2008 - Flag position (de.position) is independent of language. Don't use sys_domain
                       decode(de.position,
                              g_position_out,
                              g_position_desc_out,
                              g_position_in,
                              g_position_desc_in,
                              g_position_desc_in) position,
                       dd.height,
                       dd.width,
                       de.flg_type
                  FROM doc_component dcomp, documentation d, doc_dimension dd, doc_element de, doc_element_crit decr
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND dcomp.flg_available = g_available
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.flg_available = g_available
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.flg_default = g_default
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                 ORDER BY d.rank, de.rank;
        
            g_error := 'GET CURSOR O_ELEMNT_STATUS(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_elemnt_status FOR
                SELECT d.id_documentation,
                       dcomp.id_doc_component,
                       de.id_doc_element,
                       decr.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_doc_criteria,
                       de.position,
                       dd.height,
                       dd.width,
                       dc.flg_criteria,
                       decr.flg_default,
                       dc.element_color,
                       dc.text_color
                  FROM doc_component    dcomp,
                       documentation    d,
                       doc_dimension    dd,
                       doc_element      de,
                       doc_element_crit decr,
                       doc_criteria     dc
                 WHERE dcomp.id_doc_component = d.id_doc_component(+)
                   AND dcomp.flg_available = g_available
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template = l_doc_template
                   AND d.flg_available = g_available
                   AND d.id_documentation = de.id_documentation
                   AND de.id_doc_dimension = dd.id_doc_dimension
                   AND de.id_doc_element = decr.id_doc_element
                   AND decr.id_doc_criteria = dc.id_doc_criteria
                   AND de.flg_available = g_available
                   AND decr.flg_available = g_available
                   AND (de.flg_gender IS NULL OR de.flg_gender = l_gender)
                 ORDER BY d.rank, de.rank, dc.rank;
        
            g_error := 'GET CURSOR O_ELEMNT_ACTION(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_elemnt_action FOR
                SELECT dac.id_doc_action_criteria,
                       dec1.id_doc_element id_doc_element_crit,
                       dac.id_doc_element_crit action_element_crit,
                       pk_translation.get_translation(i_lang, dec1.code_element_open) desc_element_crit,
                       dac.flg_action,
                       dac.id_elem_crit_action action_elem_crit_action,
                       dec2.id_doc_element id_doc_element_crit_action,
                       pk_translation.get_translation(i_lang, dec2.code_element_open) desc_element_crit_action
                  FROM doc_action_criteria dac,
                       doc_element_crit    dec1,
                       doc_element_crit    dec2,
                       doc_element         de1,
                       doc_element         de2,
                       documentation       d1,
                       documentation       d2
                 WHERE d1.id_doc_template = l_doc_template
                   AND d2.id_doc_template = l_doc_template
                   AND d1.id_doc_area = i_doc_area
                   AND d2.id_doc_area = i_doc_area
                   AND d1.flg_available = g_available
                   AND d2.flg_available = g_available
                   AND de1.flg_available = g_available
                   AND de2.flg_available = g_available
                   AND de1.id_documentation = d1.id_documentation
                   AND de2.id_documentation = d2.id_documentation
                   AND dec1.flg_available = g_available
                   AND dec2.flg_available = g_available
                   AND dec1.id_doc_element = de1.id_doc_element
                   AND dec2.id_doc_element = de2.id_doc_element
                   AND dac.flg_available = g_available
                   AND dac.id_doc_area = i_doc_area
                   AND dac.id_doc_element_crit = dec1.id_doc_element_crit
                   AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                 ORDER BY dac.id_doc_action_criteria;
        
            g_error := 'GET CURSOR O_ELEMENT_EXCLUSIVE(3)';
            pk_inp_util.do_log('PK_DOCUMENTATION III', g_error);
            OPEN o_element_exclusive FOR
                SELECT der.id_doc_element_rel,
                       der.id_group,
                       de.id_doc_element,
                       d.id_documentation,
                       der.flg_type,
                       der.id_doc_element_rel_parent,
                       (SELECT der1.id_doc_element
                          FROM doc_element_rel der1
                         WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
                  FROM doc_element_rel der, doc_element de, documentation d
                 WHERE d.id_doc_template = l_doc_template
                   AND d.id_doc_area = i_doc_area
                   AND d.flg_available = g_available
                   AND de.flg_available = g_available
                   AND de.id_documentation = d.id_documentation
                   AND der.flg_available = g_available
                   AND der.id_doc_element = de.id_doc_element
                 ORDER BY der.id_doc_element_rel;
        
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
                                              'get_component_list',
                                              o_error);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_epis_complaint);
            pk_types.open_my_cursor(o_element_exclusive);
            RETURN FALSE;
    END get_component_list;

    FUNCTION get_epis_triage_color
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis              IN episode.id_episode%TYPE,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar o detalhe das cores e acuidade para um tipo de triagem  e  qual a atribuída neste episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID profissional q regista
                                 I_EPIS - ID do episódio
        
                  Saida: O_EPIS_COLOR - Listar o detalhe das cores
                 O_ERROR - erro
        
          CRIAÇÃO: SF 2006/10/07
          NOTAS:
        *********************************************************************************/
        l_triage_type triage_type.id_triage_type%TYPE;
    BEGIN
        g_error       := 'GET TRIAGE_TYPE';
        l_triage_type := pk_edis_triage.get_triage_type(i_lang, i_prof, i_epis);
        --
        g_error := 'GET CURSOR O_EPIS_TRIAGE_COLOR';
        OPEN o_epis_triage_color FOR
            SELECT pk_translation.get_translation(i_lang, tc.code_accuity) desc_accuity,
                   tc.color,
                   tc.id_triage_color,
                   (SELECT et.id_triage_color
                      FROM epis_triage et
                     WHERE et.dt_begin_tstz IN (SELECT MAX(et1.dt_begin_tstz)
                                                  FROM epis_triage et1
                                                 WHERE et1.id_episode = i_epis)) color_episode
              FROM triage_color tc
             WHERE tc.id_triage_type = l_triage_type
               AND tc.flg_show = g_flg_show
               AND tc.flg_available = 'Y'
               AND EXISTS (SELECT 0
                      FROM triage t
                     WHERE t.id_triage_color = tc.id_triage_color)
             ORDER BY rank;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_triage_color',
                                              o_error);
            pk_types.open_my_cursor(o_epis_triage_color);
            RETURN FALSE;
    END get_epis_triage_color;

    FUNCTION get_element_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sys_docum IN documentation.id_documentation%TYPE,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os elementos associados a um DOC_COMPONENTe
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_PROF - ID do profissional
                                 I_SYS_DOCUM - ID da relação DOC_COMPONENTe/ area
        
                  Saida: O_ELEMENT - Listar os elementos associados a um DOC_COMPONENTe
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_ELEMENT';
        OPEN o_element FOR
            SELECT d.id_documentation,
                   de.id_doc_element,
                   de.age_max,
                   de.age_min,
                   de.flg_gender,
                   de.flg_type,
                   de.id_doc_element,
                   pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                   de.position
              FROM documentation d, doc_element de, doc_element_crit decr
             WHERE d.id_documentation = de.id_documentation
               AND de.id_doc_element = decr.id_doc_element
               AND d.id_documentation = i_sys_docum
               AND de.flg_available = g_available
             ORDER BY de.rank;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_element_list',
                                              o_error);
            pk_types.open_my_cursor(o_element);
            RETURN FALSE;
    END get_element_list;

    FUNCTION set_epis_bartchart
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis                 IN episode.id_episode%TYPE,
        i_document_area        IN doc_area.id_doc_area%TYPE,
        i_epis_complaint       IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation IN table_number,
        i_id_sys_element       IN table_number,
        i_id_sys_element_crit  IN table_number,
        i_value                IN table_varchar,
        i_notes                IN epis_documentation_det.notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                                 I_PATIENT_COMPLAINT - ID do registo na epis_complait activo no momento
        
                                 I_ID_DOCUMENTATION   - ID do DOCUMENTATION
                                 I_ID_DOC_ELEMENT- ID do DOCUMENTATION
                                 I_ID_DOC_ELEMENT_CRIT     - ID do DOCUMENTATION
                                 I_VALUE   - Array com os valores de cada ememento (quando exite um registo de hora, numero ou texto)
                                 I_NOTES   - Notas associadas a uma DOCUMENT_AREA
        
                  Saida: O_ERROR - Erro
        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
    
        l_ret    BOOLEAN;
        l_commit VARCHAR2(0050);
        error_epis_bartchart EXCEPTION;
        o_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        g_error  := 'SET_EPIS_BARTCHART';
        l_commit := 'N';
    
        l_ret := set_epis_bartchart(i_lang,
                                    i_prof,
                                    i_epis,
                                    i_document_area,
                                    i_epis_complaint,
                                    i_id_sys_documentation,
                                    i_id_sys_element,
                                    i_id_sys_element_crit,
                                    i_value,
                                    i_notes,
                                    l_commit,
                                    o_id_epis_documentation,
                                    o_error);
    
        IF l_ret = FALSE
        THEN
            g_error := 'Error calling set_epis_bartchar';
            RAISE error_epis_bartchart;
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_epis_bartchart',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_epis_bartchart;

    /* ***************************** */
    FUNCTION set_epis_bartchart
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis                  IN episode.id_episode%TYPE,
        i_document_area         IN doc_area.id_doc_area%TYPE,
        i_epis_complaint        IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation  IN table_number,
        i_id_sys_element        IN table_number,
        i_id_sys_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation_det.notes%TYPE,
        i_commit                IN VARCHAR2,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                                 I_PATIENT_COMPLAINT - ID do registo na epis_complait activo no momento
        
                                 I_ID_DOCUMENTATION   - ID do DOCUMENTATION
                                 I_ID_DOC_ELEMENT- ID do DOCUMENTATION
                                 I_ID_DOC_ELEMENT_CRIT     - ID do DOCUMENTATION
                                 I_VALUE   - Array com os valores de cada ememento (quando exite um registo de hora, numero ou texto)
                                 I_NOTES   - Notas associadas a uma DOCUMENT_AREA
                                 I_COMMIT  - VALOR Y/N PARA DETERMINAR SE PODE FAZER COMMIT
        
                  Saida: O_ERROR - Erro
                         O_ID_EPIS_DOCUMENTATION     ID_EPIS_DOCUMENTATION CRIADO        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
        l_next_epis_documentation     epis_documentation.id_epis_documentation%TYPE;
        l_next_epis_documentation_det epis_documentation_det.id_epis_documentation_det%TYPE;
        l_char                        VARCHAR2(1);
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis;
        -- comenatdo para poder inserir documentation em episodio inactivos
        --AND flg_status = g_flg_status;
    
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation
              FROM epis_documentation eb
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_complaint = i_epis_complaint;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se o episodio já existe
        g_error := 'GET CURSOR C_EPIS_DOCUM ';
        OPEN c_epis_docum;
        FETCH c_epis_docum
            INTO l_epis_documentation;
        g_found := c_epis_docum %FOUND;
        CLOSE c_epis_docum;
        --
        IF g_found
        THEN
            g_error := 'UPDATE EPIS_DOCUMENTATION';
            --
            UPDATE epis_documentation eb
               SET eb.id_prof_last_update = i_prof.id, eb.dt_last_update_tstz = g_sysdate_tstz
             WHERE eb.id_epis_documentation = l_epis_documentation;
        
            ------- ARRAY I_ID_DOCUMENTATION--------
            FOR i IN 1 .. i_id_sys_documentation.count
            LOOP
                --
                g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                SELECT seq_epis_documentation_det.nextval
                  INTO l_next_epis_documentation_det
                  FROM dual;
                --
                -- Criar NOVA LINHA DE DETALHE para a EPIS_DOCUMENTATION
                --
                g_error := ' INSERIR EPIS_DOCUMENTATION_DET(I)';
                --
                --DBMS_OUTPUT.PUT_LINE(G_ERROR);
                --
                INSERT INTO epis_documentation_det
                    (id_epis_documentation_det,
                     id_epis_documentation,
                     id_documentation,
                     id_doc_element,
                     id_doc_element_crit,
                     id_professional,
                     dt_creation_tstz,
                     VALUE,
                     notes,
                     adw_last_update)
                VALUES
                    (l_next_epis_documentation_det,
                     l_epis_documentation,
                     i_id_sys_documentation(i),
                     i_id_sys_element(i),
                     i_id_sys_element_crit(i),
                     i_prof.id,
                     g_sysdate_tstz,
                     i_value(i),
                     i_notes,
                     SYSDATE);
            
            END LOOP;
        
        ELSE
            -- Verificar se o episodio já existe
            g_error := 'GET CURSOR C_EPISODE';
            OPEN c_episode;
            FETCH c_episode
                INTO l_char;
            g_found := c_episode%FOUND;
            CLOSE c_episode;
            --
            IF g_found
            THEN
                g_error := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
                --
                SELECT seq_epis_documentation.nextval
                  INTO l_next_epis_documentation
                  FROM dual;
                --
                g_error := 'INSERT EPIS_DOCUMENTATION';
                INSERT INTO epis_documentation
                    (id_epis_documentation,
                     id_episode,
                     id_professional,
                     dt_creation_tstz,
                     id_prof_last_update,
                     dt_last_update_tstz,
                     flg_status,
                     id_doc_area,
                     id_epis_complaint)
                VALUES
                    (l_next_epis_documentation,
                     i_epis,
                     i_prof.id,
                     g_sysdate_tstz,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_epis_bartchart_act,
                     i_document_area,
                     i_epis_complaint);
            
                o_id_epis_documentation := l_next_epis_documentation;
            
                ------- ARRAY I_ID_DOCUMENTATION--------
                FOR i IN 1 .. i_id_sys_documentation.count
                LOOP
                
                    --DBMS_OUTPUT.PUT_LINE('ARRAY I_ID_DOCUMENTATION');
                    --
                    g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                    SELECT seq_epis_documentation_det.nextval
                      INTO l_next_epis_documentation_det
                      FROM dual;
                    --
                    -- Criar NOVA LINHA DE DETALHE para a EPIS_DOCUMENTATION
                    --
                    g_error := ' INSERIR EPIS_DOCUMENTATION_DET(I)';
                    --
                    --DBMS_OUTPUT.PUT_LINE(G_ERROR);
                    --
                    INSERT INTO epis_documentation_det
                        (id_epis_documentation_det,
                         id_epis_documentation,
                         id_documentation,
                         id_doc_element,
                         id_doc_element_crit,
                         id_professional,
                         dt_creation_tstz,
                         VALUE,
                         notes,
                         adw_last_update)
                    VALUES
                        (l_next_epis_documentation_det,
                         l_next_epis_documentation,
                         i_id_sys_documentation(i),
                         i_id_sys_element(i),
                         i_id_sys_element_crit(i),
                         i_prof.id,
                         g_sysdate_tstz,
                         i_value(i),
                         i_notes,
                         g_sysdate);
                
                END LOOP;
            END IF;
        
        END IF;
        --
        g_error := 'CALL SET_CODING_ELEMENT_CHART';
        IF NOT pk_medical_decision.set_coding_element_chart(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_epis          => i_epis,
                                                            i_document_area => i_document_area,
                                                            o_error         => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_epis,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
        IF i_prof.software = 11
        THEN
            g_error := 'CALL TO pk_inp_nurse.update_scales_task';
            IF NOT pk_inp_nurse.update_scales_task(i_lang     => i_lang,
                                                   i_episode  => i_epis,
                                                   i_doc_area => i_document_area,
                                                   i_prof     => i_prof,
                                                   o_error    => o_error)
            THEN
                o_error := o_error;
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        IF i_commit = 'Y'
        THEN
            COMMIT;
        END IF;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'set_epis_bartchart',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END set_epis_bartchart;

    /* ****************************** */
    FUNCTION get_epis_bartchart
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_last_update       OUT pk_types.cursor_type,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_epis_bartchart    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
        
        
        
                  Saida: O_LAST_UPDATE   -  informação de quem e quando fez a ultima actualização na bartchart
                                 O_EPIS_TRIAGE_COLOR - Cor de triagem actribuida ao episódio
                                 O_EPIS_DOCUMENTATION  - ultimo registo da chart
                                 O_ERROR - Erro
        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_triage_type        triage_type.id_triage_type%TYPE;
        l_doc_template       doc_template.id_doc_template%TYPE;
        --
        l_comp_filter   VARCHAR2(100);
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar cursor para aceitar 'l_dep_clin_serv' como parâmetro
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_docum_f(l_dcs dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                          --
                       AND d.id_dep_clin_serv = l_dcs
                          --
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        -- CHANGE: José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        /*
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation, dt.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   doc_template           dt,
                   epis_documentation_det ebd,
                   documentation          sd
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
               AND c.id_doc_template = dt.id_doc_template(+);
        */
        --
        CURSOR c_doc_template_cipe IS
            SELECT ic.id_doc_template
              FROM icnp_epis_intervention iei, icnp_composition ic
             WHERE iei.id_episode = i_epis
               AND iei.id_composition = ic.id_composition
               AND ic.id_doc_template IS NOT NULL;
        --
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error       := 'GET TRIAGE_TYPE';
        l_triage_type := pk_edis_triage.get_triage_type(i_lang, i_prof, i_epis);
        --
        IF l_triage_type IS NOT NULL
        THEN
            g_error := 'GET CURSOR O_EPIS_TRIAGE_COLOR';
            OPEN o_epis_triage_color FOR
                SELECT pk_translation.get_translation(i_lang, tc.code_accuity) desc_accuity,
                       tc.color,
                       tc.id_triage_color,
                       (SELECT et.id_triage_color
                          FROM epis_triage et
                         WHERE et.dt_begin_tstz IN (SELECT MAX(et1.dt_begin_tstz)
                                                      FROM epis_triage et1
                                                     WHERE et1.id_episode = i_epis)) color_episode
                  FROM triage_color tc
                 WHERE tc.id_triage_type = l_triage_type
                   AND tc.flg_show = g_flg_show
                   AND tc.flg_available = 'Y'
                   AND EXISTS (SELECT 0
                          FROM triage t
                         WHERE t.id_triage_color = tc.id_triage_color)
                 ORDER BY rank;
        ELSE
            pk_types.open_my_cursor(o_epis_triage_color);
        END IF;
        --
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar filtro...
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
    
        -- CHANGE: José Brito 27/03/2008
        -- Corrigido modo como é aplicado o filtro
        /*
        IF l_comp_filter = g_comp_filter_prf
        THEN
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
        */
        --ELSIF l_comp_filter = g_comp_filter_dcs
        IF l_comp_filter = g_comp_filter_dcs
        THEN
        
            g_error := 'FIND DCS';
            SELECT nvl(ei.id_dcs_requested, ei.id_dep_clin_serv)
              INTO l_dep_clin_serv
              FROM epis_info ei
             WHERE ei.id_episode = i_epis;
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum_f(l_dep_clin_serv);
            FETCH c_epis_docum_f
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum_f %FOUND;
            CLOSE c_epis_docum_f;
        
        ELSE
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
            --g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
            --RAISE g_exception;
        END IF;
        -- CHANGE END: José Brito
    
        /*
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
        */
    
        IF i_doc_area NOT IN (33, 34, 37, 43, 50, 51)
        THEN
            IF g_found
            THEN
            
                --
                g_error := 'GET CURSOR O_LAST_UPDATE';
                OPEN o_last_update FOR
                    SELECT eb.id_epis_documentation,
                           eb.id_prof_last_update,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                           pk_date_utils.date_send_tsz(i_lang, eb.dt_last_update_tstz, i_prof) dt_last_update,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, eb.dt_last_update_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            eb.dt_creation_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM epis_documentation eb, epis_complaint ec, complaint c, professional p
                     WHERE eb.id_epis_documentation = l_epis_documentation
                          --jsilva 26-04-2007 outer-joins
                       AND eb.id_epis_complaint = ec.id_epis_complaint(+)
                       AND ec.id_complaint = c.id_complaint(+)
                       AND eb.id_prof_last_update = p.id_professional;
                --
                g_error := 'GET CURSOR O_EPIS_BARTCHART';
                OPEN o_epis_bartchart FOR
                    SELECT d.id_documentation,
                           ebd.id_doc_element,
                           ebd.id_doc_element_crit,
                           pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                           pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                           pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                           pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                           ebd.value
                      FROM (SELECT ebd1.id_epis_documentation_det last_maximo,
                                   ebd1.id_documentation,
                                   ebd1.id_doc_element,
                                   max_elem.dt
                              FROM epis_documentation_det ebd1,
                                   (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                      FROM epis_documentation_det ebd2
                                     WHERE ebd2.id_epis_documentation = l_epis_documentation
                                     GROUP BY ebd2.id_documentation) max_elem
                             WHERE ebd1.dt_creation_tstz = max_elem.dt
                               AND ebd1.id_documentation = max_elem.id_documentation) LAST,
                           epis_documentation eb,
                           epis_documentation_det ebd,
                           documentation d,
                           doc_element de,
                           -- ELEMENT E,
                           doc_component    dc,
                           doc_element_crit decr,
                           doc_criteria     dcr
                     WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                       AND ebd.id_epis_documentation = l_epis_documentation
                       AND d.id_documentation(+) = ebd.id_documentation
                       AND d.id_doc_area = i_doc_area
                          --jsilva 26-04-2007 l_doc_template pode vir a null
                       AND d.id_doc_template = nvl(l_doc_template, d.id_doc_template)
                       AND de.id_doc_element = ebd.id_doc_element
                          -- AND  DE.ID_ELEMENT=E.ID_ELEMENT
                       AND d.id_doc_component = dc.id_doc_component(+)
                       AND dc.flg_available(+) = g_available
                       AND d.flg_available(+) = g_available
                       AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                       AND decr.id_doc_criteria = dcr.id_doc_criteria
                       AND last.last_maximo = ebd.id_epis_documentation_det
                     GROUP BY ebd.id_doc_element,
                              pk_translation.get_translation(i_lang, dc.code_doc_component),
                              pk_translation.get_translation(i_lang, decr.code_element_open),
                              ebd.value,
                              d.id_documentation,
                              ebd.id_doc_element_crit,
                              pk_translation.get_translation(i_lang, decr.code_element_close);
            
            ELSE
                pk_types.open_my_cursor(o_last_update);
                pk_types.open_my_cursor(o_epis_bartchart);
            END IF;
        ELSIF i_doc_area IN (33, 34, 37, 50, 51)
        THEN
        
            --
            g_error := 'GET CURSOR O_LAST_UPDATE';
            OPEN o_last_update FOR
                SELECT eb.id_epis_documentation,
                       eb.id_prof_last_update,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_send_tsz(i_lang, eb.dt_last_update_tstz, i_prof) dt_last_update,
                       pk_date_utils. date_chr_short_read_tsz(i_lang, eb.dt_last_update_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        eb.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                  FROM epis_documentation eb, epis_complaint ec, complaint c, professional p
                 WHERE eb.id_episode = i_epis
                   AND eb.id_epis_complaint = ec.id_epis_complaint
                   AND ec.id_complaint = c.id_complaint
                   AND eb.id_prof_last_update = p.id_professional;
            --
            g_error := 'GET CURSOR O_EPIS_BARTCHART';
            OPEN o_epis_bartchart FOR
                SELECT d.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                       pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       ebd.value
                  FROM (SELECT ebd1.id_epis_documentation_det last_maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                  FROM epis_documentation eb2, epis_documentation_det ebd2
                                 WHERE eb2.id_episode = i_epis
                                   AND eb2.id_epis_documentation = ebd2.id_epis_documentation
                                 GROUP BY ebd2.id_documentation) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation) LAST,
                       epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation d,
                       doc_element de,
                       -- ELEMENT E,
                       doc_component    dc,
                       doc_element_crit decr,
                       doc_criteria     dcr
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND eb.id_episode = i_epis
                   AND d.id_documentation(+) = ebd.id_documentation
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template(+) = decode(i_doc_area, 35, 58, 37, 57, 50, 1174, 51, 1175, 50) -- L_DOC_TEMPLATE
                   AND de.id_doc_element = ebd.id_doc_element
                      -- AND  DE.ID_ELEMENT=E.ID_ELEMENT
                   AND d.id_doc_component = dc.id_doc_component(+)
                   AND dc.flg_available(+) = g_available
                   AND d.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                   AND decr.id_doc_criteria = dcr.id_doc_criteria
                   AND eb.flg_status != 'C'
                   AND last.last_maximo = ebd.id_epis_documentation_det
                 GROUP BY ebd.id_doc_element,
                          pk_translation.get_translation(i_lang, dc.code_doc_component),
                          pk_translation.get_translation(i_lang, decr.code_element_open),
                          ebd.value,
                          d.id_documentation,
                          ebd.id_doc_element_crit,
                          pk_translation.get_translation(i_lang, decr.code_element_close);
        
        ELSE
            OPEN c_doc_template_cipe;
            FETCH c_doc_template_cipe
                INTO l_doc_template;
            g_found := c_doc_template_cipe%FOUND;
            CLOSE c_doc_template_cipe;
        
            --
            g_error := 'GET CURSOR O_LAST_UPDATE';
            OPEN o_last_update FOR
                SELECT ed.id_epis_documentation,
                       ed.id_prof_last_update,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                       pk_date_utils. date_chr_short_read_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ed.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_complaint
                  FROM epis_documentation ed, icnp_epis_intervention iei, icnp_composition ic, professional p
                 WHERE ed.id_episode = i_epis
                   AND ed.id_episode = iei.id_episode
                   AND iei.id_composition = ic.id_composition
                   AND ed.id_prof_last_update = p.id_professional;
            --
            g_error := 'GET CURSOR O_EPIS_BARTCHART';
            OPEN o_epis_bartchart FOR
                SELECT d.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                       pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       ebd.value
                  FROM (SELECT ebd1.id_epis_documentation_det last_maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                  FROM epis_documentation eb2, epis_documentation_det ebd2
                                 WHERE eb2.id_episode = i_epis
                                   AND eb2.id_epis_documentation = ebd2.id_epis_documentation
                                 GROUP BY ebd2.id_documentation) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation) LAST,
                       epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation d,
                       doc_element de,
                       -- ELEMENT E,
                       doc_component    dc,
                       doc_element_crit decr,
                       doc_criteria     dcr
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND eb.id_episode = i_epis
                   AND d.id_documentation(+) = ebd.id_documentation
                   AND d.id_doc_area = i_doc_area
                   AND d.id_doc_template(+) = l_doc_template
                   AND de.id_doc_element = ebd.id_doc_element
                      -- AND  DE.ID_ELEMENT=E.ID_ELEMENT
                   AND d.id_doc_component = dc.id_doc_component(+)
                   AND dc.flg_available(+) = g_available
                   AND d.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                   AND decr.id_doc_criteria = dcr.id_doc_criteria
                   AND eb.flg_status != 'C'
                   AND last.last_maximo = ebd.id_epis_documentation_det
                 GROUP BY ebd.id_doc_element,
                          pk_translation.get_translation(i_lang, dc.code_doc_component),
                          pk_translation.get_translation(i_lang, decr.code_element_open),
                          ebd.value,
                          d.id_documentation,
                          ebd.id_doc_element_crit,
                          pk_translation.get_translation(i_lang, decr.code_element_close);
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_bartchart',
                                              o_error);
            pk_types.open_my_cursor(o_epis_triage_color);
            pk_types.open_my_cursor(o_last_update);
            pk_types.open_my_cursor(o_epis_bartchart);
            RETURN FALSE;
    END get_epis_bartchart;

    FUNCTION get_epis_bartchart
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        i_interv            IN icnp_epis_intervention.id_icnp_epis_interv%TYPE,
        o_last_update       OUT pk_types.cursor_type,
        o_epis_triage_color OUT pk_types.cursor_type,
        o_epis_bartchart    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                     I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
        
        
        
                  Saida: O_LAST_UPDATE   -  informação de quem e quando fez a ultima actualização na bartchart
                                 O_EPIS_TRIAGE_COLOR - Cor de triagem actribuida ao episódio
                                 O_EPIS_DOCUMENTATION  - ultimo registo da chart
                                 O_ERROR - Erro
        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_triage_type        triage_type.id_triage_type%TYPE;
    
        l_doc_template doc_template.id_doc_template%TYPE;
        --
        l_comp_filter   VARCHAR2(100);
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar cursor para aceitar 'l_dep_clin_serv' como parâmetro
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_docum_f(l_dcs dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                          ------ COLOCADO AQUI O PARÂMETRO DE ENTRADA??
                       AND d.id_dep_clin_serv = l_dcs
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        -- CHANGE: José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        /*
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation, dt.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   doc_template           dt,
                   epis_documentation_det ebd,
                   documentation          sd
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE eb.id_episode = i_epis
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
               AND c.id_doc_template = dt.id_doc_template(+);
        */
        --
        CURSOR c_doc_template_cipe IS
            SELECT ic.id_doc_template
              FROM icnp_epis_intervention iei, icnp_composition ic
             WHERE iei.id_icnp_epis_interv = i_interv
               AND iei.id_composition = ic.id_composition
               AND ic.id_doc_template IS NOT NULL;
        --
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'GET TRIAGE_TYPE';
        --
        l_triage_type := pk_edis_triage.get_triage_type(i_lang, i_prof, i_epis);
        --
        IF l_triage_type IS NOT NULL
        THEN
            g_error := 'GET CURSOR O_EPIS_TRIAGE_COLOR';
            OPEN o_epis_triage_color FOR
                SELECT pk_translation.get_translation(i_lang, tc.code_accuity) desc_accuity,
                       tc.color,
                       tc.id_triage_color,
                       (SELECT et.id_triage_color
                          FROM epis_triage et
                         WHERE et.dt_begin_tstz IN (SELECT MAX(et1.dt_begin_tstz)
                                                      FROM epis_triage et1
                                                     WHERE et1.id_episode = i_epis)) color_episode
                  FROM triage_color tc
                 WHERE tc.id_triage_type = l_triage_type
                   AND tc.flg_show = g_flg_show
                   AND tc.flg_available = 'Y'
                   AND EXISTS (SELECT 0
                          FROM triage t
                         WHERE t.id_triage_color = tc.id_triage_color)
                 ORDER BY rank;
        ELSE
            pk_types.open_my_cursor(o_epis_triage_color);
        END IF;
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar filtro...
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
    
        -- CHANGE: José Brito 27/03/2008
        -- Corrigido modo como é aplicado o filtro
        /*
        IF l_comp_filter = g_comp_filter_prf
        THEN
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
        */
        --ELSIF l_comp_filter = g_comp_filter_dcs
        IF l_comp_filter = g_comp_filter_dcs
        THEN
        
            g_error := 'FIND DCS';
            SELECT nvl(ei.id_dcs_requested, ei.id_dep_clin_serv)
              INTO l_dep_clin_serv
              FROM epis_info ei
             WHERE ei.id_episode = i_epis;
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum_f(l_dep_clin_serv);
            FETCH c_epis_docum_f
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum_f %FOUND;
            CLOSE c_epis_docum_f;
        
        ELSE
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
            --g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
            --RAISE g_exception;
        END IF;
        -- CHANGE END: José Brito
    
        /*
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_docum;
            FETCH c_epis_docum
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_docum %FOUND;
            CLOSE c_epis_docum;
        */
    
        IF i_doc_area = 43
        THEN
            OPEN c_doc_template_cipe;
            FETCH c_doc_template_cipe
                INTO l_doc_template;
            g_found := c_doc_template_cipe%FOUND;
            CLOSE c_doc_template_cipe;
        
            g_error := 'GET CURSOR O_LAST_UPDATE';
            OPEN o_last_update FOR
                SELECT ed.id_epis_documentation,
                       ed.id_prof_last_update,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_send_tsz(i_lang, ed.dt_last_update_tstz, i_prof) dt_last_update,
                       pk_date_utils. date_chr_short_read_tsz(i_lang, ed.dt_last_update_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ed.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_translation.get_translation(i_lang, ic.code_icnp_composition) desc_complaint
                  FROM epis_documentation ed, icnp_epis_intervention iei, icnp_composition ic, professional p
                 WHERE ed.id_episode = i_epis
                   AND ed.id_episode = iei.id_episode
                   AND iei.id_composition = ic.id_composition
                   AND ed.id_prof_last_update = p.id_professional;
        
            g_error := 'GET CURSOR O_EPIS_BARTCHART';
            OPEN o_epis_bartchart FOR
                SELECT d.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                       pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                       pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                       pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                       ebd.value
                  FROM (SELECT ebd1.id_epis_documentation_det last_maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                  FROM epis_documentation eb2, epis_documentation_det ebd2
                                 WHERE eb2.id_episode = i_epis
                                   AND eb2.id_epis_documentation = ebd2.id_epis_documentation
                                 GROUP BY ebd2.id_documentation) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation) LAST,
                       epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation d,
                       doc_element de,
                       doc_component dc,
                       doc_element_crit decr,
                       doc_criteria dcr
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND eb.id_episode = i_epis
                   AND d.id_documentation(+) = ebd.id_documentation
                   AND d.id_doc_area = i_doc_area
                   AND de.id_doc_element = ebd.id_doc_element
                   AND d.id_doc_component = dc.id_doc_component(+)
                   AND dc.flg_available(+) = g_available
                   AND d.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                   AND decr.id_doc_criteria = dcr.id_doc_criteria
                   AND eb.flg_status != 'C'
                   AND last.last_maximo = ebd.id_epis_documentation_det
                 GROUP BY ebd.id_doc_element,
                          pk_translation.get_translation(i_lang, dc.code_doc_component),
                          pk_translation.get_translation(i_lang, decr.code_element_open),
                          ebd.value,
                          d.id_documentation,
                          ebd.id_doc_element_crit,
                          pk_translation.get_translation(i_lang, decr.code_element_close);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_bartchart',
                                              o_error);
            pk_types.open_my_cursor(o_epis_triage_color);
            pk_types.open_my_cursor(o_last_update);
            pk_types.open_my_cursor(o_epis_bartchart);
            RETURN FALSE;
    END get_epis_bartchart;

    FUNCTION get_epis_bartchart_comp
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_doc_area             IN doc_area.id_doc_area%TYPE,
        i_epis                 IN episode.id_episode%TYPE,
        i_flg_show             IN VARCHAR2,
        i_id_sys_documentation IN documentation.id_documentation%TYPE,
        i_id_epis_bartchart    IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_bartchart_comp  OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                        uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                  I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                                 I_BARTCHART
                                 I_SHOW -  modo de visualização
                                 I_DOCUMENTATION - DOC_COMPONENTe para o qual quer ver registos
        
               Saida: EPIS_DOCUMENTATION_COMP -  ultimo registo mediate o modo de visualização
                                 O_ERROR - Erro
        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        --
        CURSOR c_epis_docum IS
            SELECT eb.id_epis_documentation
              FROM epis_documentation eb
             WHERE eb.id_epis_documentation = i_id_epis_bartchart;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
    
        -- Verificar se já existe uma bartchart
        g_error := 'GET CURSOR C_EPIS_DOCUM ';
        OPEN c_epis_docum;
        FETCH c_epis_docum
            INTO l_epis_documentation;
        g_found := c_epis_docum %FOUND;
        CLOSE c_epis_docum;
    
        IF i_doc_area NOT IN (33, 34)
        THEN
            IF g_found
            THEN
                --- Mostrar todos os registos anteriores para este DOC_COMPONENTe
                IF i_flg_show = 'SA'
                THEN
                    g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SA';
                    OPEN o_epis_bartchart_comp FOR
                        SELECT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                               eb.id_epis_documentation,
                               d.id_documentation,
                               ebd.id_doc_element,
                               ebd.id_doc_element_crit,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                               ebd.value,
                               p.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                ebd.dt_creation_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) hour_target,
                               last.maximo,
                               pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                               eb.id_epis_documentation
                          FROM epis_documentation eb,
                               epis_documentation_det ebd,
                               documentation d,
                               doc_element de,
                               doc_component dc,
                               doc_element_crit decr,
                               doc_criteria dcr,
                               professional p,
                               (SELECT ebd1.id_epis_documentation_det maximo,
                                       ebd1.id_documentation,
                                       ebd1.id_doc_element,
                                       max_elem.dt
                                  FROM epis_documentation_det ebd1,
                                       (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                          FROM epis_documentation_det ebd2
                                         WHERE ebd2.id_epis_documentation = i_id_epis_bartchart
                                           AND ebd2.id_professional = i_prof.id
                                         GROUP BY ebd2.id_documentation) max_elem
                                 WHERE ebd1.dt_creation_tstz = max_elem.dt
                                   AND ebd1.id_documentation = max_elem.id_documentation) LAST
                         WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                           AND ebd.id_epis_documentation = i_id_epis_bartchart
                           AND d.id_documentation = i_id_sys_documentation
                           AND d.id_documentation(+) = ebd.id_documentation
                           AND d.id_doc_area(+) = i_doc_area
                           AND de.id_doc_element = ebd.id_doc_element
                              --AND DE.ID_ELEMENT=E.ID_ELEMENT
                           AND d.id_doc_component = dc.id_doc_component(+)
                           AND dcr.flg_available(+) = g_available
                           AND d.flg_available(+) = g_available
                           AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                           AND decr.id_doc_criteria = dcr.id_doc_criteria
                           AND ebd.id_professional = p.id_professional
                           AND last.maximo(+) = ebd.id_epis_documentation_det
                         ORDER BY ebd.dt_creation_tstz DESC;
                
                    --- Mostrar os ultimos registos anteriores para este DOC_COMPONENTe
                ELSIF i_flg_show = 'SL'
                THEN
                
                    g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SL';
                    OPEN o_epis_bartchart_comp FOR
                        SELECT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                               eb.id_epis_documentation,
                               d.id_documentation,
                               ebd.id_doc_element,
                               ebd.id_doc_element_crit,
                               pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                               ebd.value,
                               p.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                ebd.dt_creation_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) hour_target,
                               last.last_maximo maximo
                          FROM epis_documentation     eb,
                               epis_documentation_det ebd,
                               documentation          d,
                               doc_element            de,
                               -- ELEMENT E,
                               doc_component dc,
                               doc_element_crit decr,
                               doc_criteria dcr,
                               professional p,
                               (SELECT ebd3.id_epis_documentation_det doc_maximo,
                                       ebd3.id_documentation,
                                       ebd3.id_doc_element,
                                       max_elem.dt                    doc_dt
                                  FROM epis_documentation_det ebd3,
                                       (SELECT MAX(ebd4.dt_creation_tstz) dt, ebd4.id_documentation
                                          FROM epis_documentation_det ebd4
                                         WHERE ebd4.id_epis_documentation = i_id_epis_bartchart
                                         GROUP BY ebd4.id_documentation) max_elem
                                 WHERE ebd3.dt_creation_tstz = max_elem.dt
                                   AND ebd3.id_documentation = max_elem.id_documentation) doc,
                               (SELECT ebd1.id_epis_documentation_det last_maximo,
                                       ebd1.id_documentation,
                                       ebd1.id_doc_element,
                                       max_elem.dt
                                  FROM epis_documentation_det ebd1,
                                       (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                          FROM epis_documentation_det ebd2
                                         WHERE ebd2.id_epis_documentation = i_id_epis_bartchart
                                           AND ebd2.id_professional = i_prof.id
                                         GROUP BY ebd2.id_documentation) max_elem
                                 WHERE ebd1.dt_creation_tstz = max_elem.dt
                                   AND ebd1.id_documentation = max_elem.id_documentation) LAST
                         WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                           AND ebd.id_epis_documentation = i_id_epis_bartchart
                           AND d.id_documentation = i_id_sys_documentation
                           AND d.id_documentation(+) = ebd.id_documentation
                           AND d.id_doc_area(+) = i_doc_area
                           AND de.id_doc_element = ebd.id_doc_element
                              --AND DE.ID_ELEMENT=E.ID_ELEMENT
                           AND d.id_doc_component = dc.id_doc_component(+)
                           AND dc.flg_available(+) = g_available
                           AND d.flg_available(+) = g_available
                           AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                           AND decr.id_doc_criteria = dcr.id_doc_criteria
                           AND ebd.id_professional = p.id_professional
                           AND last.last_maximo(+) = doc.doc_maximo
                           AND doc.doc_maximo = ebd.id_epis_documentation_det
                         GROUP BY ebd.id_doc_element,
                                  pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                                  eb.id_epis_documentation,
                                  pk_translation.get_translation(i_lang, dc.code_doc_component),
                                  pk_translation.get_translation(i_lang, decr.code_element_open),
                                  ebd.value,
                                  d.id_documentation,
                                  ebd.id_doc_element_crit,
                                  pk_translation.get_translation(i_lang, decr.code_element_close),
                                  p.id_professional,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                  pk_date_utils.date_chr_short_read(i_lang, ebd.dt_creation_tstz, i_prof),
                                  pk_date_utils.date_char_hour(i_lang,
                                                               ebd.dt_creation_tstz,
                                                               i_prof.institution,
                                                               i_prof.software),
                                  last.last_maximo;
                
                    --- Mostrar todos os registos anteriores para o utilizador actual
                ELSIF i_flg_show = 'SM'
                THEN
                    g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SM';
                    OPEN o_epis_bartchart_comp FOR
                        SELECT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                               eb.id_epis_documentation,
                               d.id_documentation,
                               ebd.id_doc_element,
                               ebd.id_doc_element_crit,
                               pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                               pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                               ebd.value,
                               p.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                ebd.dt_creation_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) hour_target,
                               last.maximo
                          FROM epis_documentation     eb,
                               epis_documentation_det ebd,
                               documentation          d,
                               doc_element            de,
                               -- ELEMENT E,
                               doc_component dc,
                               doc_element_crit decr,
                               doc_criteria dcr,
                               professional p,
                               (SELECT ebd1.id_epis_documentation_det maximo,
                                       ebd1.id_documentation,
                                       ebd1.id_doc_element,
                                       max_elem.dt
                                  FROM epis_documentation_det ebd1,
                                       (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                          FROM epis_documentation_det ebd2
                                         WHERE ebd2.id_epis_documentation = i_id_epis_bartchart
                                           AND ebd2.id_professional = i_prof.id
                                         GROUP BY ebd2.id_documentation) max_elem
                                 WHERE ebd1.dt_creation_tstz = max_elem.dt
                                   AND ebd1.id_documentation = max_elem.id_documentation) LAST
                         WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                           AND ebd.id_epis_documentation = i_id_epis_bartchart
                           AND ebd.id_professional = i_prof.id
                           AND d.id_documentation = i_id_sys_documentation
                           AND d.id_documentation(+) = ebd.id_documentation
                           AND d.id_doc_area(+) = i_doc_area
                           AND de.id_doc_element = ebd.id_doc_element
                              --   AND DE.ID_ELEMENT=E.ID_ELEMENT
                           AND d.id_doc_component = dc.id_doc_component(+)
                           AND dc.flg_available(+) = g_available
                           AND d.flg_available(+) = g_available
                           AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                           AND decr.id_doc_criteria = dcr.id_doc_criteria
                           AND ebd.id_professional = p.id_professional
                           AND last.maximo(+) = ebd.id_epis_documentation_det
                         ORDER BY ebd.dt_creation_tstz DESC;
                
                    --- Mostrar os ultimos registos anteriores para  o utilizador actual
                ELSIF i_flg_show = 'SML'
                THEN
                    g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SML';
                    OPEN o_epis_bartchart_comp FOR
                        SELECT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                               eb.id_epis_documentation,
                               d.id_documentation,
                               ebd.id_doc_element,
                               ebd.id_doc_element_crit,
                               pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                               pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                               pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                               ebd.value,
                               p.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                ebd.dt_creation_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) hour_target,
                               last.maximo
                          FROM epis_documentation     eb,
                               epis_documentation_det ebd,
                               documentation          d,
                               doc_element            de,
                               -- ELEMENT E,
                               doc_component dc,
                               doc_element_crit decr,
                               doc_criteria dcr,
                               professional p,
                               (SELECT ebd1.id_epis_documentation_det maximo,
                                       ebd1.id_documentation,
                                       ebd1.id_doc_element,
                                       max_elem.dt
                                  FROM epis_documentation_det ebd1,
                                       (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                          FROM epis_documentation_det ebd2
                                         WHERE ebd2.id_epis_documentation = i_id_epis_bartchart
                                           AND ebd2.id_professional = i_prof.id
                                         GROUP BY ebd2.id_documentation) max_elem
                                 WHERE ebd1.dt_creation_tstz = max_elem.dt
                                   AND ebd1.id_documentation = max_elem.id_documentation) LAST
                         WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                           AND ebd.id_epis_documentation = i_id_epis_bartchart
                           AND ebd.id_professional = i_prof.id
                           AND d.id_documentation = i_id_sys_documentation
                           AND d.id_documentation(+) = ebd.id_documentation
                           AND d.id_doc_area(+) = i_doc_area
                           AND de.id_doc_element = ebd.id_doc_element
                              --AND DE.ID_ELEMENT=E.ID_ELEMENT
                           AND d.id_doc_component = dc.id_doc_component(+)
                           AND dc.flg_available(+) = g_available
                           AND d.flg_available(+) = g_available
                           AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                           AND decr.id_doc_criteria = dcr.id_doc_criteria
                           AND ebd.id_professional = p.id_professional
                           AND last.maximo = ebd.id_epis_documentation_det
                         GROUP BY ebd.id_doc_element,
                                  pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                                  eb.id_epis_documentation,
                                  pk_translation.get_translation(i_lang, dc.code_doc_component),
                                  pk_translation.get_translation(i_lang, decr.code_element_open),
                                  ebd.value,
                                  d.id_documentation,
                                  ebd.id_doc_element_crit,
                                  pk_translation.get_translation(i_lang, decr.code_element_close),
                                  p.id_professional,
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                                  pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   ebd.dt_creation_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                  last.maximo;
                
                END IF;
            
            ELSE
                pk_types.open_my_cursor(o_epis_bartchart_comp);
            
            END IF;
        ELSE
            --- Mostrar todos os registos anteriores para este DOC_COMPONENTe
            IF i_flg_show = 'SA'
            THEN
                g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SA';
                OPEN o_epis_bartchart_comp FOR
                    SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                                    eb.id_epis_documentation,
                                    d.id_documentation,
                                    ebd.id_doc_element,
                                    ebd.id_doc_element_crit,
                                    pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                                    pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                                    pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                                    ebd.value,
                                    p.id_professional,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                    pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     ebd.dt_creation_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software) hour_target,
                                    last.maximo,
                                    pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation
                      FROM epis_documentation eb,
                           epis_documentation_det ebd,
                           documentation d,
                           doc_element de,
                           doc_component dc,
                           doc_element_crit decr,
                           doc_criteria dcr,
                           professional p,
                           (SELECT ebd1.id_epis_documentation_det maximo,
                                   ebd1.id_documentation,
                                   ebd1.id_doc_element,
                                   max_elem.dt
                              FROM epis_documentation eb1,
                                   epis_documentation_det ebd1,
                                   (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                      FROM epis_documentation eb2, epis_documentation_det ebd2
                                     WHERE eb2.id_episode = i_epis
                                       AND ebd2.id_epis_documentation = eb2.id_epis_documentation
                                       AND ebd2.id_professional = i_prof.id
                                     GROUP BY ebd2.id_documentation) max_elem
                             WHERE ebd1.dt_creation_tstz = max_elem.dt
                               AND ebd1.id_documentation = max_elem.id_documentation) LAST
                     WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                       AND eb.id_episode = i_epis
                       AND d.id_documentation = i_id_sys_documentation
                       AND d.id_documentation(+) = ebd.id_documentation
                       AND d.id_doc_area(+) = i_doc_area
                       AND de.id_doc_element = ebd.id_doc_element
                          --AND DE.ID_ELEMENT=E.ID_ELEMENT
                       AND d.id_doc_component = dc.id_doc_component(+)
                       AND dcr.flg_available(+) = g_available
                       AND d.flg_available(+) = g_available
                       AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                       AND decr.id_doc_criteria = dcr.id_doc_criteria
                       AND ebd.id_professional = p.id_professional
                       AND last.maximo(+) = ebd.id_epis_documentation_det
                     ORDER BY ebd.dt_creation_tstz DESC;
            
                --- Mostrar os ultimos registos anteriores para este DOC_COMPONENTe
            ELSIF i_flg_show = 'SL'
            THEN
            
                g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SL';
                OPEN o_epis_bartchart_comp FOR
                    SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                                    eb.id_epis_documentation,
                                    d.id_documentation,
                                    ebd.id_doc_element,
                                    ebd.id_doc_element_crit,
                                    pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                                    pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                                    pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                                    pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                                    ebd.value,
                                    p.id_professional,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                    pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     ebd.dt_creation_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software) hour_target,
                                    last.last_maximo maximo
                      FROM epis_documentation     eb,
                           epis_documentation_det ebd,
                           documentation          d,
                           doc_element            de,
                           -- ELEMENT E,
                           doc_component dc,
                           doc_element_crit decr,
                           doc_criteria dcr,
                           professional p,
                           (SELECT ebd3.id_epis_documentation_det doc_maximo,
                                   ebd3.id_documentation,
                                   ebd3.id_doc_element,
                                   max_elem.dt                    doc_dt
                              FROM epis_documentation_det ebd3,
                                   (SELECT MAX(ebd4.dt_creation_tstz) dt, ebd4.id_documentation
                                      FROM epis_documentation eb4, epis_documentation_det ebd4
                                     WHERE eb4.id_episode = i_epis
                                       AND ebd4.id_epis_documentation = eb4.id_epis_documentation
                                     GROUP BY ebd4.id_documentation) max_elem
                             WHERE ebd3.dt_creation_tstz = max_elem.dt
                               AND ebd3.id_documentation = max_elem.id_documentation) doc,
                           (SELECT ebd1.id_epis_documentation_det last_maximo,
                                   ebd1.id_documentation,
                                   ebd1.id_doc_element,
                                   max_elem.dt
                              FROM epis_documentation_det ebd1,
                                   (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                      FROM epis_documentation eb2, epis_documentation_det ebd2
                                     WHERE eb2.id_episode = i_epis
                                       AND ebd2.id_epis_documentation = eb2.id_epis_documentation
                                       AND ebd2.id_professional = i_prof.id
                                     GROUP BY ebd2.id_documentation) max_elem
                             WHERE ebd1.dt_creation_tstz = max_elem.dt
                               AND ebd1.id_documentation = max_elem.id_documentation) LAST
                     WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                       AND eb.id_episode = i_epis
                       AND d.id_documentation = i_id_sys_documentation
                       AND d.id_documentation(+) = ebd.id_documentation
                       AND d.id_doc_area(+) = i_doc_area
                       AND de.id_doc_element = ebd.id_doc_element
                          --AND DE.ID_ELEMENT=E.ID_ELEMENT
                       AND d.id_doc_component = dc.id_doc_component(+)
                       AND dc.flg_available(+) = g_available
                       AND d.flg_available(+) = g_available
                       AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                       AND decr.id_doc_criteria = dcr.id_doc_criteria
                       AND ebd.id_professional = p.id_professional
                       AND last.last_maximo(+) = doc.doc_maximo
                       AND doc.doc_maximo = ebd.id_epis_documentation_det
                     GROUP BY ebd.id_doc_element,
                              pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                              eb.id_epis_documentation,
                              pk_translation.get_translation(i_lang, dc.code_doc_component),
                              pk_translation.get_translation(i_lang, decr.code_element_open),
                              ebd.value,
                              d.id_documentation,
                              ebd.id_doc_element_crit,
                              pk_translation.get_translation(i_lang, decr.code_element_close),
                              p.id_professional,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                              pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                              pk_date_utils.date_char_hour_tsz(i_lang,
                                                               ebd.dt_creation_tstz,
                                                               i_prof.institution,
                                                               i_prof.software),
                              last.last_maximo;
            
                --- Mostrar todos os registos anteriores para o utilizador actual
            ELSIF i_flg_show = 'SM'
            THEN
                g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SM';
                OPEN o_epis_bartchart_comp FOR
                    SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                                    eb.id_epis_documentation,
                                    d.id_documentation,
                                    ebd.id_doc_element,
                                    ebd.id_doc_element_crit,
                                    pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                                    pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                                    pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                                    ebd.value,
                                    p.id_professional,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                    pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     ebd.dt_creation_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software) hour_target,
                                    last.maximo,
                                    pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation
                      FROM epis_documentation     eb,
                           epis_documentation_det ebd,
                           documentation          d,
                           doc_element            de,
                           -- ELEMENT E,
                           doc_component dc,
                           doc_element_crit decr,
                           doc_criteria dcr,
                           professional p,
                           (SELECT ebd1.id_epis_documentation_det maximo,
                                   ebd1.id_documentation,
                                   ebd1.id_doc_element,
                                   max_elem.dt
                              FROM epis_documentation_det ebd1,
                                   (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                      FROM epis_documentation eb2, epis_documentation_det ebd2
                                     WHERE eb2.id_episode = i_epis
                                       AND ebd2.id_epis_documentation = eb2.id_epis_documentation
                                       AND ebd2.id_professional = i_prof.id
                                     GROUP BY ebd2.id_documentation) max_elem
                             WHERE ebd1.dt_creation_tstz = max_elem.dt
                               AND ebd1.id_documentation = max_elem.id_documentation) LAST
                     WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                       AND eb.id_episode = i_epis
                       AND ebd.id_professional = i_prof.id
                       AND d.id_documentation = i_id_sys_documentation
                       AND d.id_documentation(+) = ebd.id_documentation
                       AND d.id_doc_area(+) = i_doc_area
                       AND de.id_doc_element = ebd.id_doc_element
                          --   AND DE.ID_ELEMENT=E.ID_ELEMENT
                       AND d.id_doc_component = dc.id_doc_component(+)
                       AND dc.flg_available(+) = g_available
                       AND d.flg_available(+) = g_available
                       AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                       AND decr.id_doc_criteria = dcr.id_doc_criteria
                       AND ebd.id_professional = p.id_professional
                       AND last.maximo(+) = ebd.id_epis_documentation_det
                     ORDER BY ebd.dt_creation_tstz DESC;
            
                --- Mostrar os ultimos registos anteriores para  o utilizador actual
            ELSIF i_flg_show = 'SML'
            THEN
                g_error := 'GET CURSOR  O_EPIS_BARTCHART_COMP SML';
                OPEN o_epis_bartchart_comp FOR
                    SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                                    eb.id_epis_documentation,
                                    d.id_documentation,
                                    ebd.id_doc_element,
                                    ebd.id_doc_element_crit,
                                    pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                                    pk_translation.get_translation(i_lang, decr.code_element_open) desc_element,
                                    pk_translation.get_translation(i_lang, decr.code_element_close) desc_element_close,
                                    ebd.value,
                                    p.id_professional,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                                    pk_date_utils. date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                                    pk_date_utils.date_char_hour_tsz(i_lang,
                                                                     ebd.dt_creation_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software) hour_target,
                                    last.maximo
                      FROM epis_documentation     eb,
                           epis_documentation_det ebd,
                           documentation          d,
                           doc_element            de,
                           -- ELEMENT E,
                           doc_component dc,
                           doc_element_crit decr,
                           doc_criteria dcr,
                           professional p,
                           (SELECT ebd1.id_epis_documentation_det maximo,
                                   ebd1.id_documentation,
                                   ebd1.id_doc_element,
                                   max_elem.dt
                              FROM epis_documentation_det ebd1,
                                   (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation
                                      FROM epis_documentation eb2, epis_documentation_det ebd2
                                     WHERE eb2.id_episode = i_epis
                                       AND ebd2.id_epis_documentation = eb2.id_epis_documentation
                                       AND ebd2.id_professional = i_prof.id
                                     GROUP BY ebd2.id_documentation) max_elem
                             WHERE ebd1.dt_creation_tstz = max_elem.dt
                               AND ebd1.id_documentation = max_elem.id_documentation) LAST
                     WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                       AND eb.id_episode = i_epis
                       AND ebd.id_professional = i_prof.id
                       AND d.id_documentation = i_id_sys_documentation
                       AND d.id_documentation(+) = ebd.id_documentation
                       AND d.id_doc_area(+) = i_doc_area
                       AND de.id_doc_element = ebd.id_doc_element
                          --AND DE.ID_ELEMENT=E.ID_ELEMENT
                       AND d.id_doc_component = dc.id_doc_component(+)
                       AND dc.flg_available(+) = g_available
                       AND d.flg_available(+) = g_available
                       AND ebd.id_doc_element_crit = decr.id_doc_element_crit
                       AND decr.id_doc_criteria = dcr.id_doc_criteria
                       AND ebd.id_professional = p.id_professional
                       AND last.maximo = ebd.id_epis_documentation_det
                     GROUP BY ebd.id_doc_element,
                              pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                              eb.id_epis_documentation,
                              pk_translation.get_translation(i_lang, dc.code_doc_component),
                              pk_translation.get_translation(i_lang, decr.code_element_open),
                              ebd.value,
                              d.id_documentation,
                              ebd.id_doc_element_crit,
                              pk_translation.get_translation(i_lang, decr.code_element_close),
                              p.id_professional,
                              pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional),
                              pk_date_utils. date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof),
                              pk_date_utils.date_char_hour_tsz(i_lang,
                                                               ebd.dt_creation_tstz,
                                                               i_prof.institution,
                                                               i_prof.software),
                              last.maximo;
            
            END IF;
        
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_epis_bartchart_comp',
                                              o_error);
            pk_types.open_my_cursor(o_epis_bartchart_comp);
            RETURN FALSE;
    END get_epis_bartchart_comp;

    FUNCTION sr_set_epis_documentation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_episode_context     IN episode.id_episode%TYPE,
        i_epis_documentation  IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area            IN doc_area.id_doc_area%TYPE,
        i_epis_complaint      IN epis_complaint.id_epis_complaint%TYPE,
        i_id_documentation    IN table_number,
        i_id_doc_element      IN table_number,
        i_id_doc_element_crit IN table_number,
        i_value               IN table_varchar,
        i_notes               IN epis_documentation_det.notes%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:Permite registar uma nova avaliação para o episódio ou registar novos registos sobre
                     uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                                 I_EPIS  - ID do episódio
                                 I_EPIS  - ID do episódio de contexto
                                 I_EPIS_DOCUMENTATION - ID da visita. Se não estiver preenchido cria uma nova
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                                 I_EPIS_COMPLAINT - ID do registo na epis_complait activo no momento
        
                                 I_ID_DOCUMENTATION   - ID do DOCUMENTATION
                                 I_ID_DOC_ELEMENT- ID do DOC_ELEMENT
                                 I_ID_DOC_ELEMENT_CRIT     - ID do DOC_ELEMENT_CRIT
                                 I_VALUE   - Array com os valores de cada elemento (quando exite um registo de hora, numero ou texto)
                                 I_NOTES   - Notas associadas a uma DOC_AREA
        
               Saida: O_ERROR - Erro
        
         CRIAÇÃO: RB 2006/10/23
          NOTAS:
        *********************************************************************************/
        l_next_epis_documentation     epis_documentation.id_epis_documentation%TYPE;
        l_next_epis_documentation_det epis_documentation_det.id_epis_documentation_det%TYPE;
        l_char                        VARCHAR2(1);
    
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_epis
               AND flg_status != g_cancel; --G_FLG_STATUS;
    
        CURSOR c_epis_documentation IS
            SELECT ed.id_epis_documentation
              FROM epis_documentation ed
             WHERE id_epis_documentation = i_epis_documentation;
    
        --  ed.id_episode=I_EPIS
        --     and (ed.id_epis_complaint=I_EPIS_COMPLAINT or I_EPIS_COMPLAINT is null)
        --     and ed.id_doc_area = I_DOC_AREA
        --     and id_epis_documentation = I_EPIS_DOCUMENTATION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
    
        -- verificar se o episodio já existe
        g_error := 'GET CURSOR C_EPIS_DOCUMENTATION ';
        OPEN c_epis_documentation;
        FETCH c_epis_documentation
            INTO l_epis_documentation;
        g_found := c_epis_documentation%FOUND;
        CLOSE c_epis_documentation;
    
        IF g_found
        THEN
        
            g_error := 'UPDATE EPIS_DOCUMENTATION';
            UPDATE epis_documentation eb
               SET eb.id_prof_last_update = i_prof.id, eb.dt_last_update_tstz = g_sysdate_tstz
             WHERE eb.id_epis_documentation = l_epis_documentation;
        
            ------- ARRAY I_ID_SYS_DOCUMENTATION--------
            FOR i IN 1 .. i_id_documentation.count
            LOOP
                dbms_output.put_line('ARRAY I_ID_DOCUMENTATION');
                --
                g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                SELECT seq_epis_documentation_det.nextval
                  INTO l_next_epis_documentation_det
                  FROM dual;
                --
                -- Criar NOVA LINHA DE DETALHE para a EPIS_DOCUMENTATION
                --
                g_error := ' INSERIR EPIS_DOCUMENTATION_DET(I)';
                --
                dbms_output.put_line(g_error);
                --
                INSERT INTO epis_documentation_det
                    (id_epis_documentation_det,
                     id_epis_documentation,
                     id_documentation,
                     id_doc_element,
                     id_doc_element_crit,
                     id_professional,
                     dt_creation_tstz,
                     VALUE,
                     notes,
                     adw_last_update)
                VALUES
                    (l_next_epis_documentation_det,
                     l_epis_documentation,
                     i_id_documentation(i),
                     i_id_doc_element(i),
                     i_id_doc_element_crit(i),
                     i_prof.id,
                     g_sysdate_tstz,
                     i_value(i),
                     i_notes,
                     g_sysdate);
            END LOOP;
        ELSE
        
            -- Verificar se o episodio já existe
            g_error := 'GET CURSOR C_EPISODE';
            OPEN c_episode;
            FETCH c_episode
                INTO l_char;
            g_found := c_episode%FOUND;
            CLOSE c_episode;
            --
            IF g_found
            THEN
                g_error := 'GET SEQ_EPIS_DOCUMENTATION.NEXTVAL';
            
                SELECT seq_epis_documentation.nextval
                  INTO l_next_epis_documentation
                  FROM dual;
                --
                g_error := 'INSERT EPIS_DOCUMENTATION';
                INSERT INTO epis_documentation
                    (id_epis_documentation,
                     id_episode,
                     id_professional,
                     dt_creation_tstz,
                     id_prof_last_update,
                     dt_last_update_tstz,
                     flg_status,
                     id_epis_complaint,
                     id_doc_area,
                     id_episode_context)
                VALUES
                    (l_next_epis_documentation,
                     i_epis,
                     i_prof.id,
                     g_sysdate_tstz,
                     i_prof.id,
                     g_sysdate_tstz,
                     g_epis_documentation_act,
                     i_epis_complaint,
                     i_doc_area,
                     i_episode_context);
            
                ------- ARRAY I_ID_SYS_DOCUMENTATION--------
                FOR i IN 1 .. i_id_documentation.count
                LOOP
                
                    dbms_output.put_line('ARRAY I_ID_DOCUMENTATION');
                    --
                    g_error := 'GET SEQ_EPIS_DOCUMENTATION_DET.NEXTVAL';
                    SELECT seq_epis_documentation_det.nextval
                      INTO l_next_epis_documentation_det
                      FROM dual;
                    --
                    -- Criar NOVA LINHA DE DETALHE para a EPIS_BARTCHART
                    --
                    g_error := ' INSERIR EPIS_DOCUMENTATION_DET(I)';
                    --
                    dbms_output.put_line(g_error);
                    --
                    INSERT INTO epis_documentation_det
                        (id_epis_documentation_det,
                         id_epis_documentation,
                         id_documentation,
                         id_doc_element,
                         id_doc_element_crit,
                         id_professional,
                         dt_creation_tstz,
                         VALUE,
                         notes,
                         adw_last_update)
                    VALUES
                        (l_next_epis_documentation_det,
                         l_next_epis_documentation,
                         i_id_documentation(i),
                         i_id_doc_element(i),
                         i_id_doc_element_crit(i),
                         i_prof.id,
                         g_sysdate_tstz,
                         i_value(i),
                         i_notes,
                         g_sysdate);
                
                END LOOP;
            END IF;
        END IF;
        --
    
        IF i_prof.software = 8
        THEN
            g_error := 'CALL SET_CODING_ELEMENT_CHART';
            IF NOT pk_medical_decision.set_coding_element_chart(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_epis          => i_epis,
                                                                i_document_area => i_doc_area,
                                                                o_error         => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
            --
            g_error := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_epis,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_set_epis_documentation',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END sr_set_epis_documentation;

    FUNCTION sr_get_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_last_update        OUT pk_types.cursor_type,
        o_epis_triage_color  OUT pk_types.cursor_type,
        o_epis_doc           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
              uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                         I_EPIS  - ID do episódio
                                 I_EPIS_DOCUMENTATION - ID da visita. Se não estiver preenchido cria uma nova
        
               Saida: O_LAST_UPDATE   -  informação de quem e quando fez a ultima actualização na bartchart
                                 O_EPIS_TRIAGE_COLOR - Cor de triagem actribuida ao episódio
                                 O_EPIS_BARTCHART  - ultimo registo da chart
                                 O_ERROR - Erro
        
         CRIAÇÃO: SF 2006/10/08
          NOTAS:
        *********************************************************************************/
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        l_triage_type triage_type.id_triage_type%TYPE;
    
        l_doc_template doc_template.id_doc_template%TYPE;
        --
        l_comp_filter   VARCHAR2(100);
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar cursor para aceitar 'l_dep_clin_serv' como parâmetro
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_documentation_f(l_dcs dep_clin_serv.id_dep_clin_serv%TYPE) IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                          --
                       AND d.id_dep_clin_serv = l_dcs
                          --
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        -- CHANGE: José Brito 12/03/2008
        -- Obter o ID_DOC_TEMPLATE a partir da DOC_TEMPLATE_CONTEXT
        CURSOR c_epis_documentation IS
            SELECT eb.id_epis_documentation, dtc2.id_doc_template
              FROM epis_documentation     eb,
                   epis_complaint         ec,
                   complaint              c,
                   epis_documentation_det ebd,
                   documentation          sd,
                   --
                   (SELECT d.id_doc_template, d.id_institution, d.id_software, d.id_profile_template, d.id_context
                      FROM doc_template_context d
                     WHERE d.id_institution IN (i_prof.institution, 0)
                       AND d.id_software IN (i_prof.software, 0)
                       AND d.flg_type = g_flg_type_c
                       AND d.id_profile_template IN
                           (SELECT ppt.id_profile_template
                              FROM prof_profile_template ppt
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution)) dtc2
            --jsilva 26-04-2007 outer-joins e aceder ao id_doc_area
             WHERE (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND sd.id_documentation(+) = ebd.id_documentation
               AND sd.id_doc_area = i_doc_area
               AND ec.flg_status(+) = g_epis_bartchart_act
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
                  -- necessário fazer left outer join, pois ID_DOC_TEMPLATE pode ser NULL
               AND c.id_complaint = dtc2.id_context(+)
             ORDER BY dtc2.id_institution, dtc2.id_software DESC;
    
        /*
        CURSOR c_epis_documentation IS
            SELECT eb.id_epis_documentation, ct.id_doc_template
              FROM epis_documentation eb, epis_complaint ec, complaint c, doc_template ct
             WHERE eb.id_epis_documentation = i_epis_documentation
               AND eb.id_doc_area = i_doc_area
               AND eb.id_epis_complaint = ec.id_epis_complaint(+)
               AND ec.id_complaint = c.id_complaint(+)
               AND c.id_doc_template = ct.id_doc_template(+);
               */
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error       := 'GET TRIAGE_TYPE';
        l_triage_type := pk_edis_triage.get_triage_type(i_lang, i_prof, i_epis);
        --
    
        IF i_prof.software = 8
        THEN
            IF l_triage_type IS NOT NULL
            THEN
                g_error := 'GET CURSOR O_EPIS_TRIAGE_COLOR';
                OPEN o_epis_triage_color FOR
                    SELECT pk_translation.get_translation(i_lang, tc.code_accuity) desc_accuity,
                           tc.color,
                           tc.id_triage_color,
                           (SELECT et.id_triage_color
                              FROM epis_triage et
                             WHERE et.dt_begin_tstz IN (SELECT MAX(et1.dt_begin_tstz)
                                                          FROM epis_triage et1
                                                         WHERE et1.id_episode = i_epis)) color_episode
                      FROM triage_color tc
                     WHERE tc.id_triage_type = l_triage_type
                       AND tc.flg_show = g_flg_show
                       AND tc.flg_available = 'Y'
                       AND EXISTS (SELECT 0
                              FROM triage t
                             WHERE t.id_triage_color = tc.id_triage_color)
                     ORDER BY rank;
            ELSE
                pk_types.open_my_cursor(o_epis_triage_color);
            END IF;
        ELSE
            pk_types.open_my_cursor(o_epis_triage_color);
        END IF;
    
        -- CHANGE: José Brito 12/03/2008
        -- Acrescentar filtro...
        l_comp_filter := pk_sysconfig.get_config('COMPLAINT_FILTER', i_prof);
    
        -- CHANGE: José Brito 27/03/2008
        -- Corrigido modo como é aplicado o filtro
        /*
        IF l_comp_filter = g_comp_filter_prf
        THEN
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_documentation;
            FETCH c_epis_documentation
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_documentation %FOUND;
            CLOSE c_epis_documentation;
        */
        --ELSIF l_comp_filter = g_comp_filter_dcs
        IF l_comp_filter = g_comp_filter_dcs
        THEN
        
            g_error := 'FIND DCS';
            SELECT nvl(ei.id_dcs_requested, ei.id_dep_clin_serv)
              INTO l_dep_clin_serv
              FROM epis_info ei
             WHERE ei.id_episode = i_epis;
        
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_documentation_f(l_dep_clin_serv);
            FETCH c_epis_documentation_f
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_documentation_f %FOUND;
            CLOSE c_epis_documentation_f;
        
        ELSE
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_documentation;
            FETCH c_epis_documentation
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_documentation %FOUND;
            CLOSE c_epis_documentation;
            --g_error := 'NO COMPLAINT_FILTER(' || i_prof.institution || ',' || i_prof.software || ')';
            --RAISE g_exception;
        END IF;
        -- CHANGE END: José Brito
    
        /*
            -- Verificar se já existe uma bartchart
            g_error := 'GET CURSOR C_EPIS_DOCUM ';
            OPEN c_epis_documentation;
            FETCH c_epis_documentation
                INTO l_epis_documentation, l_doc_template;
            g_found := c_epis_documentation %FOUND;
            CLOSE c_epis_documentation;
        */
    
        IF g_found
        THEN
        
            --
            g_error := 'GET CURSOR O_LAST_UPDATE';
            OPEN o_last_update FOR
                SELECT eb.id_epis_documentation,
                       eb.id_prof_last_update,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_send_tsz(i_lang, eb.dt_last_update_tstz, i_prof) dt_last_update,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, eb.dt_last_update_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        eb.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                  FROM epis_documentation eb, epis_complaint ec, complaint c, professional p
                 WHERE eb.id_epis_documentation = i_epis_documentation
                   AND eb.id_epis_complaint = ec.id_epis_complaint(+)
                   AND ec.id_complaint = c.id_complaint(+)
                   AND eb.id_prof_last_update = p.id_professional;
            --
            g_error := 'GET CURSOR O_EPIS_DOCUMENTATION';
            OPEN o_epis_doc FOR
                SELECT sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_date_utils.date_send_tsz(i_lang, MAX(ebd.dt_creation_tstz), i_prof) maximo,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value
                  FROM epis_documentation     eb,
                       epis_documentation_det ebd,
                       documentation          sd,
                       doc_element            se,
                       doc_component          c,
                       doc_element_crit       sec,
                       doc_criteria           dc
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND ebd.id_epis_documentation = i_epis_documentation
                   AND sd.id_documentation(+) = ebd.id_documentation
                   AND ebd.adw_last_update = (SELECT MAX(d1.adw_last_update)
                                                FROM epis_documentation_det d1
                                               WHERE d1.id_epis_documentation = ebd.id_epis_documentation
                                                 AND d1.id_documentation = ebd.id_documentation)
                   AND sd.id_doc_area = i_doc_area
                   AND sd.value_document_type = nvl(l_doc_template, sd.value_document_type)
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                 GROUP BY sd.id_documentation,
                          ebd.id_doc_element,
                          ebd.id_doc_element_crit,
                          pk_translation.get_translation(i_lang, c.code_doc_component),
                          pk_translation.get_translation(i_lang, sec.code_element_open),
                          decode(dc.flg_criteria,
                                 g_criteria,
                                 NULL,
                                 pk_translation.get_translation(i_lang, sec.code_element_close)),
                          ebd.value;
        
        ELSE
            pk_types.open_my_cursor(o_last_update);
            pk_types.open_my_cursor(o_epis_doc);
        END IF;
    
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_epis_documentation',
                                              o_error);
            pk_types.open_my_cursor(o_epis_triage_color);
            pk_types.open_my_cursor(o_last_update);
            pk_types.open_my_cursor(o_epis_doc);
            RETURN FALSE;
    END sr_get_epis_documentation;

    FUNCTION sr_get_epis_documentation_comp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_doc_area                IN doc_area.id_doc_area%TYPE,
        i_epis                    IN episode.id_episode%TYPE,
        i_flg_show                IN VARCHAR2,
        i_id_documentation        IN documentation.id_documentation%TYPE,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE,
        o_epis_documentation_comp OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO: Permite registar uma nova  BARTCHART para o episódio ou registar novos registos sobre
                      uma já existente e respectivas notas.
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                         I_EPIS  - ID do episódio
                                 I_DOC_AREA - Area da aplicação onde é feito o registo
                                 I_BARTCHART
                                 I_SHOW -  modo de visualização
                                 I_SYS_DOCUMENTATION - componente para o qual quer ver registos
        
                          Saida: EPIS_DOCUMENTATION_COMP -  ultimo registo mediate o modo de visualização
                                 O_ERROR - Erro
        
         CRIAÇÃO: RB 2006/10/08
          NOTAS:
        *********************************************************************************/
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        -- Verificar se já existe uma bartchart
        g_error := 'GET CURSOR C_EPIS_DOCUMENTATION ';
    
        --- Mostrar todos os registos anteriores do episódio para este componente
        IF i_flg_show = 'SA'
        THEN
            g_error := 'GET CURSOR  O_EPIS_DOCUMENTATION_COMP SA';
            OPEN o_epis_documentation_comp FOR
                SELECT 1 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1
                                 WHERE ebd2.id_documentation = i_id_documentation
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND ed1.flg_status != g_cancel
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = i_id_documentation
                   AND sd.id_documentation = i_id_documentation
                   AND sd.id_documentation(+) = ebd.id_documentation
                   AND sd.id_doc_area(+) = i_doc_area
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo(+) = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                UNION ALL
                --Workflow temático
                SELECT 2 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       documentation_rel l,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1, documentation_rel l1
                                 WHERE ebd2.id_documentation = l1.id_documentation_action
                                   AND l1.id_documentation = i_id_documentation
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND ed1.flg_status != g_cancel
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND l1.flg_action = g_flg_workflow
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = sd.id_documentation
                   AND sd.id_documentation = l.id_documentation_action
                   AND l.id_documentation = i_id_documentation
                   AND l.flg_action = g_flg_workflow
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo(+) = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                 ORDER BY 1, 4, 2 DESC;
        
            --- Mostrar o ultimo registo deste componente
        ELSIF i_flg_show = 'SL'
        THEN
        
            g_error := 'GET CURSOR  O_EPIS_DOCUMENTATION_COMP SL';
            OPEN o_epis_documentation_comp FOR
                SELECT 1 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils. date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1
                                 WHERE ebd2.id_documentation = i_id_documentation
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = i_id_documentation
                   AND sd.id_documentation = i_id_documentation
                   AND sd.id_documentation(+) = ebd.id_documentation
                   AND sd.id_doc_area(+) = i_doc_area
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                UNION ALL
                --Workflow temático
                SELECT 2 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       documentation_rel l,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1, documentation_rel l1
                                 WHERE ebd2.id_documentation = l1.id_documentation_action
                                   AND l1.id_documentation = i_id_documentation
                                   AND l1.flg_action = g_flg_workflow
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = sd.id_documentation
                   AND sd.id_documentation = l.id_documentation_action
                   AND l.id_documentation = i_id_documentation
                   AND l.flg_action = g_flg_workflow
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                 ORDER BY 1, 4, 2 DESC;
        
            --- Mostrar todos os registos anteriores do episódio para o utilizador actual
        ELSIF i_flg_show = 'SM'
        THEN
            g_error := 'GET CURSOR  O_EPIS_DOCUMENTATION_COMP SM';
            OPEN o_epis_documentation_comp FOR
                SELECT 1 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils. date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1
                                 WHERE ebd2.id_documentation = i_id_documentation
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = i_id_documentation
                   AND sd.id_documentation = i_id_documentation
                   AND sd.id_documentation(+) = ebd.id_documentation
                   AND sd.id_doc_area(+) = i_doc_area
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = i_prof.id
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo(+) = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                UNION ALL
                --Workflow temático
                SELECT 2 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       documentation_rel l,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1, documentation_rel l1
                                 WHERE ebd2.id_documentation = l1.id_documentation_action
                                   AND l1.id_documentation = i_id_documentation
                                   AND l1.flg_action = g_flg_workflow
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = sd.id_documentation
                   AND sd.id_documentation = l.id_documentation_action
                   AND l.id_documentation = i_id_documentation
                   AND l.flg_action = g_flg_workflow
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = i_prof.id
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo(+) = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                 ORDER BY 1, 4, 2 DESC;
        
            --- Mostrar o último registo do utilizador actual
        ELSIF i_flg_show = 'SML'
        THEN
            g_error := 'GET CURSOR  O_EPIS_DOCUMENTATION_COMP SML';
            OPEN o_epis_documentation_comp FOR
                SELECT 1 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1
                                 WHERE ebd2.id_documentation = i_id_documentation
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = i_id_documentation
                   AND sd.id_documentation = i_id_documentation
                   AND sd.id_documentation(+) = ebd.id_documentation
                   AND sd.id_doc_area(+) = i_doc_area
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = p.id_professional
                   AND ebd.id_professional = i_prof.id
                   AND last.maximo = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                UNION ALL
                --Workflow temático
                SELECT 2 ordem,
                       pk_date_utils.date_send_tsz(i_lang, ebd.dt_creation_tstz, i_prof) dt_creation,
                       eb.id_epis_documentation,
                       sd.id_documentation,
                       ebd.id_doc_element,
                       ebd.id_doc_element_crit,
                       pk_translation.get_translation(i_lang, c.code_doc_component) desc_component,
                       pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                       decode(dc.flg_criteria,
                              g_criteria,
                              NULL,
                              pk_translation.get_translation(i_lang, sec.code_element_close)) desc_element_close,
                       ebd.value,
                       p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       pk_date_utils.date_chr_short_read_tsz(i_lang, ebd.dt_creation_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ebd.dt_creation_tstz,
                                                        i_prof.institution,
                                                        i_prof.software) hour_target,
                       last.maximo
                  FROM epis_documentation eb,
                       epis_documentation_det ebd,
                       documentation sd,
                       doc_element se,
                       doc_component c,
                       doc_element_crit sec,
                       doc_criteria dc,
                       professional p,
                       documentation_rel l,
                       (SELECT ebd1.id_epis_documentation_det maximo,
                               ebd1.id_documentation,
                               ebd1.id_doc_element,
                               max_elem.dt
                          FROM epis_documentation_det ebd1,
                               epis_documentation ed,
                               (SELECT MAX(ebd2.dt_creation_tstz) dt, ebd2.id_documentation, ed1.id_episode
                                  FROM epis_documentation_det ebd2, epis_documentation ed1, documentation_rel l1
                                 WHERE ebd2.id_documentation = l1.id_documentation_action
                                   AND l1.id_documentation = i_id_documentation
                                   AND l1.flg_action = g_flg_workflow
                                   AND ebd2.id_professional = i_prof.id
                                   AND ebd2.id_epis_documentation = ed1.id_epis_documentation
                                   AND (ed1.id_episode = i_epis OR ed1.id_episode_context = i_epis)
                                   AND ed1.flg_status != g_cancel
                                 GROUP BY ebd2.id_documentation, ed1.id_episode) max_elem
                         WHERE ebd1.dt_creation_tstz = max_elem.dt
                           AND ebd1.id_documentation = max_elem.id_documentation
                           AND ebd1.id_epis_documentation = ed.id_epis_documentation
                           AND ed.id_episode = max_elem.id_episode) LAST
                 WHERE eb.id_epis_documentation = ebd.id_epis_documentation(+)
                   AND (eb.id_episode = i_epis OR eb.id_episode_context = i_epis)
                   AND eb.flg_status != g_cancel
                   AND ebd.id_documentation = sd.id_documentation
                   AND sd.id_documentation = l.id_documentation_action
                   AND l.id_documentation = i_id_documentation
                   AND l.flg_action = g_flg_workflow
                   AND se.id_doc_element = ebd.id_doc_element
                   AND sd.id_doc_component = c.id_doc_component(+)
                   AND c.flg_available(+) = g_available
                   AND sd.flg_available(+) = g_available
                   AND ebd.id_doc_element_crit = sec.id_doc_element_crit
                   AND ebd.id_professional = i_prof.id
                   AND ebd.id_professional = p.id_professional
                   AND last.maximo = ebd.id_epis_documentation_det
                   AND dc.id_doc_criteria = sec.id_doc_criteria
                 ORDER BY 1, 4, 2 DESC;
        
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
                                              'sr_get_epis_documentation_comp',
                                              o_error);
            pk_types.open_my_cursor(o_epis_documentation_comp);
            RETURN FALSE;
    END sr_get_epis_documentation_comp;

    FUNCTION sr_cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_notes       IN VARCHAR2,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancela uma avaliação
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_EPIS - ID do episódio
                                 I_ID_EPIS_DOC - ID da avaliação a cancelar
                                 I_NOTES - Notas de cancelamento
                                 I_TEST - Indica se deve mostrar a confirmação de alteração
        
                        Saida: O_FLG_SHOW - indica se deve ser mostrada uma mensagem (Y / N)
                   O_MSG_TITLE - Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                   O_MSG_TEXT - Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
                   O_BUTTON - Botões a mostrar: N - não, R - lido, C - confirmado
                               O_ERROR - erro
        
          CRIAÇÃO: RB 2006/10/29
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Verifica se é para mostrar mensagem de confirmação
        IF i_test = 'Y'
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T283');
            o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T284');
            o_button    := 'NC';
            RETURN TRUE;
        END IF;
    
        --Cancela a avaliação
        g_error := 'UPDATE EPIS_DOCUMENTATION';
        UPDATE epis_documentation
           SET flg_status     = g_cancel,
               dt_cancel_tstz = g_sysdate_tstz,
               id_prof_cancel = i_prof.id,
               notes_cancel   = i_notes
         WHERE id_epis_documentation = i_id_epis_doc;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_cancel_epis_documentation',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END sr_cancel_epis_documentation;

    FUNCTION sr_get_component_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_component             OUT pk_types.cursor_type,
        o_element               OUT pk_types.cursor_type,
        o_elemnt_status         OUT pk_types.cursor_type,
        o_elemnt_action         OUT pk_types.cursor_type,
        o_element_exclusive     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os componentes associados a uma área
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do profissional
                                 I_DOC_AREA- ID da área
                                 I_EPIS - ID do episódio
                                 O_ID_EPIS_DOCUMENTATION - Registo na EPIS_DOCUMENTATION para o episódio
        
               Saida: O_ID_EPIS_COMPLAINT
                                 O_COMPONENT - Listar os componentes associados a uma área
                                 O_ELEMENT - Listar os elementos associados aos componentes de uma àrea
                                 O_ELEMNT_STATUS - Listar os estados possiveis para os elementos associados aos componentes de uma àrea
                                 O_ELEMNT_ACTION - Listar as accções de elementos sobre outros elementos associados aos componentes de uma àrea                        O_ERROR - erro
        
          CRIAÇÃO: SF 2006/10/02
          NOTAS:
        *********************************************************************************/
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_pat IS
            SELECT p.gender, months_between(SYSDATE, p.dt_birth) / 12 age
              FROM patient p, episode e
             WHERE e.id_episode = i_epis
               AND p.id_patient = e.id_patient;
    
        r_pat c_pat%ROWTYPE;
    
    BEGIN
    
        --Obtem dados sobre o sexo e idade do paciente
        g_error := 'GET PATIENT INFO';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
        --
        g_error := 'GET CURSOR O_COMPONENT';
        OPEN o_component FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   pk_translation.get_translation(i_lang, comp.code_doc_component) desc_component,
                   comp.flg_type,
                   d.x_position,
                   d.height,
                   d.width,
                   sd.value_document_type,
                   nvl((SELECT SUM(d1.width)
                         FROM doc_element se, doc_dimension d1
                        WHERE se.id_documentation = sd.id_documentation
                          AND se.position = g_position_out
                          AND d1.id_doc_dimension = se.id_doc_dimension),
                       0) element_external_width
              FROM doc_component comp, documentation sd, doc_dimension d
             WHERE comp.id_doc_component = sd.id_doc_component
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.value_document_type = 1 --l_complaint_template
               AND sd.flg_available = g_available
                  --  and sd.id_institution =i_prof.institution
                  --RB                  AND sd.id_software in (I_PROF.SOFTWARE, 0)
               AND sd.flg_available = g_available
               AND sd.id_doc_dimension = d.id_doc_dimension
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank;
        --
        g_error := 'GET CURSOR O_ELEMENT';
        OPEN o_element FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   se.id_doc_element,
                   pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                   --AM 27 Aug, 2008 - Flag position (se.position) is independent of language. Don't use sys_domain
                   decode(se.position,
                          g_position_out,
                          g_position_desc_out,
                          g_position_in,
                          g_position_desc_in,
                          g_position_desc_in) position,
                   d.height,
                   d.width,
                   se.flg_type
              FROM doc_component comp, documentation sd, doc_dimension d, doc_element se, doc_element_crit sec
             WHERE comp.id_doc_component = sd.id_doc_component(+)
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.value_document_type = 1 --l_complaint_template
               AND comp.flg_available = g_available
                  --  and sd.id_institution =i_prof.institution
                  --RB                  AND sd.id_software in (I_PROF.SOFTWARE, 0)
               AND sd.flg_available = g_available
               AND nvl(se.flg_available, g_available) = g_available
               AND sd.id_documentation = se.id_documentation
               AND se.id_doc_dimension = d.id_doc_dimension
               AND se.id_doc_element = sec.id_doc_element
               AND sec.flg_default = g_default
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank, se.rank;
    
        --
        g_error := 'GET CURSOR O_ELEMNT';
        OPEN o_elemnt_status FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   se.id_doc_element,
                   sec.id_doc_element_crit,
                   --e.id_element,
                   pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                   pk_translation.get_translation(i_lang, sec.code_element_close) desc_element_close,
                   pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_element_criteria,
                   se.position,
                   d.height,
                   d.width,
                   dc.flg_criteria,
                   sec.flg_default,
                   dc.element_color,
                   dc.text_color
              FROM doc_component comp,
                   documentation sd,
                   doc_dimension d,
                   doc_element   se,
                   --element e ,
                   doc_element_crit sec,
                   doc_criteria     dc
            --element_criteria ec
             WHERE comp.id_doc_component = sd.id_doc_component(+)
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.value_document_type = 1 --l_complaint_template
               AND comp.flg_available = g_available
                  -- and sd.id_institution =i_prof.institution
                  --RB                  AND sd.id_software = I_PROF.SOFTWARE
               AND sd.flg_available = g_available
               AND sd.id_documentation = se.id_documentation
                  --and se.id_element=e.id_element
               AND se.id_doc_dimension = d.id_doc_dimension
               AND se.id_doc_element = sec.id_doc_element
                  --and sec.id_element_criteria=ec.id_element_criteria
               AND nvl(se.flg_available, g_available) = g_available
               AND sec.flg_available = g_available
               AND dc.id_doc_criteria = sec.id_doc_criteria
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank, se.rank, dc.rank;
    
        --
        g_error := 'GET CURSOR O_ACTION';
        OPEN o_elemnt_action FOR
            SELECT ac.id_doc_action_criteria,
                   sec1.id_doc_element id_doc_element_crit,
                   ac.id_doc_element_crit action_element_crit,
                   pk_translation.get_translation(i_lang, sec1.code_element_open) desc_element_crit,
                   ac.flg_action,
                   ac.id_elem_crit_action action_elem_crit_action,
                   sec2.id_doc_element id_doc_element_crit_action,
                   pk_translation.get_translation(i_lang, sec2.code_element_open) desc_element_crit_action
              FROM doc_action_criteria ac,
                   doc_element_crit    sec1,
                   doc_element_crit    sec2,
                   doc_element         se1,
                   doc_element         se2,
                   documentation       sd1,
                   documentation       sd2
            --element e1,
            --element e2
             WHERE sd1.value_document_type = g_value_doc_type_default --l_complaint_template
               AND sd2.value_document_type = g_value_doc_type_default --l_complaint_template
               AND sd1.id_doc_area = i_doc_area
               AND sd2.id_doc_area = i_doc_area
                  --  and sd1.id_institution=i_prof.institution
                  --RB                    AND sd1.id_software in (I_PROF.SOFTWARE, 0)
               AND sd1.flg_available = g_available
                  --  and sd2.id_institution=i_prof.institution
                  --RB                    AND sd2.id_software in (I_PROF.SOFTWARE, 0)
               AND sd2.flg_available = g_available
               AND se1.flg_available = g_available
               AND se2.flg_available = g_available
               AND se1.id_documentation = sd1.id_documentation
               AND se2.id_documentation = sd2.id_documentation
               AND sec1.flg_available = g_available
               AND sec2.flg_available = g_available
               AND sec1.id_doc_element = se1.id_doc_element
               AND sec2.id_doc_element = se2.id_doc_element
               AND ac.flg_available = g_available
               AND ac.id_doc_area = i_doc_area
               AND ac.id_doc_element_crit = sec1.id_doc_element_crit
               AND ac.id_elem_crit_action = sec2.id_doc_element_crit
             ORDER BY ac.id_doc_action_criteria;
    
        g_error := 'GET CURSOR O_ELEMENT_REL';
        OPEN o_element_exclusive FOR
            SELECT der.id_doc_element_rel,
                   der.id_group,
                   de.id_doc_element,
                   d.id_documentation,
                   der.flg_type,
                   der.id_doc_element_rel_parent,
                   (SELECT der1.id_doc_element
                      FROM doc_element_rel der1
                     WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
              FROM doc_element_rel der, doc_element de, documentation d
             WHERE d.value_document_type = g_value_doc_type_default
               AND d.id_doc_area = i_doc_area
                  --RB                    AND D.ID_SOFTWARE in (I_PROF.SOFTWARE, 0)
               AND d.flg_available = g_available
               AND de.flg_available = g_available
               AND de.id_documentation = d.id_documentation
               AND der.flg_available = g_available
               AND der.id_doc_element = de.id_doc_element
             ORDER BY der.id_doc_element_rel;
    
        --   else
        --     Pk_Types.OPEN_MY_CURSOR(O_COMPONENT);
        --     Pk_Types.OPEN_MY_CURSOR(O_ELEMENT);
        --     Pk_Types.OPEN_MY_CURSOR(O_ELEMNT_STATUS);
        --     Pk_Types.OPEN_MY_CURSOR(O_ELEMNT_ACTION);
        --     Pk_Types.OPEN_MY_CURSOR(O_EPIS_COMPLAINT );
        --   END IF;
        --   --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_component_list',
                                              o_error);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_element_exclusive);
            --   Pk_Types.OPEN_MY_CURSOR(O_EPIS_COMPLAINT );
            RETURN FALSE;
    END sr_get_component_list;

    FUNCTION sr_set_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN episode.id_episode%TYPE,
        i_id_pat   IN identification_notes.id_patient%TYPE,
        i_prof     IN profissional,
        i_notes    IN identification_notes.notes%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar as notas do paciente por episódio/ paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS - ID do episódio
                        I_ID_PAT - ID do paciente
                    I_PROF - ID do profissional
                    I_NOTES - Notas
                                I_DOC_AREA - Área do documentation
        
               Saida: O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/09
          NOTAS:
        *********************************************************************************/
        l_next identification_notes.id_identification_notes%TYPE;
        l_char VARCHAR2(1);
        --
        CURSOR c_patient IS
            SELECT 'X'
              FROM patient
             WHERE id_patient = i_id_pat;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- Verificar se o paciente já existe
        g_error := 'GET CURSOR C_PATIENT';
        OPEN c_patient;
        FETCH c_patient
            INTO l_char;
        g_found := c_patient%FOUND; --notfound;
        CLOSE c_patient;
        --
        IF g_found
        THEN
            g_error := 'GET SEQ_IDENTIFICATION_NOTES.NEXTVAL';
            SELECT seq_identification_notes.nextval
              INTO l_next
              FROM dual;
            --
            g_error := 'INSERT NOTES';
            INSERT INTO identification_notes
                (id_identification_notes,
                 id_patient,
                 notes,
                 flg_available,
                 dt_notes_tstz,
                 id_professional,
                 id_episode,
                 id_doc_area)
            VALUES
                (l_next, i_id_pat, i_notes, g_available, g_sysdate_tstz, i_prof.id, i_epis, i_doc_area);
        END IF;
        --
        COMMIT;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_set_notes',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
    END sr_set_notes;

    FUNCTION sr_get_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis     IN episode.id_episode%TYPE,
        i_id_pat   IN identification_notes.id_patient%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_notes    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar as notas do paciente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                        I_PROF - ID do profissional
                                 I_EPIS - ID do episódio
                         I_ID_PAT - ID do paciente
                                 I_DOCUMENT_AREA - Área do documentation
        
               Saida: O_NOTES - Listar as notas associadas ao apciente / episódio
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_NOTES';
        OPEN o_notes FOR
            SELECT n.id_identification_notes,
                   n.notes,
                   pk_date_utils.date_send_tsz(i_lang, n.dt_notes_tstz, i_prof) dt_notes,
                   pk_date_utils.date_char_tsz(i_lang, n.dt_notes_tstz, i_prof.institution, i_prof.software) date_notes,
                   n.id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, n.dt_notes_tstz, n.id_episode) desc_speciality
              FROM identification_notes n, professional p, speciality s
             WHERE n.id_professional = p.id_professional(+)
               AND s.id_speciality(+) = p.id_speciality
               AND n.id_patient = i_id_pat
               AND n.id_episode = i_epis
               AND n.id_document_area = i_doc_area
               AND n.flg_available = g_available;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_notes',
                                              o_error);
            pk_types.open_my_cursor(o_notes);
            RETURN FALSE;
    END sr_get_notes;

    FUNCTION sr_get_element_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_sys_docum IN documentation.id_documentation%TYPE,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os elementos associados a um componente
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_PROF - ID do profissional
                                 I_SYS_DOCUM - ID da relação componente/ area
        
                          Saida: O_ELEMENT - Listar os elementos associados a um componente
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/08/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_ELEMENT';
        OPEN o_element FOR
            SELECT sd.id_documentation,
                   se.id_doc_element,
                   se.age_max,
                   se.age_min,
                   se.flg_gender,
                   se.flg_type,
                   se.id_doc_element,
                   pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                   se.position
              FROM documentation sd, doc_element se, doc_element_crit sec
             WHERE sd.id_documentation = se.id_documentation
                  --AND SE.ID_DOC_ELEMENT=ELEM.ID_ELEMENT
               AND sd.id_documentation = i_sys_docum
               AND se.flg_available = g_available
               AND se.id_doc_element = sec.id_doc_element
               AND sec.flg_default = g_default
             ORDER BY se.rank;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_element_list',
                                              o_error);
            pk_types.open_my_cursor(o_element);
            RETURN FALSE;
    END sr_get_element_list;

    FUNCTION sr_get_doc_template
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_type     IN documentation_type.id_documentation_type%TYPE,
        o_doc_template OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar todos os templates
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_DOC_TYPE - ID do tipo de documentation
        
                  Saida: O_DOC_TEMPLATE - Listar todos os templates
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/11/07
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DOC_TEMPLATE';
        OPEN o_doc_template FOR
            SELECT id_doc_template, internal_name desc_doc_template, flg_gender, age_max, age_min
              FROM doc_template
             WHERE flg_available = g_available
               AND id_documentation_type = i_doc_type
             ORDER BY id_doc_template ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_doc_template',
                                              o_error);
            pk_types.open_my_cursor(o_doc_template);
            RETURN FALSE;
    END sr_get_doc_template;

    FUNCTION sr_get_doc_area
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_doc_area OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar as áreas disponiveis para a documentation
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
        
                  Saida: O_DOC_AREA - Listar as áreas disponiveis para a documentation
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/11/07
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DOC_AREA';
        OPEN o_doc_area FOR
            SELECT id_doc_area, internal_name desc_doc_area
              FROM doc_area
             WHERE flg_available = g_available
             ORDER BY id_doc_area ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_doc_area',
                                              o_error);
            pk_types.open_my_cursor(o_doc_area);
            RETURN FALSE;
    END sr_get_doc_area;

    FUNCTION sr_get_documentation
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        o_documentation OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar todos os componentes associados a uma área e a um template
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_DOC_AREA - ID da área seleccionada
                                 I_DOC_TEMPLATE - ID do template seleccionado
        
                  Saida: O_DOCUMENTATION - Listar todos os componentes associados a uma área e a um template
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/11/07
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DOCUMENTATION';
        OPEN o_documentation FOR
            SELECT d.id_documentation,
                   d.id_documentation_parent,
                   d.id_doc_component,
                   d.id_doc_dimension,
                   d.value_document_type,
                   pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                   dd.height,
                   dd.height_open,
                   dd.width,
                   dd.x_position
              FROM documentation d, doc_component dc, doc_dimension dd
             WHERE d.flg_available = g_available
               AND d.id_doc_area = i_doc_area
               AND d.id_doc_template = i_doc_template
               AND d.id_doc_component = dc.id_doc_component
               AND d.id_doc_dimension = dd.id_doc_dimension
             ORDER BY d.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_documentation',
                                              o_error);
            pk_types.open_my_cursor(o_documentation);
            RETURN FALSE;
    END sr_get_documentation;

    FUNCTION sr_get_doc_dimension
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_doc_dimension OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar as possiveis dimensões a serem atribuidas aos diferentes componentes
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
        
                  Saida: O_DOC_DIMENSION - Listar as possiveis dimensões a serem atribuidas aos diferentes componentes
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/11/07
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DOC_DIMENSION';
        OPEN o_doc_dimension FOR
            SELECT id_doc_dimension, internal_name, height, height_open, width, x_position
              FROM doc_dimension
             WHERE flg_available = g_available
             ORDER BY id_doc_dimension ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_doc_dimension',
                                              o_error);
            pk_types.open_my_cursor(o_doc_dimension);
            RETURN FALSE;
    END sr_get_doc_dimension;

    FUNCTION sr_get_doc_element
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_documentation IN documentation.id_documentation%TYPE,
        o_doc_element   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os elementos associados a um documentation (componente)
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional q regista
                                 I_DOCUMENTATION - ID da documentation
        
                  Saida: O_DOC_ELEMENT - Listar os elementos associados a um documentation (componente)
                                 O_ERROR - erro
        
          CRIAÇÃO: ET 2006/11/07
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_DOC_ELEMENT';
        OPEN o_doc_element FOR
            SELECT de.id_doc_element,
                   de.age_max,
                   de.age_min,
                   de.flg_gender,
                   de.flg_type,
                   de.max_value,
                   de.min_value,
                   de.position,
                   pk_translation.get_translation(i_lang, dc.code_element_open) desc_element_open,
                   pk_translation.get_translation(i_lang, dc.code_element_close) desc_element_close
              FROM doc_element de, doc_element_crit dc
             WHERE de.flg_available = g_available
               AND de.id_documentation = i_documentation
               AND de.id_doc_element = dc.id_doc_element
             ORDER BY de.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'sr_get_doc_element',
                                              o_error);
            pk_types.open_my_cursor(o_doc_element);
            RETURN FALSE;
    END sr_get_doc_element;

    FUNCTION get_templ_component_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_component             OUT pk_types.cursor_type,
        o_element               OUT pk_types.cursor_type,
        o_elemnt_status         OUT pk_types.cursor_type,
        o_elemnt_action         OUT pk_types.cursor_type,
        o_element_exclusive     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os componentes associados a uma área e um template
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional
                                 I_DOC_AREA- ID da área
                                 I_DOC_TEMPLATE - ID do template
                                 I_EPIS - ID do episódio
                                 O_ID_EPIS_DOCUMENTATION - Registo na EPIS_DOCUMENTATION para o episódio
        
               Saida:            O_ID_EPIS_COMPLAINT
                                 O_COMPONENT - Listar os componentes associados a uma área
                                 O_ELEMENT - Listar os elementos associados aos componentes de uma àrea
                                 O_ELEMNT_STATUS - Listar os estados possiveis para os elementos associados aos componentes de uma àrea
                                 O_ELEMNT_ACTION - Listar as accções de elementos sobre outros elementos associados aos componentes de uma àrea                        O_ERROR - erro
        
          CRIAÇÃO: JSILVA 25/05/2007
          NOTAS:
        *********************************************************************************/
    
        -- <DENORM_EPISODE_JOSE_BRITO>
        CURSOR c_pat IS
            SELECT p.gender, months_between(SYSDATE, p.dt_birth) / 12 age
              FROM patient p, episode e
             WHERE e.id_episode = i_epis
               AND p.id_patient = e.id_patient;
    
        r_pat c_pat%ROWTYPE;
    
    BEGIN
    
        --Obtem dados sobre o sexo e idade do paciente
        g_error := 'GET PATIENT INFO';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
        --
        g_error := 'GET CURSOR O_COMPONENT';
        OPEN o_component FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   pk_translation.get_translation(i_lang, comp.code_doc_component) desc_doc_component,
                   comp.flg_type,
                   d.x_position,
                   d.height,
                   d.width,
                   sd.value_document_type,
                   nvl((SELECT SUM(d1.width)
                         FROM doc_element se, doc_dimension d1
                        WHERE se.id_documentation = sd.id_documentation
                          AND se.position = g_position_out
                          AND d1.id_doc_dimension = se.id_doc_dimension),
                       0) element_external_width
              FROM doc_component comp, documentation sd, doc_dimension d
             WHERE comp.id_doc_component = sd.id_doc_component
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.id_doc_template = i_doc_template
               AND sd.flg_available = g_available
               AND sd.flg_available = g_available
               AND sd.id_doc_dimension = d.id_doc_dimension
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank;
        --
        g_error := 'GET CURSOR O_ELEMENT';
        OPEN o_element FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   se.id_doc_element,
                   pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                   --AM 27 Aug, 2008 - Flag position (se.position) is independent of language. Don't use sys_domain
                   decode(se.position,
                          g_position_out,
                          g_position_desc_out,
                          g_position_in,
                          g_position_desc_in,
                          g_position_desc_in) position,
                   d.height,
                   d.width,
                   se.flg_type
              FROM doc_component comp, documentation sd, doc_dimension d, doc_element se, doc_element_crit sec
             WHERE comp.id_doc_component = sd.id_doc_component(+)
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.id_doc_template = i_doc_template
               AND comp.flg_available = g_available
               AND sd.flg_available = g_available
               AND sd.id_documentation = se.id_documentation
               AND se.id_doc_dimension = d.id_doc_dimension
               AND se.id_doc_element = sec.id_doc_element
               AND se.flg_available = g_available
               AND sec.flg_default = g_default
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank, se.rank;
    
        --
        g_error := 'GET CURSOR O_ELEMNT';
        OPEN o_elemnt_status FOR
            SELECT sd.id_documentation,
                   comp.id_doc_component,
                   se.id_doc_element,
                   sec.id_doc_element_crit,
                   pk_translation.get_translation(i_lang, sec.code_element_open) desc_element,
                   pk_translation.get_translation(i_lang, sec.code_element_close) desc_element_close,
                   pk_translation.get_translation(i_lang, dc.code_doc_criteria) desc_element_criteria,
                   se.position,
                   d.height,
                   d.width,
                   dc.flg_criteria,
                   sec.flg_default,
                   dc.element_color,
                   dc.text_color,
                   se.max_value,
                   se.min_value
              FROM doc_component    comp,
                   documentation    sd,
                   doc_dimension    d,
                   doc_element      se,
                   doc_element_crit sec,
                   doc_criteria     dc
             WHERE comp.id_doc_component = sd.id_doc_component(+)
               AND comp.flg_available = g_available
               AND sd.id_doc_area = i_doc_area
               AND sd.id_doc_template = i_doc_template
               AND comp.flg_available = g_available
               AND sd.flg_available = g_available
               AND sd.id_documentation = se.id_documentation
               AND se.id_doc_dimension = d.id_doc_dimension
               AND se.id_doc_element = sec.id_doc_element
               AND se.flg_available = g_available
               AND sec.flg_available = g_available
               AND dc.id_doc_criteria = sec.id_doc_criteria
               AND ((r_pat.gender IS NOT NULL AND nvl(comp.flg_gender, 'T') IN ('T', r_pat.gender)) OR
                   r_pat.gender IS NULL OR r_pat.gender = 'T')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(comp.age_min, 0) AND nvl(comp.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY sd.rank, se.rank, dc.rank;
    
        --
        g_error := 'GET CURSOR O_ACTION';
        OPEN o_elemnt_action FOR
            SELECT ac.id_doc_action_criteria,
                   sec1.id_doc_element id_doc_element_crit,
                   ac.id_doc_element_crit action_element_crit,
                   pk_translation.get_translation(i_lang, sec1.code_element_open) desc_element_crit,
                   ac.flg_action,
                   ac.id_elem_crit_action action_elem_crit_action,
                   sec2.id_doc_element id_doc_element_crit_action,
                   pk_translation.get_translation(i_lang, sec2.code_element_open) desc_element_crit_action
              FROM doc_action_criteria ac,
                   doc_element_crit    sec1,
                   doc_element_crit    sec2,
                   doc_element         se1,
                   doc_element         se2,
                   documentation       sd1,
                   documentation       sd2
             WHERE sd1.id_doc_area = i_doc_area
               AND sd2.id_doc_area = i_doc_area
               AND sd1.id_doc_template = i_doc_template
               AND sd2.id_doc_template = i_doc_template
               AND sd1.flg_available = g_available
               AND sd2.flg_available = g_available
               AND se1.flg_available = g_available
               AND se2.flg_available = g_available
               AND se1.id_documentation = sd1.id_documentation
               AND se2.id_documentation = sd2.id_documentation
               AND sec1.flg_available = g_available
               AND sec2.flg_available = g_available
               AND sec1.id_doc_element = se1.id_doc_element
               AND sec2.id_doc_element = se2.id_doc_element
               AND ac.flg_available = g_available
               AND ac.id_doc_area = i_doc_area
               AND ac.id_doc_element_crit = sec1.id_doc_element_crit
               AND ac.id_elem_crit_action = sec2.id_doc_element_crit
             ORDER BY ac.id_doc_action_criteria;
    
        g_error := 'GET CURSOR O_ELEMENT_REL';
        OPEN o_element_exclusive FOR
            SELECT der.id_doc_element_rel,
                   der.id_group,
                   de.id_doc_element,
                   d.id_documentation,
                   der.flg_type,
                   der.id_doc_element_rel_parent,
                   (SELECT der1.id_doc_element
                      FROM doc_element_rel der1
                     WHERE der1.id_doc_element_rel = der.id_doc_element_rel_parent) doc_element_parent
              FROM doc_element_rel der, doc_element de, documentation d
             WHERE d.id_doc_area = i_doc_area
               AND d.id_doc_template = i_doc_template
               AND d.flg_available = g_available
               AND de.flg_available = g_available
               AND de.id_documentation = d.id_documentation
               AND der.flg_available = g_available
               AND der.id_doc_element = de.id_doc_element
             ORDER BY der.id_doc_element_rel;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_templ_component_list',
                                              o_error);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_element_exclusive);
            RETURN FALSE;
    END get_templ_component_list;

    /********************************************************************************************
    * Establishes relationships between qualifications
    *                                                                                                                                          
    * @param i_id_group               Group ID                                                                                              
    * @param i_id_doc_element_qualif  Element qualification ID
    * @param i_flg_type               Relationship type
    * @param i_doc_qualif_parent      Parent element qualification ID                                                                                       
    * @param o_error                  Output with error message
    *                                                                                                                                         
    * @return                         true or false on success or error                                                        
    *                                                                                                                          
    * @value i_flg_type               {*} 'E'  Exclusive {*} 'U' Unique {*} 'R'  Relational 
                   
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.3.7)                                                                                                     
    * @since                          2008/10/13                                                                                               
    ********************************************************************************************/

    /********************************************************************************************
    * Establishes relationships between elements. Used to parametrize actions between two elements
    *                                                                                                                                          
    * @param i_doc_element            Element ID (source)
    * @param i_doc_element_target     Element ID (target)                                                                                     
    * @param i_id_group               Group ID
    * @param i_flg_type               Action type
    * @param o_error                  Output with error message
    *                                                                                                                                         
    * @return                         true or false on success or error                                                        
    *                                                                                                                          
    * @value i_flg_type               {*} 'C'  Copy action 
                   
    * @author                         Ariel Geraldo Machado                                                                                    
    * @version                         1.0 (2.4.4)                                                                                                     
    * @since                          2009/03/24                                                                                               
    ********************************************************************************************/

    /*
    Function for History of Present Illness doc_area
    */
    -- **********************************************
    FUNCTION get_doc_area_hpi RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 21;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_hpi;

    /*
    Function for Review of systems doc area 
    */
    -- **********************************************
    FUNCTION get_doc_area_review_sys RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 22;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_review_sys;

    /*
    Function for Famly history doc area 
    */
    -- **********************************************
    FUNCTION get_doc_area_family_hist RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 47;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_family_hist;

    /*
    Function for plan doc area 
    */
    -- **********************************************
    FUNCTION get_doc_area_plan RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 36110;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_plan;

    /*
    Function for Famly history doc area 
    */
    -- **********************************************
    FUNCTION get_doc_area_social_hist RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 48;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_social_hist;

    FUNCTION get_doc_area_phys_exam RETURN NUMBER IS
        k_id_doc_area CONSTANT NUMBER(24) := 28;
    BEGIN
        RETURN k_id_doc_area;
    END get_doc_area_phys_exam;

    FUNCTION get_medical_documents_area RETURN table_number IS
        l_doc_area table_number;
    BEGIN
        SELECT sps.id_doc_area
          BULK COLLECT
          INTO l_doc_area
          FROM summary_page sp
         INNER JOIN summary_page_section sps
            ON sp.id_summary_page = sps.id_summary_page
         WHERE sp.id_summary_page = 50;
        RETURN l_doc_area;
    END get_medical_documents_area;
    --***********************************************
    FUNCTION get_documentation_active_flag RETURN VARCHAR2 IS
        k_flag_active CONSTANT VARCHAR2(0001 CHAR) := 'A';
    BEGIN
        RETURN k_flag_active;
    END get_documentation_active_flag;

    -- *************************************************
    FUNCTION get_visit_info(i_episode IN NUMBER) RETURN visit%ROWTYPE IS
        l_vis visit%ROWTYPE;
    
        CURSOR vis_c IS
            SELECT v.id_patient, v.id_visit
              FROM episode e
              JOIN visit v
                ON v.id_visit = e.id_visit
             WHERE id_episode = i_episode;
    
        TYPE vis_type IS TABLE OF vis_c%ROWTYPE;
        tbl_vis vis_type;
    
    BEGIN
    
        OPEN vis_c;
        FETCH vis_c BULK COLLECT
            INTO tbl_vis;
        CLOSE vis_c;
    
        IF tbl_vis.count > 0
        THEN
            l_vis.id_patient := tbl_vis(1).id_patient;
            l_vis.id_visit   := tbl_vis(1).id_visit;
        END IF;
    
        RETURN l_vis;
    END get_visit_info;

    FUNCTION get_vwr_api_count
    (
        i_episode    IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_doc_area   IN table_number
    ) RETURN NUMBER IS
        l_count             NUMBER;
        l_id_visit          NUMBER(24);
        l_id_patient        NUMBER(24);
        l_vis               visit%ROWTYPE;
        k_flg_status_active VARCHAR2(0100 CHAR);
    
    BEGIN
    
        l_vis               := get_visit_info(i_episode => i_episode);
        k_flg_status_active := get_documentation_active_flag();
    
        CASE i_scope_type
            WHEN 'P' THEN
            
                SELECT COUNT(*)
                  INTO l_count
                  FROM epis_documentation ed
                  JOIN episode e
                    ON e.id_episode = ed.id_episode
                  JOIN visit v
                    ON v.id_visit = e.id_visit
                  LEFT JOIN epis_documentation_det edd
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  LEFT JOIN documentation d
                    ON edd.id_documentation = d.id_documentation
                 WHERE v.id_patient = l_vis.id_patient
                   AND ed.flg_status = k_flg_status_active
                   AND (d.id_doc_area IN (SELECT column_value
                                            FROM TABLE(i_doc_area)) OR
                       d.id_doc_area IS NULL AND
                       ed.id_doc_area IN (SELECT column_value
                                             FROM TABLE(i_doc_area)));
            
            WHEN 'V' THEN
            
                SELECT COUNT(*)
                  INTO l_count
                  FROM epis_documentation ed
                  JOIN episode e
                    ON e.id_episode = ed.id_episode
                  JOIN visit v
                    ON v.id_visit = e.id_visit
                  LEFT JOIN epis_documentation_det edd
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  LEFT JOIN documentation d
                    ON edd.id_documentation = d.id_documentation
                 WHERE v.id_visit = l_vis.id_visit
                   AND ed.flg_status = k_flg_status_active
                   AND (d.id_doc_area IN (SELECT column_value
                                            FROM TABLE(i_doc_area)) OR
                       d.id_doc_area IS NULL AND
                       ed.id_doc_area IN (SELECT column_value
                                             FROM TABLE(i_doc_area)));
            
            WHEN 'E' THEN
                SELECT COUNT(*)
                  INTO l_count
                  FROM epis_documentation ed
                  LEFT JOIN epis_documentation_det edd
                    ON ed.id_epis_documentation = edd.id_epis_documentation
                  LEFT JOIN documentation d
                    ON edd.id_documentation = d.id_documentation
                 WHERE ed.id_episode = i_episode
                   AND ed.flg_status = k_flg_status_active
                   AND (d.id_doc_area IN (SELECT column_value
                                            FROM TABLE(i_doc_area)) OR
                       d.id_doc_area IS NULL AND
                       ed.id_doc_area IN (SELECT column_value
                                             FROM TABLE(i_doc_area)));
            
        END CASE;
    
        RETURN l_count;
    
    END get_vwr_api_count;

    FUNCTION get_vwr_api_count2
    (
        i_episode  IN table_number,
        i_doc_area IN table_number
    ) RETURN NUMBER IS
        l_count             NUMBER := 0;
        l_id_visit          NUMBER(24);
        l_id_patient        NUMBER(24);
        k_flg_status_active VARCHAR2(0100 CHAR);
        k_flg_canceled CONSTANT VARCHAR2(1 CHAR) := 'C';
        l_doc_area NUMBER := i_doc_area(1);
    BEGIN
    
        k_flg_status_active := get_documentation_active_flag();
    
        SELECT COUNT(*)
          INTO l_count
          FROM (SELECT 1
                  FROM epis_documentation ed
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE tbl1 ROWS=1) */
                        column_value id_episode
                         FROM TABLE(i_episode) tbl1) epis
                    ON epis.id_episode = ed.id_episode
                 WHERE ed.flg_status = k_flg_status_active
                   AND ed.id_doc_area = l_doc_area
                --                   AND ed.id_episode IN (SELECT /*+ OPT_ESTIMATE(TABLE tbl1 ROWS=1) */ column_value FROM TABLE(i_episode) tbl1)
                UNION
                SELECT 1
                  FROM epis_documentation ed
                  JOIN review_detail rd
                    ON rd.id_record_area = ed.id_epis_documentation
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE tbl2 ROWS=1) */
                        column_value id_episode
                         FROM TABLE(i_episode) tbl2) epis
                    ON rd.id_episode = epis.id_episode
                 WHERE ed.flg_status = k_flg_status_active
                   AND rd.flg_context IN (pk_review.get_past_history_context(), pk_review.get_template_context()) -- EMR-250
                   AND ed.id_doc_area = l_doc_area
                UNION
                SELECT 1
                  FROM pat_past_hist_free_text pp
                  JOIN review_detail rd
                    ON rd.id_record_area = pp.id_pat_ph_ft
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE tbl3 ROWS=1) */
                        column_value id_episode
                         FROM TABLE(i_episode) tbl3) epis
                    ON epis.id_episode = rd.id_episode
                 WHERE pp.id_doc_area = l_doc_area
                   AND pp.flg_status != k_flg_canceled
                   AND rd.flg_context = pk_review.get_past_history_ft_context());
    
        RETURN l_count;
    
    END get_vwr_api_count2;

    -- ****************************************************************
    FUNCTION get_vwr_doc_area_base(i_area IN VARCHAR2) RETURN table_number IS
        l_return table_number;
        l_value  NUMBER;
    BEGIN
    
        CASE i_area
            WHEN k_doc_area_hpi THEN
                l_value := get_doc_area_hpi();
            WHEN k_doc_area_review_sys THEN
                l_value := get_doc_area_review_sys();
            WHEN k_doc_area_family_hist THEN
                l_value := get_doc_area_family_hist();
            WHEN k_doc_area_social_hist THEN
                l_value := get_doc_area_social_hist();
            WHEN k_doc_area_phys_exam THEN
                l_value := get_doc_area_phys_exam();
            WHEN k_doc_area_plan THEN
                l_value := get_doc_area_plan();
            WHEN k_doc_area_ml THEN
                l_return := get_medical_documents_area();
            ELSE
                l_value  := NULL;
                l_return := NULL;
        END CASE;
    
        IF l_value IS NOT NULL
        THEN
            l_return := table_number(l_value);
        END IF;
    
        RETURN l_return;
    
    END get_vwr_doc_area_base;

    FUNCTION get_vwr_base
    (
        i_area       IN VARCHAR2,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_count  NUMBER;
        l_status VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        tbl_area table_number := get_vwr_doc_area_base(i_area => i_area);
    BEGIN
    
        l_count := get_vwr_api_count(i_episode => i_episode, i_scope_type => i_scope_type, i_doc_area => tbl_area);
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_vwr_base;

    FUNCTION get_vwr_base2
    (
        i_area       IN VARCHAR2,
        i_scope_type IN VARCHAR2,
        i_episode    IN table_number
    ) RETURN VARCHAR2 IS
        k_doc_area table_number;
        l_count    NUMBER;
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
    BEGIN
    
        k_doc_area := get_vwr_doc_area_base(i_area => i_area);
    
        l_count := get_vwr_api_count2(i_episode => i_episode, i_doc_area => k_doc_area);
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    END get_vwr_base2;

    /* *******************************************************************************************
    *  Get current state of HPI for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_hpi
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_status := get_vwr_base(i_area => k_doc_area_hpi, i_scope_type => i_scope_type, i_episode => i_episode);
    
        RETURN l_status;
    
    END get_vwr_hpi;

    /* *******************************************************************************************
    *  Get current state of Reviews of system for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_review_sys
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_status := get_vwr_base(i_area => k_doc_area_review_sys, i_scope_type => i_scope_type, i_episode => i_episode);
    
        RETURN l_status;
    
    END get_vwr_review_sys;

    -- *********************************************************************
    FUNCTION get_vwr_family_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR);
        l_episodes table_number := table_number();
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        l_status := get_vwr_base2(i_area       => k_doc_area_family_hist,
                                  i_scope_type => i_scope_type,
                                  i_episode    => l_episodes);
    
        RETURN l_status;
    
    END get_vwr_family_hist;

    -- *********************************************************************
    FUNCTION get_vwr_social_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR);
        l_episodes table_number := table_number();
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        l_status := get_vwr_base2(i_area       => k_doc_area_social_hist,
                                  i_scope_type => i_scope_type,
                                  i_episode    => l_episodes);
    
        RETURN l_status;
    
    END get_vwr_social_hist;

    -- *********************************************************************
    FUNCTION get_vwr_physical_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_status := get_vwr_base(i_area => k_doc_area_phys_exam, i_scope_type => i_scope_type, i_episode => i_episode);
    
        RETURN l_status;
    
    END get_vwr_physical_exam;

    -- *********************************************************************
    FUNCTION get_vwr_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_status := get_vwr_base(i_area => k_doc_area_plan, i_scope_type => i_scope_type, i_episode => i_episode);
    
        RETURN l_status;
    
    END get_vwr_plan;

    /* *******************************************************************************************
    *  Get current state of medico legista for viewer checlist 
    *             
    * @param    i_lang          Language ID
    * @param    i_prof          Logged professional structure
    * @param    i_scope_type    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode    Episode ID
    * @param    i_id_patient    Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_medic_legist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR);
    BEGIN
    
        l_status := get_vwr_base(i_area => k_doc_area_ml, i_scope_type => i_scope_type, i_episode => i_episode);
    
        RETURN l_status;
    
    END get_vwr_medic_legist;

--
--
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_documentation;
/
