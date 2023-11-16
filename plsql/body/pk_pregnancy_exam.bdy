/*-- Last Change Revision: $Rev: 2055402 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:44:22 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_pregnancy_exam AS

    /********************************************************************************************
    * Checks if the exam type applies to the patient
    * 
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_prof                professional id, software and institution
    * @param   i_patient             patient ID
    * @param   i_exam_type           exam type ID
    * @param   i_flg_type            exam type: U - ultrasound
    *
    * @param   o_flg_female_exam     the exam applies to the patient: Y - yes, N - no
    * @param   o_exam_type           exam type ID
    * @param   o_error               an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  José Silva
    * @version 1.0
    * @since   04-11-2009
    **********************************************************************************************/
    FUNCTION check_exam_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_exam_type       IN exam_type.id_exam_type%TYPE,
        i_flg_type        IN exam_type.flg_type%TYPE,
        o_flg_female_exam OUT VARCHAR2,
        o_exam_type       OUT exam_type.id_exam_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_gender       exam_type.gender%TYPE;
        l_exam_age_max exam_type.age_max%TYPE;
        l_exam_age_min exam_type.age_min%TYPE;
    
        l_flg_female_exam VARCHAR2(10);
        l_age             patient.age%TYPE;
    
        CURSOR c_pat_gender IS
            SELECT decode(gender, l_gender, g_yes, g_no),
                   nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12)) age
              FROM patient p
             WHERE id_patient = i_patient;
    
    BEGIN
    
        g_error := 'GET ULTRASOUND GENDER AND AGE PARAMS';
        SELECT id_exam_type, gender, age_max, age_min
          INTO o_exam_type, l_gender, l_exam_age_max, l_exam_age_min
          FROM exam_type
         WHERE id_exam_type = nvl(i_exam_type, id_exam_type)
           AND flg_type = nvl(i_flg_type, flg_type);
    
        g_error := 'GET PAT GENDER';
        OPEN c_pat_gender;
        FETCH c_pat_gender
            INTO l_flg_female_exam, l_age;
        CLOSE c_pat_gender;
    
        g_error := 'CHECK PATIENT AGE';
        IF l_age IS NULL
           OR l_age <= l_exam_age_min
           OR l_age >= l_exam_age_max
        THEN
            l_flg_female_exam := g_no;
        END IF;
    
        o_flg_female_exam := l_flg_female_exam;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CHECK_EXAM_TYPE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_exam_type;

    FUNCTION check_exam_pregn_conditions
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_exam            IN table_number,
        i_exam_req_det    IN table_number, /*exam_req_det.id_exam_req_det%TYPE,*/
        o_flg_female_exam OUT VARCHAR2,
        o_pat_pregnancy   OUT pk_types.cursor_type,
        o_pat_exams       OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Verificar se os exames requisitados contêm ecografias ginecológicas pélvicas e quais as condições de requisição
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_PATIENT - ID do paciente
                                 I_EXAM - Lista de exames requisitados
                                 I_EXAM_REQ_DET - ID do detalhe da requisição do exame
                         SAIDA:  O_FLG_FEMALE_EXAM - Indica se paciente é mulher e se o exame requisitado é ecog. pelvica ginecologica.
                                 Se 'B' entao redirecciona para o ecra de criação de gravidez
                                 O_PAT_PREGNANCY - Gravidez activa do paciente caso esta exista
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 23/05/2007
        *********************************************************************************/
    
        l_flg_female_exam       VARCHAR2(0050);
        l_age                   NUMBER;
        l_dt_pregnancy          DATE;
        l_dt_exam_result        DATE;
        l_ret                   BOOLEAN;
        l_weeks                 NUMBER;
        l_trimester             NUMBER;
        l_desc_trimester        VARCHAR2(0050);
        l_bypass_yes            VARCHAR2(0050);
        l_check_bypass          NUMBER;
        l_check_wh              NUMBER;
        l_flg_bypass_validation VARCHAR2(0050);
        l_id_exam_type          exam_type.id_exam_type%TYPE;
    
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_count_results       NUMBER;
        l_counter_exams_pregn NUMBER := 0;
        l_id_exam             exam.id_exam%TYPE;
    
        l_flg_status    VARCHAR2(2 CHAR);
        l_status_string VARCHAR2(50 CHAR);
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
        CURSOR c_weeks_pregnancy(i IN NUMBER) IS
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.dt_init_preg_lmp, CAST(pp.dt_intervention AS DATE)
              FROM pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det(i), 'Y')) er
             WHERE er.id_pat_pregnancy = pp.id_pat_pregnancy
               AND pp.dt_intervention IS NOT NULL
            UNION ALL
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.dt_init_preg_lmp, MAX(CAST(er.dt_result AS DATE))
              FROM pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det(i), 'Y')) er
             WHERE er.id_pat_pregnancy = pp.id_pat_pregnancy
             GROUP BY pp.dt_init_preg_lmp;
    
    BEGIN
        o_pat_exams  := table_number();
        l_bypass_yes := 'B';
        l_weeks      := 0;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        -- imaging technicians don't support this worflow
        IF /*i_prof.software = pk_alert_constant.g_soft_imgtech
                                                                                                                                                                                                                                                                                                                                                                                                                           OR*/
         l_flg_profile = pk_alert_constant.g_flg_student
        THEN
            o_flg_female_exam := pk_alert_constant.get_no;
            pk_types.open_my_cursor(o_pat_pregnancy);
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL TO CHECK_EXAM_TYPE';
        IF NOT check_exam_type(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_patient         => i_patient,
                               i_exam_type       => NULL,
                               i_flg_type        => g_exam_ultrasound,
                               o_flg_female_exam => l_flg_female_exam,
                               o_exam_type       => l_id_exam_type,
                               o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF i_exam IS NOT NULL
           AND i_exam_req_det IS NOT NULL
           AND i_exam_req_det.count > 0
        THEN
        
            FOR i IN 1 .. i_exam.count
            LOOP
            
                BEGIN
                    SELECT DISTINCT a.id_exam
                      INTO l_id_exam
                      FROM exam_type_group a
                     INNER JOIN exam_type b
                        ON a.id_exam_type = b.id_exam_type
                     WHERE a.id_exam = i_exam(i)
                       AND b.flg_type = g_exam_ultrasound;
                EXCEPTION
                    WHEN no_data_found THEN
                        CONTINUE;
                END;
                l_counter_exams_pregn := l_counter_exams_pregn + 1;
                o_pat_exams.extend;
                o_pat_exams(l_counter_exams_pregn) := i_exam_req_det(i);
            
            END LOOP;
        END IF;
    
        IF l_flg_female_exam = pk_alert_constant.get_no
        THEN
            o_flg_female_exam := l_flg_female_exam;
            pk_types.open_my_cursor(o_pat_pregnancy);
            RETURN TRUE;
        END IF;
    
        l_flg_female_exam := pk_alert_constant.get_no;
    
        g_error := 'CHECK EXAM TYPE';
    
        l_check_bypass := 0;
        l_check_wh     := 0;
    
        IF i_exam IS NOT NULL
        THEN
        
            FOR i IN 1 .. i_exam.count
            LOOP
                BEGIN
                    SELECT flg_bypass_validation
                      INTO l_flg_bypass_validation
                      FROM exam_type_group
                     WHERE id_exam = i_exam(i)
                       AND id_exam_type = l_id_exam_type
                       AND id_software IN (i_prof.software, 0)
                       AND id_institution IN (i_prof.institution, 0);
                
                    l_check_wh := l_check_wh + 1;
                
                    IF l_flg_bypass_validation = pk_alert_constant.get_yes
                    THEN
                        l_check_bypass := l_check_bypass + 1;
                    END IF;
                
                    -- COMO ENCONTROU, SAI LOGO DO LOOP
                    EXIT;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            
            END LOOP;
        END IF;
    
        l_flg_female_exam := pk_alert_constant.get_no;
        IF l_check_wh > 0
        THEN
            l_flg_female_exam := pk_alert_constant.get_yes;
        END IF;
    
        IF l_check_bypass > 0
        THEN
            l_flg_female_exam := l_bypass_yes;
        END IF;
    
        o_flg_female_exam := l_flg_female_exam;
    
        g_error := 'GET WEEKS PREGNANCY';
    
        IF i_exam_req_det IS NOT NULL
           AND i_exam_req_det.count > 0
        THEN
        
            FOR i IN 1 .. i_exam_req_det.count
            LOOP
                OPEN c_weeks_pregnancy(i);
                FETCH c_weeks_pregnancy
                    INTO l_dt_pregnancy, l_dt_exam_result;
                CLOSE c_weeks_pregnancy;
            
                l_ret := pk_woman_health.get_preg_converted_time(i_lang,
                                                                 NULL,
                                                                 l_dt_pregnancy,
                                                                 l_dt_exam_result,
                                                                 l_weeks,
                                                                 l_trimester,
                                                                 l_desc_trimester,
                                                                 o_error);
            
                IF l_weeks IS NOT NULL
                   AND l_weeks > 0
                THEN
                    EXIT;
                END IF;
            
            END LOOP;
        
            g_error := 'OPEN O_PAT_PREGNANCY';
            OPEN o_pat_pregnancy FOR
                SELECT pregn.id_pat_pregnancy,
                       pregn.n_pregnancy num_pregnancy,
                       nvl(pregn.dt_init_preg_lmp, pregn.dt_init_pregnancy) dt_last_menstruation,
                       pk_date_utils.dt_chr(i_lang, pregn.dt_last_menstruation, i_prof) dt_last_menstruation_f,
                       CAST(pregn.dt_intervention AS DATE) dt_childbirth,
                       pk_date_utils.date_char_tsz(i_lang, pregn.dt_intervention, i_prof.institution, i_prof.software) dt_childbirth_f,
                       NULL flg_childbirth_type,
                       NULL desc_childbirth_type,
                       pregn.n_children,
                       NULL flg_abbort,
                       NULL desc_abbort,
                       pregn.flg_multiple,
                       pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TYPE', pregn.flg_multiple, i_lang) desc_multiple,
                       l_weeks weeks_c,
                       pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER',
                                               to_char(pk_woman_health.conv_weeks_to_trimester(l_weeks)),
                                               i_lang) trimester,
                       nvl2(pregn.dt_last_menstruation, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_has_dt_menstr,
                       nvl(pregn.n_children, 1) fetus_qty
                  FROM pat_pregnancy pregn
                 WHERE pregn.id_patient = i_patient
                   AND pregn.flg_status = g_flg_pregnancy_active;
        ELSE
        
            g_error := 'OPEN O_PAT_PREGNANCY';
            OPEN o_pat_pregnancy FOR
                SELECT pregn.id_pat_pregnancy,
                       pregn.n_pregnancy num_pregnancy,
                       nvl(pregn.dt_init_preg_lmp, pregn.dt_init_pregnancy) dt_last_menstruation,
                       pk_date_utils.dt_chr(i_lang, pregn.dt_last_menstruation, i_prof) dt_last_menstruation_f,
                       CAST(pregn.dt_intervention AS DATE) dt_childbirth,
                       pk_date_utils.date_char_tsz(i_lang, pregn.dt_intervention, i_prof.institution, i_prof.software) dt_childbirth_f,
                       NULL flg_childbirth_type,
                       NULL desc_childbirth_type,
                       pregn.n_children,
                       NULL flg_abbort,
                       NULL desc_abbort,
                       pregn.flg_multiple,
                       pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TYPE', pregn.flg_multiple, i_lang) desc_multiple,
                       l_weeks weeks_c,
                       pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER',
                                               to_char(pk_woman_health.conv_weeks_to_trimester(l_weeks)),
                                               i_lang) trimester,
                       nvl2(pregn.dt_last_menstruation, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_has_dt_menstr,
                       nvl(pregn.n_children, 1) fetus_qty
                  FROM pat_pregnancy pregn
                 WHERE pregn.id_patient = i_patient
                   AND pregn.flg_status = g_flg_pregnancy_active;
        
        END IF;
    
        /*18-09-2019 - If pass more than 6 months, then clean the lines commented below. Thank you!*/
    
        /*IF i_exam_req_det IS NOT NULL
           AND i_exam_req_det.count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count_results
              FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er
             WHERE er.id_exam_result IS NOT NULL;
        
            IF l_count_results > 0
            THEN
                o_flg_female_exam := pk_alert_constant.get_yes;
            ELSE
                o_flg_female_exam := pk_alert_constant.get_yes;
            END IF;
        END IF;*/
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CHECK_EXAM_PREGN_CONDITIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_pat_pregnancy);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_exam_pregn_conditions;

    FUNCTION check_exam_pregn
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_exam_req        IN table_number,
        o_flg_female_exam OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_female_exam VARCHAR2(0050);
    
        l_bypass_yes            VARCHAR2(0050);
        l_check_bypass          NUMBER;
        l_check_wh              NUMBER;
        l_flg_bypass_validation VARCHAR2(0050);
        l_id_exam_type          exam_type.id_exam_type%TYPE;
    
        l_exam table_number := table_number();
    
        l_flg_profile profile_template.flg_profile%TYPE;
    
        l_count PLS_INTEGER := 0;
    
        l_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        l_bypass_yes := 'B';
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        -- imaging technicians don't support this worflow
        IF l_flg_profile = pk_alert_constant.g_flg_student
        THEN
            o_flg_female_exam := pk_alert_constant.get_no;
            RETURN TRUE;
        END IF;
    
        g_error := 'CALL TO CHECK_EXAM_TYPE';
        IF NOT check_exam_type(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_patient         => i_patient,
                               i_exam_type       => NULL,
                               i_flg_type        => g_exam_ultrasound,
                               o_flg_female_exam => l_flg_female_exam,
                               o_exam_type       => l_id_exam_type,
                               o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_flg_female_exam = pk_alert_constant.get_no
        THEN
            o_flg_female_exam := l_flg_female_exam;
            RETURN TRUE;
        END IF;
    
        l_flg_female_exam := pk_alert_constant.get_no;
    
        g_error := 'CHECK EXAM TYPE';
    
        l_check_bypass := 0;
        l_check_wh     := 0;
    
        SELECT DISTINCT erd.id_exam
          BULK COLLECT
          INTO l_exam
          FROM exam_req er
          JOIN exam_req_det erd
            ON erd.id_exam_req = er.id_exam_req
         WHERE er.id_exam_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   t.*
                                    FROM TABLE(i_exam_req) t)
           AND erd.flg_status NOT IN ('C');
    
        IF l_exam IS NOT NULL
        THEN
            FOR i IN 1 .. l_exam.count
            LOOP
                BEGIN
                    SELECT flg_bypass_validation
                      INTO l_flg_bypass_validation
                      FROM exam_type_group
                     WHERE id_exam = l_exam(i)
                       AND id_exam_type = l_id_exam_type
                       AND id_software IN (i_prof.software, 0)
                       AND id_institution IN (i_prof.institution, 0);
                
                    l_check_wh := l_check_wh + 1;
                
                    IF l_flg_bypass_validation = pk_alert_constant.get_yes
                    THEN
                        l_check_bypass := l_check_bypass + 1;
                    END IF;
                
                    -- COMO ENCONTROU, SAI LOGO DO LOOP
                    EXIT;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END LOOP;
        END IF;
    
        l_flg_female_exam := pk_alert_constant.get_no;
        IF l_check_wh > 0
        THEN
            l_flg_female_exam := pk_alert_constant.get_yes;
        END IF;
    
        IF l_check_bypass > 0
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM pat_pregnancy pregn
             WHERE pregn.id_patient = i_patient
               AND pregn.flg_status = g_flg_pregnancy_active;
        
            IF l_count > 0
            THEN
                l_flg_female_exam := l_bypass_yes;
            ELSE
                l_flg_female_exam := 'BN';
            END IF;
        END IF;
    
        o_flg_female_exam := l_flg_female_exam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CHECK_EXAM_PREGN',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_exam_pregn;

    FUNCTION get_exam_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam_type IN exam_type.flg_type%TYPE,
        o_exam      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Lista de exames de um determinado tipo (com base na tabela exam_type)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_TYPE - Tipo de exames
                         SAIDA:  O_EXAM - Lista de exames
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 28/05/2007
        *********************************************************************************/
    BEGIN
    
        g_error := 'GET EXAM LIST';
        OPEN o_exam FOR
            SELECT DISTINCT pk_exams_api_db.get_alias_translation(i_lang, i_prof, e.code_exam, NULL) exam,
                            pk_mcdt.check_mcdt_laterality(i_lang, i_prof, 'E', e.id_exam) flg_laterality_mcdt,
                            e.id_exam,
                            'E' TYPE,
                            ed.rank
              FROM exam e, exam_type et, exam_dep_clin_serv ed, exam_type_group etg
             WHERE et.flg_type = i_exam_type
               AND et.id_exam_type = etg.id_exam_type
               AND etg.id_exam = e.id_exam
               AND etg.id_software IN (i_prof.software, 0)
               AND etg.id_institution IN (i_prof.institution, 0)
               AND e.flg_available = g_flg_available
               AND ed.id_exam = e.id_exam
               AND ed.id_institution = i_prof.institution
               AND ed.id_software = i_prof.software
               AND ed.flg_type = 'P'
               AND e.flg_type = g_exam_type_img
             ORDER BY rank, exam;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_TYPE_LIST',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_exam);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_type_list;

    FUNCTION get_epis_cab_exam_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN exam_req.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_exam_type     IN exam.flg_type%TYPE,
        i_flg_type      IN exam_type.flg_type%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_exam          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter as requisições de exames de um episódio associados a um tipo (com base na exam_type)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EPIS - ID do episódio
                                 I_PATIENT - ID do paciente
                                 I_EXAM_TYPE - Tipo de exames
                                 I_FLG_TYPE - Tipo de exames (pode ser considerado um sub-tipo de I_EXAM_TYPE)
                         SAIDA:  O_EXAM - Lista de exames
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 29/05/2007
        *********************************************************************************/
    
        l_ret                  BOOLEAN;
        l_id_pat_pregnancy     NUMBER;
        l_dt_exam_result       DATE;
        l_dt_req               TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_last_menstruation DATE;
        l_flg_weeks            VARCHAR2(0050);
        l_msg_notes            sys_message.desc_message%TYPE;
    
        CURSOR c_cat IS
            SELECT cat.flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category;
    
        l_cat category.flg_type%TYPE;
    
        l_exam           pk_exam_external.t_cur_exam_listview;
        l_r_epis_exam    pk_exam_external.t_rec_exam_listview;
        l_num_weeks      NUMBER(6);
        l_trimester      NUMBER(6);
        l_desc_trimester VARCHAR2(50);
        l_exception EXCEPTION;
    
        CURSOR c_pat_pregnancy(i_id_exam_req_det IN NUMBER) IS
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.id_pat_pregnancy,
             CAST(pp.dt_intervention AS DATE),
             er.dt_req dt_req_tstz,
             erp.flg_weeks_criteria,
             erp.weeks_pregnancy,
             pp.dt_init_pregnancy
              FROM exam_result_pregnancy erp,
                   pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_id_exam_req_det, 'Y')) er
             WHERE erp.id_exam_result(+) = er.id_exam_result
               AND er.id_pat_pregnancy = pp.id_pat_pregnancy(+)
            UNION ALL
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.id_pat_pregnancy,
             MAX(CAST(er.dt_result AS DATE)),
             er.dt_req dt_req_tstz,
             erp.flg_weeks_criteria,
             erp.weeks_pregnancy,
             pp.dt_init_pregnancy
              FROM exam_result_pregnancy erp,
                   pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_id_exam_req_det, 'Y')) er
             WHERE erp.id_exam_result(+) = er.id_exam_result
               AND er.id_pat_pregnancy = pp.id_pat_pregnancy(+)
             GROUP BY pp.id_pat_pregnancy, er.dt_req, flg_weeks_criteria, weeks_pregnancy, dt_init_pregnancy;
    
    BEGIN
    
        pk_alert_constant.date_hour_send_format(i_prof);
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_CAT';
        OPEN c_cat;
        FETCH c_cat
            INTO l_cat;
        CLOSE c_cat;
    
        l_msg_notes := pk_message.get_message(i_lang, 'COMMON_M008');
    
        IF i_epis IS NULL
        THEN
            g_error := 'MISSING ID_EPISODE';
            pk_types.open_my_cursor(o_exam);
            RAISE l_exception;
        END IF;
        g_error := 'GET EPIS EXAM';
        IF NOT pk_exams_external_api_db.get_exam_listview(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_patient      => i_patient,
                                                          i_episode      => i_epis,
                                                          i_exam_type    => g_exam_type_img,
                                                          i_flg_all_exam => g_yes,
                                                          i_scope        => i_epis,
                                                          i_flg_scope    => pk_alert_constant.g_scope_type_episode,
                                                          i_start_date   => NULL,
                                                          i_end_date     => NULL,
                                                          i_cancelled    => NULL,
                                                          i_crit_type    => NULL,
                                                          o_list         => l_exam,
                                                          o_error        => o_error)
        THEN
            pk_types.open_my_cursor(o_exam);
            RETURN FALSE;
        END IF;
    
        DELETE tmp_epis_exam;
    
        g_error := 'FETCH EPIS EXAM';
        LOOP
            FETCH l_exam
                INTO l_r_epis_exam;
        
            EXIT WHEN l_exam%NOTFOUND;
        
            g_error := 'OPEN c_pat_pregnancy';
            OPEN c_pat_pregnancy(l_r_epis_exam.id_exam_req_det);
            FETCH c_pat_pregnancy
                INTO l_id_pat_pregnancy, l_dt_exam_result, l_dt_req, l_flg_weeks, l_num_weeks, l_dt_last_menstruation;
            CLOSE c_pat_pregnancy;
            IF l_flg_weeks = pk_pregnancy_core.g_ultrasound_criteria
               AND l_num_weeks IS NOT NULL
            THEN
                g_error := 'CONVERT PREGNANCY DATE 1';
                l_ret   := pk_woman_health.get_preg_converted_time(i_lang,
                                                                   l_num_weeks,
                                                                   NULL,
                                                                   NULL,
                                                                   l_num_weeks,
                                                                   l_trimester,
                                                                   l_desc_trimester,
                                                                   o_error);
            
                IF l_ret = FALSE
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSIF l_flg_weeks = pk_pregnancy_core.g_pregnant_criteria
                  OR l_flg_weeks IS NULL
            THEN
                g_error := 'CONVERT PREGNANCY DATE 2';
                l_ret   := pk_woman_health.get_preg_converted_time(i_lang,
                                                                   NULL,
                                                                   l_dt_last_menstruation,
                                                                   nvl(l_dt_exam_result, CAST(l_dt_req AS DATE)),
                                                                   l_num_weeks,
                                                                   l_trimester,
                                                                   l_desc_trimester,
                                                                   o_error);
            
                IF l_ret = FALSE
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            g_error := 'INSERT INTO TEMP TABLE';
            INSERT INTO tmp_epis_exam
                (id_exam_req,
                 dt,
                 rank,
                 id_exam_req_det,
                 flg_status,
                 flg_time,
                 id_exam,
                 dt_req,
                 flg_mov_pat,
                 desc_status,
                 desc_epi_ant,
                 desc_flg_time,
                 dt_begin,
                 date_target,
                 hour_target,
                 dt_target,
                 desc_exam,
                 avail_butt_ok,
                 avail_butt_det,
                 notes,
                 title_notes,
                 prof_req,
                 date_req,
                 hour_req,
                 avail_butt_cancel,
                 flg_cancel,
                 dt_ord1,
                 dt_ord2,
                 flg_shortcut,
                 desc_diagnosis,
                 status_string,
                 num_weeks,
                 trimester,
                 desc_trimester,
                 id_task_dependency,
                 icon_name)
            VALUES
                (l_r_epis_exam.id_exam_req,
                 NULL,
                 l_r_epis_exam.rank,
                 l_r_epis_exam.id_exam_req_det,
                 l_r_epis_exam.flg_status,
                 l_r_epis_exam.flg_time,
                 l_r_epis_exam.id_exam,
                 NULL,
                 NULL,
                 l_r_epis_exam.desc_status,
                 NULL,
                 l_r_epis_exam.to_be_perform,
                 NULL,
                 l_r_epis_exam.dt_begin,
                 l_r_epis_exam.hr_begin,
                 NULL,
                 l_r_epis_exam.desc_exam,
                 l_r_epis_exam.avail_button_ok,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 l_r_epis_exam.avail_button_cancel,
                 NULL,
                 NULL,
                 NULL,
                 NULL,
                 l_r_epis_exam.desc_diagnosis,
                 l_r_epis_exam.status_string,
                 l_num_weeks,
                 l_trimester,
                 l_desc_trimester,
                 l_r_epis_exam.id_task_dependency,
                 l_r_epis_exam.icon_name);
        
            g_error := 'after INSERT INTO TEMP TABLE';
        END LOOP;
        CLOSE l_exam;
    
        g_error := 'GET EXAM TYPE LIST';
        OPEN o_exam FOR
            SELECT tmp.*
              FROM tmp_epis_exam tmp
              JOIN exam_req_det erd
                ON erd.id_exam_req_det = tmp.id_exam_req_det
             WHERE erd.id_pat_pregnancy = i_pat_pregnancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EPIS_CAB_EXAM_TYPE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_exam);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_cab_exam_type;

    /******************************************************************************
    OBJECTIVO: -
    PARAMETROS:  ENTRADA:
                    I_LANG                    - Língua registada como preferência do profissional
                    I_PROF                    - ID do profissional, software e instituição
                    I_ID_NEW_RESULT_PREGNANCY - ID DE EXAM_RESULT_PREGNANCY
                    I_ID_PAT_PREGN_FETUS      - ID do feto para a gravidez corrente
                    I_ID_EPIS_DOCUMENTATION   - ID da DOCUMENTATION a associar
    
             SAIDA:
                    O_ID_EXAM_RES_PREGN_FETUS - ID criado
                    O_ERROR - erro
    
    CRIAÇÃO: CMF 31/05/2007
    *********************************************************************************/
    FUNCTION set_new_res_pregn_fetus
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_new_result_pregnancy IN exam_result_pregnancy.id_exam_result_pregnancy%TYPE,
        i_id_pat_pregn_fetus      IN pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_gender              IN exam_res_pregn_fetus.flg_gender%TYPE,
        o_id_exam_res_pregn_fetus OUT exam_res_pregn_fetus.id_exam_res_pregn_fetus%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next NUMBER;
        l_comm VARCHAR2(4000);
    BEGIN
    
        l_comm := 'GET SEQUENCE';
        SELECT seq_exam_res_pregn_fetus.nextval
          INTO l_next
          FROM dual;
    
        INSERT INTO exam_res_pregn_fetus
            (id_exam_res_pregn_fetus, id_exam_result_pregnancy, id_pat_pregn_fetus, id_epis_documentation, flg_gender)
        VALUES
            (l_next, i_id_new_result_pregnancy, i_id_pat_pregn_fetus, i_id_epis_documentation, i_flg_gender);
    
        o_id_exam_res_pregn_fetus := l_next;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_NEW_RES_PREGN_FETUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_new_res_pregn_fetus;

    /******************************************************************************
    OBJECTIVO: --
    PARAMETROS:  ENTRADA:
                    I_LANG                    - Língua registada como preferência do profissional
                    I_PROF                    - ID do profissional, software e instituição
                    I_ID_PAT_PREGNANCY        - ID da gravidez
                    I_ID_EXAM_RESULT          - ID do RESULTADO DE ANALISE
                    I_ID_EPIS_DOCUMENTATION   - ID DA DOCUMENTATION ASSOCIADA
    
             SAIDA:
                    O_ID_NEW_RESULT_PREGNANCY - id DE EXAM_RESULT_PREGNANCY
                    O_ERROR - erro
    
    CRIAÇÃO: CMF 31/05/2007
    *********************************************************************************/
    FUNCTION set_new_result_pregnancy
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat_pregnancy        IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_exam_result          IN exam_result.id_exam_result%TYPE,
        i_weeks                   IN exam_result_pregnancy.weeks_pregnancy%TYPE,
        i_flg_criteria            IN exam_result_pregnancy.flg_weeks_criteria%TYPE,
        i_flg_multiple            IN exam_result_pregnancy.flg_multiple%TYPE,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE,
        i_fetus_number            IN pat_pregnancy.n_children%TYPE,
        o_id_new_result_pregnancy OUT exam_result_pregnancy.id_exam_result_pregnancy%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next           NUMBER;
        l_flg_pregnant   VARCHAR2(1);
        l_dt_exam_result exam_result.dt_exam_result_tstz%TYPE;
        l_dt_init_pregn  pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_pdel_us     pat_pregnancy.dt_pdel_correct%TYPE;
        l_exception EXCEPTION;
        l_rowids             table_varchar;
        l_curr_fetus_num     pat_pregnancy.n_children%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
    
    BEGIN
    
        g_error := 'INSERT RESULT PREGNANCY';
        SELECT seq_exam_result_pregnancy.nextval
          INTO l_next
          FROM dual;
    
        l_flg_pregnant := 'Y';
        IF i_id_pat_pregnancy IS NULL
        THEN
            l_flg_pregnant := 'N';
        END IF;
    
        INSERT INTO exam_result_pregnancy
            (id_exam_result_pregnancy,
             id_exam_result,
             flg_pregnant,
             id_pat_pregnancy,
             id_epis_documentation,
             weeks_pregnancy,
             flg_weeks_criteria,
             flg_multiple)
        VALUES
            (l_next,
             i_id_exam_result,
             l_flg_pregnant,
             i_id_pat_pregnancy,
             i_id_epis_documentation,
             i_weeks,
             i_flg_criteria,
             i_flg_multiple);
    
        g_error := 'CHECK ULTRASOUND CRITERIA';
        IF i_flg_criteria = pk_pregnancy_core.g_ultrasound_criteria
           AND i_weeks IS NOT NULL
        THEN
            SELECT er.dt_result
              INTO l_dt_exam_result
              FROM TABLE(pk_exam_external.tf_exam_pregnancy_result_info(i_lang, i_prof, i_id_exam_result)) er;
        
            g_error         := 'GET DT_INIT';
            l_dt_init_pregn := pk_pregnancy_api.get_dt_pregnancy_start(i_prof            => i_prof,
                                                                       i_num_weeks       => NULL,
                                                                       i_num_weeks_exam  => NULL,
                                                                       i_num_weeks_us    => i_weeks,
                                                                       i_dt_intervention => l_dt_exam_result,
                                                                       i_flg_precision   => pk_pregnancy_core.g_dt_flg_precision_h);
        
            g_error      := 'GET DT_END';
            l_dt_pdel_us := pk_pregnancy_api.get_dt_pregnancy_end(i_lang, i_prof, i_weeks, NULL, l_dt_init_pregn);
        
            g_error := 'SET PREGNANCY HISTORY';
            IF NOT pk_pregnancy_api.set_pat_pregnancy_hist(i_lang, i_id_pat_pregnancy, o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'UPDATE PAT PREGNANCY';
            ts_pat_pregnancy.upd(dt_init_pregnancy_in     => l_dt_init_pregn,
                                 num_gest_weeks_us_in     => i_weeks,
                                 dt_pdel_correct_in       => l_dt_pdel_us,
                                 id_pat_pregnancy_in      => i_id_pat_pregnancy,
                                 id_professional_in       => i_prof.id,
                                 dt_pat_pregnancy_tstz_in => current_timestamp,
                                 rows_out                 => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_PREGNANCY',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
        END IF;
    
        IF i_id_pat_pregnancy IS NOT NULL
           AND i_fetus_number IS NOT NULL
        THEN
            g_error          := 'GET FETUS NUMBER';
            l_curr_fetus_num := nvl(pk_pregnancy_api.get_fetus_number(i_lang, i_prof, i_id_pat_pregnancy), 0);
        
            IF l_curr_fetus_num <> i_fetus_number
            THEN
                g_error := 'CHECK IF PREGNANCY_HISTORY WAS ALREADY INSERTED';
                IF (nvl(i_flg_criteria, pk_pregnancy_core.g_pregnant_criteria) <>
                   pk_pregnancy_core.g_ultrasound_criteria OR i_weeks IS NULL)
                THEN
                    IF NOT pk_pregnancy_api.set_pat_pregnancy_hist(i_lang, i_id_pat_pregnancy, o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    ts_pat_pregnancy.upd(id_pat_pregnancy_in      => i_id_pat_pregnancy,
                                         id_professional_in       => i_prof.id,
                                         dt_pat_pregnancy_tstz_in => current_timestamp,
                                         rows_out                 => l_rowids);
                END IF;
            
                g_error := 'SET FETUS NUMBER';
                ts_pat_pregnancy.upd(id_pat_pregnancy_in => i_id_pat_pregnancy,
                                     n_children_in       => i_fetus_number,
                                     rows_out            => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PREGNANCY',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'SET FETUS INFO';
                IF NOT pk_pregnancy.set_pat_pregn_fetus(i_lang,
                                                        i_prof,
                                                        i_id_pat_pregnancy,
                                                        i_fetus_number,
                                                        NULL,
                                                        NULL,
                                                        table_varchar(),
                                                        table_varchar(),
                                                        table_varchar(),
                                                        table_number(),
                                                        table_varchar(),
                                                        table_varchar(),
                                                        table_varchar(),
                                                        l_id_pat_pregn_fetus,
                                                        o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        o_id_new_result_pregnancy := l_next;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_NEW_RESULT_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_new_result_pregnancy;

    /******************************************************************************
    OBJECTIVO: GRAVA OS RESULTADOS DE ECOGRAFIA DE SAUDE MATERNA
    PARAMETROS:  ENTRADA:
                    I_LANG                    - Língua registada como preferência do profissional
                    I_PROF                    - ID do profissional, software e instituição
                    I_ID_PAT_PREGNANCY        - ID da gravidez
                    I_ID_EPIS_DOCUMENTATION   - ID DA DOCUMENTATION ASSOCIADA
    
             SAIDA:
                    O_ERROR - erro
    
    CRIAÇÃO: CMF 31/05/2007
    *********************************************************************************/
    FUNCTION set_result_fetus
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_pat_pregnancy      IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_id_exam_result        IN exam_result.id_exam_result%TYPE,
        i_fetus_number          IN pat_pregn_fetus.fetus_number%TYPE,
        i_flg_gender            IN pat_pregn_fetus.flg_gender%TYPE,
        i_vs                    IN table_number,
        i_vs_value              IN table_number,
        i_vs_doc                IN table_number,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_tbl_documentation  IN table_number,
        i_id_tbl_element        IN table_number,
        i_id_tbl_element_crit   IN table_number,
        i_tbl_value             IN table_varchar,
        i_doc_notes             IN epis_documentation_det.notes%TYPE,
        o_id_pat_pregn_fetus    OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        r_sul                     exam_result%ROWTYPE;
        l_epis_complaint          NUMBER;
        l_comm                    VARCHAR2(4000);
        l_ret                     BOOLEAN;
        l_commit                  VARCHAR2(0050);
        o_id_new_result           exam_result.id_exam_result%TYPE;
        o_id_biom                 pat_pregn_fetus_biom.id_pat_pregn_fetus_biom%TYPE;
        o_id_new_result_pregnancy exam_result_pregnancy.id_exam_result_pregnancy%TYPE;
    
        o_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        l_id_doc_fetus        epis_documentation.id_epis_documentation%TYPE;
        l_id_doc_not_pregnant epis_documentation.id_epis_documentation%TYPE;
    
        o_id_exam_res_pregn_fetus    exam_res_pregn_fetus.id_exam_res_pregn_fetus%TYPE;
        o_id_exam_res_fetus_biom     exam_res_fetus_biom.id_exam_res_fetus_biom%TYPE;
        o_id_exam_res_fetus_biom_img exam_res_fetus_biom_img.id_exam_res_fetus_biom_img%TYPE;
    
        l_rowids table_varchar := table_varchar();
        l_exception EXCEPTION;
    BEGIN
    
        l_commit         := 'N';
        l_epis_complaint := NULL;
    
        l_comm := 'GET INFO EXAM_RESULT';
        SELECT er.id_episode -- José Brito ALERT-56027 16/11/2009
          INTO r_sul.id_episode
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_result_info(i_lang, i_prof, i_id_exam_result)) er;
    
        l_comm          := 'SAVE NEW RESULT';
        o_id_new_result := i_id_exam_result;
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        l_ret := pk_documentation.set_epis_bartchart(i_lang,
                                                     i_prof,
                                                     r_sul.id_episode,
                                                     i_id_doc_area,
                                                     l_epis_complaint,
                                                     i_id_tbl_documentation,
                                                     i_id_tbl_element,
                                                     i_id_tbl_element_crit,
                                                     i_tbl_value,
                                                     i_doc_notes,
                                                     l_commit,
                                                     o_id_epis_documentation,
                                                     o_error);
        IF l_ret = FALSE
           OR nvl(o_id_epis_documentation, 0) = 0
        THEN
            RAISE l_exception;
        END IF;
    
        l_comm := 'IF NOT PREGNANT, SAVE RESULTS'; -- SHE'S NOT PREGNANT
        IF i_id_pat_pregnancy IS NULL
        THEN
        
            l_id_doc_fetus        := NULL;
            l_id_doc_not_pregnant := o_id_epis_documentation;
        
        ELSE
        
            l_id_doc_fetus        := o_id_epis_documentation;
            l_id_doc_not_pregnant := NULL;
        
        END IF;
    
        l_comm := 'GET EXAM RESULT PREGNANCY';
        SELECT ep.id_exam_result_pregnancy
          INTO o_id_new_result_pregnancy
          FROM exam_result_pregnancy ep
         WHERE id_exam_result = i_id_exam_result;
    
        l_comm               := 'GET PAT_PREGN_FETUS ID';
        o_id_pat_pregn_fetus := pk_pregnancy_api.get_pregn_fetus_id(i_lang          => i_lang,
                                                                    i_prof          => i_prof,
                                                                    i_pat_pregnancy => i_id_pat_pregnancy,
                                                                    i_fetus_number  => i_fetus_number);
    
        l_comm := 'SAVE NEW_RES_PREGN_FETUS';
        l_ret  := set_new_res_pregn_fetus(i_lang,
                                          i_prof,
                                          o_id_new_result_pregnancy,
                                          o_id_pat_pregn_fetus,
                                          l_id_doc_fetus,
                                          i_flg_gender,
                                          o_id_exam_res_pregn_fetus,
                                          o_error);
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        l_comm := 'SET FETUS BIOM';
        FOR i IN 1 .. i_vs.count
        LOOP
        
            l_ret := pk_woman_health.set_new_fetus_biom(i_lang,
                                                        i_prof,
                                                        o_id_pat_pregn_fetus,
                                                        i_vs(i),
                                                        i_vs_value(i),
                                                        o_id_biom,
                                                        o_error);
            IF l_ret = FALSE
            THEN
                RAISE l_exception;
            END IF;
        
            l_ret := set_new_exam_res_fetus_biom(i_lang,
                                                 i_prof,
                                                 o_id_biom,
                                                 o_id_exam_res_pregn_fetus,
                                                 o_id_exam_res_fetus_biom,
                                                 o_error);
            IF l_ret = FALSE
            THEN
                RAISE l_exception;
            END IF;
        
            l_ret := set_new_res_fetus_biom_img(i_lang,
                                                i_prof,
                                                o_id_exam_res_fetus_biom,
                                                i_vs_doc(i),
                                                o_id_exam_res_fetus_biom_img,
                                                o_error);
            IF l_ret = FALSE
            THEN
                RAISE l_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_comm,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_RESULT_FETUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_result_fetus;

    FUNCTION set_new_exam_res_fetus_biom
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_pat_pregn_fetus_biom IN pat_pregn_fetus_biom.id_pat_pregn_fetus_biom%TYPE,
        i_id_exam_res_pregn_fetus IN exam_res_pregn_fetus.id_exam_res_pregn_fetus%TYPE,
        o_id_exam_res_fetus_biom  OUT exam_res_fetus_biom.id_exam_res_fetus_biom%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next NUMBER;
    BEGIN
    
        SELECT seq_exam_res_fetus_biom.nextval
          INTO l_next
          FROM dual;
    
        INSERT INTO exam_res_fetus_biom
            (id_exam_res_fetus_biom, id_pat_pregn_fetus_biom, id_exam_res_pregn_fetus)
        VALUES
            (l_next, i_id_pat_pregn_fetus_biom, i_id_exam_res_pregn_fetus);
    
        o_id_exam_res_fetus_biom := l_next;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_NEW_EXAM_RES_FETUS_BIOM',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_new_exam_res_fetus_biom;

    FUNCTION get_exam_type_vs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_exam_type  IN exam_type.flg_type%TYPE,
        o_vital_sign OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter os sinais vitais associados ao registo de resultados de um determinado tipo de exames
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_TYPE - Tipo de exame
                         SAIDA:  O_VITAL_SIGN - Lista de SINAIS VITAIS
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET VITAL_SIGNS';
        OPEN o_vital_sign FOR
            SELECT DISTINCT vs.id_vital_sign,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_vital_sign,
                            pk_translation.get_translation(i_lang, um.code_unit_measure) desc_measure
              FROM exam_type et, exam_type_vs etv, vital_sign_unit_measure vum, unit_measure um, vital_sign vs
             WHERE et.flg_type = i_exam_type
               AND et.id_exam_type = etv.id_exam_type
               AND etv.id_vital_sign_unit_measure = vum.id_vital_sign_unit_measure
               AND vum.id_vital_sign = vs.id_vital_sign
               AND vum.id_unit_measure = um.id_unit_measure
               AND vum.id_institution = i_prof.institution
               AND vum.id_software = i_prof.software;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_TYPE_VS',
                                              o_error);
            pk_types.open_my_cursor(o_vital_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_type_vs;

    FUNCTION get_exam_fetus_vs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_exam_result  IN exam_result.id_exam_result%TYPE,
        i_fetus_number IN pat_pregn_fetus.fetus_number%TYPE,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Obter os sinais vitais registados para um feto com base no ID da requisição ou ID do resultado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_TYPE - Tipo de exame
                         SAIDA:  O_VITAL_SIGN - Lista de SINAIS VITAIS
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_url          VARCHAR2(2000);
        g_doc_inactive VARCHAR2(0050);
    BEGIN
    
        g_doc_inactive := 'I';
        l_url          := pk_sysconfig.get_config('URL_DOC_IMAGE', i_prof);
    
        g_error := 'GET FETUS VS';
        OPEN o_vital_sign FOR
            SELECT /*+opt_estimate(table er rows=1)*/
             er.id_exam_result,
             de.id_doc_external,
             pk_message.get_message(i_lang, 'EXAM_IMAGE_T063') label_gender,
             pk_sysdomain.get_domain('PATIENT.GENDER', erf.flg_gender, i_lang) gender,
             ppfb.id_vital_sign,
             ppfb.value,
             pk_translation.get_translation(i_lang, vs.code_vital_sign) desc_vital_sign,
             pk_translation.get_translation(i_lang, um.code_unit_measure) desc_measure,
             erf.id_epis_documentation,
             ppf.fetus_number,
             di.id_doc_image,
             di.file_name name,
             pk_date_utils.date_send_tsz(i_lang, di.dt_img_tstz, i_prof) dt_img,
             REPLACE(REPLACE(REPLACE(l_url, '@1', ebi.id_doc_external), '@2', id_doc_image), '@3', '0') url,
             REPLACE(REPLACE(REPLACE(l_url, '@1', ebi.id_doc_external), '@2', id_doc_image), '@3', '1') url_thumb,
             di.flg_import,
             pk_date_utils.date_send_tsz(i_lang, di.dt_import_tstz, i_prof) dt_import
              FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er,
                   exam_result_pregnancy erp,
                   exam_res_pregn_fetus erf,
                   exam_res_fetus_biom erfb,
                   pat_pregn_fetus_biom ppfb,
                   pat_pregn_fetus ppf,
                   exam_res_fetus_biom_img ebi,
                   doc_external de,
                   doc_image di,
                   vital_sign vs,
                   exam_type et,
                   exam_type_group etg,
                   exam_type_vs etvs,
                   vital_sign_unit_measure vum,
                   unit_measure um
             WHERE er.id_exam_result = nvl(i_exam_result, er.id_exam_result)
               AND er.id_exam_req_det = nvl(i_exam_req_det, er.id_exam_req_det)
               AND erp.id_exam_result = er.id_exam_result
               AND er.id_exam = etg.id_exam
               AND etg.id_exam_type = et.id_exam_type
               AND etg.id_software = (SELECT MAX(etg2.id_software)
                                        FROM exam_type_group etg2
                                       WHERE etg2.id_exam_type = et.id_exam_type
                                         AND etg2.id_software IN (i_prof.software, 0))
               AND etg.id_institution = (SELECT MAX(etg2.id_institution)
                                           FROM exam_type_group etg2
                                          WHERE etg2.id_exam_type = et.id_exam_type
                                            AND etg2.id_institution IN (i_prof.institution, 0))
               AND et.id_exam_type = etvs.id_exam_type
               AND etvs.id_vital_sign_unit_measure = vum.id_vital_sign_unit_measure
               AND vum.id_vital_sign = vs.id_vital_sign
               AND um.id_unit_measure = vum.id_unit_measure
               AND vum.id_software = (SELECT MAX(vsum2.id_software)
                                        FROM vital_sign_unit_measure vsum2
                                       WHERE vsum2.id_vital_sign = vs.id_vital_sign
                                         AND vsum2.id_vital_sign_unit_measure = etvs.id_vital_sign_unit_measure
                                         AND vsum2.id_software IN (i_prof.software, 0))
               AND vum.id_institution = (SELECT MAX(vsum2.id_institution)
                                           FROM vital_sign_unit_measure vsum2
                                          WHERE vsum2.id_vital_sign = vs.id_vital_sign
                                            AND vsum2.id_vital_sign_unit_measure = etvs.id_vital_sign_unit_measure
                                            AND vsum2.id_institution IN (i_prof.institution, 0))
               AND erf.id_exam_result_pregnancy = erp.id_exam_result_pregnancy
               AND erfb.id_exam_res_pregn_fetus = erf.id_exam_res_pregn_fetus
               AND erf.id_pat_pregn_fetus = ppf.id_pat_pregn_fetus
               AND ppf.fetus_number = nvl(i_fetus_number, ppf.fetus_number)
               AND ppfb.id_pat_pregn_fetus_biom = erfb.id_pat_pregn_fetus_biom
               AND ppfb.id_vital_sign = vs.id_vital_sign
               AND ebi.id_exam_res_fetus_biom(+) = erfb.id_exam_res_fetus_biom
               AND de.id_doc_external(+) = ebi.id_doc_external
               AND di.id_doc_external(+) = de.id_doc_external
               AND de.flg_status(+) <> g_doc_inactive
               AND di.flg_status(+) <> g_doc_inactive
             ORDER BY er.id_exam_result DESC, erf.id_epis_documentation, vs.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_FETUS_VS',
                                              o_error);
            pk_types.open_my_cursor(o_vital_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_fetus_vs;

    FUNCTION set_exam_pregn_general
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_exam_req_det   IN exam_req_det.id_exam_req_det%TYPE,
        i_weeks          IN exam_result_pregnancy.weeks_pregnancy%TYPE,
        i_flg_criteria   IN exam_result_pregnancy.flg_weeks_criteria%TYPE,
        i_flg_multiple   IN pat_pregnancy.flg_multiple%TYPE,
        i_fetus_number   IN pat_pregnancy.n_children%TYPE,
        o_id_exam_result OUT exam_result.id_exam_result%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO: Inserir os aspectos gerais do resultado de uma ecografia
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_PATIENT - ID do paciente
                                 I_EXAM_REQ_DET - ID da requisição
                                 I_WEEKS - numero de semanas ecograficas da gravidez
                                 I_FLG_CRITERIA - indica se consideramos a idade ecografica ou a idade cronologica
                                 I_FLG_MULTIPLE - tipo de gestação múltipla
                                 I_TRIMESTER - trimestre da gravidez
                                 I_EXAM_TYPE - Tipo de exame
                         SAIDA:  O_ID_DOC_TEMPLATE - template da documentação a mostrar no resultado
                                 O_ID_EXAM_RESULT - ID do resultado do exame
                                 O_ERROR - erro
        
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_exam          exam.id_exam%TYPE;
        l_episode          episode.id_episode%TYPE;
        l_ret              BOOLEAN;
        l_next             NUMBER;
        l_id_exam_result   exam_result.id_exam_result%TYPE;
    
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET EXAM INFO';
        SELECT id_pat_pregnancy, id_episode
          INTO l_id_pat_pregnancy, l_episode
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'Y'));
    
        g_error := 'INSERT EXAM RESULT';
        l_ret   := pk_exams_api_db.set_exam_result(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_patient               => i_patient,
                                                   i_episode               => l_episode,
                                                   i_exam_req_det          => i_exam_req_det,
                                                   i_exam_result           => NULL,
                                                   i_dt_result             => NULL,
                                                   i_result_status         => NULL,
                                                   i_abnormality           => NULL,
                                                   i_flg_result_origin     => NULL,
                                                   i_result_origin_notes   => NULL,
                                                   i_flg_import            => table_varchar(),
                                                   i_id_doc                => table_number(),
                                                   i_doc_type              => table_number(),
                                                   i_desc_doc_type         => table_varchar(),
                                                   i_dt_doc                => table_varchar(),
                                                   i_dest                  => table_number(),
                                                   i_desc_dest             => table_varchar(),
                                                   i_ori_doc_type          => table_number(),
                                                   i_desc_ori_doc_type     => table_varchar(),
                                                   i_original              => table_number(),
                                                   i_desc_original         => table_varchar(),
                                                   i_title                 => table_varchar(),
                                                   i_desc_perf_by          => table_varchar(),
                                                   i_doc_template          => NULL,
                                                   i_flg_type              => pk_touch_option.g_flg_edition_type_new,
                                                   i_id_documentation      => table_number(),
                                                   i_id_doc_element        => table_number(),
                                                   i_id_doc_element_crit   => table_number(),
                                                   i_value                 => table_varchar(),
                                                   i_id_doc_element_qualif => table_table_number(),
                                                   i_documentation_notes   => NULL,
                                                   o_exam_result           => l_id_exam_result,
                                                   o_error                 => o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        o_id_exam_result := l_id_exam_result;
    
        g_error := 'SAVE NEW RESULT PREGNANCY';
        l_ret   := set_new_result_pregnancy(i_lang,
                                            i_prof,
                                            l_id_pat_pregnancy,
                                            l_id_exam_result,
                                            i_weeks,
                                            i_flg_criteria,
                                            i_flg_multiple,
                                            NULL,
                                            i_fetus_number,
                                            l_next,
                                            o_error);
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'UPDATE PAT PREGNANCY';
        UPDATE pat_pregnancy
           SET flg_multiple = i_flg_multiple
         WHERE id_pat_pregnancy = l_id_pat_pregnancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_EXAM_PREGN_GENERAL',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_exam_pregn_general;

    FUNCTION create_exam_pregn_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_exam_req_det  IN exam_req_det.id_exam_req_det%TYPE,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Inserir na requisição de exame a informação
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_REQ_DET - ID da requisição
                                 I_PAT_PREGNANCY - ID da gravidez (caso venha a NULL insere a gravidez activa actualmente)
                         SAIDA:  O_PAT_PREGNANCY - ID da gravidez que foi associada ao exame
                                 O_ERROR - erro
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
    BEGIN
    
        RETURN pk_pregnancy_exam.create_exam_pregn_info(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_patient          => i_patient,
                                                        i_id_exam_req_det  => table_number(i_id_exam_req_det),
                                                        i_id_pat_pregnancy => i_id_pat_pregnancy,
                                                        o_id_pat_pregnancy => o_id_pat_pregnancy,
                                                        o_error            => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CREATE_EXAM_PREGN_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_exam_pregn_info;

    FUNCTION create_exam_pregn_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_exam_req_det  IN table_number,
        i_id_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregnancy OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Inserir na requisição de exame a informação
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_REQ_DET - ID da requisição (lista)
                                 I_PAT_PREGNANCY - ID da gravidez (caso venha a NULL insere a gravidez activa actualmente)
                         SAIDA:  O_PAT_PREGNANCY - ID da gravidez que foi associada ao exame
                                 O_ERROR - erro
          CRIAÇÃO: JSILVA 16/06/2007
        *********************************************************************************/
    
        CURSOR c_pat_pregnancy IS
            SELECT id_pat_pregnancy
              FROM pat_pregnancy
             WHERE id_patient = i_patient
               AND flg_status = g_flg_pregnancy_active;
    
        CURSOR c_exam_type(i_exam IN NUMBER) IS
            SELECT et.flg_type
              FROM exam_type et, exam_type_group etg
             WHERE etg.id_exam = i_exam
               AND etg.id_software IN (i_prof.software, 0)
               AND etg.id_institution IN (i_prof.institution, 0)
               AND etg.id_exam_type = et.id_exam_type;
    
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_exam          exam.id_exam%TYPE;
        l_exam_req         exam_req_det.id_exam_req%TYPE;
        l_episode          exam_req.id_episode%TYPE;
        l_order_recurr     exam_req_det.id_order_recurrence%TYPE;
        l_flg_type         exam_type.flg_type%TYPE;
    
        l_tab_exam_req_det table_number;
        l_tab_exam_req     table_number;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'GET PAT PREGNANCY';
        IF i_id_pat_pregnancy IS NOT NULL
        THEN
            l_id_pat_pregnancy := i_id_pat_pregnancy;
        ELSE
            OPEN c_pat_pregnancy;
            FETCH c_pat_pregnancy
                INTO l_id_pat_pregnancy;
            CLOSE c_pat_pregnancy;
        END IF;
    
        g_error := 'FOR ID_EXAM_REQ_DET';
        FOR i IN 1 .. i_id_exam_req_det.count
        LOOP
        
            g_error := 'GET ID EXAM';
            SELECT erd.id_exam, erd.id_exam_req, er.id_episode, erd.id_order_recurrence
              INTO l_id_exam, l_exam_req, l_episode, l_order_recurr
              FROM exam_req_det erd, exam_req er
             WHERE erd.id_exam_req_det = i_id_exam_req_det(i)
               AND erd.id_exam_req = er.id_exam_req;
        
            g_error := 'CHECK EXAM TYPE';
            OPEN c_exam_type(l_id_exam);
            FETCH c_exam_type
                INTO l_flg_type;
            CLOSE c_exam_type;
        
            IF l_flg_type = g_exam_ultrasound
            THEN
            
                g_error := 'GET EXAM RECURRENCE';
                SELECT erd.id_exam_req_det, er.id_exam_req
                  BULK COLLECT
                  INTO l_tab_exam_req_det, l_tab_exam_req
                  FROM exam_req_det erd
                  JOIN exam_req er
                    ON er.id_exam_req = erd.id_exam_req
                 WHERE erd.id_exam = l_id_exam
                   AND er.id_episode = l_episode
                   AND erd.id_order_recurrence = l_order_recurr
                   AND erd.id_exam_req_det <> i_id_exam_req_det(i);
            
                l_tab_exam_req_det.extend;
                l_tab_exam_req_det(l_tab_exam_req_det.count) := i_id_exam_req_det(i);
            
                l_tab_exam_req.extend;
                l_tab_exam_req(l_tab_exam_req.count) := l_exam_req;
            
                FOR k IN 1 .. l_tab_exam_req_det.count
                LOOP
                    g_error := 'UPDATE EXAM REQ DET';
                    ts_exam_req_det.upd(id_exam_req_det_in  => l_tab_exam_req_det(k),
                                        id_pat_pregnancy_in => l_id_pat_pregnancy,
                                        rows_out            => l_rows_out);
                
                    g_error := 'PK_EXAMS_API_DB.SET_EXAM_GRID_TASK';
                    IF NOT pk_exams_api_db.set_exam_grid_task(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_patient      => i_patient,
                                                              i_episode      => l_episode,
                                                              i_exam_req     => l_tab_exam_req(k),
                                                              i_exam_req_det => l_tab_exam_req_det(k),
                                                              o_error        => o_error)
                    THEN
                        ROLLBACK;
                        RETURN FALSE;
                    END IF;
                END LOOP;
            
            END IF;
        
        END LOOP;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        o_id_pat_pregnancy := l_id_pat_pregnancy;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CREATE_EXAM_PREGN_INFO',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_exam_pregn_info;

    /********************************************************************************************
    * Replicates the ultrasound pregnancy information in a recurrence plan
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_new_exam_req_det       New exam request ID
    * @param i_old_exam_req_det       Old exam request ID (that originated the recurrence plan)
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.6.1.1
    * @since                          2011/06/27
    **********************************************************************************************/
    FUNCTION create_exam_pregn_recurr
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_new_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_old_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows_out      table_varchar := table_varchar();
        l_pat_pregnancy exam_req_det.id_pat_pregnancy%TYPE;
    
    BEGIN
    
        g_error := 'GET ID EXAM';
        SELECT erd.id_pat_pregnancy
          INTO l_pat_pregnancy
          FROM exam_req_det erd
         WHERE erd.id_exam_req_det = i_old_exam_req_det;
    
        g_error := 'UPDATE EXAM REQ DET';
        ts_exam_req_det.upd(id_exam_req_det_in  => i_new_exam_req_det,
                            id_pat_pregnancy_in => l_pat_pregnancy,
                            rows_out            => l_rows_out);
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EXAM_REQ_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'CREATE_EXAM_PREGN_RECURR',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_exam_pregn_recurr;

    FUNCTION get_exam_fetus_doc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_doc_area          IN doc_area.id_doc_area%TYPE,
        i_doc_template      IN doc_template.id_doc_template%TYPE,
        o_vital_sign        OUT pk_types.cursor_type,
        o_component         OUT pk_types.cursor_type,
        o_element           OUT pk_types.cursor_type,
        o_elemnt_status     OUT pk_types.cursor_type,
        o_elemnt_action     OUT pk_types.cursor_type,
        o_element_exclusive OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Devolve os campos para inserir resultados nas ecografias relativos ao feto
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_REQ_DET - ID da requisição
                                 I_PAT_PREGNANCY - ID da gravidez (caso venha a NULL insere a gravidez activa actualmente)
                         SAIDA:  O_ERROR - erro
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_ret         BOOLEAN;
        l_id_epis_doc NUMBER;
    
    BEGIN
    
        g_error := 'GET EXAM VITAL SIGNS';
        l_ret   := get_exam_type_vs(i_lang, i_prof, g_exam_ultrasound, o_vital_sign, o_error);
    
        IF l_ret = FALSE
        THEN
            ROLLBACK;
            pk_types.open_my_cursor(o_vital_sign);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_element_exclusive);
            RETURN FALSE;
        END IF;
    
        g_error := 'GET DOCUMENTATION COMPONENT LIST';
        l_ret   := pk_documentation.get_templ_component_list(i_lang,
                                                             i_prof,
                                                             i_doc_area,
                                                             i_doc_template,
                                                             i_id_episode,
                                                             l_id_epis_doc,
                                                             o_component,
                                                             o_element,
                                                             o_elemnt_status,
                                                             o_elemnt_action,
                                                             o_element_exclusive,
                                                             o_error);
    
        IF l_ret = FALSE
        THEN
            pk_types.open_my_cursor(o_vital_sign);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_element_exclusive);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_FETUS_DOC',
                                              o_error);
            pk_types.open_my_cursor(o_vital_sign);
            pk_types.open_my_cursor(o_component);
            pk_types.open_my_cursor(o_element);
            pk_types.open_my_cursor(o_elemnt_status);
            pk_types.open_my_cursor(o_elemnt_action);
            pk_types.open_my_cursor(o_element_exclusive);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_fetus_doc;

    FUNCTION get_exam_fetus_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_exam_result  IN exam_result.id_exam_result%TYPE,
        i_fetus_number IN pat_pregn_fetus.fetus_number%TYPE,
        o_vital_sign   OUT pk_types.cursor_type,
        o_filled_vs    OUT pk_types.cursor_type,
        o_last_update  OUT pk_types.cursor_type,
        o_fetus_gender OUT pk_types.cursor_type,
        o_epis_doc     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Devolve o detalhe de um resultado de ecografia associado a um feto
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EPISODE - ID do episodio
                                 I_DOC_AREA - ID da area
                                 I_EXAM_RESULT - ID do resultado do exame
                                 I_FETUS_NUMBER -  número do feto
                         SAIDA:  O_ERROR - erro
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_ret                BOOLEAN;
        l_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_fetus_gender       pat_pregn_fetus.flg_gender%TYPE;
        l_desc_fetus_gender  VARCHAR2(4000);
    
        l_exception EXCEPTION;
    BEGIN
    
        g_error := 'GET EXAM VITAL SIGNS';
        l_ret   := get_exam_type_vs(i_lang, i_prof, 'U', o_vital_sign, o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET EPIS DOCUMENTATION';
    
        SELECT /*+opt_estimate(table er rows=1)*/
         erf.id_epis_documentation,
         ppf.flg_gender,
         pk_sysdomain.get_domain('PATIENT.GENDER', erf.flg_gender, i_lang) gender
          INTO l_epis_documentation, l_fetus_gender, l_desc_fetus_gender
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_result_info(i_lang, i_prof, i_exam_result)) er,
               exam_result_pregnancy erp,
               exam_res_pregn_fetus erf,
               pat_pregn_fetus ppf
         WHERE er.id_exam_result = erp.id_exam_result
           AND erp.id_exam_result_pregnancy = erf.id_exam_result_pregnancy
           AND erf.id_pat_pregn_fetus = ppf.id_pat_pregn_fetus
           AND ppf.fetus_number = i_fetus_number;
    
        l_ret := pk_documentation.sr_get_epis_documentation(i_lang,
                                                            i_prof,
                                                            i_doc_area,
                                                            i_id_episode,
                                                            l_epis_documentation,
                                                            o_last_update,
                                                            o_fetus_gender,
                                                            o_epis_doc,
                                                            o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'GET FETUS VS';
        l_ret   := get_exam_fetus_vs(i_lang, i_prof, NULL, i_exam_result, i_fetus_number, o_filled_vs, o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        CLOSE o_fetus_gender;
        OPEN o_fetus_gender FOR
            SELECT l_fetus_gender gender, l_desc_fetus_gender desc_gender
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_FETUS_DET',
                                              o_error);
            pk_types.open_my_cursor(o_vital_sign);
            pk_types.open_my_cursor(o_filled_vs);
            pk_types.open_my_cursor(o_last_update);
            pk_types.open_my_cursor(o_fetus_gender);
            pk_types.open_my_cursor(o_epis_doc);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_fetus_det;

    FUNCTION get_exam_screen_name
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_exam        IN exam.id_exam%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        o_screen_name OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Devolve o ecra a carregar com base no exame
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM - ID do exame
                                 O_SCREEN_NAME - ecra a carregar
                         SAIDA:  O_ERROR - erro
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_screen_name     exam_type_template.screen_name%TYPE;
        l_exam_type       exam_type.id_exam_type%TYPE;
        l_flg_female_exam VARCHAR2(10);
    
        CURSOR c_screen_name IS
            SELECT ett.screen_name, et.id_exam_type
              FROM exam_type et, exam_type_template ett, exam_type_group etg
             WHERE etg.id_exam = i_exam
               AND etg.id_software IN (i_prof.software, 0)
               AND etg.id_institution IN (i_prof.institution, 0)
               AND ett.id_software IN (i_prof.software, 0)
               AND ett.id_institution IN (i_prof.institution, 0)
               AND etg.id_exam_type = et.id_exam_type
               AND et.id_exam_type = ett.id_exam_type
             ORDER BY etg.id_institution DESC, etg.id_software DESC, ett.id_institution DESC, ett.id_software DESC;
    
    BEGIN
    
        g_error := 'GET SCREEN NAME';
        OPEN c_screen_name;
        FETCH c_screen_name
            INTO l_screen_name, l_exam_type;
        CLOSE c_screen_name;
    
        g_error := 'CALL TO CHECK_EXAM_TYPE';
        IF NOT check_exam_type(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_patient         => i_patient,
                               i_exam_type       => l_exam_type,
                               i_flg_type        => NULL,
                               o_flg_female_exam => l_flg_female_exam,
                               o_exam_type       => l_exam_type,
                               o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'SET SCREEN NAME';
        IF l_flg_female_exam = g_no
        THEN
            l_screen_name := NULL;
        END IF;
    
        o_screen_name := l_screen_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_SCREEN_NAME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_screen_name;

    /******************************************************************************
       OBJECTIVO: Devolve o template a carregar na documentation associada ao exame (e ao trimestre no caso das ecografias)
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                             I_PROF - ID do profissional, software e instituição
                             I_EXAM - ID do exame
                             I_TRIMESTER - trimestre da gravidez
                             O_DOC_TEMPLATE - template a carregar
                     SAIDA:  O_ERROR - erro
      CRIAÇÃO: JSILVA 31/05/2007
    *********************************************************************************/
    FUNCTION get_exam_doc_template
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_exam      IN exam.id_exam%TYPE,
        i_trimester IN NUMBER,
        --o_doc_template OUT doc_template.id_doc_template%TYPE,
        o_doc_template OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        tbl_id_doc_template table_number := table_number();
        tbl_period          table_number := table_number();
        tbl_return          table_number := table_number();
        l_idx               NUMBER;
    
        --********************************
        PROCEDURE l_get_templates IS
        BEGIN
        
            SELECT ett.id_doc_template, ett.period
              BULK COLLECT
              INTO tbl_id_doc_template, tbl_period
              FROM exam_type et
              JOIN exam_type_template ett
                ON ett.id_exam_type = et.id_exam_type
            --AND ett.period = i_trimester
              JOIN exam_type_group etg
                ON etg.id_exam_type = et.id_exam_type
             WHERE 0 = 0 --etg.id_exam = i_exam
               AND etg.id_software IN (i_prof.software, 0)
               AND etg.id_institution IN (i_prof.institution, 0)
               AND ett.id_software IN (i_prof.software, 0)
               AND ett.id_institution IN (i_prof.institution, 0)
             ORDER BY etg.id_institution DESC, etg.id_software DESC, ett.id_institution DESC, ett.id_software DESC;
        
        END l_get_templates;
    
        -- ***********************************
        PROCEDURE l_find_trimester IS
        BEGIN
        
            <<lup_thru_period>>
            FOR i IN 1 .. tbl_period.count
            LOOP
            
                IF tbl_period(i) = i_trimester
                THEN
                    l_idx := i;
                    EXIT lup_thru_period;
                END IF;
            
            END LOOP lup_thru_period;
        
        END l_find_trimester;
    
        --***************************
        PROCEDURE l_assert_id_template IS
        BEGIN
        
            IF l_idx > 0
            THEN
                tbl_return.extend;
                tbl_return(tbl_return.count) := tbl_id_doc_template(l_idx);
            ELSE
                tbl_return := tbl_return MULTISET UNION tbl_id_doc_template;
            END IF;
        
        END l_assert_id_template;
    
        -- *************************
        PROCEDURE l_process_cursor(o_doc_template OUT pk_types.cursor_type) IS
            k_code CONSTANT VARCHAR2(0200 CHAR) := 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.';
        BEGIN
        
            OPEN o_doc_template FOR
                SELECT t.id_doc_template,
                       pk_translation.get_translation(i_lang, k_code || t.id_doc_template) template_desc
                  FROM (SELECT DISTINCT tbl.column_value id_doc_template
                          FROM TABLE(tbl_return) tbl) t;
        
        END l_process_cursor;
    
    BEGIN
    
        l_idx := 0;
    
        l_get_templates();
    
        l_find_trimester();
    
        l_assert_id_template();
    
        l_process_cursor(o_doc_template);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_EXAM_DOC_TEMPLATE',
                                              o_error);
            pk_types.open_my_cursor(o_doc_template);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_exam_doc_template;

    FUNCTION get_uts_exam_detail_main
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_exam_result IN exam_result.id_exam_result%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_fetus_qty NUMBER;
        l_res       exam_result%ROWTYPE;
    BEGIN
    
        IF i_id_exam_result IS NOT NULL
        THEN
        
            g_error := 'GET FETUS QTY';
            SELECT COUNT(*)
              INTO l_fetus_qty
              FROM exam_result_pregnancy erp, exam_res_pregn_fetus erf
             WHERE erp.id_exam_result = i_id_exam_result
               AND erp.id_exam_result_pregnancy = erf.id_exam_result_pregnancy;
        
            g_error := 'OPEN O_DETAIL';
            OPEN o_detail FOR
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam id_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || er.id_exam, NULL) desc_exam,
                 l_fetus_qty fetus_qty,
                 pk_date_utils.dt_chr(i_lang, pry.dt_last_menstruation, i_prof) dt_last_menstruation_f,
                 pk_pregnancy_api.get_pregnancy_weeks(i_prof,
                                                      nvl(pry.dt_init_preg_lmp, pry.dt_init_pregnancy),
                                                      nvl(pry.dt_intervention, er.dt_result),
                                                      NULL) amnorea_age,
                 erp.weeks_pregnancy ultrasound_age,
                 pk_pregnancy_api.get_ultrasound_trimester(i_lang,
                                                           i_prof,
                                                           erp.flg_weeks_criteria,
                                                           pry.dt_init_preg_lmp,
                                                           er.dt_result,
                                                           erp.weeks_pregnancy) trimester,
                 pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER',
                                         pk_pregnancy_api.get_ultrasound_trimester(i_lang,
                                                                                   i_prof,
                                                                                   erp.flg_weeks_criteria,
                                                                                   pry.dt_init_preg_lmp,
                                                                                   er.dt_result,
                                                                                   erp.weeks_pregnancy),
                                         i_lang) desc_trimester,
                 n_pregnancy n_pregnancy,
                 erp.flg_multiple flg_multiple,
                 erp.flg_weeks_criteria,
                 pk_sysdomain.get_domain('EXAM_RESULT_PREGNANCY.FLG_WEEKS_CRITERIA', erp.flg_weeks_criteria, i_lang) desc_flg_weeks_criteria,
                 pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MULTIPLE', erp.flg_multiple, i_lang) desc_flg_multiple,
                 decode(pry.num_gest_weeks, NULL, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_has_dt_menstr
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_id_exam_result)) er,
                       exam_result_pregnancy erp,
                       pat_pregnancy pry
                 WHERE er.id_exam_result = erp.id_exam_result
                   AND er.id_pat_pregnancy = pry.id_pat_pregnancy;
        ELSE
            OPEN o_detail FOR
                SELECT 1
                  FROM dual
                 WHERE 1 = 0;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_UTS_EXAM_DETAIL_MAIN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_uts_exam_detail_main;

    FUNCTION get_ultrasound_summ_page
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_general      OUT pk_types.cursor_type,
        o_det_fetus    OUT pk_types.cursor_type,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Devolve a informação da folha resumo do resultado de ecografias
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_EXAM_REQ_DET - ID do detalhe da requisição do exame
                        SAIDA:   O_GENERAL - template a carregar
                                 O_DET_FETUS - informação dos relatórios dos fetos
                                 O_ERROR - erro
          CRIAÇÃO: JSILVA 31/05/2007
        *********************************************************************************/
    
        l_ret                 BOOLEAN;
        l_count               NUMBER;
        l_doc_criteria_button NUMBER;
        l_doc_criteria_text   NUMBER;
    
    BEGIN
    
        l_doc_criteria_button := 1;
        l_doc_criteria_text   := 6;
    
        g_error := 'GET EXAM PAT PREGNANCY';
        SELECT /*+opt_estimate(table er rows=1)*/
         COUNT(*)
          INTO l_count
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er
         WHERE id_pat_pregnancy IS NOT NULL;
    
        IF l_count > 0
        THEN
        
            g_error := 'GET ULTRASOUND GENERAL';
            OPEN o_general FOR
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result,
                 er.dt_result, -- necessário como parametro de ordenação (não é usado no flash)
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_exam_result,
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_result_format,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) name,
                 pk_prof_utils.get_spec_signature(i_lang, i_prof, er.id_professional, er.dt_result, er.id_episode) speciality,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T043') label_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || er.id_exam, NULL) exam,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T044') label_weeks,
                 decode(erp.flg_weeks_criteria,
                        pk_pregnancy_core.g_ultrasound_criteria,
                        erp.weeks_pregnancy,
                        pk_pregnancy_api.get_pregnancy_weeks(i_prof,
                                                             pp.dt_init_pregnancy,
                                                             nvl(pp.dt_intervention, er.dt_result),
                                                             NULL)) weeks_pregnant,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T045') label_trimester,
                 pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER',
                                         pk_pregnancy_api.get_ultrasound_trimester(i_lang,
                                                                                   i_prof,
                                                                                   erp.flg_weeks_criteria,
                                                                                   pp.dt_init_pregnancy,
                                                                                   er.dt_result,
                                                                                   erp.weeks_pregnancy),
                                         i_lang) trimester,
                 pk_pregnancy_api.get_ultrasound_trimester(i_lang,
                                                           i_prof,
                                                           erp.flg_weeks_criteria,
                                                           pp.dt_init_pregnancy,
                                                           er.dt_result,
                                                           erp.weeks_pregnancy) num_trimester,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T046') label_pregnancy_num,
                 pp.n_pregnancy,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T047') label_last_menstruation,
                 pp.dt_last_menstruation,
                 pk_date_utils.dt_chr(i_lang, pp.dt_last_menstruation, i_prof.institution, i_prof.software) dt_last_menstr_format,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T048') label_num_fetus,
                 COUNT(*) num_fetus,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T049') label_flg_multiple,
                 pk_sysdomain.get_domain('PAT_PREGNANCY.FLG_MULTIPLE', erp.flg_multiple, i_lang) desc_multiple,
                 NULL notes
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er,
                       exam_result_pregnancy erp,
                       pat_pregnancy pp,
                       exam_res_pregn_fetus erf
                 WHERE erp.id_exam_result = er.id_exam_result
                   AND er.id_pat_pregnancy = pp.id_pat_pregnancy
                   AND erf.id_exam_result_pregnancy = erp.id_exam_result_pregnancy
                 GROUP BY er.id_exam_result,
                          er.dt_result,
                          pp.dt_init_pregnancy,
                          er.id_professional,
                          er.id_episode,
                          er.id_exam,
                          erp.flg_weeks_criteria,
                          erp.weeks_pregnancy,
                          pp.dt_intervention,
                          pp.n_pregnancy,
                          pp.dt_last_menstruation,
                          erp.flg_multiple
                UNION ALL
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result,
                 er.dt_result, -- necessário como parametro de ordenação (não é usado no flash)
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_exam_result,
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_result_format,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) name,
                 pk_prof_utils.get_spec_signature(i_lang, i_prof, er.id_professional, er.dt_result, er.id_episode) speciality,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T043') label_exam,
                 pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || er.id_exam, NULL) exam,
                 NULL label_weeks,
                 NULL weeks_pregnant,
                 NULL label_trimester,
                 NULL trimester,
                 NULL num_trimester,
                 NULL label_pregnancy_num,
                 NULL n_pregnancy,
                 NULL label_last_menstruation,
                 NULL dt_last_menstruation,
                 NULL dt_last_menstr_format,
                 NULL label_num_fetus,
                 0 num_fetus,
                 NULL label_flg_multiple,
                 NULL desc_multiple,
                 er.notes
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er
                 WHERE dbms_lob.substr(er.notes, 3800) IS NOT NULL
                 ORDER BY dt_result DESC;
        
            g_error := 'GET FETUS ULTRASOUND RESULT';
            OPEN o_det_fetus FOR
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation_format,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ed.id_professional,
                                                  ed.dt_creation_tstz,
                                                  ed.id_episode) speciality,
                 ed.id_epis_documentation,
                 d.id_doc_component,
                 de.id_doc_element,
                 ppf.fetus_number,
                 pk_message.get_message(i_lang, 'EXAM_IMAGE_T063') label_gender,
                 pk_sysdomain.get_domain('PATIENT.GENDER', erf.flg_gender, i_lang) gender,
                 d.rank,
                 c.id_doc_element_crit,
                 decode(pk_translation.get_translation(i_lang, n.code_doc_component),
                        NULL,
                        NULL,
                        pk_translation.get_translation(i_lang, n.code_doc_component) || ':') d_comp,
                 decode(c.id_doc_criteria,
                        l_doc_criteria_text,
                        dd.value,
                        decode(dd.value, NULL, pk_translation.get_translation(i_lang, c.code_element_open), NULL)) d_crit,
                 -- se o elemento for um keypad ou um botão associado a um keypad o valor introduzido é colocado neste campo
                 (SELECT pk_touch_option.get_formatted_value(i_lang,
                                                             i_prof,
                                                             de.flg_type,
                                                             edd.value,
                                                             edd.value_properties,
                                                             de.input_mask,
                                                             de.flg_optional_value,
                                                             de.flg_element_domain_type,
                                                             de.code_element_domain) VALUE
                    FROM doc_element_crit       dec1,
                         doc_element_crit       dec2,
                         doc_action_criteria    dac,
                         epis_documentation_det edd,
                         doc_element            de
                   WHERE dd.id_doc_element = dec1.id_doc_element
                     AND dec1.id_doc_element_crit = dac.id_doc_element_crit
                     AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                     AND dec2.id_doc_element = edd.id_doc_element
                     AND (dec2.id_doc_element <> dd.id_doc_element OR dd.value IS NOT NULL)
                     AND edd.id_doc_element = de.id_doc_element
                     AND (dec1.id_doc_criteria = 3 OR
                         (dec1.id_doc_criteria = 1 AND NOT EXISTS
                          (SELECT dec3.id_doc_element_crit
                              FROM doc_action_criteria dac2, doc_element_crit dec3
                             WHERE dec3.id_doc_element_crit = dac2.id_doc_element_crit
                               AND dec3.id_doc_criteria = 3
                               AND dec3.id_doc_element = dec1.id_doc_element)))
                     AND dd.id_epis_documentation = edd.id_epis_documentation) VALUE,
                 -- ID do componente associado ao título da secção a que corresponde este elemento
                 nvl((SELECT dc.id_doc_component
                       FROM documentation doc, doc_component dc
                      WHERE dc.id_doc_component = doc.id_doc_component
                        AND dc.flg_type = 'T'
                        AND doc.id_doc_template = d.id_doc_template
                        AND doc.rank = (SELECT MAX(doc1.rank)
                                          FROM documentation doc1, doc_component dc1
                                         WHERE dc1.id_doc_component = doc1.id_doc_component
                                           AND dc1.flg_type = 'T'
                                           AND doc1.id_doc_template = d.id_doc_template
                                           AND doc1.rank < d.rank)),
                     0) id_doc_title,
                 -- descritivo do título da secção a que corresponde este elemento
                 (SELECT pk_translation.get_translation(i_lang, dc.code_doc_component)
                    FROM documentation doc, doc_component dc
                   WHERE dc.id_doc_component = doc.id_doc_component
                     AND dc.flg_type = 'T'
                     AND doc.id_doc_template = d.id_doc_template
                     AND doc.rank = (SELECT MAX(doc1.rank)
                                       FROM documentation doc1, doc_component dc1
                                      WHERE dc1.id_doc_component = doc1.id_doc_component
                                        AND dc1.flg_type = 'T'
                                        AND doc1.id_doc_template = d.id_doc_template
                                        AND doc1.rank < d.rank)) desc_title,
                 d.id_doc_template
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er,
                       exam_result_pregnancy erp,
                       exam_res_pregn_fetus erf,
                       pat_pregn_fetus ppf,
                       doc_element_crit c,
                       documentation d,
                       doc_component n,
                       epis_documentation ed,
                       epis_documentation_det dd,
                       doc_element de
                 WHERE er.id_exam_result = erp.id_exam_result
                   AND erf.id_exam_result_pregnancy = erp.id_exam_result_pregnancy
                   AND erf.id_pat_pregn_fetus = ppf.id_pat_pregn_fetus
                   AND ed.id_epis_documentation(+) = erf.id_epis_documentation
                   AND ed.flg_status(+) = g_doc_active
                   AND dd.id_epis_documentation(+) = ed.id_epis_documentation
                   AND dd.id_documentation = d.id_documentation(+)
                   AND dd.id_doc_element = de.id_doc_element(+)
                   AND d.id_doc_component = n.id_doc_component(+)
                   AND dd.id_doc_element_crit = c.id_doc_element_crit(+)
                   AND (c.id_doc_criteria IN (l_doc_criteria_button, l_doc_criteria_text) OR c.id_doc_criteria IS NULL)
                 ORDER BY er.dt_result DESC, ed.id_epis_documentation, d.rank, de.rank;
        
            g_error := 'GET FETUS VS';
            l_ret   := get_exam_fetus_vs(i_lang, i_prof, i_exam_req_det, NULL, NULL, o_vital_sign, o_error);
        
            IF l_ret = FALSE
            THEN
                ROLLBACK;
                pk_types.open_my_cursor(o_general);
                pk_types.open_my_cursor(o_det_fetus);
                pk_types.open_my_cursor(o_vital_sign);
                RETURN FALSE;
            END IF;
        
        ELSE
        
            g_error := 'GET ULTRASOUND GENERAL';
            OPEN o_general FOR
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result, erp.id_epis_documentation
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er,
                       exam_result_pregnancy erp
                 WHERE erp.id_exam_result = er.id_exam_result
                 ORDER BY er.dt_result DESC;
        
            g_error := 'GET FETUS ULTRASOUND RESULT';
            OPEN o_det_fetus FOR
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result,
                 er.dt_result dt_exam_result_tstz,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation,
                 pk_date_utils.date_char_tsz(i_lang, ed.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation_format,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, ed.id_professional) name,
                 pk_prof_utils.get_spec_signature(i_lang,
                                                  i_prof,
                                                  ed.id_professional,
                                                  ed.dt_creation_tstz,
                                                  ed.id_episode) speciality,
                 ed.id_epis_documentation,
                 d.id_doc_component,
                 de.id_doc_element,
                 d.rank,
                 de.rank rank_elem,
                 c.id_doc_element_crit,
                 pk_translation.get_translation(i_lang, code_doc_component) || ':' d_comp,
                 -- se o elemento for um campo de texto devolve a mensagem '(Com notas)'
                 to_clob(decode(c.id_doc_criteria,
                                l_doc_criteria_text,
                                '(' || pk_message.get_message(i_lang, 'COMMON_M008') || ')',
                                decode(dd.value, NULL, pk_translation.get_translation(i_lang, c.code_element_open), NULL))) d_crit,
                 -- se o elemento for um keypad ou um botão associado a um keypad o valor introduzido é colocado neste campo
                 (SELECT pk_touch_option.get_formatted_value(i_lang,
                                                             i_prof,
                                                             de.flg_type,
                                                             edd.value,
                                                             edd.value_properties,
                                                             de.input_mask,
                                                             de.flg_optional_value,
                                                             de.flg_element_domain_type,
                                                             de.code_element_domain) VALUE
                    FROM doc_element_crit       dec1,
                         doc_element_crit       dec2,
                         doc_action_criteria    dac,
                         epis_documentation_det edd,
                         doc_element            de
                   WHERE dd.id_doc_element = dec1.id_doc_element
                     AND dec1.id_doc_element_crit = dac.id_doc_element_crit
                     AND dac.id_elem_crit_action = dec2.id_doc_element_crit
                     AND dec2.id_doc_element = edd.id_doc_element
                     AND edd.id_doc_element = de.id_doc_element
                     AND (dec1.id_doc_criteria = 3 OR
                         (dec1.id_doc_criteria = 1 AND NOT EXISTS
                          (SELECT dec3.id_doc_element_crit
                              FROM doc_action_criteria dac2, doc_element_crit dec3
                             WHERE dec3.id_doc_element_crit = dac2.id_doc_element_crit
                               AND dec3.id_doc_criteria = 3
                               AND dec3.id_doc_element = dec1.id_doc_element)))
                     AND dd.id_epis_documentation = edd.id_epis_documentation) VALUE,
                 -- ID do componente associado ao título da secção a que corresponde este elemento
                 nvl((SELECT dc.id_doc_component
                       FROM documentation doc, doc_component dc
                      WHERE dc.id_doc_component = doc.id_doc_component
                        AND dc.flg_type = 'T'
                        AND doc.id_doc_template = d.id_doc_template
                        AND doc.rank = (SELECT MAX(doc1.rank)
                                          FROM documentation doc1, doc_component dc1
                                         WHERE dc1.id_doc_component = doc1.id_doc_component
                                           AND dc1.flg_type = 'T'
                                           AND doc1.id_doc_template = d.id_doc_template
                                           AND doc1.rank < d.rank)),
                     0) id_doc_title,
                 -- descritivo do título da secção a que corresponde este elemento
                 (SELECT pk_translation.get_translation(i_lang, dc.code_doc_component)
                    FROM documentation doc, doc_component dc
                   WHERE dc.id_doc_component = doc.id_doc_component
                     AND dc.flg_type = 'T'
                     AND doc.id_doc_template = d.id_doc_template
                     AND doc.rank = (SELECT MAX(doc1.rank)
                                       FROM documentation doc1, doc_component dc1
                                      WHERE dc1.id_doc_component = doc1.id_doc_component
                                        AND dc1.flg_type = 'T'
                                        AND doc1.id_doc_template = d.id_doc_template
                                        AND doc1.rank < d.rank)) desc_title
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er,
                       exam_result_pregnancy erp,
                       doc_element_crit c,
                       documentation d,
                       doc_component n,
                       epis_documentation ed,
                       epis_documentation_det dd,
                       doc_element de
                 WHERE erp.id_exam_result = er.id_exam_result
                   AND ed.id_epis_documentation = erp.id_epis_documentation
                   AND ed.flg_status = g_doc_active
                   AND dd.id_epis_documentation = ed.id_epis_documentation
                   AND dd.id_documentation = d.id_documentation
                   AND d.id_doc_component = n.id_doc_component
                   AND dd.id_doc_element = de.id_doc_element
                   AND dd.id_doc_element_crit = c.id_doc_element_crit
                   AND c.id_doc_criteria IN (l_doc_criteria_button, l_doc_criteria_text)
                UNION ALL
                SELECT /*+opt_estimate(table er rows=1)*/
                 er.id_exam_result,
                 er.dt_result dt_exam_result_tstz,
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_creation,
                 pk_date_utils.date_char_tsz(i_lang, er.dt_result, i_prof.institution, i_prof.software) dt_creation_format,
                 pk_prof_utils.get_name_signature(i_lang, i_prof, er.id_professional) name,
                 pk_prof_utils.get_spec_signature(i_lang, i_prof, er.id_professional, er.dt_result, er.id_episode) speciality,
                 NULL id_epis_documentation,
                 1 id_doc_component,
                 1 id_doc_element,
                 1 rank,
                 1 rank_elem,
                 1 id_doc_element_crit,
                 NULL d_comp,
                 er.notes d_crit,
                 NULL VALUE,
                 NULL id_doc_title,
                 NULL desc_title
                  FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'N')) er
                 WHERE er.notes IS NOT NULL
                 ORDER BY dt_exam_result_tstz DESC, id_epis_documentation, rank, rank_elem;
        
            pk_types.open_my_cursor(o_vital_sign);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_ULTRASOUND_SUMM_PAGE',
                                              o_error);
            pk_types.open_my_cursor(o_general);
            pk_types.open_my_cursor(o_det_fetus);
            pk_types.open_my_cursor(o_vital_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ultrasound_summ_page;

    FUNCTION get_ultrasound_summ_page_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof_id      IN professional.id_professional%TYPE,
        i_prof_inst    IN institution.id_institution%TYPE,
        i_prof_sw      IN software.id_software%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        o_general      OUT pk_types.cursor_type,
        o_det_fetus    OUT pk_types.cursor_type,
        o_vital_sign   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_prof profissional := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
    BEGIN
    
        RETURN get_ultrasound_summ_page(i_lang, i_prof, i_exam_req_det, o_general, o_det_fetus, o_vital_sign, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'GET_ULTRASOUND_SUMM_PAGE_REP',
                                              o_error);
            pk_types.open_my_cursor(o_general);
            pk_types.open_my_cursor(o_det_fetus);
            pk_types.open_my_cursor(o_vital_sign);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ultrasound_summ_page_rep;

    FUNCTION set_new_res_fetus_biom_img
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_exam_res_fetus_biom     IN exam_res_fetus_biom.id_exam_res_fetus_biom%TYPE,
        i_id_doc_external            IN doc_external.id_doc_external%TYPE,
        o_id_exam_res_fetus_biom_img OUT exam_res_fetus_biom_img.id_exam_res_fetus_biom_img%TYPE,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_next NUMBER;
    BEGIN
    
        IF i_id_doc_external IS NOT NULL
        THEN
        
            SELECT seq_exam_res_fetus_biom_img.nextval
              INTO l_next
              FROM dual;
        
            INSERT INTO exam_res_fetus_biom_img
                (id_exam_res_fetus_biom_img, id_exam_res_fetus_biom, id_doc_external)
            VALUES
                (l_next, i_id_exam_res_fetus_biom, i_id_doc_external);
        
            o_id_exam_res_fetus_biom_img := l_next;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_NEW_RES_FETUS_BIOM_IMG',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_new_res_fetus_biom_img;

    FUNCTION set_new_result_no_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_prof_cat_type        IN category.flg_type%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_exam_req_det      IN exam_req_det.id_exam_req_det%TYPE,
        i_notes                IN VARCHAR2,
        i_id_pat_pregnancy     IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_document_area        IN doc_area.id_doc_area%TYPE,
        i_epis_complaint       IN epis_complaint.id_epis_complaint%TYPE,
        i_id_sys_documentation IN table_number,
        i_id_sys_element       IN table_number,
        i_id_sys_element_crit  IN table_number,
        i_value                IN table_varchar,
        i_doc_notes            IN epis_documentation_det.notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret BOOLEAN;
        l_det exam_req_det%ROWTYPE;
    
        l_commit VARCHAR2(0050);
        l_comm   VARCHAR2(4000);
    
        o_id_exam_result           exam_result.id_exam_result%TYPE;
        o_id_epis_documentation    epis_documentation_det.id_epis_documentation%TYPE;
        o_id_exam_result_pregnancy exam_result_pregnancy.id_exam_result_pregnancy%TYPE;
        l_exception EXCEPTION;
    BEGIN
    
        l_commit := 'N';
    
        l_comm := 'GET EXAM_REQ_DET';
        SELECT id_exam
          INTO l_det.id_exam
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_id_exam_req_det, 'N'));
    
        l_comm := 'SET EXAM_RESULT';
        l_ret  := pk_exams_api_db.set_exam_result(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_patient               => i_id_patient,
                                                  i_episode               => i_id_episode,
                                                  i_exam_req_det          => i_id_exam_req_det,
                                                  i_exam_result           => NULL,
                                                  i_dt_result             => NULL,
                                                  i_result_status         => NULL,
                                                  i_abnormality           => NULL,
                                                  i_flg_result_origin     => NULL,
                                                  i_result_origin_notes   => NULL,
                                                  i_flg_import            => table_varchar(),
                                                  i_id_doc                => table_number(),
                                                  i_doc_type              => table_number(),
                                                  i_desc_doc_type         => table_varchar(),
                                                  i_dt_doc                => table_varchar(),
                                                  i_dest                  => table_number(),
                                                  i_desc_dest             => table_varchar(),
                                                  i_ori_doc_type          => table_number(),
                                                  i_desc_ori_doc_type     => table_varchar(),
                                                  i_original              => table_number(),
                                                  i_desc_original         => table_varchar(),
                                                  i_title                 => table_varchar(),
                                                  i_desc_perf_by          => table_varchar(),
                                                  i_doc_template          => NULL,
                                                  i_flg_type              => pk_touch_option.g_flg_edition_type_new,
                                                  i_id_documentation      => table_number(),
                                                  i_id_doc_element        => table_number(),
                                                  i_id_doc_element_crit   => table_number(),
                                                  i_value                 => table_varchar(),
                                                  i_id_doc_element_qualif => table_table_number(),
                                                  i_documentation_notes   => i_notes,
                                                  o_exam_result           => o_id_exam_result,
                                                  o_error                 => o_error);
    
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        l_comm := 'SET DOCUMENTATION';
        l_ret  := pk_documentation.set_epis_bartchart(i_lang,
                                                      i_prof,
                                                      i_id_episode,
                                                      i_document_area,
                                                      i_epis_complaint,
                                                      i_id_sys_documentation,
                                                      i_id_sys_element,
                                                      i_id_sys_element_crit,
                                                      i_value,
                                                      i_doc_notes,
                                                      l_commit,
                                                      o_id_epis_documentation,
                                                      o_error);
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        l_comm := 'NEW PREGNANCY';
        l_ret  := set_new_result_pregnancy(i_lang,
                                           i_prof,
                                           i_id_pat_pregnancy,
                                           o_id_exam_result,
                                           NULL,
                                           'N',
                                           NULL,
                                           o_id_epis_documentation,
                                           NULL,
                                           o_id_exam_result_pregnancy,
                                           o_error);
        IF l_ret = FALSE
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_PREGNANCY_EXAM',
                                              'SET_NEW_RESULT_NO_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_new_result_no_pregnancy;
    --
    /**
    * Encapsulates the logic of saving a pregnancy exam request
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_patient          Patient id
    * @param   i_params           XML with all input parameters
    * @param   o_exam_req         Exams order id
    * @param   o_exam_req_det     Exams order details id 
    * @param   o_pat_pregnancy    Pat pregnancy id 
    * @param   o_exam_result      Exams result id 
    * @param   o_pat_pregn_fetus  Pat pregnancy fetus id 
    * @param   o_error            Error information
    *
    * @example i_params           Example of the possible XML passed in this variable
    * <PREGNANCY_EXAM_ALL>
    *   <ID_EPISODE></ID_EPISODE>
    *   <PROF_CAT_TYPE></PROF_CAT_TYPE>
    *   <ID_PAT_PREGNANCY></ID_PAT_PREGNANCY>
    *   <!-- EXAM_TAGS - BEGIN -->
    *   <!-- 
    *     1 - At least one of the following tags must have a value 
    *     2 - If (ID_EXAM_REQ_DET is NULL) then a call is made to CREATE_EXAM_WITH_RESULT function and then to CREATE_EXAM_PREGN_INFO function 
    *     3 - It's always called the functions SET_EXAM_PREGN_GENERAL and SET_RESULT_FETUS 
    *   -->
    *   <ID_EXAM></ID_EXAM>
    *   <ID_EXAM_REQ_DET></ID_EXAM_REQ_DET>
    *   <!-- EXAM_TAGS - END -->
    *   <ID_DOC_AREA></ID_DOC_AREA>
    *   <WEEKS></WEEKS>
    *   <FLG_CRITERIA></FLG_CRITERIA>
    *   <FLG_MULTIPLE></FLG_MULTIPLE>
    *   <!-- Fetus sequence -->
    *   <FETAL>
    *       <FETUS ID="" FLG_GENDER=""> <!-- Fetus ID = 1..N where 1 is the first fetus and N represents the N fetus -->
    *       <!-- VS sequence -->
    *       <VITAL_SIGNS>
    *            <VITAL_SIGN ID_VITAL_SIGN="" VALUE="" IMAGE="" />
    *       </VITAL_SIGNS>
    *       <!-- DOCs sequence -->
    *       <DOCS>
    *            <DOC ID_DOCUMENTATION="" ID_DOC_ELEMENT="" ID_DOC_ELEMENT_CRIT="" VALUE="" />
    *       </DOCS>
    *       </FETUS>
    *   </FETAL>
    * </PREGNANCY_EXAM_ALL>
    * <EXAM_ORDER>
    *   <ID_EPISODE></ID_EPISODE>
    *   <FLG_TEST></FLG_TEST>
    *   <!-- Exams sequence -->
    *   <EXAMS>
    *     <EXAM ID="" FLG_TYPE="" CODIFICATION="" FLG_TIME="" DT_BEGIN="" PRIORITY="" EXEC_ROOM="" EXEC_INST="" CLINICAL_PURPOSE="">
    *       <NOTES></NOTES>
    *       <TECH_NOTES></TECH_NOTES>
    *       <PAT_NOTES></PAT_NOTES>
    *       <ORDER ID_PROF="" DATE="" TYPE="" />
    *       <!-- Diagnoses sequence -->
    *       <DIAGNOSES>
    *         <DIAGNOSIS ID_DIAGNOSIS="" DESC="" />
    *       </DIAGNOSES>
    *       <!-- Clinical questions sequence -->
    *       <CLINICAL_QUESTIONS>
    *         <CLINICAL_QUESTION ID="" RESPONSE="" NOTES="" />
    *       </CLINICAL_QUESTIONS>
    *     </EXAM>
    *   </EXAMS>
    * </EXAM_ORDER>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION set_pregnancy_exam_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_params             IN CLOB,
        o_exam_req           OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det       OUT exam_req_det.id_exam_req_det%TYPE,
        o_pat_pregnancy      OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_exam_result        OUT exam_result.id_exam_result%TYPE,
        o_id_pat_pregn_fetus OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_req            OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_exam_req_array     OUT NOCOPY table_number,
        o_exam_req_det_array OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(50) := 'SET_PREGNANCY_EXAM_ALL';
        --
        l_vs                   table_number;
        l_vs_value             table_number;
        l_vs_doc               table_number;
        l_id_tbl_documentation table_number;
        l_id_tbl_element       table_number;
        l_id_tbl_element_crit  table_number;
        l_tbl_value            table_varchar;
        --
        l_nls_num_char   CONSTANT VARCHAR2(30) := 'NLS_NUMERIC_CHARACTERS';
        l_cfg_dec_symbom CONSTANT sys_config.id_sys_config%TYPE := 'DECIMAL_SYMBOL';
        l_decimal_symbol  sys_config.value%TYPE;
        l_grouping_symbol VARCHAR2(1);
        l_back_nls        VARCHAR2(2);
        --
        l_id_exam           table_number;
        l_flg_type          table_varchar;
        l_codification      table_number;
        l_flg_time          table_varchar;
        l_dt_begin          table_varchar;
        l_priority          table_varchar;
        l_exec_room         table_number;
        l_exec_inst         table_number;
        l_clinical_purpose  table_number;
        l_notes             table_varchar;
        l_notes_scheduler   table_varchar;
        l_tech_notes        table_varchar;
        l_pat_notes         table_varchar;
        l_notes_diagnosis   table_varchar;
        l_order_id_prof     table_number;
        l_order_date        table_varchar;
        l_order_type        table_number;
        l_xml_diag          table_clob;
        l_tbl_diags         pk_edis_types.table_in_epis_diagnosis;
        l_tbl_id_clin_quest table_table_number;
        l_tbl_clin_resp     table_table_varchar;
        l_tbl_clin_notes    table_table_varchar;
        --
        l_num_fetus NUMBER;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET DECIMAL SYMBOL';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        l_decimal_symbol := pk_sysconfig.get_config(l_cfg_dec_symbom, i_prof);
    
        g_error := 'SET GROUPING SYMBOL';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        IF l_decimal_symbol = ','
        THEN
            l_grouping_symbol := '.';
        ELSE
            l_grouping_symbol := ',';
        END IF;
    
        g_error := 'GET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        SELECT VALUE
          INTO l_back_nls
          FROM nls_session_parameters
         WHERE parameter = l_nls_num_char;
    
        g_error := 'SET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_decimal_symbol || l_grouping_symbol || '''';
    
        g_error := 'SCROLL THROUGH ALL PREGNANCIES EXAMS';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        FOR r_preg_exam IN (SELECT a.id_episode,
                                   a.prof_cat_type,
                                   a.id_pat_pregnancy,
                                   a.id_exam,
                                   a.id_exam_req_det,
                                   a.id_doc_area,
                                   a.weeks,
                                   a.flg_criteria,
                                   a.flg_multiple,
                                   extract(b.preg_exam_all, '/PREGNANCY_EXAM_ALL/FETAL') fetal
                              FROM (SELECT VALUE(p) preg_exam_all
                                      FROM TABLE(xmlsequence(extract(xmltype(i_params), '/PREGNANCY_EXAM_ALL'))) p) b,
                                   xmltable('/PREGNANCY_EXAM_ALL' passing b.preg_exam_all columns --
                                            "ID_EPISODE" NUMBER(24) path 'ID_EPISODE', --
                                            "PROF_CAT_TYPE" VARCHAR2(1 CHAR) path 'PROF_CAT_TYPE', --
                                            "ID_PAT_PREGNANCY" NUMBER(24) path 'ID_PAT_PREGNANCY', --
                                            "ID_EXAM" NUMBER(24) path 'ID_EXAM', --
                                            "ID_EXAM_REQ_DET" NUMBER(24) path 'ID_EXAM_REQ_DET', --
                                            "ID_DOC_AREA" NUMBER(24) path 'ID_DOC_AREA',
                                            "WEEKS" NUMBER(6) path 'WEEKS',
                                            "FLG_CRITERIA" VARCHAR2(1 CHAR) path 'FLG_CRITERIA',
                                            "FLG_MULTIPLE" VARCHAR2(1 CHAR) path 'FLG_MULTIPLE') a)
        LOOP
            g_error := 'VALIDATE WORKFLOW PARAM''s';
            pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            IF r_preg_exam.id_exam IS NULL
               AND r_preg_exam.id_exam_req_det IS NULL
            THEN
                g_error := 'BOTH WORKFLOW VARS EMPTY!';
                pk_alertlog.log_error(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                raise_application_error(-20101, g_error);
            END IF;
        
            IF r_preg_exam.id_exam IS NOT NULL
               AND r_preg_exam.id_exam_req_det IS NULL
            THEN
                -- Enters the 1º workflow where is created the exam_req and is also made the association between the exam_req and the pat_pregn
                g_error := 'CALL PK_EXAMS_API_DB.CREATE_EXAM_WITH_RESULT';
                pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                IF NOT pk_exams_api_db.create_exam_with_result(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_patient             => i_patient,
                                                               i_episode             => r_preg_exam.id_episode,
                                                               i_exam_req_det        => NULL,
                                                               i_reg                 => NULL,
                                                               i_exam                => r_preg_exam.id_exam,
                                                               i_prof_performed      => NULL,
                                                               i_start_time          => NULL,
                                                               i_end_time            => NULL,
                                                               i_flg_pregnancy       => pk_alert_constant.g_yes,
                                                               i_result_status       => NULL,
                                                               i_flg_result_origin   => NULL,
                                                               i_result_origin_notes => NULL,
                                                               i_notes               => NULL,
                                                               i_flg_import          => table_varchar(),
                                                               i_id_doc              => table_number(),
                                                               i_doc_type            => table_number(),
                                                               i_desc_doc_type       => table_varchar(),
                                                               i_dt_doc              => table_varchar(),
                                                               i_dest                => table_number(),
                                                               i_desc_dest           => table_varchar(),
                                                               i_ori_doc_type        => table_number(),
                                                               i_desc_ori_doc_type   => table_varchar(),
                                                               i_original            => table_number(),
                                                               i_desc_original       => table_varchar(),
                                                               i_title               => table_varchar(),
                                                               i_desc_perf_by        => table_varchar(),
                                                               o_exam_req            => o_exam_req,
                                                               o_exam_req_det        => o_exam_req_det,
                                                               o_error               => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                g_error := 'CALL PK_PREGNANCY_EXAM.CREATE_EXAM_PREGN_INFO';
                pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                IF NOT pk_pregnancy_exam.create_exam_pregn_info(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_patient          => i_patient,
                                                                i_id_exam_req_det  => o_exam_req_det,
                                                                i_id_pat_pregnancy => r_preg_exam.id_pat_pregnancy,
                                                                o_id_pat_pregnancy => o_pat_pregnancy,
                                                                o_error            => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSIF r_preg_exam.id_exam_req_det IS NOT NULL
            THEN
                -- Enters the 2º workflow. The exam_req already exists as the relation between exam_req and pat_preg
                o_exam_req_det  := r_preg_exam.id_exam_req_det;
                o_pat_pregnancy := r_preg_exam.id_pat_pregnancy;
            END IF;
        
            g_error := 'GET FETUS COUNT';
            pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            SELECT COUNT(a.id_fetus)
              INTO l_num_fetus
              FROM (SELECT VALUE(p) fetus
                      FROM TABLE(xmlsequence(extract(r_preg_exam.fetal, '/FETAL/FETUS'))) p) b,
                   xmltable('/FETUS' passing b.fetus columns --
                            "ID_FETUS" NUMBER(24) path '@ID', --
                            "FLG_GENDER" VARCHAR2(1 CHAR) path '@FLG_GENDER') a;
        
            g_error := 'CALL PK_PREGNANCY_EXAM.SET_EXAM_PREGN_GENERAL';
            pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            IF NOT pk_pregnancy_exam.set_exam_pregn_general(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_patient        => i_patient,
                                                            i_exam_req_det   => o_exam_req_det,
                                                            i_weeks          => r_preg_exam.weeks,
                                                            i_flg_criteria   => r_preg_exam.flg_criteria,
                                                            i_flg_multiple   => r_preg_exam.flg_multiple,
                                                            i_fetus_number   => l_num_fetus,
                                                            o_id_exam_result => o_exam_result,
                                                            o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'SCROLL THROUGH ALL FETUS';
            pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            FOR r_fetus IN (SELECT a.id_fetus,
                                   a.flg_gender,
                                   extract(b.fetus, '/FETUS/VITAL_SIGNS') vital_signs,
                                   extract(b.fetus, '/FETUS/DOCS') docs
                              FROM (SELECT VALUE(p) fetus
                                      FROM TABLE(xmlsequence(extract(r_preg_exam.fetal, '/FETAL/FETUS'))) p) b,
                                   xmltable('/FETUS' passing b.fetus columns --
                                            "ID_FETUS" NUMBER(24) path '@ID', --
                                            "FLG_GENDER" VARCHAR2(1 CHAR) path '@FLG_GENDER') a)
            LOOP
                g_error := 'GET ALL FETUS VS';
                pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                SELECT a.id_vital_sign, a.value, a.image
                  BULK COLLECT
                  INTO l_vs, l_vs_value, l_vs_doc
                  FROM (SELECT VALUE(b) vital_sign
                          FROM TABLE(xmlsequence(extract(r_fetus.vital_signs, '/VITAL_SIGNS/*'))) b) c,
                       xmltable('/VITAL_SIGN' passing c.vital_sign columns --
                                "ID_VITAL_SIGN" NUMBER(24) path '@ID_VITAL_SIGN',
                                "VALUE" NUMBER(10, 3) path '@VALUE',
                                "IMAGE" NUMBER(24) path '@IMAGE') a;
            
                g_error := 'SCROLL THROUGH ALL FETUS DOCS';
                pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                SELECT a.id_documentation, a.id_doc_element, a.id_doc_element_crit, a.value
                  BULK COLLECT
                  INTO l_id_tbl_documentation, l_id_tbl_element, l_id_tbl_element_crit, l_tbl_value
                  FROM (SELECT VALUE(b) vital_sign
                          FROM TABLE(xmlsequence(extract(r_fetus.docs, '/DOCS/*'))) b) c,
                       xmltable('/DOC' passing c.vital_sign columns --
                                "ID_DOCUMENTATION" NUMBER(24) path '@ID_DOCUMENTATION',
                                "ID_DOC_ELEMENT" NUMBER(24) path '@ID_DOC_ELEMENT',
                                "ID_DOC_ELEMENT_CRIT" NUMBER(24) path '@ID_DOC_ELEMENT_CRIT',
                                "VALUE" VARCHAR2(1000 CHAR) path '@VALUE') a;
            
                g_error := 'CALL SET_RESULT_FETUS';
                pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
                IF NOT set_result_fetus(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_prof_cat_type         => r_preg_exam.prof_cat_type,
                                        i_id_patient            => i_patient,
                                        i_id_pat_pregnancy      => o_pat_pregnancy,
                                        i_id_exam_result        => o_exam_result,
                                        i_fetus_number          => r_fetus.id_fetus,
                                        i_flg_gender            => r_fetus.flg_gender,
                                        i_vs                    => l_vs,
                                        i_vs_value              => l_vs_value,
                                        i_vs_doc                => l_vs_doc,
                                        i_id_epis_documentation => NULL,
                                        i_id_doc_area           => r_preg_exam.id_doc_area,
                                        i_id_tbl_documentation  => l_id_tbl_documentation,
                                        i_id_tbl_element        => l_id_tbl_element,
                                        i_id_tbl_element_crit   => l_id_tbl_element_crit,
                                        i_tbl_value             => l_tbl_value,
                                        i_doc_notes             => NULL,
                                        o_id_pat_pregn_fetus    => o_id_pat_pregn_fetus,
                                        o_error                 => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
        END LOOP;
    
        g_error := 'SCROLL THROUGH ALL EXAMS ORDERS';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        FOR r_exam_order IN (SELECT a.id_episode, a.flg_test, extract(b.exam_order, '/EXAM_ORDER/EXAMS') exams
                               FROM (SELECT VALUE(p) exam_order
                                       FROM TABLE(xmlsequence(extract(xmltype(i_params), '/EXAM_ORDER'))) p) b,
                                    xmltable('/PREGNANCY_EXAM_ALL' passing b.exam_order columns --
                                             "ID_EPISODE" NUMBER(24) path 'ID_EPISODE', --
                                             "FLG_TEST" VARCHAR2(1 CHAR) path 'FLG_TEST') a)
        LOOP
            g_error := 'GET ALL EXAMS VARS';
            pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            SELECT a.id_exam,
                   a.flg_type,
                   a.codification,
                   a.flg_time,
                   a.dt_begin,
                   a.priority,
                   a.exec_room,
                   a.exec_inst,
                   a.clinical_purpose,
                   a.notes,
                   a.notes_scheduler,
                   a.tech_notes,
                   a.pat_notes,
                   a.order_id_prof,
                   a.order_date,
                   a.order_type,
                   extract(b.exam, '/EXAM/DIAGNOSES').getclobval() tbl_id_diags,
                   pk_pregnancy_core.get_exam_id_clin_quest(extract(b.exam, '/EXAM/CLINICAL_QUESTIONS')) tbl_id_clin_quest,
                   pk_pregnancy_core.get_exam_clin_resp(extract(b.exam, '/EXAM/CLINICAL_QUESTIONS')) tbl_clin_resp,
                   pk_pregnancy_core.get_exam_clin_notes(extract(b.exam, '/EXAM/CLINICAL_QUESTIONS')) tbl_clin_notes
              BULK COLLECT
              INTO l_id_exam,
                   l_flg_type,
                   l_codification,
                   l_flg_time,
                   l_dt_begin,
                   l_priority,
                   l_exec_room,
                   l_exec_inst,
                   l_clinical_purpose,
                   l_notes,
                   l_notes_scheduler,
                   l_tech_notes,
                   l_pat_notes,
                   l_order_id_prof,
                   l_order_date,
                   l_order_type,
                   l_xml_diag,
                   l_tbl_id_clin_quest,
                   l_tbl_clin_resp,
                   l_tbl_clin_notes
              FROM (SELECT VALUE(p) exam
                      FROM TABLE(xmlsequence(extract(r_exam_order.exams, '/EXAMS/EXAM'))) p) b,
                   xmltable('/EXAM' passing b.exam columns --
                            "ID_EXAM" NUMBER(24) path '@ID', --
                            "FLG_TYPE" VARCHAR2(1 CHAR) path '@FLG_TYPE', --
                            "CODIFICATION" NUMBER(24) path '@CODIFICATION', --
                            "FLG_TIME" VARCHAR2(1 CHAR) path '@FLG_TIME', --
                            "DT_BEGIN" VARCHAR2(14 CHAR) path '@DT_BEGIN', --
                            "PRIORITY" VARCHAR2(1 CHAR) path '@PRIORITY', --
                            "EXEC_ROOM" NUMBER(24) path '@EXEC_ROOM', --
                            "EXEC_INST" NUMBER(24) path '@EXEC_INST', --
                            "CLINICAL_PURPOSE" VARCHAR2(2 CHAR) path '@CLINICAL_PURPOSE', --
                            "NOTES" VARCHAR2(1000 CHAR) path 'NOTES', --
                            "NOTES_SCHEDULER" VARCHAR2(1000 CHAR) path 'NOTES_SCHEDULER', --
                            "TECH_NOTES" VARCHAR2(1000 CHAR) path 'TECH_NOTES', --
                            "PAT_NOTES" VARCHAR2(1000 CHAR) path 'PAT_NOTES', --
                            "ORDER_ID_PROF" NUMBER(24) path 'ORDER@ID_PROF', --
                            "ORDER_DATE" VARCHAR2(14 CHAR) path 'ORDER@DATE', --
                            "ORDER_TYPE" NUMBER(24) path 'ORDER@TYPE') a;
        
            l_tbl_diags := pk_edis_types.table_in_epis_diagnosis();
        
            IF l_xml_diag IS NOT NULL
               AND l_xml_diag.count > 0
            THEN
                FOR i IN l_xml_diag.first .. l_xml_diag.last
                LOOP
                    l_tbl_diags.extend;
                    l_tbl_diags(l_tbl_diags.count) := pk_pregnancy_core.get_exam_diags(i_lang       => i_lang,
                                                                                       i_prof       => i_prof,
                                                                                       i_id_patient => i_patient,
                                                                                       i_id_episode => r_exam_order.id_episode,
                                                                                       i_diags      => xmltype(l_xml_diag(i)));
                END LOOP;
            END IF;
        
            g_error := 'CALL PK_EXAMS_API_DB.CREATE_EXAM_ORDER';
            IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                     i_prof                    => i_prof,
                                                     i_patient                 => i_patient,
                                                     i_episode                 => r_exam_order.id_episode,
                                                     i_exam_req                => NULL,
                                                     i_exam_req_det            => table_number(),
                                                     i_exam                    => l_id_exam,
                                                     i_flg_type                => l_flg_type,
                                                     i_dt_req                  => table_varchar(),
                                                     i_flg_time                => l_flg_time,
                                                     i_dt_begin                => l_dt_begin,
                                                     i_dt_begin_limit          => table_varchar(), --NEW FIELD
                                                     i_episode_destination     => table_number(),
                                                     i_order_recurrence        => table_number(),
                                                     i_priority                => l_priority,
                                                     i_flg_prn                 => table_varchar(),
                                                     i_notes_prn               => table_varchar(),
                                                     i_flg_fasting             => table_varchar(),
                                                     i_notes                   => l_notes,
                                                     i_notes_scheduler         => l_notes_scheduler,
                                                     i_notes_technician        => l_tech_notes,
                                                     i_notes_patient           => l_pat_notes,
                                                     i_diagnosis_notes         => NULL,
                                                     i_diagnosis               => l_tbl_diags,
                                                     i_exec_room               => l_exec_room,
                                                     i_exec_institution        => l_exec_inst,
                                                     i_clinical_purpose        => l_clinical_purpose,
                                                     i_codification            => l_codification,
                                                     i_health_plan             => table_number(),
                                                     i_prof_order              => l_order_id_prof,
                                                     i_dt_order                => l_order_date,
                                                     i_order_type              => l_order_type,
                                                     i_clinical_question       => l_tbl_id_clin_quest,
                                                     i_response                => l_tbl_clin_resp,
                                                     i_clinical_question_notes => l_tbl_clin_notes,
                                                     i_clinical_decision_rule  => table_number(), --NEW FIELD
                                                     i_flg_origin_req          => NULL,
                                                     i_task_dependency         => table_number(),
                                                     i_flg_task_depending      => table_varchar(),
                                                     i_episode_followup_app    => table_number(),
                                                     i_schedule_followup_app   => table_number(),
                                                     i_event_followup_app      => table_number(),
                                                     i_test                    => r_exam_order.flg_test,
                                                     o_flg_show                => o_flg_show,
                                                     o_msg_title               => o_msg_title,
                                                     o_msg_req                 => o_msg_req,
                                                     o_button                  => o_button,
                                                     o_exam_req_array          => o_exam_req_array,
                                                     o_exam_req_det_array      => o_exam_req_det_array,
                                                     o_error                   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        g_error := 'SET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_back_nls || '''';
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pregnancy_exam_all;

    /**
    * Encapsulates the logic of saving a pregnancy exam request
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_exam_req_det     Exam req det id
    *
    * @return  Table of t_preg_result
    *
    * @author  Alexandre Santos
    * @version v2.6.0.3
    * @since   27-05-2010
    */
    FUNCTION tf_get_pregn_result_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req_det IN exam_result.id_exam_req_det%TYPE
    ) RETURN t_col_preg_result IS
        l_func_name CONSTANT VARCHAR2(50) := 'TF_GET_PREGN_RESULT_DET';
        --
        l_cd_msg_wks        CONSTANT sys_message.code_message%TYPE := 'EXAM_IMAGE_T044';
        l_cd_msg_tri        CONSTANT sys_message.code_message%TYPE := 'EXAM_IMAGE_T045';
        l_cd_domain_prg_tri CONSTANT sys_domain.code_domain%TYPE := 'WOMAN_HEALTH.PREGNANCY_TRIMESTER';
        --
        l_msg_wks sys_message.desc_message%TYPE;
        l_msg_tri sys_message.desc_message%TYPE;
        --
        l_tbl_ret t_col_preg_result;
    BEGIN
        g_error := 'GET MESSAGES';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        l_msg_wks := pk_message.get_message(i_lang => i_lang, i_code_mess => l_cd_msg_wks);
        l_msg_tri := pk_message.get_message(i_lang => i_lang, i_code_mess => l_cd_msg_tri);
    
        g_error := 'FILL TABLE t_preg_result';
        pk_alertlog.log_debug(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
        SELECT /*+opt_estimate(table er rows=1)*/
         rec_preg_result_det(erp.id_pat_pregnancy,
                             l_msg_wks,
                             decode(erp.flg_weeks_criteria,
                                    pk_pregnancy_core.g_ultrasound_criteria,
                                    erp.weeks_pregnancy,
                                    pk_pregnancy_api.get_pregnancy_weeks(i_prof,
                                                                         pp.dt_init_pregnancy,
                                                                         nvl(pp.dt_intervention, er.dt_result),
                                                                         NULL)),
                             l_msg_tri,
                             pk_sysdomain.get_domain(l_cd_domain_prg_tri,
                                                     decode(erp.flg_weeks_criteria,
                                                            pk_pregnancy_core.g_ultrasound_criteria,
                                                            pk_woman_health.conv_weeks_to_trimester(erp.weeks_pregnancy),
                                                            pk_woman_health.conv_weeks_to_trimester(trunc((trunc(CAST(er.dt_result AS DATE)) -
                                                                                                          trunc(CAST(nvl(pp.dt_init_preg_lmp,
                                                                                                                          pp.dt_init_pregnancy) AS DATE)) + 6) / 7))),
                                                     i_lang))
          BULK COLLECT
          INTO l_tbl_ret
          FROM TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'Y')) er,
               exam_result_pregnancy erp,
               pat_pregnancy pp
         WHERE er.id_exam_result = erp.id_exam_result
           AND pp.id_pat_pregnancy = erp.id_pat_pregnancy;
    
        RETURN l_tbl_ret;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' <-> ' || SQLCODE || ' - ' || SQLERRM;
            pk_alertlog.log_error(object_name => g_package_name, sub_object_name => l_func_name, text => g_error);
            RETURN NULL;
    END tf_get_pregn_result_det;

    PROCEDURE inicialize IS
    BEGIN
    
        pk_alertlog.who_am_i(g_package_owner, g_package_name);
        pk_alertlog.log_init(g_package_name);
    
        g_exam_mov_pat        := 'Y';
        g_flg_time_epis       := 'E';
        g_flg_time_next       := 'N';
        g_flg_time_betw       := 'B';
        g_flg_time_resu       := 'R';
        g_exam_det_tosched    := 'PA';
        g_exam_det_sched      := 'A';
        g_exam_det_efectiv    := 'EF';
        g_exam_det_pend       := 'D';
        g_exam_det_req        := 'R';
        g_exam_det_canc       := 'C';
        g_exam_det_exec       := 'E';
        g_exam_det_result     := 'F';
        g_exam_det_read       := 'L';
        g_exam_det_transp     := 'T';
        g_exam_det_end_transp := 'M';
    
        g_exam_req_det_status := 'EXAM_REQ_DET.FLG_STATUS';
    
        g_exam_tosched := 'PA';
        g_exam_sched   := 'A';
        g_exam_efectiv := 'EF';
        g_exam_pend    := 'D';
        g_exam_req     := 'R';
        g_exam_canc    := 'C';
        g_exam_exec    := 'E';
        g_exam_res     := 'F';
        g_exam_part    := 'P';
    
        g_mov_status_pend   := 'P';
        g_mov_status_req    := 'R';
        g_mov_status_cancel := 'C';
        g_mov_status_finish := 'F';
        g_mov_status_interr := 'S';
    
        g_cat_type_doc   := 'D';
        g_cat_type_tec   := 'T';
        g_cat_type_nurse := 'N';
    
        g_exam_available := 'Y';
        g_exam_execute   := 'R';
        g_exam_freq      := 'M';
        g_exam_can_req   := 'P';
        g_exam_conv      := 'C';
    
        g_mov_pat         := 'Y';
        g_cat_doctor      := 'D';
        g_result_type_tec := 'T';
    
        g_exam_type     := 'E';
        g_exam_type_img := 'I';
    
        g_epis_active := 'A';
    
        g_domain_flg_time := 'EXAM_REQ.FLG_TIME';
        g_epis_type       := 2;
        g_selected        := 'S';
        g_inp_software    := 11;
    
        g_flg_available := 'Y';
    
        g_exam_ultrasound      := 'U';
        g_flg_pregnancy_active := 'A';
    
        g_doc_active := 'A';
    
        g_edcs_flg_type_p     := 'P';
        g_ext_doc_flg_state_f := 'F';
    
        g_doc_active := 'A';
    
        g_edcs_flg_type_p     := 'P';
        g_ext_doc_flg_state_f := 'F';
    
        g_exam_req_read := 'L';
        g_exam_req_canc := 'C';
        g_flg_admin     := 'A';
        g_flg_tech      := 'T';
    
        g_edis_software := 8;
    
    END inicialize;

    FUNCTION get_pregnancy_confirm_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PREGNANCY_CONFIRM_FORM_VALUES';
    
        l_curr_comp_int_name ds_component.internal_name%TYPE;
        l_id_ds_component    ds_component.id_ds_component%TYPE;
    
        l_aux_val          VARCHAR2(4000 CHAR);
        l_aux_val_desc     VARCHAR2(4000 CHAR);
        l_aux_unit_measure NUMBER(24);
    
        l_association_option      VARCHAR2(1 CHAR);
        l_association_option_desc VARCHAR2(4000 CHAR);
        l_n_live_births           VARCHAR2(10 CHAR);
        l_weeks                   NUMBER := 0;
        l_bool                    BOOLEAN;
        l_dt_pregnancy            DATE;
        l_dt_exam_result          DATE;
        l_trimester               NUMBER;
        l_desc_trimester          VARCHAR2(0050);
        l_flg_female_exam         VARCHAR2(2 CHAR);
        l_dt_epis_begin           episode.dt_begin_tstz%TYPE;
        l_date_comparison         VARCHAR2(1 CHAR);
        l_code_error_message      sys_message.code_message%TYPE;
    
        --Return variable
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_exception EXCEPTION;
    
        CURSOR pregancy_info IS
            SELECT pregn.id_pat_pregnancy,
                   pregn.n_pregnancy num_pregnancy,
                   coalesce(pregn.dt_last_menstruation, pregn.dt_init_preg_lmp, pregn.dt_init_pregnancy) dt_last_menstruation,
                   CAST(pregn.dt_intervention AS DATE) dt_childbirth,
                   pregn.n_children,
                   pregn.flg_multiple,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TYPE', pregn.flg_multiple, i_lang) desc_multiple,
                   l_weeks weeks_c,
                   pk_sysdomain.get_domain('WOMAN_HEALTH.PREGNANCY_TRIMESTER',
                                           to_char(pk_woman_health.conv_weeks_to_trimester(l_weeks)),
                                           i_lang) trimester,
                   nvl2(pregn.dt_last_menstruation, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_has_dt_menstr,
                   nvl(pregn.n_children, 1) fetus_qty
              FROM pat_pregnancy pregn
             WHERE pregn.id_patient = i_patient
               AND pregn.flg_status = g_flg_pregnancy_active;
    
        CURSOR c_weeks_pregnancy(i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE) IS
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.dt_init_preg_lmp, CAST(pp.dt_intervention AS DATE)
              FROM pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'Y')) er
             WHERE er.id_pat_pregnancy = pp.id_pat_pregnancy
               AND pp.dt_intervention IS NOT NULL
            UNION ALL
            SELECT /*+opt_estimate(table er rows=1)*/
             pp.dt_init_preg_lmp, MAX(CAST(er.dt_result AS DATE))
              FROM pat_pregnancy pp,
                   TABLE(pk_exam_external.tf_exam_pregnancy_info(i_lang, i_prof, i_exam_req_det, 'Y')) er
             WHERE er.id_pat_pregnancy = pp.id_pat_pregnancy
             GROUP BY pp.dt_init_preg_lmp;
    
        l_pregnancy_info_row pregancy_info%ROWTYPE;
    
        FUNCTION get_weeks RETURN NUMBER IS
        
            l_exam_req_det table_number := table_number();
            k_weeks        NUMBER := 0;
        
        BEGIN
        
            SELECT erd.id_exam_req_det
              BULK COLLECT
              INTO l_exam_req_det
              FROM exam_req er
              JOIN exam_req_det erd
                ON erd.id_exam_req = er.id_exam_req
             WHERE er.id_exam_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       t.*
                                        FROM TABLE(i_tbl_id_pk) t);
        
            IF l_exam_req_det IS NOT NULL
               AND l_exam_req_det.count > 0
            THEN
            
                FOR i IN 1 .. l_exam_req_det.count
                LOOP
                    OPEN c_weeks_pregnancy(l_exam_req_det(i));
                    FETCH c_weeks_pregnancy
                        INTO l_dt_pregnancy, l_dt_exam_result;
                    CLOSE c_weeks_pregnancy;
                
                    l_bool := pk_woman_health.get_preg_converted_time(i_lang,
                                                                      NULL,
                                                                      l_dt_pregnancy,
                                                                      l_dt_exam_result,
                                                                      k_weeks,
                                                                      l_trimester,
                                                                      l_desc_trimester,
                                                                      o_error);
                
                    IF k_weeks IS NOT NULL
                       AND k_weeks > 0
                    THEN
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            RETURN k_weeks;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN 0;
        END get_weeks;
    
    BEGIN
        IF i_action IS NULL
        THEN
            l_flg_female_exam := i_tbl_data(i_idx) (1);
        
            IF l_flg_female_exam IS NOT NULL
               AND l_flg_female_exam <> 'BN'
            THEN
                g_error := 'ERROR GETTING WEEKS';
                l_weeks := get_weeks;
            
                g_error := 'ERROR OPEINING pregancy_info';
                OPEN pregancy_info;
                LOOP
                    FETCH pregancy_info
                        INTO l_pregnancy_info_row;
                    EXIT WHEN pregancy_info%NOTFOUND;
                END LOOP;
                CLOSE pregancy_info;
            END IF;
        
            g_error := 'SELECT INTO TBL_RESULT';
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_pregnancy_number THEN
                                                                  to_char(l_pregnancy_info_row.num_pregnancy)
                                                                 WHEN pk_orders_constant.g_ds_last_menstrual_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                              i_date => l_pregnancy_info_row.dt_last_menstruation,
                                                                                              i_prof => i_prof)
                                                                 WHEN pk_orders_constant.g_ds_delivery_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                              i_date => l_pregnancy_info_row.dt_childbirth,
                                                                                              i_prof => i_prof)
                                                                 WHEN pk_orders_constant.g_ds_live_births THEN
                                                                  to_char(l_pregnancy_info_row.n_children)
                                                                 WHEN pk_orders_constant.g_ds_flg_female_exam THEN
                                                                  l_flg_female_exam
                                                                 WHEN pk_orders_constant.g_ds_dummy_number THEN
                                                                  to_char(l_pregnancy_info_row.id_pat_pregnancy)
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_pregnancy_number THEN
                                                                  to_char(l_pregnancy_info_row.num_pregnancy)
                                                                 WHEN pk_orders_constant.g_ds_live_births THEN
                                                                  to_char(l_pregnancy_info_row.n_children)
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE t.internal_name_child
                                                                 WHEN pk_orders_constant.g_ds_exam_associate_pregnancy_record THEN
                                                                  CASE
                                                                      WHEN l_flg_female_exam = 'BN' THEN
                                                                       pk_orders_constant.g_component_inactive
                                                                      ELSE
                                                                       def.flg_event_type
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_delivery_date THEN
                                                                  CASE
                                                                      WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                       pk_orders_constant.g_component_inactive
                                                                      ELSE
                                                                       nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_live_births THEN
                                                                  CASE
                                                                      WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                       pk_orders_constant.g_component_read_only
                                                                      ELSE
                                                                       nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_delivery_type THEN
                                                                  CASE
                                                                      WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                       pk_orders_constant.g_component_inactive
                                                                      ELSE
                                                                       nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                  END
                                                                 WHEN pk_orders_constant.g_ds_pregnancy_abortion_type THEN
                                                                  CASE
                                                                      WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                       pk_orders_constant.g_component_inactive
                                                                      ELSE
                                                                       nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                  END
                                                                 ELSE
                                                                  nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                             END,
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.internal_name IN (pk_orders_constant.g_ds_exam_associate_pregnancy_record,
                                       pk_orders_constant.g_ds_pregnancy_number,
                                       pk_orders_constant.g_ds_last_menstrual_date,
                                       pk_orders_constant.g_ds_delivery_date,
                                       pk_orders_constant.g_ds_live_births,
                                       pk_orders_constant.g_ds_delivery_type,
                                       pk_orders_constant.g_ds_pregnancy_abortion_type,
                                       pk_orders_constant.g_ds_flg_female_exam,
                                       pk_orders_constant.g_ds_dummy_number)
             ORDER BY t.rn;
        
        ELSIF i_action = pk_dyn_form_constant.get_submit_action
        THEN
            IF i_curr_component IS NOT NULL
            THEN
                --Check which element has been changed
                SELECT d.internal_name_child
                  INTO l_curr_comp_int_name
                  FROM ds_cmpt_mkt_rel d
                 WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
            
                IF l_curr_comp_int_name IN
                   (pk_orders_constant.g_ds_last_menstrual_date, pk_orders_constant.g_ds_delivery_date)
                THEN
                    l_aux_val := pk_orders_utils.get_value(i_internal_name_child => l_curr_comp_int_name,
                                                           i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                           i_value               => i_value);
                
                    l_date_comparison := pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                                         i_date1 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                  i_prof,
                                                                                                                                                                  l_aux_val,
                                                                                                                                                                  NULL),
                                                                                                                     i_format    => 'DD'),
                                                                         i_date2 => pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                                                     i_timestamp => current_timestamp,
                                                                                                                     i_format    => 'DD'));
                    IF l_date_comparison = 'G'
                    THEN
                        l_code_error_message := 'COMMON_M163';
                    END IF;
                
                    tbl_result.extend();
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                              id_ds_component    => d.id_ds_component_child,
                                              internal_name      => d.internal_name_child,
                                              VALUE              => l_aux_val,
                                              value_clob         => NULL,
                                              min_value          => NULL,
                                              max_value          => NULL,
                                              desc_value         => NULL,
                                              desc_clob          => NULL,
                                              id_unit_measure    => d.id_unit_measure,
                                              desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                 i_prof         => i_prof,
                                                                                                                 i_unit_measure => d.id_unit_measure),
                                              flg_validation     => CASE l_date_comparison
                                                                        WHEN 'G' THEN
                                                                         pk_orders_constant.g_component_error
                                                                        ELSE
                                                                         pk_alert_constant.g_yes
                                                                    END,
                                              err_msg            => CASE l_date_comparison
                                                                        WHEN 'G' THEN
                                                                         pk_message.get_message(i_lang,
                                                                                                l_code_error_message)
                                                                    END,
                                              flg_event_type     => pk_orders_constant.g_component_active,
                                              flg_multi_status   => NULL,
                                              idx                => i_idx)
                      INTO tbl_result(tbl_result.count)
                      FROM ds_cmpt_mkt_rel d
                     WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_exam_associate_pregnancy_record
                THEN
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_exam_associate_pregnancy_record
                        THEN
                            l_aux_val := i_value(i) (1);
                        ELSIF i_tbl_int_name(i) = pk_orders_constant.g_ds_live_births
                        THEN
                            l_n_live_births := i_value(i) (1);
                        END IF;
                    END LOOP;
                
                    IF l_aux_val IS NOT NULL
                       AND l_aux_val <> 'U'
                    THEN
                        FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(i) IN
                               (pk_orders_constant.g_ds_delivery_date,
                                pk_orders_constant.g_ds_live_births,
                                pk_orders_constant.g_ds_delivery_type,
                                pk_orders_constant.g_ds_pregnancy_abortion_type)
                            THEN
                                tbl_result.extend();
                                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                                           id_ds_component    => d.id_ds_component_child,
                                                           internal_name      => d.internal_name_child,
                                                           VALUE              => CASE d.internal_name_child
                                                                                     WHEN pk_orders_constant.g_ds_live_births THEN
                                                                                      l_n_live_births
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                           value_clob         => NULL,
                                                           min_value          => NULL,
                                                           max_value          => NULL,
                                                           desc_value         => CASE d.internal_name_child
                                                                                     WHEN pk_orders_constant.g_ds_live_births THEN
                                                                                      l_n_live_births
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                           desc_clob          => NULL,
                                                           id_unit_measure    => d.id_unit_measure,
                                                           desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                              i_prof         => i_prof,
                                                                                                                              i_unit_measure => d.id_unit_measure),
                                                           flg_validation     => pk_orders_constant.g_component_valid,
                                                           err_msg            => NULL,
                                                           flg_event_type     => CASE l_aux_val
                                                                                     WHEN 'N' THEN
                                                                                      CASE
                                                                                          WHEN i_tbl_int_name(i) IN
                                                                                               (pk_orders_constant.g_ds_delivery_date,
                                                                                                pk_orders_constant.g_ds_live_births) THEN
                                                                                           pk_orders_constant.g_component_mandatory
                                                                                          WHEN i_tbl_int_name(i) IN
                                                                                               (pk_orders_constant.g_ds_delivery_type,
                                                                                                pk_orders_constant.g_ds_pregnancy_abortion_type) THEN
                                                                                           pk_orders_constant.g_component_active
                                                                                      END
                                                                                     ELSE
                                                                                      CASE
                                                                                          WHEN i_tbl_int_name(i) IN (pk_orders_constant.g_ds_live_births) THEN
                                                                                           pk_orders_constant.g_component_read_only
                                                                                          ELSE
                                                                                           pk_orders_constant.g_component_inactive
                                                                                      END
                                                                                 END,
                                                           flg_multi_status   => NULL,
                                                           idx                => i_idx)
                                  INTO tbl_result(tbl_result.count)
                                  FROM ds_cmpt_mkt_rel d
                                 WHERE d.id_ds_cmpt_mkt_rel = i_tbl_mkt_rel(i);
                            END IF;
                        END LOOP;
                    ELSE
                        l_flg_female_exam := i_tbl_data(i_idx) (1);
                    
                        g_error := 'ERROR OPENING pregancy_info';
                        OPEN pregancy_info;
                        LOOP
                            FETCH pregancy_info
                                INTO l_pregnancy_info_row;
                            EXIT WHEN pregancy_info%NOTFOUND;
                        END LOOP;
                        CLOSE pregancy_info;
                    
                        g_error              := 'ERROR GETTING ASSOCIATION OPTION';
                        l_association_option := pk_orders_utils.get_value(i_internal_name_child => l_curr_comp_int_name,
                                                                          i_tbl_mkt_rel         => i_tbl_mkt_rel,
                                                                          i_value               => i_value);
                        IF l_association_option IS NOT NULL
                        THEN
                            l_association_option_desc := pk_sysdomain.get_domain(i_code_dom => 'EXAM_ASSOCIATE_PREGNANCY',
                                                                                 i_val      => l_association_option,
                                                                                 i_lang     => i_lang);
                        END IF;
                    
                        g_error := 'SELECT INTO TBL_RESULT';
                        SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                                   id_ds_component    => t.id_ds_component_child,
                                                   internal_name      => t.internal_name_child,
                                                   VALUE              => CASE t.internal_name_child
                                                                             WHEN
                                                                              pk_orders_constant.g_ds_exam_associate_pregnancy_record THEN
                                                                              l_association_option
                                                                             WHEN pk_orders_constant.g_ds_pregnancy_number THEN
                                                                              to_char(l_pregnancy_info_row.num_pregnancy)
                                                                             WHEN pk_orders_constant.g_ds_last_menstrual_date THEN
                                                                              pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                          i_date => l_pregnancy_info_row.dt_last_menstruation,
                                                                                                          i_prof => i_prof)
                                                                             WHEN pk_orders_constant.g_ds_delivery_date THEN
                                                                              pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                                                          i_date => l_pregnancy_info_row.dt_childbirth,
                                                                                                          i_prof => i_prof)
                                                                             WHEN pk_orders_constant.g_ds_live_births THEN
                                                                              to_char(l_pregnancy_info_row.n_children)
                                                                             WHEN pk_orders_constant.g_ds_flg_female_exam THEN
                                                                              l_flg_female_exam
                                                                             WHEN pk_orders_constant.g_ds_dummy_number THEN
                                                                              to_char(l_pregnancy_info_row.id_pat_pregnancy)
                                                                         END,
                                                   value_clob         => NULL,
                                                   min_value          => NULL,
                                                   max_value          => NULL,
                                                   desc_value         => CASE t.internal_name_child
                                                                             WHEN
                                                                              pk_orders_constant.g_ds_exam_associate_pregnancy_record THEN
                                                                              l_association_option_desc
                                                                             WHEN pk_orders_constant.g_ds_pregnancy_number THEN
                                                                              to_char(l_pregnancy_info_row.num_pregnancy)
                                                                             WHEN pk_orders_constant.g_ds_live_births THEN
                                                                              to_char(l_pregnancy_info_row.n_children)
                                                                         END,
                                                   desc_clob          => NULL,
                                                   id_unit_measure    => t.id_unit_measure,
                                                   desc_unit_measure  => CASE
                                                                             WHEN t.id_unit_measure IS NOT NULL THEN
                                                                              pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                           i_prof         => i_prof,
                                                                                                                           i_unit_measure => t.id_unit_measure)
                                                                             ELSE
                                                                              NULL
                                                                         END,
                                                   flg_validation     => pk_orders_constant.g_component_valid,
                                                   err_msg            => NULL,
                                                   flg_event_type     => CASE t.internal_name_child
                                                                             WHEN pk_orders_constant.g_ds_exam_associate_pregnancy_record THEN
                                                                              CASE
                                                                                  WHEN l_flg_female_exam = 'BN' THEN
                                                                                   pk_orders_constant.g_component_inactive
                                                                                  ELSE
                                                                                   def.flg_event_type
                                                                              END
                                                                             WHEN pk_orders_constant.g_ds_delivery_date THEN
                                                                              CASE
                                                                                  WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                                   pk_orders_constant.g_component_inactive
                                                                                  ELSE
                                                                                   nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                              END
                                                                             WHEN pk_orders_constant.g_ds_live_births THEN
                                                                              CASE
                                                                                  WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                                   pk_orders_constant.g_component_read_only
                                                                                  ELSE
                                                                                   nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                              END
                                                                             WHEN pk_orders_constant.g_ds_delivery_type THEN
                                                                              CASE
                                                                                  WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                                   pk_orders_constant.g_component_inactive
                                                                                  ELSE
                                                                                   nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                              END
                                                                             WHEN pk_orders_constant.g_ds_pregnancy_abortion_type THEN
                                                                              CASE
                                                                                  WHEN l_flg_female_exam IN ('Y', 'B', 'BN') THEN
                                                                                   pk_orders_constant.g_component_inactive
                                                                                  ELSE
                                                                                   nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                              END
                                                                             ELSE
                                                                              nvl(def.flg_event_type, pk_orders_constant.g_component_active)
                                                                         END,
                                                   flg_multi_status   => pk_alert_constant.g_no,
                                                   idx                => i_idx)
                          BULK COLLECT
                          INTO tbl_result
                          FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                       dc.id_ds_component_child,
                                       dc.internal_name_child,
                                       dc.flg_event_type,
                                       dc.rn,
                                       dc.flg_component_type_child,
                                       dc.id_unit_measure
                                  FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                     i_prof           => i_prof,
                                                                     i_patient        => NULL,
                                                                     i_component_name => i_root_name,
                                                                     i_action         => NULL)) dc) t
                          JOIN ds_component d
                            ON d.id_ds_component = t.id_ds_component_child
                          LEFT JOIN ds_def_event def
                            ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
                         WHERE d.internal_name IN (pk_orders_constant.g_ds_exam_associate_pregnancy_record,
                                                   pk_orders_constant.g_ds_pregnancy_number,
                                                   pk_orders_constant.g_ds_last_menstrual_date,
                                                   pk_orders_constant.g_ds_delivery_date,
                                                   pk_orders_constant.g_ds_live_births,
                                                   pk_orders_constant.g_ds_delivery_type,
                                                   pk_orders_constant.g_ds_pregnancy_abortion_type,
                                                   pk_orders_constant.g_ds_flg_female_exam,
                                                   pk_orders_constant.g_ds_dummy_number)
                         ORDER BY t.rn;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_delivery_type
                THEN
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) = pk_orders_constant.g_ds_exam_associate_pregnancy_record
                        THEN
                            l_aux_val := i_value(i) (1);
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_aux_val IN ('N')
                    THEN
                        FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                        LOOP
                            IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_pregnancy_abortion_type)
                            THEN
                                tbl_result.extend();
                                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                                          id_ds_component    => d.id_ds_component_child,
                                                          internal_name      => d.internal_name_child,
                                                          VALUE              => NULL,
                                                          value_clob         => NULL,
                                                          min_value          => NULL,
                                                          max_value          => NULL,
                                                          desc_value         => NULL,
                                                          desc_clob          => NULL,
                                                          id_unit_measure    => d.id_unit_measure,
                                                          desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                             i_prof         => i_prof,
                                                                                                                             i_unit_measure => d.id_unit_measure),
                                                          flg_validation     => pk_orders_constant.g_component_valid,
                                                          err_msg            => NULL,
                                                          flg_event_type     => pk_orders_constant.g_component_active,
                                                          flg_multi_status   => NULL,
                                                          idx                => i_idx)
                                  INTO tbl_result(tbl_result.count)
                                  FROM ds_cmpt_mkt_rel d
                                 WHERE d.id_ds_cmpt_mkt_rel = i_tbl_mkt_rel(i);
                            END IF;
                        END LOOP;
                    END IF;
                ELSIF l_curr_comp_int_name = pk_orders_constant.g_ds_pregnancy_abortion_type
                THEN
                    FOR i IN i_tbl_int_name.first .. i_tbl_int_name.last
                    LOOP
                        IF i_tbl_int_name(i) IN (pk_orders_constant.g_ds_delivery_type)
                        THEN
                            tbl_result.extend();
                            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => d.id_ds_cmpt_mkt_rel,
                                                      id_ds_component    => d.id_ds_component_child,
                                                      internal_name      => d.internal_name_child,
                                                      VALUE              => NULL,
                                                      value_clob         => NULL,
                                                      min_value          => NULL,
                                                      max_value          => NULL,
                                                      desc_value         => NULL,
                                                      desc_clob          => NULL,
                                                      id_unit_measure    => d.id_unit_measure,
                                                      desc_unit_measure  => pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                                         i_prof         => i_prof,
                                                                                                                         i_unit_measure => d.id_unit_measure),
                                                      flg_validation     => pk_orders_constant.g_component_valid,
                                                      err_msg            => NULL,
                                                      flg_event_type     => pk_orders_constant.g_component_active,
                                                      flg_multi_status   => NULL,
                                                      idx                => i_idx)
                              INTO tbl_result(tbl_result.count)
                              FROM ds_cmpt_mkt_rel d
                             WHERE d.id_ds_cmpt_mkt_rel = i_tbl_mkt_rel(i);
                        END IF;
                    END LOOP;
                    --  END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_pregnancy_confirm_form_values;

    FUNCTION tf_get_pregn_associated_opt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_female_exam IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT VARCHAR2(1000 CHAR) := 'TF_GET_PREGN_ASSOCIATED_OPT';
        l_error t_error_out;
        l_ret   t_tbl_core_domain;
    BEGIN
    
        g_error := 'ERROR OPPENING L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_val,
                                         domain_value  => val,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT sd.desc_val, sd.val
                          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                              i_prof,
                                                                              'EXAM_ASSOCIATE_PREGNANCY',
                                                                              NULL)) sd
                         WHERE i_flg_female_exam IS NULL
                            OR i_flg_female_exam NOT IN ('B')
                            OR (i_flg_female_exam = 'B' AND sd.val <> 'U')));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END tf_get_pregn_associated_opt;

    FUNCTION set_pat_pregnancy
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_varchar,
        i_cdr_call             IN cdr_event.id_cdr_call%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_pat_pregnancy     pat_pregnancy.id_pat_pregnancy%TYPE;
        l_n_pregnancy          pat_pregnancy.n_pregnancy%TYPE;
        l_dt_last_menstruation pat_pregnancy.dt_last_menstruation%TYPE;
        l_dt_childbirth        DATE;
        l_n_children           pat_pregnancy.n_children%TYPE;
        l_flg_childbirth_type  VARCHAR2(2 CHAR);
        l_flg_abbort           VARCHAR2(2 CHAR);
    
        l_association_option VARCHAR2(1 CHAR);
    
        l_msg       VARCHAR2(4000 CHAR);
        l_msg_title VARCHAR2(4000 CHAR);
        l_flg_show  VARCHAR2(4000 CHAR);
        l_button    VARCHAR2(4000 CHAR);
    
        l_rows_out table_varchar := table_varchar();
    BEGIN
        g_error := 'ERROR GETTING VALUES FROM I_TBL_REAL_VAL';
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_dummy_number
            THEN
                l_id_pat_pregnancy := to_number(i_tbl_real_val(i));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_exam_associate_pregnancy_record
            THEN
                l_association_option := i_tbl_real_val(i);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_pregnancy_number
            THEN
                l_n_pregnancy := to_number(i_tbl_real_val(i));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_last_menstrual_date
            THEN
                l_dt_last_menstruation := trunc(pk_date_utils.get_string_tstz(i_lang, i_prof, i_tbl_real_val(i), NULL));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_delivery_date
            THEN
                l_dt_childbirth := trunc(pk_date_utils.get_string_tstz(i_lang, i_prof, i_tbl_real_val(i), NULL));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_live_births
            THEN
                l_n_children := to_number(i_tbl_real_val(i));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_delivery_type
            THEN
                l_flg_childbirth_type := i_tbl_real_val(i);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_pregnancy_abortion_type
            THEN
                l_flg_abbort := i_tbl_real_val(i);
            END IF;
        END LOOP;
    
        IF l_association_option IS NULL
           OR l_association_option = 'N'
        THEN
            g_error := 'ERROR CALLING PK_WOMAN_HEALTH.SET_PAT_PREGNANCY';
            IF NOT pk_woman_health.set_pat_pregnancy(i_lang                 => i_lang,
                                                i_patient              => i_id_patient,
                                                i_pat_pregnancy        => l_id_pat_pregnancy,
                                                i_dt_last_menstruation => l_dt_last_menstruation,
                                                i_dt_childbirth        => l_dt_childbirth,
                                                i_n_pregnancy          => l_n_pregnancy,
                                                i_flg_childbirth_type  => l_flg_childbirth_type,
                                                i_n_children           => l_n_children,
                                                i_flg_abbort           => l_flg_abbort,
                                                i_flg_active           => pk_alert_constant.g_yes,
                                                i_prof                 => i_prof,
                                                i_id_episode           => i_id_episode,
                                                i_cdr_call             => CASE
                                                                              WHEN i_cdr_call = -1 THEN
                                                                               NULL
                                                                              ELSE
                                                                               i_cdr_call
                                                                          END,
                                                o_msg                  => l_msg,
                                                o_msg_title            => l_msg_title,
                                                o_flg_show             => l_flg_show,
                                                o_button               => l_button,
                                                o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF l_association_option = 'Y'
              AND l_id_pat_pregnancy IS NOT NULL
        THEN
            ts_pat_pregnancy.upd(id_pat_pregnancy_in      => l_id_pat_pregnancy,
                                 id_professional_in       => i_prof.id,
                                 dt_last_menstruation_in  => l_dt_last_menstruation,
                                 dt_last_menstruation_nin => FALSE,
                                 id_episode_in            => i_id_episode,
                                 id_cdr_call_in           => CASE
                                                                 WHEN i_cdr_call = -1 THEN
                                                                  NULL
                                                                 ELSE
                                                                  i_cdr_call
                                                             END,
                                 id_cdr_call_nin          => FALSE,
                                 handle_error_in          => TRUE,
                                 rows_out                 => l_rows_out);
        
            UPDATE pat_pregn_fetus ppf
               SET ppf.flg_childbirth_type = l_flg_childbirth_type
             WHERE ppf.id_pat_pregnancy = l_id_pat_pregnancy;
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
                                              'SET_PAT_PREGNANCY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_pregnancy;

BEGIN
    inicialize();
END pk_pregnancy_exam;
/
