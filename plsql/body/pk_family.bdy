/*-- Last Change Revision: $Rev: 2027151 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_family AS

    /******************************************************************************
    
      PURPOSE:  Family Functions
      CREATION: RdSN 2006/10/12
       
    ******************************************************************************/

    FUNCTION get_family_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_id_pat   IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_pat_prob OUT pk_types.cursor_type,
        o_pat      OUT pk_types.cursor_type,
        o_epis     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- patient data query         
        g_error := 'GET CURSOR PATIENT DATA';
        OPEN o_pat FOR
            SELECT pf_mem.id_pat_related id_patient,
                   i_id_pat id_pat_origin,
                   pfm.id_pat_family_member,
                   pk_patient.get_pat_gender(pf_mem.id_pat_related) gender,
                   pk_patient.get_pat_age(i_lang, pf_mem.id_pat_related, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pf_mem.id_pat_related),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pf_mem.id_pat_related, i_prof)) photo,
                   decode(p.id_patient,
                          i_id_pat,
                          NULL,
                          pk_translation.get_translation(i_lang, fr.code_family_relationship)) family_relationship,
                   pk_patient.get_pat_name(i_lang, i_prof, pf_mem.id_pat_related, NULL) name,
                   decode(pj.id_occupation,
                          NULL,
                          pj.occupation_desc,
                          pk_translation.get_translation(i_lang, 'OCCUPATION.CODE_OCCUPATION.' || pj.id_occupation)) occupation,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pfp.id_professional) doctor_nick_name,
                   inst.flg_type inst_type
              FROM patient p,
                   pat_family_member pfm,
                   pat_family_prof pfp,
                   family_relationship fr,
                   pat_job pj,
                   institution inst,
                   (SELECT i_id_pat id_pat_related
                      FROM dual
                    UNION ALL
                    SELECT id_pat_related
                      FROM pat_family_member pfm2
                     WHERE pfm2.id_patient = i_id_pat) pf_mem
             WHERE p.id_patient = pf_mem.id_pat_related
               AND pf_mem.id_pat_related = pfm.id_pat_related(+)
               AND pfm.id_family_relationship = fr.id_family_relationship(+)
               AND p.id_patient = pj.id_patient(+)
               AND pf_mem.id_pat_related = pfp.id_patient(+)
               AND inst.id_institution = i_prof.institution
               AND p.flg_status = pk_alert_constant.g_active
             ORDER BY pf_mem.id_pat_related;
    
        -- problems for each family member    
        g_error := 'GET CURSOR PROBLEMS';
        OPEN o_pat_prob FOR
        -------------------
        -- Relevant diseases
        -------------------   
            SELECT phd.id_pat_history_diagnosis id_problem,
                   decode(phd.id_alert_diagnosis,
                          NULL,
                          phd.desc_pat_history_diagnosis,
                          -- ALERT-736 synonyms diagnosis
                          pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                     i_id_diagnosis       => d.id_diagnosis,
                                                     i_code               => d.code_icd,
                                                     i_flg_other          => d.flg_other,
                                                     i_flg_std_diag       => ad.flg_icd9) ||
                          decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis)) desc_pat_problem,
                   decode(phd.id_alert_diagnosis,
                          NULL,
                          pk_message.get_message(i_lang, 'PROBLEMS_M001'),
                          pk_message.get_message(i_lang, 'PROBLEMS_M004')) title,
                   phd.id_patient,
                   pk_sysdomain.get_rank(i_lang, 'PAT_HISTORY_DIAGNOSIS.FLG_STATUS', phd.flg_status) rank_type,
                   pk_date_utils.date_send_tsz(i_lang, phd.dt_pat_history_diagnosis_tstz, i_prof) dt_order
              FROM pat_history_diagnosis phd, alert_diagnosis ad, diagnosis d
             WHERE id_pat_history_diagnosis IN
                   (SELECT decode(id_alert_diagnosis,
                                  NULL,
                                  pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                       NULL,
                                                                       desc_pat_history_diagnosis,
                                                                       phd.id_patient,
                                                                       i_prof,
                                                                       pk_alert_constant.g_available),
                                  pk_problems.get_pat_hist_diag_recent(i_lang,
                                                                       id_alert_diagnosis,
                                                                       NULL,
                                                                       phd.id_patient,
                                                                       i_prof,
                                                                       pk_alert_constant.g_available))
                      FROM pat_history_diagnosis phd
                     WHERE phd.id_patient IN (SELECT pat2.id_patient
                                                FROM patient pat, patient pat2
                                               WHERE pat.id_patient = i_id_pat
                                                 AND pat2.id_pat_family = pat.id_pat_family
                                                 AND pat.id_patient != pat2.id_patient)
                       AND flg_type = 'M'
                       AND (id_alert_diagnosis IS NOT NULL OR desc_pat_history_diagnosis IS NOT NULL)
                     GROUP BY id_alert_diagnosis, desc_pat_history_diagnosis, phd.id_patient)
               AND phd.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND phd.id_diagnosis = d.id_diagnosis(+)
               AND phd.flg_status IN ('A', 'P')
            UNION ALL
            -------------------
            -- Diagnosis and habits
            -------------------   
            SELECT pp.id_pat_problem id_problem,
                   decode(pp.desc_pat_problem,
                          '',
                          decode(pp.id_habit,
                                 '',
                                 -- ALERT-736 synonyms diagnosis
                                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                            i_id_diagnosis        => d.id_diagnosis,
                                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                            i_code                => d.code_icd,
                                                            i_flg_other           => d.flg_other,
                                                            i_flg_std_diag        => ad.flg_icd9,
                                                            i_epis_diag           => ed.id_epis_diagnosis),
                                 pk_translation.get_translation(i_lang, h.code_habit)),
                          pp.desc_pat_problem) desc_pat_problem,
                   decode(pp.desc_pat_problem,
                          '',
                          decode(pp.id_habit,
                                 '',
                                 decode(nvl(ed.id_epis_diagnosis, 0),
                                        0,
                                        pk_message.get_message(i_lang, 'PROBLEMS_M004'),
                                        decode(ed.flg_type,
                                               'P',
                                               pk_message.get_message(i_lang, 'PROBLEMS_M002'),
                                               pk_message.get_message(i_lang, 'PROBLEMS_M003'))),
                                 pk_message.get_message(i_lang, 'PROBLEMS_M006')),
                          pk_message.get_message(i_lang, 'PROBLEMS_M001')) title,
                   pp.id_patient,
                   pk_sysdomain.get_rank(i_lang, 'PAT_PROBLEM.FLG_STATUS', pp.flg_status) rank_type,
                   pk_date_utils.date_send_tsz(i_lang, pp.dt_pat_problem_tstz, i_prof) dt_order
              FROM pat_problem     pp,
                   diagnosis       d,
                   alert_diagnosis ad,
                   epis_diagnosis  ed,
                   diagnosis       d1,
                   alert_diagnosis ad1,
                   habit           h
             WHERE pp.id_patient IN (SELECT pat2.id_patient
                                       FROM patient pat, patient pat2
                                      WHERE pat.id_patient = i_id_pat
                                        AND pat2.id_pat_family = pat.id_pat_family
                                        AND pat.id_patient != pat2.id_patient)
               AND pp.id_diagnosis = d.id_diagnosis(+)
               AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+)
               AND pp.flg_status = nvl(NULL, pp.flg_status)
               AND ed.id_epis_diagnosis(+) = pp.id_epis_diagnosis
               AND d1.id_diagnosis(+) = ed.id_diagnosis
               AND ad1.id_alert_diagnosis(+) = ed.id_alert_diagnosis
               AND pp.id_habit = h.id_habit(+)
                  -- RdSN To exclude relev.diseases and problems
               AND (pp.id_habit = h.id_habit OR ed.id_epis_diagnosis = pp.id_epis_diagnosis)
               AND pp.flg_status IN ('A', 'P')
            UNION ALL
            -- alergies
            SELECT pa.id_pat_allergy id_problem,
                   pk_translation.get_translation(i_lang, a.code_allergy) desc_pat_problem,
                   pk_message.get_message(i_lang, 'PROBLEMS_M005') title,
                   pa.id_patient,
                   pk_sysdomain.get_rank(i_lang, 'PAT_ALLERGY.FLG_STATUS', pa.flg_status) rank_type,
                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_order
              FROM pat_allergy pa, allergy a, professional p
             WHERE pa.id_patient IN (SELECT pat2.id_patient
                                       FROM patient pat, patient pat2
                                      WHERE pat.id_patient = i_id_pat
                                        AND pat2.id_pat_family = pat.id_pat_family
                                        AND pat.id_patient != pat2.id_patient)
               AND a.id_allergy = pa.id_allergy
               AND p.id_professional = pa.id_prof_write
               AND pa.flg_status IN (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)
             ORDER BY rank_type, dt_order;
    
        OPEN o_epis FOR
            SELECT e.id_episode, ei.id_patient, ei.id_schedule
              FROM episode e, epis_info ei
             WHERE ei.id_patient IN (SELECT pat2.id_patient
                                       FROM patient pat, patient pat2
                                      WHERE pat.id_patient = i_id_pat
                                        AND pat2.id_pat_family = pat.id_pat_family
                                        AND pat.id_patient != pat2.id_patient)
               AND e.flg_status = pk_alert_constant.g_flg_status_a
               AND e.id_episode = ei.id_episode(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FAMILY_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_pat_prob);
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_epis);
            RETURN FALSE;
    END get_family_grid;

    FUNCTION get_family_relationships
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_family_relat OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_family_relat FOR
            SELECT fr.id_family_relationship id_fr,
                   pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_fr
              FROM family_relationship fr, patient pat
             WHERE pat.id_patient = i_patient
               AND (fr.gender = nvl(pat.gender, fr.gender) -- patient's gender
                    OR fr.gender = 'T' -- valid for both genders
                    OR pat.gender NOT IN ('M', 'F'))
               AND fr.flg_available = pk_alert_constant.g_available
             ORDER BY desc_fr;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FAMILY_RELATIONSHIPS',
                                              o_error);
            pk_types.open_my_cursor(o_family_relat);
            RETURN FALSE;
    END get_family_relationships;

    FUNCTION set_family_relat_pat
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_patient             IN pat_family_member.id_patient%TYPE,
        i_id_pat_related         IN pat_family_member.id_pat_related%TYPE,
        i_id_family_relationship IN pat_family_member.id_family_relationship%TYPE,
        i_prof                   IN profissional,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_family patient.id_pat_family%TYPE;
        l_flg_status    patient.flg_status%TYPE := 'A';
    
    BEGIN
    
        SELECT id_pat_family
          INTO l_id_pat_family
          FROM patient
         WHERE id_patient = i_id_patient;
    
        -- updates first relationship (example: father)
        MERGE INTO pat_family_member pfm
        USING (SELECT DISTINCT fr.id_family_relationship, pat.id_patient
                 FROM family_relationship_relat frr, family_relationship fr, patient pat, pat_family_member pfm
                WHERE ((frr.id_family_relationship = i_id_family_relationship AND
                      frr.id_family_relationship_reverse = fr.id_family_relationship) OR
                      (frr.id_family_relationship_reverse = i_id_family_relationship AND
                      frr.id_family_relationship = fr.id_family_relationship))
                  AND (fr.gender = pat.gender -- patient's gender
                       OR fr.gender = 'T' -- valid for both genders
                       OR pat.gender NOT IN ('M', 'F')) -- prevents the case of an undefined gender 
                  AND fr.flg_available = pk_alert_constant.g_available
                  AND pat.id_patient = i_id_pat_related) x
        ON (pfm.id_pat_related = i_id_pat_related AND pfm.id_patient = i_id_patient) -- AND pfm.id_institution IN (i_prof.institution, 0))
        WHEN MATCHED THEN
            UPDATE
               SET pfm.id_family_relationship = i_id_family_relationship
        WHEN NOT MATCHED THEN
            INSERT
                (pfm.id_pat_family_member,
                 pfm.id_patient,
                 pfm.id_pat_related,
                 pfm.id_family_relationship,
                 pfm.id_pat_family,
                 pfm.id_institution,
                 pfm.flg_status,
                 pfm.id_episode)
            VALUES
                (seq_pat_family_member.nextval,
                 i_id_patient,
                 i_id_pat_related,
                 i_id_family_relationship,
                 l_id_pat_family,
                 i_prof.institution,
                 l_flg_status,
                 -1);
    
        -- updates inverse relationship with the patient gender (example: father vs son/daughter) 
        MERGE INTO pat_family_member pfm
        USING (SELECT DISTINCT fr.id_family_relationship, pat.id_patient
                 FROM family_relationship_relat frr, family_relationship fr, patient pat, pat_family_member pfm
                WHERE ((frr.id_family_relationship = i_id_family_relationship AND
                      frr.id_family_relationship_reverse = fr.id_family_relationship) OR
                      (frr.id_family_relationship_reverse = i_id_family_relationship AND
                      frr.id_family_relationship = fr.id_family_relationship))
                  AND (fr.gender = pat.gender -- patient's gender
                       OR fr.gender = 'T' -- valid for both genders
                       OR pat.gender NOT IN ('M', 'F')) -- prevents the case of an undefined gender 
                  AND fr.flg_available = pk_alert_constant.g_available
                  AND pat.id_patient = i_id_patient) x
        ON (pfm.id_pat_related = i_id_patient AND pfm.id_patient = i_id_pat_related) -- AND pfm.id_institution IN (i_prof.institution, 0))
        WHEN MATCHED THEN
            UPDATE
               SET pfm.id_family_relationship = x.id_family_relationship
        WHEN NOT MATCHED THEN
            INSERT
                (pfm.id_pat_family_member,
                 pfm.id_patient,
                 pfm.id_pat_related,
                 pfm.id_family_relationship,
                 pfm.id_pat_family,
                 pfm.id_institution,
                 pfm.flg_status,
                 pfm.id_episode)
            VALUES
                (seq_pat_family_member.nextval,
                 i_id_pat_related,
                 i_id_patient,
                 x.id_family_relationship,
                 l_id_pat_family,
                 i_prof.institution,
                 l_flg_status,
                 -1);
    
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
                                              'SET_FAMILY_RELAT_PAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_family_relat_pat;

    FUNCTION get_pat_episodes
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_pat     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtém cursor com os episódios                              
        g_error := 'GET CURSOR';
        OPEN o_pat FOR
            SELECT e.id_episode,
                   decode(sp.flg_state,
                          'A',
                          '',
                          pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)) hour_target,
                   decode(sp.flg_state,
                          'A',
                          '',
                          pk_date_utils.dt_chr_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)) date_target,
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service) cons_type,
                   lpad(to_char(pk_sysdomain.get_rank(i_lang, 'SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched)), 6, '0') ||
                   pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched) img_sched,
                   pk_prof_utils.get_nickname(i_lang, ei.id_professional) doctor_nick_name,
                   s.id_schedule,
                   ei.id_software
              FROM epis_info ei, episode e, schedule_outp sp, schedule s, dep_clin_serv dcs
             WHERE ei.id_patient = i_patient
               AND ei.id_software = i_prof.software
               AND e.id_episode = ei.id_episode
               AND e.flg_status = 'A'
               AND s.id_schedule = sp.id_schedule(+)
               AND s.flg_status != 'C'
               AND dcs.id_dep_clin_serv(+) = s.id_dcs_requested
               AND ei.id_schedule = s.id_schedule(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EPISODES',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_episodes;

    FUNCTION call_update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_family_members VARCHAR2(200);
        i                NUMBER;
        l_patient        NUMBER;
        l_patients       pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'COUNT PATIENTS';
        FOR i IN 1 .. i_id_patient.count
        LOOP
            IF l_family_members IS NULL
            THEN
                l_family_members := i_id_patient(i);
            ELSE
                l_family_members := l_family_members || ',' || i_id_patient(i);
            END IF;
        END LOOP;
    
        g_error := 'OPEN PATIENTS';
        OPEN l_patients FOR --
         'SELECT id_patient ' || --
         '  FROM patient ' || --
         ' WHERE id_pat_family =  = ' || i_id_pat_family || ' ' || --
         '   AND id_patient NOT IN (' || l_family_members || ') ';
    
        -- para cada registo em O_PAT coloca o seu ID_PAT_FAMILY na tabela PATIENT a NULL 
        --  e apaga os registos da PAT_FAMILY_MEMBER
        LOOP
        
            g_error := 'LOOP';
            FETCH l_patients
                INTO l_patient;
            EXIT WHEN l_patients%NOTFOUND;
        
            g_error := 'UPDATE PATIENT WITH PATIENT : ' || l_patient;
            UPDATE patient
               SET id_pat_family = NULL
             WHERE id_patient = l_patient;
        
            g_error := 'DELETE PAT_FAMILY_MEMBER WITH PATIENT : ' || l_patient;
            DELETE pat_family_member
             WHERE id_patient = l_patient
                OR id_pat_related = l_patient;
        
        END LOOP;
    
        -- RdSN 2006/11/21
        -- Commented following a request from the interface layer
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_UPDATE_ORPHAN_FAM_MEM',
                                              o_error);
        
    END call_update_orphan_fam_mem;

    FUNCTION update_orphan_fam_mem
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_family IN patient.id_pat_family%TYPE,
        i_id_patient    IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'PK_FAMILY.CALL_UPDATE_ORPHAN_FAM_MEM';
        IF NOT pk_family.call_update_orphan_fam_mem(i_lang          => i_lang,
                                                    i_id_pat_family => i_id_pat_family,
                                                    i_id_patient    => i_id_patient,
                                                    o_error         => o_error)
        THEN
            RAISE g_exception;
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
                                              'UPDATE_ORPHAN_FAM_MEM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_orphan_fam_mem;

    FUNCTION get_group_relationships
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_relationship_type IN relationship_type.id_relationship_type%TYPE,
        o_relationship      OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market_inst market.id_market%TYPE;
        l_market      market.id_market%TYPE;
    
    BEGIN
        -- get id_market
        l_market_inst := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        BEGIN
            SELECT id_market
              INTO l_market
              FROM (SELECT rgm.id_market, row_number() over(ORDER BY id_market DESC) rn
                      FROM relationship_grp_market rgm
                      JOIN family_relationship fr
                        ON rgm.id_family_relationship = fr.id_family_relationship
                     WHERE rgm.id_relationship_type = i_relationship_type
                       AND fr.flg_available = pk_alert_constant.g_yes
                       AND rgm.id_market IN (pk_alert_constant.g_id_market_all, l_market_inst))
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_market := 0;
        END;
    
        g_error := 'OPEN O_RELATION_SHIP';
        OPEN o_relationship FOR
            SELECT fr.id_family_relationship val,
                   pk_translation.get_translation(i_lang, fr.code_family_relationship) family_desc
              FROM relationship_grp_market rgm
              JOIN family_relationship fr
                ON rgm.id_family_relationship = fr.id_family_relationship
             WHERE rgm.id_relationship_type = i_relationship_type
               AND rgm.id_market = l_market
               AND fr.flg_available = pk_alert_constant.g_yes
             ORDER BY rgm.rank, family_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GROUP_RELATIONSHIPS',
                                              o_error);
            pk_types.open_my_cursor(o_relationship);
        
            RETURN FALSE;
    END get_group_relationships;

    FUNCTION get_family_relationship_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_family_relationship IN family_relationship.id_family_relationship%TYPE
    ) RETURN VARCHAR2 IS
    
        l_family_relationship VARCHAR2(200);
    
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, fr.code_family_relationship)
          INTO l_family_relationship
          FROM family_relationship fr
         WHERE fr.id_family_relationship = i_id_family_relationship;
    
        RETURN l_family_relationship;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_family_relationship_desc;

    FUNCTION get_family_relationship_id
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_family_relationship IN family_relationship.id_family_relationship%TYPE
    ) RETURN VARCHAR2 IS
    
        l_family_relationship VARCHAR2(200);
    
    BEGIN
    
        SELECT fr.id_content
          INTO l_family_relationship
          FROM family_relationship fr
         WHERE fr.id_family_relationship = i_id_family_relationship;
    
        RETURN l_family_relationship;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_family_relationship_id;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_family;
/
