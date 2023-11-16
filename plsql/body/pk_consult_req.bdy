/*-- Last Change Revision: $Rev: 2026898 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:20 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_consult_req IS

    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_commit_data      IN VARCHAR2,
        i_reason_for_visit IN consult_req.reason_for_visit%TYPE DEFAULT NULL,
        i_epis_type        IN consult_req.id_epis_type%TYPE DEFAULT NULL,
        i_flg_type         IN VARCHAR2,
        i_notes_admin      IN consult_req.notes_admin%TYPE DEFAULT NULL,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
            OBJECTIVO:   Criar requisição de consulta interna / externa para ourra especialidade 
            PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                        I_EPISODE - ID do episódio 
                        I_PROF_REQ - ID do profissional q requisita exame / consulta 
                      I_PAT - doente para quem é pedido o exame / consulta 
                      I_INSTIT_REQUESTS - instituição requisitante. Pode ser NULL  
                      I_INSTIT_REQUESTED - instituição requisitada 
                      I_CONSULT_TYPE, I_CLINICAL_SERVICE, I_DEP_CLIN_SERV - Tipo de 
                              exame / consulta requisitada. Se requisição é externa, 
                          preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço 
                          pretendido está registado na BD da instituição 
                          requisitante) ou CONSULT_TYPE (campo de texto livre).
                          Se requisição é interna, selecciona-se o tipo de 
                          serviço (ID_CLINICAL_SERVICE) e o departamento (DEP_CLIN_SERV).
                      I_DT_SCHEDULED - data agendada 
                      I_NOTES - notas do prof. requisitante 
                      I_PROF_REQUESTED - prof requisitado (req. internas) 
                      I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                                como é retornada em PK_LOGIN.GET_PROF_PREF 
                      I_COMMIT_DATA - Flag que indica se a função deve fazer o commit dos dados                                       
                   Saida:   O_ERROR - erro 
           
           CRIAÇÃO: CRS 2005/05/05 
           Alteração: AA 2005/11/22 
                CRS 2006/11/07 Eliminar referência à configuração 'ID_DEPARTMENT_CONSULT' 
                      SS 2006/11/27 Utilizar DEPARTMENT.FLG_TYPE em vez de DEP_CLIN_SERV_TYPE
              
           NOTAS: Para consulta subsequente, os campos a preencher são: 
                I_EPISODE, I_PROF_REQ, I_PAT, I_DT_SCHEDULED, I_NOTES, 
              I_PROF_REQUESTED, I_PROF_CAT_TYPE 
        *
        * Changed:
        *                             Elisabete bugalho
        *                             2009/03/24
        *                             Insert reason for visit in free-text
         *********************************************************************************/
        l_next           consult_req.id_consult_req%TYPE;
        l_error          t_error_out;
        l_instit_requsts consult_req.id_instit_requests%TYPE;
        l_inst_requested consult_req.id_inst_requested%TYPE;
        l_dep_clin_serv  consult_req.id_dep_clin_serv%TYPE;
        l_prof_requested consult_req.id_prof_requested%TYPE;
        i_dt_scheduled   TIMESTAMP WITH TIME ZONE;
        l_commit_data    BOOLEAN;
    
        CURSOR c_dcs IS
            SELECT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs, episode e, department dep
             WHERE e.id_episode = i_episode
               AND dcs.id_clinical_service = e.id_clinical_service
               AND dep.id_department = dcs.id_department
               AND dep.id_institution = i_prof_req.institution
               AND instr(dep.flg_type, 'C') > 0;
    
        l_rows_out       table_varchar := table_varchar();
        l_notes_admin_in consult_req.notes_admin%TYPE;
        l_notes_in       consult_req.notes%TYPE;
        l_flg_status_in  consult_req.flg_status%TYPE;
    
        l_flg_type consult_req.flg_type%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF (i_commit_data = 'N')
        THEN
            l_commit_data := FALSE;
        ELSE
            l_commit_data := TRUE;
        END IF;
    
        g_error          := 'GET INSTITUTION';
        l_instit_requsts := nvl(i_instit_requests, i_prof_req.institution);
        l_inst_requested := nvl(i_instit_requested, i_prof_req.institution);
    
        i_dt_scheduled := pk_date_utils.get_string_tstz(i_lang, i_prof_req, i_dt_scheduled_str, NULL);
    
        -- A flg g_flg_type_WaitList nao existe na tabela mas serve para distinguir se 
        -- o pedido vem da waiting list ou do ecra de consultas de especialidade    
        IF i_flg_type = g_flg_type_waitlist
        THEN
            l_flg_type := g_flg_type_speciality;
        ELSE
            l_flg_type := i_flg_type;
        END IF;
    
        g_error := 'GET PROF REQUESTED';
        IF i_prof_requested = -1
        THEN
            l_prof_requested := NULL;
        ELSE
            l_prof_requested := i_prof_requested;
        END IF;
    
        g_error         := 'GET DEP_CLIN_SERV';
        l_dep_clin_serv := i_dep_clin_serv;
        IF l_prof_requested = i_prof_req.id
           AND nvl(l_dep_clin_serv, 0) = 0
        THEN
            -- Prof requisitante = requisitado (ie, consulta subsequente) 
            OPEN c_dcs;
            FETCH c_dcs
                INTO l_dep_clin_serv;
            CLOSE c_dcs;
        END IF;
    
        g_error := 'VALIDATE';
        IF i_consult_type IS NULL
           AND i_clinical_service IS NULL
           AND l_dep_clin_serv IS NULL
        THEN
            RAISE g_exception_msg;
        
        END IF;
    
        g_error := 'INSERT CONSULT_REQ';
    
        IF (l_prof_requested = i_prof_req.id)
        THEN
            l_notes_admin_in := i_notes;
        ELSE
            l_notes_admin_in := NULL;
        END IF;
    
        IF (l_prof_requested = i_prof_req.id)
        THEN
            l_notes_in := NULL;
        ELSE
            l_notes_in := i_notes;
        END IF;
    
        IF (i_prof_req.id = l_prof_requested)
        THEN
            l_flg_status_in := g_consult_req_stat_reply;
        ELSE
            IF i_prof_requested = -1
            THEN
                IF i_flg_type = g_flg_type_speciality
                THEN
                    l_flg_status_in := g_consult_req_stat_req;
                ELSE
                    l_flg_status_in := g_consult_req_stat_reply;
                END IF;
            ELSE
                IF i_flg_type = g_flg_type_speciality
                THEN
                    l_flg_status_in := g_consult_req_stat_req;
                ELSE
                    l_flg_status_in := g_consult_req_stat_reply;
                END IF;
            END IF;
        END IF;
    
        ts_consult_req.ins(id_consult_req_out     => l_next,
                           dt_consult_req_tstz_in => g_sysdate_tstz,
                           consult_type_in        => i_consult_type,
                           id_clinical_service_in => i_clinical_service,
                           id_patient_in          => i_pat,
                           id_instit_requests_in  => l_instit_requsts,
                           id_inst_requested_in   => l_inst_requested,
                           id_episode_in          => i_episode,
                           id_prof_req_in         => i_prof_req.id,
                           dt_scheduled_tstz_in   => i_dt_scheduled,
                           notes_admin_in         => nvl(i_notes_admin, l_notes_admin_in), -- consulta subsequente; notas p/ a administrativa 
                           notes_in               => l_notes_in, -- consulta de especialidade; notas para o colega 
                           id_dep_clin_serv_in    => l_dep_clin_serv,
                           id_prof_requested_in   => l_prof_requested,
                           flg_status_in          => l_flg_status_in,
                           flg_type_date_in       => i_flg_type_date,
                           id_complaint_in        => i_id_complaint,
                           reason_for_visit_in    => i_reason_for_visit,
                           flg_type_in            => l_flg_type,
                           id_epis_type_in        => i_epis_type,
                           rows_out               => l_rows_out);
    
        g_error := 't_data_gov_mnt.process_insert ts_consult_req';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof_req,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        o_consult_req := l_next;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof_req,
                                      i_prof_cat_type       => i_prof_cat_type,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_commit_data
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := REPLACE(REPLACE(pk_message.get_message(i_lang, 'COMMON_M004'),
                                                           '@1',
                                                           'departamento e serviço clínico'),
                                                   '@2',
                                                   'tipo de exame/consulta');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'SET_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'SET_CONSULT_REQ');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
            
                IF l_commit_data
                THEN
                    pk_utils.undo_changes;
                END IF;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_flg_type         IN VARCHAR2,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Chama a função set_consult_req com o valor do parâmetro commit_data a YES
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPISODE - ID do episódio 
                       I_PROF_REQ - ID do profissional q requisita exame / consulta 
                     I_PAT - doente para quem é pedido o exame / consulta 
                     I_INSTIT_REQUESTS - instituição requisitante. Pode ser NULL  
                     I_INSTIT_REQUESTED - instituição requisitada 
                     I_CONSULT_TYPE, I_CLINICAL_SERVICE, I_DEP_CLIN_SERV - Tipo de 
                             exame / consulta requisitada. Se requisição é externa, 
                         preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço 
                         pretendido está registado na BD da instituição 
                         requisitante) ou CONSULT_TYPE (campo de texto livre).
                         Se requisição é interna, selecciona-se o tipo de 
                         serviço (ID_CLINICAL_SERVICE) e o departamento (DEP_CLIN_SERV).
                     I_DT_SCHEDULED - data agendada 
                     I_NOTES - notas do prof. requisitante 
                     I_PROF_REQUESTED - prof requisitado (req. internas) 
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/05/05 
          Alteração: AA 2005/11/22 
               CRS 2006/11/07 Eliminar referência à configuração 'ID_DEPARTMENT_CONSULT' 
                     SS 2006/11/27 Utilizar DEPARTMENT.FLG_TYPE em vez de DEP_CLIN_SERV_TYPE
             
          NOTAS: Para consulta subsequente, os campos a preencher são: 
               I_EPISODE, I_PROF_REQ, I_PAT, I_DT_SCHEDULED, I_NOTES, 
             I_PROF_REQUESTED, I_PROF_CAT_TYPE 
        *********************************************************************************/
    
    BEGIN
        RETURN set_consult_req(i_lang             => i_lang,
                               i_episode          => i_episode,
                               i_prof_req         => i_prof_req,
                               i_pat              => i_pat,
                               i_instit_requests  => i_instit_requests,
                               i_instit_requested => i_instit_requested,
                               i_consult_type     => i_consult_type,
                               i_clinical_service => i_clinical_service,
                               i_dt_scheduled_str => i_dt_scheduled_str,
                               i_flg_type_date    => i_flg_type_date,
                               i_notes            => i_notes,
                               i_dep_clin_serv    => i_dep_clin_serv,
                               i_prof_requested   => i_prof_requested,
                               i_prof_cat_type    => i_prof_cat_type,
                               i_id_complaint     => i_id_complaint,
                               i_commit_data      => g_yes,
                               i_flg_type         => i_flg_type,
                               o_consult_req      => o_consult_req,
                               o_error            => o_error);
    
    END;

    /**********************************************************************************************
    * Chama a função set_consult_req com o valor do parâmetro commit_data a YES, 
    * inclui o paramatro do motivo de consulta de texto livre
    *
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_EPISODE - ID do episódio 
    * @param I_PROF_REQ - ID do profissional q requisita exame / consulta 
    * @param I_PAT - doente para quem é pedido o exame / consulta 
    * @param I_INSTIT_REQUESTS - instituição requisitante. Pode ser NULL  
    * @param I_INSTIT_REQUESTED - instituição requisitada 
    * @param I_CONSULT_TYPE, I_CLINICAL_SERVICE, I_DEP_CLIN_SERV - Tipo de 
                             exame / consulta requisitada. Se requisição é externa, 
                         preenche-se ID_CLINICAL_SERVICE (se o tipo de serviço 
                         pretendido está registado na BD da instituição 
                         requisitante) ou CONSULT_TYPE (campo de texto livre).
                         Se requisição é interna, selecciona-se o tipo de 
                         serviço (ID_CLINICAL_SERVICE) e o departamento (DEP_CLIN_SERV).
    * @param I_DT_SCHEDULED - data agendada 
    * @param I_NOTES - notas do prof. requisitante 
    * @param I_PROF_REQUESTED - prof requisitado (req. internas) 
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal 
                               como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param i_id_complaint - Id of complaint from table COMPLAINT
    * @param i_reason_for_visit - Reason of complaint
    *
    * @param o_consult_req         ID of consult req
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/24
    **********************************************************************************************/
    FUNCTION set_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN consult_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_consult_type     IN consult_req.consult_type%TYPE,
        i_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        i_notes            IN consult_req.notes%TYPE,
        i_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_complaint     IN consult_req.id_complaint%TYPE,
        i_reason_for_visit IN consult_req.reason_for_visit%TYPE,
        i_flg_type         IN VARCHAR2,
        o_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_consult_req(i_lang             => i_lang,
                               i_episode          => i_episode,
                               i_prof_req         => i_prof_req,
                               i_pat              => i_pat,
                               i_instit_requests  => i_instit_requests,
                               i_instit_requested => i_instit_requested,
                               i_consult_type     => i_consult_type,
                               i_clinical_service => i_clinical_service,
                               i_dt_scheduled_str => i_dt_scheduled_str,
                               i_flg_type_date    => i_flg_type_date,
                               i_notes            => i_notes,
                               i_dep_clin_serv    => i_dep_clin_serv,
                               i_prof_requested   => i_prof_requested,
                               i_prof_cat_type    => i_prof_cat_type,
                               i_id_complaint     => i_id_complaint,
                               i_commit_data      => g_yes,
                               i_reason_for_visit => i_reason_for_visit,
                               i_flg_type         => i_flg_type,
                               o_consult_req      => o_consult_req,
                               o_error            => o_error);
    
    END;

    FUNCTION update_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        i_flg         IN consult_req.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar o estado da requisição de consulta interna / externa 
                  para processada, aprovada, ou autorizada.
                Só para req. externas! 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do registo a actualizar 
                       ID_PROF - Profissional 
                     I_FLG - novo estado: T - autorizado, V - aprovado, S - processado 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/24 
          NOTAS: 
        *********************************************************************************/
        l_prof_auth consult_req.id_prof_auth%TYPE;
        l_prof_apr  consult_req.id_prof_appr%TYPE;
        l_prof_proc consult_req.id_prof_proc%TYPE;
        l_error     t_error_out;
    
        CURSOR c_exist IS
            SELECT id_prof_auth, id_prof_appr, id_prof_proc, id_prof_req, flg_status, id_episode
              FROM consult_req
             WHERE id_consult_req = i_consult_req;
        r_exist c_exist%ROWTYPE;
    
        l_rows table_varchar := table_varchar();
    
        l_id_prof_auth consult_req.id_prof_auth%TYPE;
        l_id_prof_appr consult_req.id_prof_appr%TYPE;
        l_id_prof_proc consult_req.id_prof_proc%TYPE;
    
        CURSOR cr_prof(i_consult_req consult_req.id_consult_req%TYPE) IS
            SELECT cr.id_prof_auth, cr.id_prof_appr, cr.id_prof_proc
              FROM consult_req cr
             WHERE cr.id_consult_req = i_consult_req;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR C_EXIST';
        OPEN c_exist;
        FETCH c_exist
            INTO r_exist;
        CLOSE c_exist;
        IF r_exist.flg_status = g_consult_req_stat_cancel
        THEN
            RAISE g_exception_msg;
        END IF;
    
        g_error := 'GET STATUS';
        IF i_flg = g_consult_req_stat_auth
        THEN
            l_prof_auth := i_prof.id;
        
        ELSIF i_flg = g_consult_req_stat_apr
        THEN
            IF r_exist.id_prof_auth IS NOT NULL
            THEN
                RAISE g_exception_msg_1;
            END IF;
            l_prof_apr := i_prof.id;
        
        ELSIF i_flg = g_consult_req_stat_proc
        THEN
            -- processamento administrativo 
            IF r_exist.id_prof_auth IS NULL
            THEN
                -- Só pode ser processada dps de estar autorizada 
                RAISE g_exception_msg_2;
            END IF;
            l_prof_proc := i_prof.id;
        END IF;
    
        g_error := 'GET cr_prof';
        OPEN cr_prof(i_consult_req);
        FETCH cr_prof
            INTO l_id_prof_auth, l_id_prof_appr, l_id_prof_proc;
        CLOSE cr_prof;
    
        g_error := 'UPDATE';
        ts_consult_req.upd(id_prof_auth_in => CASE l_prof_auth
                                                  WHEN NULL THEN
                                                   l_id_prof_auth
                                                  ELSE
                                                   l_prof_auth
                                              END,
                           id_prof_appr_in => CASE l_prof_apr
                                                  WHEN NULL THEN
                                                   l_id_prof_appr
                                                  ELSE
                                                   l_prof_apr
                                              END,
                           id_prof_proc_in => CASE l_prof_proc
                                                  WHEN NULL THEN
                                                   l_id_prof_proc
                                                  ELSE
                                                   l_prof_proc
                                              END,
                           flg_status_in   => i_flg,
                           where_in        => 'id_consult_req=' || i_consult_req,
                           rows_out        => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PROF_AUTH,ID_PROF_APPR,ID_PROF_PROC,FLG_STATUS'));
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => r_exist.id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'pedido');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'UPDATE_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_1 THEN
            -- Req já foi autorizada, portanto já ñ precisa de aprovação 
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M004');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'UPDATE_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_2 THEN
            -- Req já foi autorizada, portanto já ñ precisa de aprovação 
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M003');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'UPDATE_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'UPDATE_CONSULT_REQ');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION cancel_consult_req_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_consult_req  IN consult_req.id_consult_req%TYPE,
        i_prof_cancel  IN profissional,
        i_notes_cancel IN consult_req.notes_cancel%TYPE,
        i_commit_data  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar requisição de consulta interna / externa 
           Função efectua o cancelamento sem validar sem efectuar validações de lógica
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do registo a actualizar 
                       ID_PROF_CANCEL - Profissional q cancela a req. 
                     NOTES_CANCEL - notas de cancelamento 
                     I_COMMIT_DATA - Flag que indica se a função deve fazer o commit dos dados
                     I_EPISODE - Episódio onde é feita a requisição
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          NOTAS: 
        *********************************************************************************/
        l_error       t_error_out;
        l_commit_data BOOLEAN;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF (i_commit_data = 'N')
        THEN
            l_commit_data := FALSE;
        ELSE
            l_commit_data := TRUE;
        END IF;
    
        g_error := 'UPDATE';
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof_cancel,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        ts_consult_req.upd(id_prof_cancel_in => i_prof_cancel.id,
                           dt_cancel_tstz_in => g_sysdate_tstz,
                           notes_cancel_in   => i_notes_cancel,
                           flg_status_in     => g_consult_req_stat_cancel,
                           where_in          => 'id_consult_req = ' || i_consult_req,
                           rows_out          => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof_cancel,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PROF_CANCEL,DT_CANCEL_TSTZ,NOTES_CANCEL,FLG_STATUS'));
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof_cancel,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_commit_data
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'CANCEL_CONSULT_REQ');
            
                -- undo changes quando aplicável-> só faz ROLLBACK                  
                IF l_commit_data
                THEN
                    pk_utils.undo_changes;
                END IF;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION cancel_consult_req
    (
        i_lang          IN language.id_language%TYPE,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_prof_cancel   IN profissional,
        i_notes_cancel  IN consult_req.notes_cancel%TYPE,
        i_commit_data   IN VARCHAR2,
        i_flg_discharge IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar requisição de consulta interna / externa
                        Verifica se o pedido já está cancelado, se já foi respondido e 
                        se o profissional que cancela é o mesmo que requisitou
           
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do registo a actualizar 
                       ID_PROF_CANCEL - Profissional q cancela a req. 
                     NOTES_CANCEL - notas de cancelamento 
                     I_COMMIT_DATA - Flag que indica se a função deve fazer o commit dos dados
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          NOTAS: 
        *********************************************************************************/
        l_flg         consult_req.flg_status%TYPE;
        l_prof        consult_req.id_prof_req%TYPE;
        l_episode     consult_req.id_episode%TYPE;
        l_error       t_error_out;
        l_commit_data BOOLEAN;
    
        CURSOR c_exist IS
            SELECT flg_status, id_prof_req, id_episode
              FROM consult_req
             WHERE id_consult_req = i_consult_req;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF (i_commit_data = 'N')
        THEN
            l_commit_data := FALSE;
        ELSE
            l_commit_data := TRUE;
        END IF;
    
        g_error := 'OPEN CURSOR C_EXIST';
        OPEN c_exist;
        FETCH c_exist
            INTO l_flg, l_prof, l_episode;
        CLOSE c_exist;
    
        g_error := 'VALIDATE(1)';
        IF l_flg = g_consult_req_stat_cancel
        THEN
            -- Verificar se o registo já estava cancelado 
            RAISE g_exception_msg;
        
        ELSIF l_flg NOT IN (g_consult_req_stat_req, g_consult_req_stat_reply)
        THEN
            -- Se o pedido já foi respondido, ñ pode ser cancelado  
            RAISE g_exception_msg_1;
        
        ELSIF l_prof != i_prof_cancel.id
        THEN
            IF (pk_tools.get_prof_cat(i_prof_cancel) != g_prof_cat_administrative AND i_flg_discharge IS NULL)
            THEN
                -- Prof q tenta cancelar ñ é o requisitante (nem é administrativo)
                RAISE g_exception_msg_2;
            END IF;
        END IF;
    
        IF NOT cancel_consult_req_internal(i_lang,
                                           i_consult_req,
                                           i_prof_cancel,
                                           i_notes_cancel,
                                           i_commit_data,
                                           l_episode,
                                           o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'pedido');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CANCEL_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_1 THEN
            -- Req já foi autorizada, portanto já ñ precisa de aprovação 
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M001');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CANCEL_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_2 THEN
            -- Req já foi autorizada, portanto já ñ precisa de aprovação 
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M002');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CANCEL_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'CANCEL_CONSULT_REQ');
            
                -- undo changes quando aplicável-> só faz ROLLBACK                  
                IF l_commit_data
                THEN
                    pk_utils.undo_changes;
                END IF;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION cancel_consult_req_noprofcheck
    (
        i_lang         IN language.id_language%TYPE,
        i_consult_req  IN consult_req.id_consult_req%TYPE,
        i_prof_cancel  IN profissional,
        i_notes_cancel IN consult_req.notes_cancel%TYPE,
        i_commit_data  IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar requisição de consulta interna / externa
                        Verifica se o pedido já está cancelado, se já foi respondido e 
                        se o profissional que cancela é o mesmo que requisitou
           
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do registo a actualizar 
                       ID_PROF_CANCEL - Profissional q cancela a req. 
                     NOTES_CANCEL - notas de cancelamento 
                     I_COMMIT_DATA - Flag que indica se a função deve fazer o commit dos dados
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          NOTAS: 
        *********************************************************************************/
        l_flg         consult_req.flg_status%TYPE;
        l_prof        consult_req.id_prof_req%TYPE;
        l_episode     consult_req.id_episode%TYPE;
        l_error       t_error_out;
        l_commit_data BOOLEAN;
    
        CURSOR c_exist IS
            SELECT flg_status, id_prof_req, id_episode
              FROM consult_req
             WHERE id_consult_req = i_consult_req;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF (i_commit_data = 'N')
        THEN
            l_commit_data := FALSE;
        ELSE
            l_commit_data := TRUE;
        END IF;
    
        g_error := 'OPEN CURSOR C_EXIST';
        OPEN c_exist;
        FETCH c_exist
            INTO l_flg, l_prof, l_episode;
        CLOSE c_exist;
    
        g_error := 'VALIDATE(1)';
        IF l_flg = g_consult_req_stat_cancel
        THEN
            -- Verificar se o registo já estava cancelado 
            RAISE g_exception_msg;
        
            --ELSIF l_flg NOT IN (g_consult_req_stat_req, g_consult_req_stat_reply)
            --THEN
            -- Se o pedido já foi respondido, ñ pode ser cancelado  
            --    RAISE g_exception_msg_1;
        END IF;
    
        IF NOT cancel_consult_req_internal(i_lang,
                                           i_consult_req,
                                           i_prof_cancel,
                                           i_notes_cancel,
                                           i_commit_data,
                                           l_episode,
                                           o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'pedido');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CANCEL_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_1 THEN
            -- Req já foi autorizada, portanto já ñ precisa de aprovação 
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M001');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CANCEL_CONSULT_REQ',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'CANCEL_CONSULT_REQ');
            
                -- undo changes quando aplicável-> só faz ROLLBACK                  
                IF l_commit_data
                THEN
                    pk_utils.undo_changes;
                END IF;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION cancel_consult_req
    (
        i_lang         IN language.id_language%TYPE,
        i_consult_req  IN consult_req.id_consult_req%TYPE,
        i_prof_cancel  IN profissional,
        i_notes_cancel IN consult_req.notes_cancel%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Chama a função cancel_consult_req com o valor do parâmetro commit_data a YES
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do registo a actualizar 
                       ID_PROF_CANCEL - Profissional q cancela a req. 
                     NOTES_CANCEL - notas de cancelamento 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
    
        RETURN cancel_consult_req(i_lang         => i_lang,
                                  i_consult_req  => i_consult_req,
                                  i_prof_cancel  => i_prof_cancel,
                                  i_notes_cancel => i_notes_cancel,
                                  i_commit_data  => g_yes,
                                  o_error        => o_error);
    
    END;

    FUNCTION set_consult_req_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_consult_req      IN consult_req.id_consult_req%TYPE,
        i_prof             IN profissional,
        i_deny_acc         IN consult_req_prof.flg_status%TYPE,
        i_denial_justif    IN consult_req_prof.denial_justif%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_notes_admin      consult_req.notes_admin%TYPE,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar leitura e aceitação / rejeição do pedido INTERNO de consulta  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do pedido de exame / consulta  
                       ID_PROF - Profissional lê e aceita / rejeita 
                     I_DENY_ACC - aceitar / não aceitar o pedido 
                     I_DENIAL_JUSTIF - Justificação de rejeição do pedido 
                     I_DT_SCHEDULED - Data / hora da consulta 
                                             I_NOTES_ADMIN - Notas para o administrativo 
                  Saida:   O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/24 
          Alteração: AA 2005/11/22 
          NOTAS: 
        *********************************************************************************/
        l_flg_status   consult_req_prof.flg_status%TYPE;
        l_status       consult_req.flg_status%TYPE;
        l_id           consult_req_prof.id_consult_req_prof%TYPE;
        l_error        t_error_out;
        i_dt_scheduled TIMESTAMP WITH TIME ZONE;
    
        CURSOR c_req IS
            SELECT id_prof_req, flg_status, id_episode
              FROM consult_req
             WHERE id_consult_req = i_consult_req;
    
        r_req c_req%ROWTYPE;
    
        CURSOR c_exist IS
            SELECT id_consult_req_prof, flg_status
              FROM consult_req_prof
             WHERE id_consult_req = i_consult_req
               AND id_professional = i_prof.id
             ORDER BY dt_consult_req_prof_tstz DESC;
    
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        i_dt_scheduled := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_scheduled_str, NULL);
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR C_REQ';
        OPEN c_req;
        FETCH c_req
            INTO r_req;
        CLOSE c_req;
    
        IF r_req.id_prof_req = i_prof.id
           AND -- O prof q lê é o mesmo q requisitou 
           r_req.flg_status = g_consult_req_stat_reply
        THEN
            -- O pedido já foi respondido 
            NULL;
        ELSIF r_req.id_prof_req != i_prof.id
        THEN
            -- O prof q lê ñ é o mesmo q requisitou
        
            g_error := 'OPEN CURSOR C_EXIST';
            OPEN c_exist;
            FETCH c_exist
                INTO l_id, l_flg_status;
            g_found := c_exist%NOTFOUND;
            CLOSE c_exist;
        
            IF g_found
            THEN
                -- É a 1ª vez q este user lê o pedido 
                g_error := 'INSERT';
                INSERT INTO consult_req_prof
                    (id_consult_req_prof,
                     dt_consult_req_prof_tstz,
                     id_consult_req,
                     id_professional,
                     flg_status,
                     dt_scheduled_tstz)
                VALUES
                    (seq_consult_req_prof.nextval,
                     g_sysdate_tstz,
                     i_consult_req,
                     i_prof.id,
                     g_cons_req_prof_read,
                     i_dt_scheduled);
            
                l_status := g_consult_req_stat_read;
            
            END IF;
        
            IF r_req.flg_status = g_consult_req_stat_reply
               AND -- O pedido já foi respondido 
               i_deny_acc = g_cons_req_prof_accept
            THEN
                -- O user pretende aceitar o pedido 
                RAISE g_exception_msg;
            END IF;
        
            IF r_req.flg_status IN (g_consult_req_stat_reply)
               AND --O pedido já foi respondido 
               i_deny_acc = g_consult_req_stat_reply
            THEN
                -- O user lê o pedido
                NULL;
            END IF;
        
            g_error := 'VALIDATE:';
            IF l_flg_status != g_cons_req_prof_read
               AND i_deny_acc = g_consult_req_stat_reply
            THEN
                RAISE g_exception_msg_1;
            END IF;
        
            IF i_deny_acc IN (g_cons_req_prof_accept, g_cons_req_prof_deny)
            THEN
            
                g_error := 'UPDATE';
                ts_consult_req.upd(id_consult_req_in => i_consult_req,
                                   flg_type_date_in  => i_flg_type_date,
                                   rows_out          => l_rows);
            
                g_error := 't_data_gov_mnt.process_update ts_consult_req';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'CONSULT_REQ',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_TYPE_DATE'));
            
                g_error := 'INSERT2';
                INSERT INTO consult_req_prof
                    (id_consult_req_prof,
                     dt_consult_req_prof_tstz,
                     id_consult_req,
                     id_professional,
                     flg_status,
                     denial_justif,
                     dt_scheduled_tstz)
                VALUES
                    (seq_consult_req_prof.nextval,
                     g_sysdate_tstz,
                     i_consult_req,
                     i_prof.id,
                     i_deny_acc,
                     i_denial_justif,
                     i_dt_scheduled);
            
                IF i_deny_acc = g_cons_req_prof_accept
                THEN
                    l_status := g_consult_req_stat_reply;
                ELSE
                    l_status := g_consult_req_stat_rejected;
                END IF;
            
            END IF;
        END IF;
    
        IF l_status IS NOT NULL
        THEN
        
            l_rows := NULL;
        
            g_error := 'UPDATE2';
            ts_consult_req.upd(flg_status_in  => l_status,
                               notes_admin_in => i_notes_admin,
                               --dt_scheduled_tstz_in => i_dt_scheduled,
                               id_consult_req_in => i_consult_req,
                               rows_out          => l_rows);
        
            g_error := 't_data_gov_mnt.process_update ts_consult_req';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'CONSULT_REQ',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS,NOTES_ADMIN,DT_SCHEDULED_TSTZ,ID_CONSULT_REQ'));
        
        END IF;
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => r_req.id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M005');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'SET_CONSULT_REQ_PROF',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception_msg_1 THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret     BOOLEAN;
                l_error_v VARCHAR2(100) := pk_message.get_message(i_lang, 'CONSULT_REQ_M001');
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'SET_CONSULT_REQ_PROF',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'SET_CONSULT_REQ_PROF');
            
                -- undo changes quando aplicável-> só faz ROLLBACK                  
                pk_utils.undo_changes;
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION get_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_pat              IN consult_req.id_patient%TYPE,
        i_instit_requests  IN consult_req.id_instit_requests%TYPE,
        i_instit_requested IN consult_req.id_inst_requested%TYPE,
        i_prof             IN profissional,
        o_req              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter requisição de consulta interna / externa de um doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                     I_PAT - doente para quem é pedido o exame / consulta 
                     I_INSTIT_REQUESTS - instituição requisitante (opcional) 
                     I_INSTIT_REQUESTED - instituição requisitada (opcional) 
                  Saida:   O_REQ - requisições de exame / consulta 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          NOTAS: 
        *********************************************************************************/
    
        l_aux_sql VARCHAR2(4000);
    
    BEGIN
    
        l_aux_sql := 'SELECT CR.ID_CONSULT_REQ, CR.FLG_STATUS,' || 'PK_DATE_UTILS.DATE_CHAR_tsz(' || i_lang ||
                     ', CR.DT_CONSULT_REQ_tstz, ' || i_prof.institution || ', ' || i_prof.software ||
                     ') DT_CONSULT_REQ,' || 'CR.CONSULT_TYPE, P_REQ.NICK_NAME, P_AUTH.NICK_NAME, P_APR.NICK_NAME, ' ||
                     'P_PROC.NICK_NAME, P_REQD.NICK_NAME, CR.NOTES, CR.NOTES_CANCEL, P_CAN.NICK_NAME,' ||
                     'PK_DATE_UTILS.DATE_CHAR_tsz(' || i_lang || ', CR.DT_CANCEL_tstz, ' || i_prof.institution || ', ' ||
                     i_prof.software || ') DT_CANCEL,' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                     ', CS.CODE_CLINICAL_SERVICE) CLIN_SERV,' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                     ', I.CODE_INSTITUTION) INSTIT_REQUESTS,' || 'PK_TRANSLATION.GET_TRANSLATION(' || i_lang ||
                     ', I1.CODE_INSTITUTION) INSTIT_REQUESTED,' || 'PK_DATE_UTILS.DATE_CHAR_tsz(' || i_lang ||
                     ', CR.DT_SCHEDULED_tstz, ' || i_prof.institution || ', ' || i_prof.software || ') DT_SCHEDULED, ' ||
                     'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', DEP.CODE_DEPARTMENT) DEP,' ||
                     'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS1.CODE_CLINICAL_SERVICE) CLN_SRV, ' ||
                     'PK_SYSDOMAIN.GET_DOMAIN(''CONSULT_REQ.FLG_STATUS'', CR.FLG_STATUS, ' || i_lang ||
                     ') DESC_STATUS ' || 'FROM CONSULT_REQ CR, CLINICAL_SERVICE CS, INSTITUTION I, INSTITUTION I1,' ||
                     'PROFESSIONAL P_REQ, PROFESSIONAL P_AUTH, PROFESSIONAL P_APR, ' ||
                     'PROFESSIONAL P_PROC, PROFESSIONAL P_REQD, DEP_CLIN_SERV DCS, ' ||
                     'PROFESSIONAL P_CAN, DEPARTMENT DEP, CLINICAL_SERVICE CS1 ' || 'WHERE CR.ID_PATIENT = ' || i_pat ||
                     ' AND CR.ID_INSTIT_REQUESTS = NVL(''' || i_instit_requests || ''', CR.ID_INSTIT_REQUESTS)' ||
                     ' AND CR.ID_INST_REQUESTED = NVL(''' || i_instit_requested || ''', CR.ID_INST_REQUESTED)' ||
                     ' AND CS.ID_CLINICAL_SERVICE(+) = CR.ID_CLINICAL_SERVICE' ||
                     ' AND I.ID_INSTITUTION = CR.ID_INSTIT_REQUESTS' ||
                     ' AND I1.ID_INSTITUTION(+) = CR.ID_INST_REQUESTED' ||
                     ' AND P_REQ.ID_PROFESSIONAL = CR.ID_PROF_REQ' ||
                     ' AND P_AUTH.ID_PROFESSIONAL(+) = CR.ID_PROF_AUTH' ||
                     ' AND P_APR.ID_PROFESSIONAL(+) = CR.ID_PROF_APPR' ||
                     ' AND P_PROC.ID_PROFESSIONAL(+) = CR.ID_PROF_PROC' ||
                     ' AND P_REQD.ID_PROFESSIONAL(+) = CR.ID_PROF_REQUESTED' ||
                     ' AND DCS.ID_DEP_CLIN_SERV(+) = CR.ID_DEP_CLIN_SERV' ||
                     ' AND DCS.ID_DEPARTMENT = DEP.ID_DEPARTMENT' ||
                     ' AND DCS.ID_CLINICAL_SERVICE = CS1.ID_CLINICAL_SERVICE' ||
                     ' AND P_CAN.ID_PROFESSIONAL(+) = CR.ID_PROF_CANCEL' ||
                     ' ORDER BY PK_SYSDOMAIN.GET_RANK(I_LANG, ''CONSULT_REQ.FLG_STATUS'', CR.FLG_STATUS), CR.DT_CONSULT_REQ_tstz DESC';
    
        g_error := 'GET CURSOR';
        OPEN o_req FOR l_aux_sql;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'GET_CONSULT_REQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_req);
            RETURN FALSE;
    END;

    FUNCTION get_cons_req_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_req         OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter leituras e respostas a requisição de consulta INTERNA de um doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID do pedido de exame / consulta  
                  Saida:   O_REQ - requisições de exame / consulta 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/03/28 
          Alteração: AA 2005/11/22 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_req FOR
            SELECT crp.id_consult_req_prof,
                   crp.denial_justif,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, crp.id_professional) nick_name,
                   --                   p.nick_name,
                   pk_date_utils.date_char_tsz(i_lang,
                                               crp.dt_consult_req_prof_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt,
                   pk_sysdomain.get_domain('CONSULT_REQ_PROF.FLG_STATUS', crp.flg_status, i_lang) flg_status
              FROM consult_req_prof crp --, professional p
             WHERE id_consult_req = i_consult_req;
        --               AND crp.id_professional = p.id_professional;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'GET_CONS_REQ_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_req);
            RETURN FALSE;
    END;

    FUNCTION get_subs_req_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN consult_req.id_episode%TYPE,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_flg_status     OUT VARCHAR2,
        o_status_string  OUT VARCHAR2,
        o_flg_finished   OUT VARCHAR2,
        o_flg_canceled   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obtém todos os parâmetros que devolvem o estado de uma requisição de consulta.  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                                 I_PROF - Profissional
                                 I_EPIS - ID do episódio
                                 I_ID_CONSULT_REQ - ID da requisição                         
                        Saida:   O_FLG_STATUS - Estado da requisição
                                 O_STATUS_STRING - String do estado para ser interpretada pelo Flash
                                 O_FLG_FINISHED - Indica se a requisição da consulta já está num estado final
                                 O_FLG_CANCELED - Indica se a requisição da foi cancelada
                                 O_ERROR - erro 
          
          CRIAÇÃO: Tiago Silva 2008/05/28
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET REQUEST STATUS';
    
        SELECT cr.flg_status,
               pk_utils.get_status_string(i_lang, i_prof, cr.status_str, cr.status_msg, cr.status_icon, cr.status_flg) status_string,
               decode(cr.flg_status, g_consult_req_stat_proc, g_yes, g_consult_req_stat_sched, g_yes, g_no) AS flg_finished,
               decode(cr.flg_status, g_consult_req_stat_cancel, g_yes, g_consult_req_stat_rejected, g_yes, g_no) AS flg_canceled
          INTO o_flg_status, o_status_string, o_flg_finished, o_flg_canceled
          FROM consult_req cr
         WHERE cr.id_consult_req = i_id_consult_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_SUBS_REQ_STATUS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_subs_req
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN consult_req.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_req      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter pedidos de consulta subsequente num episódio  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_EPIS - ID do episódio 
                  Saida:   O_REQ - requisições 
                     O_ERROR - erro 
          
          CRIAÇÃO: CRS 2005/08/05  
          Alteração: AA 2005/11/22 
          NOTAS: 
        *********************************************************************************/
        CURSOR c_prof IS
            SELECT flg_type
              FROM category cat, prof_cat pc
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND cat.id_category = pc.id_category;
    
        g_cons_subs      VARCHAR2(1) := 'S';
        g_cons_esp       VARCHAR2(1) := 'E';
        l_pat            patient.id_patient%TYPE;
        l_flg_cat_type   category.flg_type%TYPE;
        l_message_admin  sys_message.desc_message%TYPE;
        l_message_cancel sys_message.desc_message%TYPE;
    
    BEGIN
        l_message_admin  := pk_message.get_message(i_lang, 'CONSULT_REQ_T010');
        l_message_cancel := pk_message.get_message(i_lang, 'OPINION_T010');
    
        g_error := 'GET ID_PATIENT';
        SELECT id_patient
          INTO l_pat
          FROM episode
         WHERE id_episode = i_epis;
    
        g_error := 'OPEN C_PROF;';
        OPEN c_prof;
        FETCH c_prof
            INTO l_flg_cat_type;
        CLOSE c_prof;
    
        g_error := 'GET CURSOR';
        OPEN o_req FOR
            SELECT cr.id_consult_req,
                   sch.id_schedule,
                   --                   p.nick_name spec_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) spec_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_req,
                   --                   p1.nick_name prof_req,
                   cr.flg_status,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) dt_target,
                   decode(cr.notes_admin,
                          NULL,
                          decode(cr.notes_cancel, NULL, NULL, pk_message.get_message(i_lang, i_prof, 'COMMON_M008')),
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M008')) dt_target_notes,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_scheduled_tstz, i_prof.institution, i_prof.software) hr_target,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              cr.status_str,
                                              cr.status_msg,
                                              cr.status_icon,
                                              cr.status_flg) desc_status,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   decode(l_flg_cat_type,
                          'N',
                          g_nurse_category,
                          decode(i_prof.id,
                                 cr.id_prof_req,
                                 'N',
                                 decode(cr.flg_status, g_consult_req_stat_req, 'Y', g_consult_req_stat_read, 'Y', 'N'))) avail_butt_ok,
                   decode(cr.flg_status,
                          g_consult_req_stat_cancel,
                          'N',
                          g_consult_req_stat_sched,
                          'N',
                          g_consult_req_stat_proc,
                          'N',
                          g_consult_req_stat_rejected,
                          'N',
                          decode(i_prof.id, cr.id_prof_req, 'Y', 'N')) avail_butt_canc,
                   decode(cr.flg_status, g_consult_req_stat_cancel, 'Y', 'N') flg_cancel,
                   decode(cr.notes,
                          '',
                          decode(cr.notes_cancel, '', '', pk_message.get_message(i_lang, 'COMMON_M008')),
                          pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_scheduled_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord2,
                   pk_sysdomain.get_rank(i_lang, 'CONSULT_REQ.FLG_STATUS', cr.flg_status) rank,
                   pk_date_utils.date_send_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_consult_req,
                   (SELECT pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) dept_req
                      FROM schedule s, epis_info ei, dep_clin_serv dcs, clinical_service cs, dept dept, department d
                     WHERE ei.id_episode = i_epis
                       AND ei.id_schedule(+) = s.id_schedule
                       AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                       AND dcs.id_dep_clin_serv =
                           decode(s.id_dcs_requests, NULL, ei.id_dep_clin_serv, s.id_dcs_requests)
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.id_department = d.id_department
                       AND d.id_dept = dept.id_dept) dept_req,
                   decode(sch.flg_status,
                          g_sched_canc,
                          NULL,
                          pk_date_utils.date_char_tsz(i_lang, sch.dt_begin_tstz, i_prof.institution, i_prof.software)) dt_sched_desc,
                   pk_date_utils.to_char_insttimezone(i_prof, sch.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_begin_tstz,
                   decode(cr.notes_cancel,
                          NULL,
                          decode(cr.notes_admin, NULL, NULL, l_message_admin || ': ' || cr.notes_admin),
                          l_message_cancel || ': ' || cr.notes_cancel) notes_tooltip
              FROM consult_req cr,
                   --                   professional     p,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   --                   professional     p1,
                   schedule sch
             WHERE ((cr.id_episode = i_epis) OR (cr.id_patient = l_pat AND cr.id_episode IS NULL))
                  --             AND cr.id_prof_requested = p.id_professional(+)
                  --               AND cr.id_prof_req = p1.id_professional
                  -- AND ((cr.id_prof_req = cr.id_prof_requested AND i_flg_type = g_cons_subs) OR
                  --    (cr.id_prof_req != nvl(cr.id_prof_requested, 0) AND i_flg_type = g_cons_esp))
                  
               AND ((cr.flg_type = g_cons_subs AND i_flg_type = g_cons_subs) OR
                   (cr.flg_type = g_cons_esp AND i_flg_type = g_cons_esp))
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND sch.id_schedule(+) = cr.id_schedule
               AND (sch.flg_status != pk_schedule.g_sched_status_cache OR sch.id_schedule IS NULL) -- agendamentos temporários (SCH 3.0)
            UNION ALL
            SELECT NULL,
                   s.id_schedule,
                   --                   pk_prof_utils.get_nickname(i_lang, schr.id_professional) spec_prof,
                   --                   pk_prof_utils.get_nickname(i_lang, s.id_prof_schedules) prof_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, schr.id_professional) spec_prof,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, s.id_prof_schedules) prof_req,
                   g_consult_req_stat_sched flg_status,
                   NULL dt_target,
                   NULL dt_target_notes,
                   NULL hr_target,
                   NULL date_target,
                   NULL hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   '0' ||
                   --pk_utils.get_status_string(i_lang, i_prof, '|I|||#|||||&', '', 'SCHEDULE.FLG_STATUS', s.flg_status) desc_status,
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         pk_alert_constant.g_display_type_icon,
                                                         s.flg_status,
                                                         NULL,
                                                         NULL,
                                                         'SCHEDULE.FLG_STATUS') desc_status,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   'N' avail_butt_ok,
                   'N' avail_butt_canc,
                   'N' flg_cancel,
                   decode(s.reason_notes, '', '', pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                   NULL dt_ord1,
                   NULL dt_ord2,
                   20 rank,
                   NULL dt_consult_req,
                   NULL dept_req,
                   pk_date_utils.date_char_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) dt_sched_desc,
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, 'YYYYMMDDHH24MISS') dt_begin_tstz,
                   NULL notes_tooltip
              FROM schedule s
              JOIN sch_group sg
                ON (s.id_schedule = sg.id_schedule)
              JOIN schedule_outp so
                ON (s.id_schedule = so.id_schedule)
              JOIN sch_prof_outp spo
                ON (spo.id_schedule_outp = so.id_schedule_outp)
              JOIN sch_resource schr
                ON (s.id_schedule = schr.id_schedule)
              LEFT JOIN dep_clin_serv dcs
                ON (s.id_dcs_requested = dcs.id_dep_clin_serv)
              LEFT JOIN clinical_service cs
                ON (dcs.id_clinical_service = cs.id_clinical_service)
             WHERE sg.id_patient = l_pat
               AND s.flg_status != pk_schedule.g_sched_status_cancelled
               AND so.id_epis_type IN (SELECT etsi.id_epis_type
                                         FROM epis_type_soft_inst etsi
                                        WHERE etsi.id_software = i_prof.software
                                          AND etsi.id_institution IN (i_prof.institution, 0))
               AND s.id_schedule NOT IN (SELECT ei.id_schedule
                                           FROM epis_info ei
                                           JOIN episode e
                                             ON (ei.id_episode = e.id_episode)
                                          WHERE e.id_patient = l_pat
                                               --AND e.flg_ehr IN (g_flg_ehr_scheduled)
                                            AND ei.id_schedule IS NOT NULL)
             ORDER BY rank, dt_consult_req DESC, dt_begin_tstz DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_SUBS_REQ');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_req);
                RETURN FALSE;
            
            END;
    END;

    /**
    * Equal to GET_SUBS_REQ, with additional out variable o_create.
    *
    * @param      i_lang              language identifier.
    * @param      i_epis              episode identifier.
    * @param      i_prof              logged professional structure.
    * @param      i_flg_type          consult type.
    * @param      o_req               subsequent consults requested.
    * @param      o_create            avail_butt_create.
    * @param      o_error             erro
    *
    * @return     boolean             false if errors occur, true otherwise.
    * @author     Pedro Carneiro
    * @version    1.0
    * @since      2009/04/23
    * @notes      Based on get_subs_req
    */
    FUNCTION get_subs_req_amb
    (
        i_lang     IN language.id_language%TYPE,
        i_epis     IN consult_req.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_req      OUT pk_types.cursor_type,
        o_create   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_this_epis_type  episode.id_epis_type%TYPE;
        l_nurse_epis_type sys_config.value%TYPE;
        l_cat             category.flg_type%TYPE;
        l_create          VARCHAR2(1);
    BEGIN
        g_error           := 'SET o_create';
        l_this_epis_type  := pk_episode.get_epis_type(i_lang, i_epis);
        l_nurse_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
        l_cat             := pk_prof_utils.get_category(i_lang, i_prof);
        l_create          := 'Y'; -- default value
    
        IF l_cat = g_flg_doctor
        THEN
            IF l_this_epis_type = l_nurse_epis_type
            THEN
                l_create := 'N';
            ELSE
                l_create := 'Y';
            END IF;
        ELSIF l_cat = g_nurse_category
        THEN
            IF l_this_epis_type = l_nurse_epis_type
            THEN
                l_create := 'Y';
            ELSE
                l_create := 'N';
            END IF;
        END IF;
    
        o_create := l_create;
    
        g_error := 'CALL get_subs_req';
        RETURN get_subs_req(i_lang, i_epis, i_prof, i_flg_type, o_req, o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'GET_SUBS_REQ_AMB',
                                              o_error);
            pk_types.open_my_cursor(o_req);
            RETURN FALSE;
    END get_subs_req_amb;

    FUNCTION get_subs_req_det
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_prof        IN profissional,
        o_req         OUT pk_types.cursor_type,
        o_req_det     OUT pk_types.cursor_type,
        o_sch_det     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter detalhe de um pedido de consulta subsequente  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_CONSULT_REQ - ID da consulta  
                  Saida:   O_REQ - requisições 
                     O_ERROR - erro 
          
          CRIAÇÃO: AA 2005/12/12  
          NOTAS: 
          CHANGED: Elisabete Bugalho
                   24-03-2009
                   ALERT-1040 - Retornar o motivo da próxima consulta
        *********************************************************************************/
        l_error t_error_out;
        l_dummy pk_types.cursor_type;
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_req FOR
            SELECT pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_req,
                   cr.notes_admin,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hr_req,
                   pk_date_utils.dt_chr_tsz(i_lang, nvl(cr.dt_scheduled_tstz, crp.dt_scheduled_tstz), i_prof) dt_scheduled,
                   decode(cr.flg_type_date,
                          g_flg_type_date_h,
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           nvl(cr.dt_scheduled_tstz, crp.dt_scheduled_tstz),
                                                           i_prof.institution,
                                                           i_prof.software),
                          ' ') hr_scheduled,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', cr.flg_status, i_lang) desc_status,
                   --                   p3.nick_name prof_ped,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_ped,
                   --nvl(pk_translation.get_translation(i_lang, spec.code_speciality),' ') desc_spec,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_spec,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    cr.id_prof_req,
                                                    cr.dt_consult_req_tstz,
                                                    cr.id_episode) desc_spec,
                   decode(cr.flg_status, g_consult_req_stat_cancel, pk_message.get_message(i_lang, 'COMMON_M017'), '') title_cancel,
                   cr.notes notes_ped,
                   cr.notes_cancel,
                   --                   p2.nick_name prof_cancel,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_cancel) prof_cancel,
                   --                   pk_translation.get_translation(i_lang, spec1.code_speciality) desc_spec_cancel,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, cr.id_prof_cancel, cr.dt_cancel_tstz, cr.id_episode) desc_spec_cancel,
                   pk_date_utils.date_char_tsz(i_lang, cr.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   pk_message.get_message(i_lang, 'COMMON_M018') n_aplic,
                   decode(crp.flg_status,
                          g_cons_req_prof_read,
                          NULL,
                          pk_sysdomain.get_domain('CONSULT_REQ_PROF.FLG_STATUS', crp.flg_status, i_lang)) desc_decision,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   decode(c.id_complaint,
                          NULL,
                          reason_for_visit,
                          pk_translation.get_translation(i_lang, c.code_complaint)) desc_complaint,
                   pk_message.get_message(i_lang, 'SCH_CANCEL_T004') tit_cancel_reason,
                   nvl(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, cr.id_cancel_reason), '--') cancel_reason
              FROM consult_req cr,
                   --                   professional p2,
                   --                   professional p3,
                   --                   speciality spec,
                   --                   speciality spec1,
                   dep_clin_serv dcs,
                   clinical_service cs,
                   complaint c,
                   (SELECT *
                      FROM consult_req_prof
                     WHERE dt_consult_req_prof_tstz = (SELECT MAX(dt_consult_req_prof_tstz)
                                                         FROM consult_req_prof
                                                        WHERE id_consult_req = i_consult_req)) crp
             WHERE cr.id_consult_req = i_consult_req
               AND c.id_complaint(+) = cr.id_complaint
                  --               AND p3.id_professional = cr.id_prof_req
                  --               AND p2.id_professional(+) = cr.id_prof_cancel
                  --               AND spec.id_speciality(+) = p3.id_speciality
                  --               AND spec1.id_speciality(+) = p2.id_speciality
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND crp.id_consult_req(+) = cr.id_consult_req;
    
        OPEN o_req_det FOR
            SELECT REPLACE(REPLACE(decode(crp.flg_status,
                                          g_cons_req_prof_read,
                                          pk_message.get_message(i_lang, 'CONSULT_REQ_M006'),
                                          g_cons_req_prof_accept,
                                          pk_message.get_message(i_lang, 'CONSULT_REQ_M007'),
                                          g_cons_req_prof_deny,
                                          pk_message.get_message(i_lang, 'CONSULT_REQ_M008')),
                                   '@1',
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, crp.id_professional)),
                           --                                   p.nick_name),
                           '@2',
                           pk_date_utils.date_char_tsz(i_lang,
                                                       crp.dt_consult_req_prof_tstz,
                                                       i_prof.institution,
                                                       i_prof.software)) || ' ' ||
                   decode(cr.dt_scheduled_tstz,
                          NULL,
                          NULL,
                          decode(crp.flg_status,
                                 g_cons_req_prof_read,
                                 NULL,
                                 REPLACE(pk_message.get_message(i_lang, 'CONSULT_REQ_M009'),
                                         '@1',
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  cr.dt_scheduled_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software)))) text,
                   crp.denial_justif notes_resp
              FROM consult_req cr, consult_req_prof crp --, professional p
             WHERE cr.id_consult_req = i_consult_req
               AND crp.id_consult_req = cr.id_consult_req
               AND ((crp.flg_status IN (g_cons_req_prof_accept, g_cons_req_prof_deny)) OR
                   (crp.flg_status = g_cons_req_prof_read AND
                   (crp.id_professional, crp.dt_consult_req_prof_tstz) IN
                   (SELECT id_professional, MIN(dt_consult_req_prof_tstz)
                        FROM consult_req_prof
                       WHERE id_consult_req = i_consult_req
                       GROUP BY id_professional)))
            --               AND p.id_professional = crp.id_professional
             ORDER BY crp.dt_consult_req_prof_tstz;
    
        IF i_id_schedule IS NOT NULL
        THEN
            IF NOT pk_schedule.get_schedule_details(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_schedule      => i_id_schedule,
                                                    o_schedule_details => o_sch_det,
                                                    -- Sofia MEndes (18-06-2009): new parameter on get_schedule_detais
                                                    o_patients => l_dummy,
                                                    o_error    => l_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            OPEN o_sch_det FOR
                SELECT 1
                  FROM dual
                 WHERE 1 = 2;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_SUBS_REQ_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_req);
                pk_types.open_my_cursor(o_req_det);
                pk_types.open_my_cursor(o_sch_det);
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION get_aux_reply
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_cursor      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Info para ecrã auxiliar de resposta ao pedido   
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_CONSULT_REQ - ID da consulta  
                                 I_PROF - profissional 
                  Saida: O_REQ - requisições 
                 O_ERROR - erro 
          
          CRIAÇÃO: CRS 2006/09/07  
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_cursor FOR
            SELECT cr.notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) nick_name,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hr_req,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_req
              FROM consult_req cr --, professional p
             WHERE cr.id_consult_req = i_consult_req;
        --               AND p.id_professional = cr.id_prof_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_AUX_REPLY');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_cursor);
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION get_prof_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        o_prof          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de PROFISSIONAIS POR DEP_CLIN_SERV 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  Saida:   I_DEP_CLIN_SERV 
                         O_PROF - profisionais 
                     O_ERROR - erro 
          
          CRIAÇÃO: AA 2005/12/07   
                 CRS 2006/02/19 - PROF_FUNC 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_prof FOR
            SELECT pdcs.id_professional,
                   1 rank,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) nick_name
              FROM prof_dep_clin_serv pdcs, professional p, prof_cat pc, category c, prof_func pf, prof_institution pi
             WHERE pdcs.id_dep_clin_serv = i_dep_clin_serv
               AND pdcs.flg_status = g_selected
               AND p.id_professional = pdcs.id_professional
               AND p.flg_state = g_prof_active
               AND p.id_professional != i_prof.id
               AND pc.id_professional = p.id_professional
               AND c.id_category = pc.id_category
               AND c.flg_type = g_flg_doctor
               AND pf.id_professional = p.id_professional
               AND pf.id_functionality = pk_sysconfig.get_config('FUNCTIONALITY_CONSULT_REQ', i_prof)
               AND pf.id_institution = i_prof.institution
               AND pi.id_professional = p.id_professional
               AND pi.id_institution = pc.id_institution
               AND pi.flg_state = g_prof_active
               AND pi.dt_end_tstz IS NULL
            UNION
            SELECT -1 id_professional, -1 rank, pk_message.get_message(i_lang, 'OPINION_M001') nick_name
              FROM dual
             WHERE EXISTS (SELECT pdcs.id_professional, p.nick_name
                      FROM prof_dep_clin_serv pdcs,
                           professional       p,
                           prof_cat           pc,
                           category           c,
                           prof_func          pf,
                           prof_institution   pi
                     WHERE pdcs.id_dep_clin_serv = i_dep_clin_serv
                       AND pdcs.flg_status = g_selected
                       AND p.id_professional = pdcs.id_professional
                       AND p.flg_state = g_prof_active
                       AND p.id_professional != i_prof.id
                       AND pc.id_professional = p.id_professional
                       AND c.id_category = pc.id_category
                       AND c.flg_type = g_flg_doctor
                       AND pf.id_professional = p.id_professional
                       AND pf.id_functionality = pk_sysconfig.get_config('FUNCTIONALITY_CONSULT_REQ', i_prof)
                       AND pf.id_institution = i_prof.institution
                       AND pi.id_professional = p.id_professional
                       AND pi.id_institution = pc.id_institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL)
             ORDER BY rank, nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_PROF_DEP_CLIN_SERV');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_prof);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_dep_clin_serv
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_prof  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de DEP_CLIN_SERV 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  Saida:   I_PROF  
                         O_PROF - profisionais 
                     O_ERROR - erro 
          
          CRIAÇÃO: AA 2005/12/07  
          ALTERAÇÃO: SS 2006/11/27 Utilizar DEPARTMENT.FLG_TYPE em vez de DEP_CLIN_SERV_TYPE  
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_prof FOR
            SELECT dcs.id_dep_clin_serv,
                   cs.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                   pk_translation.get_translation(i_lang, d.code_department) desc_department
              FROM department d, dep_clin_serv dcs, clinical_service cs --, DEP_CLIN_SERV_TYPE DCST
             WHERE d.id_institution = i_prof.institution
               AND instr(d.flg_type, 'C') > 0
               AND dcs.id_department = d.id_department
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND dcs.flg_available = g_flg_available
               AND dcs.flg_appointment = g_flg_available
               AND EXISTS
             (SELECT 1
                      FROM professional p, prof_dep_clin_serv pdcs, prof_func pf
                     WHERE p.flg_state = g_prof_active
                       AND p.id_professional != i_prof.id
                       AND pdcs.id_professional = p.id_professional
                       AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                       AND pdcs.flg_status = g_selected
                       AND pf.id_professional = p.id_professional
                       AND pf.id_functionality = pk_sysconfig.get_config('FUNCTIONALITY_CONSULT_REQ', i_prof)
                       AND pf.id_institution = i_prof.institution)
             ORDER BY cs.rank, desc_clin_serv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_DEP_CLIN_SERV');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_prof);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_accept_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista: aceite / não aceite 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                  Saida:   O_LIST - lista de valores aceite / não aceite 
                     O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/12/09 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT val, desc_val
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = g_accept
               AND domain_owner = pk_sysdomain.k_default_schema
               AND flg_available = g_flg_available
             ORDER BY rank, desc_val;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_ACCEPT_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_consult_req_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de pedidos de consulta  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                     I_PROF -  profissional
                    Saida:   O_LIST - info 
                 O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/12/27 
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados 
                     LG 2007/Mar/27 Incluir consultas subsequentes/especialidade marcadas em episódios agendados através da agenda Alert
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR -- 1ªs consultas 
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   --s.id_schedule,
                   ei.id_schedule,
                   cr.id_episode,
                   e.id_epis_type,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   --p1.nick_name prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   decode(cr.id_prof_req,
                          cr.id_prof_requested,
                          pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof),
                          pk_date_utils.dt_chr_tsz(i_lang, crp.dt_scheduled_tstz, i_prof)) date_target,
                   decode(cr.id_prof_req,
                          cr.id_prof_requested,
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           cr.dt_scheduled_tstz,
                                                           i_prof.institution,
                                                           i_prof.software),
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           crp.dt_scheduled_tstz,
                                                           i_prof.institution,
                                                           i_prof.software)) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_translation.get_translation(i_lang, dept.code_dept) dept_req
              FROM consult_req      cr,
                   consult_req_prof crp,
                   patient          pat,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   epis_info        ei,
                   sys_domain       sd,
                   episode          e,
                   dept             dept,
                   department       d
             WHERE cr.id_episode = ei.id_episode
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_prof_req != nvl(cr.id_prof_requested, 0)
               AND cr.id_inst_requested = i_prof.institution
               AND cr.id_schedule IS NULL
               AND crp.id_consult_req = cr.id_consult_req
               AND crp.flg_status = g_cons_req_prof_accept
                  --               AND p2.id_professional(+) = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val = g_flg_first_img
               AND e.id_episode = cr.id_episode
               AND e.flg_status != g_epis_canc
                  --lg 2007-Mar-27 AND s.notes IS NULL
               AND d.id_department = dcs.id_department
               AND dept.id_dept = d.id_dept
            UNION ALL -- consultas subsequentes
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   ei.id_schedule,
                   cr.id_episode,
                   e.id_epis_type,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_scheduled_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   pk_translation.get_translation(i_lang, dept.code_dept) dept_req
              FROM consult_req cr,
                   patient     pat,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   epis_info        ei,
                   sys_domain       sd,
                   episode          e,
                   dept             dept,
                   department       d
             WHERE cr.id_episode = ei.id_episode
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_prof_req = cr.id_prof_requested
               AND cr.id_inst_requested = i_prof.institution
                  --               AND p2.id_professional = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val = g_flg_subs_img
               AND e.id_episode = cr.id_episode
               AND e.flg_status != g_epis_canc
                  --lg 2007-Mar-27 AND s.notes IS NULL
               AND cr.id_schedule IS NULL
               AND d.id_department = dcs.id_department
               AND dept.id_dept = d.id_dept
            UNION ALL -- provenientes da agenda
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   cr.id_schedule,
                   cr.id_episode,
                   NULL id_epis_type,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   --p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(1, 6, '0') || pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_SCHED', so.flg_sched) img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   (SELECT pk_translation.get_translation(i_lang, dept.code_dept) dept_req
                      FROM schedule s, epis_info ei, dep_clin_serv dcs, clinical_service cs, dept dept, department d
                     WHERE ei.id_episode = cr.id_episode
                       AND ei.id_schedule(+) = s.id_schedule
                       AND dcs.id_dep_clin_serv =
                           decode(s.id_dcs_requests, NULL, ei.id_dep_clin_serv, s.id_dcs_requests)
                       AND cs.id_clinical_service = dcs.id_clinical_service
                       AND dcs.id_department = d.id_department
                       AND d.id_dept = dept.id_dept) dept_req
              FROM schedule    s,
                   consult_req cr,
                   patient     pat,
                   -- professional         p1,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   schedule_outp    so
             WHERE cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_inst_requested = i_prof.institution
               AND s.id_schedule = cr.id_schedule
               AND s.flg_status = g_sched_pend
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                  --AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional(+) = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND so.id_schedule = s.id_schedule
             ORDER BY date_target, hour_target;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_CONSULT_REQ_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_pat_consult_req
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de pedidos de consulta de um paciente  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_PATIENT - ID do paciente
                  Saida: O_LIST - info 
                 O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/12/27 
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT cr.id_consult_req,
                   --                   p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', cr.flg_status, i_lang) status,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1
              FROM consult_req      cr,
                   consult_req_prof crp,
                   patient          pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   dep_clin_serv    dcs,
                   clinical_service cs
             WHERE cr.id_patient = i_patient
               AND pat.id_patient = cr.id_patient
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional = cr.id_prof_requested
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_prof_req != cr.id_prof_requested
               AND crp.id_consult_req = cr.id_consult_req
               AND crp.flg_status = g_cons_req_prof_accept
            UNION
            SELECT cr.id_consult_req,
                   --                   p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', cr.flg_status, i_lang) status,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1
              FROM consult_req      cr,
                   consult_req_prof crp,
                   patient          pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   dep_clin_serv    dcs,
                   clinical_service cs
             WHERE cr.id_patient = i_patient
               AND cr.id_prof_req = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional = cr.id_prof_requested
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_CONSULT_REQ', 'GET_PAT_CONSULT_REQ');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_pat_consult_req_det
    (
        i_lang        IN language.id_language%TYPE,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof        IN profissional,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de pedidos de consulta de um paciente  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_CONSULT_REQ - ID do pedido
                  Saida: O_LIST - info 
                 O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/12/27 
          NOTAS: 
          -- Alteração. 20080312 - Rita Lopes
          -- Alterei o join entre as tabelas professional e consult_req_prof e passei a usar 
             as funcoes do pk_tools 
        *********************************************************************************/
        l_flg_sched schedule_outp.flg_sched%TYPE DEFAULT NULL;
    BEGIN
        /* Agenda */
        BEGIN
            SELECT b.flg_sched
              INTO l_flg_sched
              FROM consult_req a, schedule_outp b
             WHERE a.id_consult_req = i_consult_req
               AND b.id_schedule = a.id_schedule;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_sched := NULL;
        END;
        /* Fim Agenda */
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT --p1.nick_name prof_requests,
             pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
             pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt_req,
             pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hr_req,
             pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
             pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_TYPE',
                                     nvl(decode(l_flg_sched,
                                                'D',
                                                g_flg_first,
                                                'M',
                                                g_flg_subs,
                                                'P',
                                                g_flg_first,
                                                'Q',
                                                g_flg_subs,
                                                NULL),
                                         decode(cr.id_prof_req, cr.id_prof_requested, g_flg_subs, g_flg_first)),
                                     i_lang) flg_sched,
             cr.notes_admin, --CR.NOTES_CANCEL, CRP.DENIAL_JUSTIF,
             --                   pk_tools.get_prof_nick_name(i_lang, nvl(cr.id_prof_requested, crp.id_professional)) prof_requested,
             --p2.nick_name prof_requested,
             pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cr.id_prof_requested, crp.id_professional)) prof_requested,
             decode(cr.id_prof_req,
                    cr.id_prof_requested,
                    pk_date_utils.dt_chr_tsz(i_lang, cr.dt_scheduled_tstz, i_prof),
                    pk_date_utils.dt_chr_tsz(i_lang, crp.dt_scheduled_tstz, i_prof)) dt_sched,
             decode(cr.id_prof_req,
                    cr.id_prof_requested,
                    pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_scheduled_tstz, i_prof.institution, i_prof.software),
                    pk_date_utils.date_char_hour_tsz(i_lang, crp.dt_scheduled_tstz, i_prof.institution, i_prof.software)) hr_sched,
             pk_date_utils.to_char_insttimezone(i_prof,
                                                decode(cr.id_prof_req,
                                                       cr.id_prof_requested,
                                                       cr.dt_scheduled_tstz,
                                                       crp.dt_scheduled_tstz),
                                                'YYYYMMDDHH24MISS') date_sched,
             decode(cr.dt_scheduled_tstz, NULL, 'Y', 'N') avail_butt_ok,
             pk_translation.get_translation(i_lang, cs_epis.code_clinical_service) cons_type_req,
             (SELECT pk_translation.get_translation(i_lang, dept.code_dept) dept_req
                FROM schedule s, epis_info ei, dep_clin_serv dcs, clinical_service cs, dept dept, department d
               WHERE ei.id_episode = cr.id_episode
                 AND ei.id_schedule = s.id_schedule(+)
                 AND dcs.id_dep_clin_serv = decode(s.id_dcs_requests, NULL, ei.id_dep_clin_serv, s.id_dcs_requests)
                 AND cs.id_clinical_service = dcs.id_clinical_service
                 AND dcs.id_department = d.id_department
                 AND d.id_dept = dept.id_dept) dept_req,
             pk_tools.get_prof_speciality(i_lang, nvl(cr.id_prof_requested, crp.id_professional)) prof_spec
            -- (SELECT '(' || pk_translation.get_translation(i_lang, spec.code_speciality) || ')'
            --    FROM speciality spec
            --   WHERE p2.id_speciality = spec.id_speciality) prof_spec
              FROM consult_req      cr,
                   consult_req_prof crp,
                   patient          pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   episode          e,
                   clinical_service cs_epis
             WHERE cr.id_consult_req = i_consult_req
               AND crp.id_consult_req(+) = cr.id_consult_req
               AND crp.flg_status(+) = g_cons_req_prof_accept
               AND pat.id_patient = cr.id_patient
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional = crp.id_professional
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND cr.flg_status != g_consult_req_stat_cancel
               AND e.id_episode(+) = cr.id_episode
               AND cs_epis.id_clinical_service(+) = e.id_clinical_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_PAT_CONSULT_REQ_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION update_consult_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_dt_sched_str  IN VARCHAR2,
        i_prof          IN profissional,
        i_flg_type_date IN consult_req.flg_type_date%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Registar data  da consulta e alterar o estado do pedido de consulta para "agendado"  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_CONSULT_REQ - ID do pedido de consulta
                                 I_DT_SCHED - data agendada da consulta
                  Saida: O_ERROR - erro 
          
          CRIAÇÃO: SS 2005/12/27 
          NOTAS: 
        *********************************************************************************/
        l_dt_sched TIMESTAMP WITH TIME ZONE;
        l_rows     table_varchar := table_varchar();
    
    BEGIN
    
        l_dt_sched := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_sched_str, NULL);
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE STATUS';
        ts_consult_req.upd(flg_status_in        => g_consult_req_stat_sched,
                           dt_scheduled_tstz_in => l_dt_sched,
                           id_prof_proc_in      => i_prof.id,
                           flg_type_date_in     => i_flg_type_date,
                           id_consult_req_in    => i_consult_req,
                           rows_out             => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS,DT_SCHEDULED_TSTZ,ID_PROF_PROC,FLG_TYPE_DATE'));
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'UPDATE_CONSULT_REQ_STATUS');
            
                pk_utils.undo_changes;
                -- execute error processing                 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    /**
    * Public Function. 
    * Patient consults requested but not scheduled.
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_DT                data das requisições
    * @param      I_ID_PATIENT        Id do paciente
    * @param      o_list              consultas
    * @param      O_ERROR             erro
    *
    * @return     boolean
    * @author     Luís Gaspar
    * @version    0.1
    * @since      2007/03/27
    * @notes      Based on get_consult_req_list
    */
    FUNCTION get_patient_consult_req_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_list FOR
        -- lg consultas de especialidade aceites
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   ei.id_schedule,
                   cr.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   --                   p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   cr.id_episode
              FROM consult_req      cr,
                   consult_req_prof crp,
                   patient          pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   epis_info        ei,
                   sys_domain       sd,
                   episode          e
             WHERE ei.id_software = i_prof.software
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND cr.id_episode = ei.id_episode
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_prof_req != nvl(cr.id_prof_requested, 0)
               AND cr.id_inst_requested = i_prof.institution
               AND crp.id_consult_req = cr.id_consult_req
               AND crp.flg_status = g_cons_req_prof_accept
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional(+) = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val = decode(cr.id_prof_req, cr.id_prof_requested, g_flg_subs_img, g_flg_first_img)
               AND e.id_episode = cr.id_episode
               AND e.flg_status != g_epis_canc
               AND cr.id_schedule IS NULL
               AND pat.id_patient = i_id_patient
            UNION
            -- lg consultas subsequentes comigo
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   ei.id_schedule,
                   cr.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   --                   p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   cr.id_episode
              FROM consult_req cr,
                   patient     pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   epis_info        ei,
                   sys_domain       sd,
                   episode          e
             WHERE ei.id_software = i_prof.software
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND cr.id_episode = ei.id_episode
               AND cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_prof_req = cr.id_prof_requested
               AND cr.id_inst_requested = i_prof.institution
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND sd.val = decode(cr.id_prof_req, cr.id_prof_requested, g_flg_subs_img, g_flg_first_img)
               AND e.id_episode = cr.id_episode
               AND e.flg_status != g_epis_canc
               AND cr.id_schedule IS NULL
               AND pat.id_patient = i_id_patient
            UNION
            -- lg consultas marcadas via agenda alert e que ainda não existem no sistema administrativo
            -- quer por não existir interface no sentido alert-->ADT quer por ter ocorrido algum problema nesse interface
            SELECT cr.id_consult_req,
                   pat.id_patient,
                   cr.id_schedule,
                   cr.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pat.name,
                   crec.num_clin_record,
                   --                   p1.nick_name prof_requests,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_req) prof_requests,
                   --                   p2.nick_name prof_requested,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, cr.id_prof_requested) prof_requested,
                   pk_date_utils.dt_chr_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   lpad(1, 6, '0') || pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_SCHED', so.flg_sched) img_sched,
                   pk_date_utils.to_char_insttimezone(i_prof, cr.dt_consult_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   cr.id_episode
              FROM schedule    s,
                   consult_req cr,
                   patient     pat,
                   --                   professional     p1,
                   --                   professional     p2,
                   clin_record      crec,
                   dep_clin_serv    dcs,
                   clinical_service cs,
                   schedule_outp    so
             WHERE cr.flg_status NOT IN (g_consult_req_stat_cancel, g_consult_req_stat_sched)
               AND cr.id_inst_requested = i_prof.institution
               AND s.id_schedule = cr.id_schedule
               AND s.flg_status = g_sched_pend
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                  --               AND p1.id_professional = cr.id_prof_req
                  --               AND p2.id_professional(+) = cr.id_prof_requested
               AND pat.id_patient = cr.id_patient
               AND crec.id_patient = pat.id_patient
               AND crec.id_institution = i_prof.institution
               AND dcs.id_dep_clin_serv = cr.id_dep_clin_serv
               AND cs.id_clinical_service = dcs.id_clinical_service
               AND so.id_schedule = s.id_schedule
               AND pat.id_patient = i_id_patient
             ORDER BY date_target, hour_target;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_PATIENT_CONSULT_REQ_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            
            END;
    END get_patient_consult_req_list;

    /*******************************************************************************************************************************************
    * Nome : GET_FOLLOWUP_DEFAULT_VALUES                                                                                                       *
    * Descrição: Returns the default values when accessing the Follow-up button                                                                *
    *                                                                                                                                          *
    * @param I_LANG                   Language ID                                                                                              *
    * @param I_PROF                   Professional                                                                                             *
    * @param I_ID_EPISODE             Episode identification                                                                                   *
    * @param O_CUR                    The cursor with the default values                                                                       *
    * @param O_ERROR                  Output error                                                                                             *
    *                                                                                                                                          *
    * @return                         Return false if exist an error and true otherwise                                                        *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Eduardo Lourenço                                                                                         *
    * @version                        2.4.3                                                                                                    *
    * @since                          2008/05/13                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_followup_default_values
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE, -- tco 30/05/2008
        o_cur           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        OPEN o_cur FOR
            SELECT a.id_professional,
                   a.nickname,
                   b.id_dep_clin_serv,
                   b.desc_clin_serv,
                   b.id_complaint,
                   b.desc_complaint,
                   pk_schedule.has_permission(i_lang,
                                              i_prof,
                                              b.id_dep_clin_serv,
                                              decode(i_prof_cat_type,
                                                     'N',
                                                     g_sch_event_id_followup_nurse,
                                                     g_sch_event_id_followup),
                                              a.id_professional) permission
              FROM (SELECT rownum    AS a,
                           i_prof.id id_professional,
                           --pk_prof_utils.get_nickname(i_lang, i_prof.id) nickname
                           pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) nickname
                      FROM dual) a,
                   (SELECT rownum AS b,
                           nvl(dcs1.id_dep_clin_serv, dcs2.id_dep_clin_serv) id_dep_clin_serv,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                           c.id_complaint,
                           pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint
                      FROM episode e
                     INNER JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                      LEFT OUTER JOIN epis_complaint ec
                        ON ec.id_episode = e.id_episode
                      LEFT OUTER JOIN dep_clin_serv dcs1
                        ON (dcs1.id_dep_clin_serv = ei.id_first_dep_clin_serv)
                      LEFT OUTER JOIN dep_clin_serv dcs2
                        ON (dcs2.id_dep_clin_serv = ei.id_dcs_requested)
                      LEFT JOIN clinical_service cs
                        ON nvl(dcs1.id_clinical_service, dcs2.id_clinical_service) = cs.id_clinical_service
                      LEFT JOIN complaint c
                        ON ec.id_complaint = c.id_complaint
                     WHERE e.id_episode = i_id_episode
                       AND (ec.flg_status IS NULL OR ec.flg_status = g_active)) b
             WHERE a.a = b.b(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_FOLLOWUP_DEFAULT_VALUES');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_cur);
                RETURN FALSE;
            
            END;
    END get_followup_default_values;

    /*
    * Get list of professionals
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF professional, institution and software ids
    * @param   I_FLG_TYPE 'M' consulta médica; 'S' consulta de especialidade
    * @param   O_CURSOR array de destinos de alta
    * @param   O_ERROR warning/error message
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Eduardo Lourenço
    * @version 2.4.3
    * @since   2008-05-14
    */
    FUNCTION get_professional_dest_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE, -- tco 26/05/2008
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Returning doctors of current institution';
        -- neste caso só pode haver um registo em disch_reas_Dest com nenhum destino parametrizado
        -- este query retorna todos os medicos da institutição
        g_error := 'get UNIQUE DISCH_RAS_DEST ';
    
        OPEN o_cursor FOR
            SELECT DISTINCT --p.nick_name 
                            pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) desc_disch_reas_dest,
                            pdcs.id_professional,
                            pk_schedule.has_permission(i_lang,
                                                       i_prof,
                                                       i_dep_clin_serv,
                                                       decode(i_flg_type,
                                                              'M',
                                                              g_sch_event_id_followup,
                                                              'S',
                                                              g_sch_event_id_followup_spec),
                                                       p.id_professional) permission
              FROM prof_dep_clin_serv pdcs, professional p, prof_cat pc, category c, prof_institution pi
             WHERE pdcs.id_dep_clin_serv = i_dep_clin_serv
               AND pdcs.flg_status = g_selected
               AND p.id_professional = pdcs.id_professional
               AND p.flg_state = g_prof_active
               AND pc.id_professional = p.id_professional
               AND pi.id_professional = p.id_professional
               AND pi.id_institution = pc.id_institution
               AND pi.flg_state = g_prof_active
               AND pi.dt_end_tstz IS NULL
               AND c.id_category = pc.id_category
               AND c.flg_type = g_flg_doctor
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY desc_disch_reas_dest;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'GET_PROFESSIONAL_DEST_LIST');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_cursor);
                RETURN FALSE;
            
            END;
    END get_professional_dest_list;

    /*
    * Similar to GET_PROFESSIONAL_DEST_LIST.
    * Returns professionals of same category as the caller.
    *
    * @param      i_lang            language identifier.
    * @param      i_prof            logged professional structure.
    * @param      i_dep_clin_serv   dep_clin_serv identifier.
    * @param      i_flg_type        'M' consulta médica; 'S' consulta de especialidade.
    * @param      i_prof_cat_type   logged professional category.
    * @param      o_cursor          cursor.
    * @param      o_error           error.
    *
    * @return     false if errors occur, true otherwise.
    * @author     Pedro Carneiro
    * @version    1.0
    * @since      2009/04/23
    * @notes      Based on GET_PROFESSIONAL_DEST_LIST.
    */
    FUNCTION get_professional_dest_list_amb
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_type      IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_cursor        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Returning professionals of current institution';
        -- neste caso só pode haver um registo em disch_reas_Dest com nenhum destino parametrizado
        -- este query retorna todos os profissionais da institutição, da categoria passada por parâmetro
        g_error := 'OPEN o_cursor';
        OPEN o_cursor FOR
            SELECT DISTINCT pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) desc_disch_reas_dest,
                            pdcs.id_professional,
                            pk_schedule.has_permission(i_lang,
                                                       i_prof,
                                                       i_dep_clin_serv,
                                                       decode(i_flg_type,
                                                              'M',
                                                              g_sch_event_id_followup,
                                                              'S',
                                                              g_sch_event_id_followup_spec),
                                                       p.id_professional) permission
              FROM prof_dep_clin_serv pdcs, professional p, prof_cat pc, category c, prof_institution pi
             WHERE pdcs.id_dep_clin_serv = i_dep_clin_serv
               AND pdcs.flg_status = g_selected
               AND p.id_professional = pdcs.id_professional
               AND p.flg_state = g_prof_active
               AND pc.id_professional = p.id_professional
               AND pi.id_professional = p.id_professional
               AND pi.id_institution = pc.id_institution
               AND pi.flg_state = g_prof_active
               AND pi.dt_end_tstz IS NULL
               AND c.id_category = pc.id_category
               AND c.flg_type = i_prof_cat_type
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY desc_disch_reas_dest;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'GET_PROFESSIONAL_DEST_LIST_AMB',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END get_professional_dest_list_amb;

    /********************************************************************************************
    *  Check if it exists conflicts for a given dep_clin_serv ID associated to a appointment
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_PROF               Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_DEP_CLIN_SERV   Department clinical service ID associated to a appointment
    * @param    O_FLG_CONFLICT       Flag that indicates if it exists conflicts (Y/N)
    *
    * @return   BOOLEAN: true in case of conflict and false otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/29
    ********************************************************************************************/
    FUNCTION check_consult_req_conflict
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_conflict     OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        g_error := 'GET CURSOR';
    
        SELECT COUNT(1)
          INTO l_count
          FROM department d, dep_clin_serv dcs, clinical_service cs --, DEP_CLIN_SERV_TYPE DCST
         WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv
           AND d.id_institution = i_prof.institution
           AND instr(d.flg_type, 'C') > 0
           AND dcs.id_department = d.id_department
           AND cs.id_clinical_service = dcs.id_clinical_service
           AND dcs.flg_available = g_flg_available
           AND EXISTS (SELECT 1
                  FROM professional p, prof_dep_clin_serv pdcs, prof_func pf
                 WHERE p.flg_state = g_prof_active
                   AND p.id_professional != i_prof.id
                   AND pdcs.id_professional = p.id_professional
                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND pdcs.flg_status = g_selected
                   AND pf.id_professional = p.id_professional
                   AND pf.id_functionality = pk_sysconfig.get_config('FUNCTIONALITY_CONSULT_REQ', i_prof)
                   AND pf.id_institution = i_prof.institution);
    
        IF (l_count > 0)
        THEN
            o_flg_conflict := g_no;
        ELSE
            o_flg_conflict := g_yes;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_CONSULT_REQ',
                                   'CHECK_CONSULT_REQ_CONFLIT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END check_consult_req_conflict;

    /**********************************************************************************************
    * Retorna o motivo da consulta ou o do agendamento
    *
    * @param i_lang                ID language
    * @param i_id_consult_req      ID consult requisition
    *
    * @param o_reason              The reason for next consult
    * @param o_error               Error message
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Elisabete Bugalho
    * @version                     2.4.4
    * @since                       2009/03/24
    **********************************************************************************************/
    FUNCTION get_consult_req_reason
    (
        i_lang           IN language.id_language%TYPE,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        o_reason         OUT consult_req.reason_for_visit%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET REASON FOR VISIT';
        SELECT decode(c.id_complaint,
                      NULL,
                      reason_for_visit,
                      (SELECT pk_translation.get_translation(i_lang, code_complaint)
                         FROM complaint
                        WHERE id_complaint = c.id_complaint))
          INTO o_reason
          FROM consult_req c
         WHERE id_consult_req = i_id_consult_req;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'GET_CONSULT_REQ_REASON',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /* get content id from APPOINTMENT using available data from consult_req 
    * INLINE FUNCTION
    * 
    * @return                      APPOINTMENT.id_content%TYPE
    *                        
    * @author   Telmo
    * @version  2.6
    * @date     05-01-2010
    */
    FUNCTION get_content_dcs_code
    (
        i_flg_type            IN consult_req.flg_type%TYPE,
        i_id_clinical_service IN consult_req.id_clinical_service%TYPE,
        i_id_dep_clin_serv    IN consult_req.id_dep_clin_serv%TYPE,
        i_id_inst_requested   IN consult_req.id_inst_requested%TYPE,
        i_sch_type            IN sch_event.dep_type%TYPE,
        i_ids_content         IN table_varchar
        
    ) RETURN appointment.code_appointment%TYPE IS
        l_res           appointment.code_appointment%TYPE;
        l_count_content PLS_INTEGER := 0;
    BEGIN
        IF i_ids_content IS NOT NULL
        THEN
            l_count_content := i_ids_content.count;
        END IF;
    
        SELECT sacd.code_appointment
          INTO l_res
          FROM appointment sacd
          JOIN sch_event se
            ON sacd.id_sch_event = se.id_sch_event
         WHERE (l_count_content = 0 OR
               sacd.id_appointment IN (SELECT column_value
                                          FROM TABLE(i_ids_content)))
              --                        AND sacd.id_institution = cr.id_inst_requested
           AND sacd.flg_available = pk_alert_constant.g_yes
           AND se.flg_available = pk_alert_constant.g_yes
           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_id_inst_requested, 0) =
               pk_alert_constant.g_yes
           AND ((i_sch_type IS NULL AND
               se.dep_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_cons,
                                 pk_schedule_common.g_sch_dept_flg_dep_type_nurs,
                                 pk_schedule_common.g_sch_dept_flg_dep_type_nut)) OR
               (i_sch_type IS NOT NULL AND se.dep_type = i_sch_type))
              
           AND ((i_flg_type = g_flg_type_speciality AND se.flg_target_professional = pk_alert_constant.g_no AND
               se.flg_target_dep_clin_serv = pk_alert_constant.g_yes) OR
               (i_flg_type = g_flg_type_subsequent AND se.flg_occurrence = pk_schedule.g_event_occurrence_subs AND
               se.flg_target_professional = pk_alert_constant.g_yes))
           AND ((i_id_clinical_service IS NOT NULL AND sacd.id_clinical_service = i_id_clinical_service) OR
               (i_id_dep_clin_serv IS NOT NULL AND EXISTS
                (SELECT 1
                    FROM dep_clin_serv dcs1
                    JOIN department d
                      ON dcs1.id_department = d.id_department
                   WHERE dcs1.id_dep_clin_serv = i_id_dep_clin_serv
                     AND dcs1.id_clinical_service = sacd.id_clinical_service
                     AND d.id_institution = i_id_inst_requested
                     AND d.flg_available = pk_alert_constant.g_yes)))
           AND rownum = 1;
        RETURN l_res;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_content_dcs_code;

    /*  search physician, nurse and nutrition appoint. requisitions by 
    * - patient data
    * - appointment id (see new table appointment)
    * - dates
    * These are all AND conditions.
    *
    * @param i_lang                 language id
    * @param i_prof                 professional data
    * @param i_id_market            market id needed for patient searching. 
    * @param i_pat_search_values    assoc. array (hashtable) with patient criteria and their values to search for
    * @param i_ids_content          appointment table content ids. 
    * @param i_min_date             suggested date (if exists) must be higher than i_min_date, if supplied
    * @param i_min_date             suggested date (if exists) must be lower than i_max_date, if supplied
    * @param i_id_cancel_reason     cancel reason. If exists, the search must be conducted among canceled reqs.
    * @param i_ids_prof             list of requested profs, those that will perform the appointment. reqs with no requested prof are always considered
    * @param i_reason_for_visit     reason for visit (motivo da consulta)
    * @param i_sch_type             sch_type. If null then all are considered. C=medical app.  N=nurse app.  U=nutrition app.
    * @param o_error                Error data
    *
    * @return                      True on success, false otherwise
    *                        
    * @author   Telmo
    * @version  2.6
    * @date     05-01-2010
    */
    FUNCTION search_consult_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_market         IN market.id_market%TYPE,
        i_pat_search_values IN pk_utils.hashtable_pls_integer,
        i_ids_content       IN table_varchar,
        i_min_date          IN VARCHAR2,
        i_max_date          IN VARCHAR2,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_ids_prof          IN table_number,
        i_reason_for_visit  IN VARCHAR2,
        i_sch_type          IN sch_dep_type.dep_type%TYPE,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count_ids_content NUMBER := CASE
                                          WHEN i_ids_content IS NULL THEN
                                           0
                                          ELSE
                                           i_ids_content.count
                                      END;
        l_count_ids_prof NUMBER := CASE
                                       WHEN i_ids_prof IS NULL THEN
                                        0
                                       ELSE
                                        i_ids_prof.count
                                   END;
        l_min_date          TIMESTAMP WITH TIME ZONE;
        l_max_date          TIMESTAMP WITH TIME ZONE;
        l_all_patients      VARCHAR2(1);
    
    BEGIN
        -- SEARCH PATIENTS
        g_error := 'SEARCH PATIENTS';
        IF NOT pk_patient.search_patients(i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_id_market     => i_id_market,
                                          i_search_values => i_pat_search_values,
                                          o_all_patients  => l_all_patients,
                                          o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        pk_date_utils.set_dst_time_check_off;
    
        -- converter min date
        g_error := 'CALL GET_STRING_TSTZ FOR I_MIN_DATE';
        IF i_min_date IS NOT NULL
           AND NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_min_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_min_date,
                                                 o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- converter max date
        g_error := 'CALL GET_STRING_TSTZ FOR I_MAX_DATE';
        IF i_max_date IS NOT NULL
           AND NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_max_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_max_date,
                                                 o_error     => o_error)
        THEN
            pk_date_utils.set_dst_time_check_on;
            RETURN FALSE;
        END IF;
    
        -- output 
        g_error := 'OPEN CURSOR';
        OPEN o_list FOR
            SELECT cr.id_consult_req id_req,
                   cr.id_patient,
                   cr.id_episode,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pat.name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(cr.id_prof_requested, cr.id_prof_req)) requested_prof_name,
                   decode(cr.id_prof_req, cr.id_prof_requested, cr.dt_scheduled_tstz, crp.dt_scheduled_tstz) date_target,
                   nvl(pk_translation.get_translation(i_lang, cs.code_clinical_service), cr.consult_type) clinical_service_name,
                   cr.dt_consult_req_tstz date_requested,
                   cr.notes,
                   pk_translation.get_translation(i_lang, i.code_institution) instit_requested_name,
                   cr.flg_instructions,
                   cr.flg_type,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_TYPE', cr.flg_type, i_lang) flg_type_name,
                   pk_translation.get_translation(i_lang,
                                                  get_content_dcs_code(cr.flg_type,
                                                                       cr.id_clinical_service,
                                                                       cr.id_dep_clin_serv,
                                                                       cr.id_inst_requested,
                                                                       i_sch_type,
                                                                       i_ids_content)) content_code,
                   (SELECT pk_translation.get_translation(i_lang, code_cancel_reason)
                      FROM cancel_reason rea
                     WHERE rea.id_cancel_reason = cr.id_cancel_reason) cancel_reason_name
              FROM consult_req cr
              JOIN patient pat
                ON cr.id_patient = pat.id_patient
              LEFT JOIN clinical_service cs
                ON cr.id_clinical_service = cs.id_clinical_service
              LEFT JOIN consult_req_prof crp
                ON cr.id_consult_req = crp.id_consult_req
              LEFT JOIN institution i
                ON cr.id_inst_requested = i.id_institution
             WHERE
            -- fixed restrictions
             (crp.id_consult_req IS NULL OR crp.flg_status = g_cons_req_prof_accept)
            -- cancel reason restriction
             AND ((i_id_cancel_reason IS NULL AND cr.flg_status IN (g_consult_req_stat_req, g_consult_req_stat_reply)) OR
             (i_id_cancel_reason IS NOT NULL AND cr.id_cancel_reason = i_id_cancel_reason AND
             cr.flg_status = g_consult_req_stat_cancel))
            -- requested prof restriction
             AND (l_count_ids_prof = 0 OR
             cr.id_prof_requested IN (SELECT column_value
                                         FROM TABLE(i_ids_prof)))
            -- patient restriction
             AND (l_all_patients = pk_alert_constant.g_yes OR EXISTS
              (SELECT 1
                 FROM pat_tmptab_search tm
                WHERE tm.id_patient = cr.id_patient))
            -- dates restrictions
             AND (l_min_date IS NULL OR (cr.dt_scheduled_tstz IS NOT NULL AND cr.dt_scheduled_tstz >= l_min_date))
             AND (l_max_date IS NULL OR (cr.dt_scheduled_tstz IS NOT NULL AND cr.dt_scheduled_tstz <= l_max_date))
            -- reason for visit
             AND (i_reason_for_visit IS NULL OR
             (i_reason_for_visit IS NOT NULL AND cr.reason_for_visit LIKE '%' || i_reason_for_visit || '%'))
            -- content ids restrictions
             AND (l_count_ids_content = 0 OR get_content_dcs_code(cr.flg_type,
                                                              cr.id_clinical_service,
                                                              cr.id_dep_clin_serv,
                                                              cr.id_inst_requested,
                                                              i_sch_type,
                                                              i_ids_content) IS NOT NULL);
    
        pk_date_utils.set_dst_time_check_on;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'SEARCH_CONSULT_REQ',
                                              o_error);
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END search_consult_req;

    /********************************************************************************************
    * Send a consult_request to history
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req       future events identifier
    *
    * @param  o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION send_cr_to_history
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(60 CHAR) := 'SEND_CR_TO_HISTORY';
        l_id_prof_list        table_number;
        l_name_prof_list      table_varchar;
        l_id_consult_req_hist consult_req_hist.id_consult_req_hist%TYPE;
        l_rowids_hist         table_varchar;
        v_consult_req_hist    consult_req_hist%ROWTYPE;
    
        CURSOR c_consult_req(l_id consult_req.id_consult_req%TYPE) IS
            SELECT cr.id_consult_req,
                   cr.consult_type,
                   cr.id_clinical_service,
                   cr.id_patient,
                   cr.id_instit_requests,
                   cr.id_inst_requested,
                   cr.id_episode,
                   cr.id_prof_req,
                   cr.id_prof_auth,
                   cr.id_prof_appr,
                   cr.id_prof_proc,
                   cr.notes,
                   cr.id_prof_cancel,
                   cr.notes_cancel,
                   cr.id_dep_clin_serv,
                   cr.id_prof_requested,
                   cr.flg_status,
                   cr.notes_admin,
                   cr.id_schedule,
                   cr.dt_consult_req_tstz,
                   cr.dt_scheduled_tstz,
                   cr.dt_cancel_tstz,
                   cr.next_visit_in_notes,
                   cr.flg_instructions,
                   cr.id_complaint,
                   cr.flg_type_date,
                   cr.status_flg,
                   cr.status_icon,
                   cr.status_msg,
                   cr.status_str,
                   cr.reason_for_visit,
                   cr.flg_type,
                   cr.id_cancel_reason,
                   cr.id_epis_documentation,
                   cr.id_epis_type,
                   cr.dt_last_update,
                   cr.id_prof_last_update,
                   cr.id_inst_last_update,
                   cr.id_sch_event,
                   cr.dt_begin_event,
                   cr.dt_end_event,
                   cr.flg_priority,
                   cr.flg_contact_type,
                   cr.instructions,
                   cr.id_room,
                   cr.flg_request_type,
                   cr.flg_req_resp,
                   cr.request_reason,
                   cr.id_language,
                   cr.flg_recurrence,
                   cr.frequency,
                   cr.dt_rec_begin,
                   cr.dt_rec_end,
                   cr.nr_events,
                   cr.week_day,
                   cr.week_nr,
                   cr.month_day,
                   cr.month_nr,
                   cr.id_soft_reg_by
              FROM consult_req cr
             WHERE cr.id_consult_req = l_id;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_CONSULT_REQ';
        OPEN c_consult_req(i_consult_req);
        FETCH c_consult_req
            INTO v_consult_req_hist.id_consult_req,
                 v_consult_req_hist.consult_type,
                 v_consult_req_hist.id_clinical_service,
                 v_consult_req_hist.id_patient,
                 v_consult_req_hist.id_instit_requests,
                 v_consult_req_hist.id_inst_requested,
                 v_consult_req_hist.id_episode,
                 v_consult_req_hist.id_prof_req,
                 v_consult_req_hist.id_prof_auth,
                 v_consult_req_hist.id_prof_appr,
                 v_consult_req_hist.id_prof_proc,
                 v_consult_req_hist.notes,
                 v_consult_req_hist.id_prof_cancel,
                 v_consult_req_hist.notes_cancel,
                 v_consult_req_hist.id_dep_clin_serv,
                 v_consult_req_hist.id_prof_requested,
                 v_consult_req_hist.flg_status,
                 v_consult_req_hist.notes_admin,
                 v_consult_req_hist.id_schedule,
                 v_consult_req_hist.dt_consult_req_tstz,
                 v_consult_req_hist.dt_scheduled_tstz,
                 v_consult_req_hist.dt_cancel_tstz,
                 v_consult_req_hist.next_visit_in_notes,
                 v_consult_req_hist.flg_instructions,
                 v_consult_req_hist.id_complaint,
                 v_consult_req_hist.flg_type_date,
                 v_consult_req_hist.status_flg,
                 v_consult_req_hist.status_icon,
                 v_consult_req_hist.status_msg,
                 v_consult_req_hist.status_str,
                 v_consult_req_hist.reason_for_visit,
                 v_consult_req_hist.flg_type,
                 v_consult_req_hist.id_cancel_reason,
                 v_consult_req_hist.id_epis_documentation,
                 v_consult_req_hist.id_epis_type,
                 v_consult_req_hist.dt_last_update,
                 v_consult_req_hist.id_prof_last_update,
                 v_consult_req_hist.id_inst_last_update,
                 v_consult_req_hist.id_sch_event,
                 v_consult_req_hist.dt_begin_event,
                 v_consult_req_hist.dt_end_event,
                 v_consult_req_hist.flg_priority,
                 v_consult_req_hist.flg_contact_type,
                 v_consult_req_hist.instructions,
                 v_consult_req_hist.id_room,
                 v_consult_req_hist.flg_request_type,
                 v_consult_req_hist.flg_req_resp,
                 v_consult_req_hist.request_reason,
                 v_consult_req_hist.id_language,
                 v_consult_req_hist.flg_recurrence,
                 v_consult_req_hist.frequency,
                 v_consult_req_hist.dt_rec_begin,
                 v_consult_req_hist.dt_rec_end,
                 v_consult_req_hist.nr_events,
                 v_consult_req_hist.week_day,
                 v_consult_req_hist.week_nr,
                 v_consult_req_hist.month_day,
                 v_consult_req_hist.month_nr,
                 v_consult_req_hist.id_soft_reg_by;
        g_found := c_consult_req%NOTFOUND;
        CLOSE c_consult_req;
    
        g_error               := 'INSERT INTO CONSULT_REQ_HIST';
        l_id_consult_req_hist := ts_consult_req_hist.next_key;
        ts_consult_req_hist.ins(id_consult_req_hist_in   => l_id_consult_req_hist,
                                id_consult_req_in        => v_consult_req_hist.id_consult_req,
                                consult_type_in          => v_consult_req_hist.consult_type,
                                id_clinical_service_in   => v_consult_req_hist.id_clinical_service,
                                id_patient_in            => v_consult_req_hist.id_patient,
                                id_instit_requests_in    => v_consult_req_hist.id_instit_requests,
                                id_inst_requested_in     => v_consult_req_hist.id_inst_requested,
                                id_episode_in            => v_consult_req_hist.id_episode,
                                id_prof_req_in           => v_consult_req_hist.id_prof_req,
                                id_prof_auth_in          => v_consult_req_hist.id_prof_auth,
                                id_prof_appr_in          => v_consult_req_hist.id_prof_appr,
                                id_prof_proc_in          => v_consult_req_hist.id_prof_proc,
                                notes_in                 => v_consult_req_hist.notes,
                                id_prof_cancel_in        => v_consult_req_hist.id_prof_cancel,
                                notes_cancel_in          => v_consult_req_hist.notes_cancel,
                                id_dep_clin_serv_in      => v_consult_req_hist.id_dep_clin_serv,
                                id_prof_requested_in     => v_consult_req_hist.id_prof_requested,
                                flg_status_in            => v_consult_req_hist.flg_status,
                                notes_admin_in           => v_consult_req_hist.notes_admin,
                                id_schedule_in           => v_consult_req_hist.id_schedule,
                                dt_consult_req_tstz_in   => v_consult_req_hist.dt_consult_req_tstz,
                                dt_scheduled_tstz_in     => v_consult_req_hist.dt_scheduled_tstz,
                                dt_cancel_tstz_in        => v_consult_req_hist.dt_cancel_tstz,
                                next_visit_in_notes_in   => v_consult_req_hist.next_visit_in_notes,
                                flg_instructions_in      => v_consult_req_hist.flg_instructions,
                                id_complaint_in          => v_consult_req_hist.id_complaint,
                                flg_type_date_in         => v_consult_req_hist.flg_type_date,
                                status_flg_in            => v_consult_req_hist.status_flg,
                                status_icon_in           => v_consult_req_hist.status_icon,
                                status_msg_in            => v_consult_req_hist.status_msg,
                                status_str_in            => v_consult_req_hist.status_str,
                                reason_for_visit_in      => v_consult_req_hist.reason_for_visit,
                                flg_type_in              => v_consult_req_hist.flg_type,
                                id_cancel_reason_in      => v_consult_req_hist.id_cancel_reason,
                                id_epis_documentation_in => v_consult_req_hist.id_epis_documentation,
                                id_epis_type_in          => v_consult_req_hist.id_epis_type,
                                dt_last_update_in        => v_consult_req_hist.dt_last_update,
                                id_prof_last_update_in   => v_consult_req_hist.id_prof_last_update,
                                id_inst_last_update_in   => v_consult_req_hist.id_inst_last_update,
                                id_sch_event_in          => v_consult_req_hist.id_sch_event,
                                dt_begin_event_in        => v_consult_req_hist.dt_begin_event,
                                dt_end_event_in          => v_consult_req_hist.dt_end_event,
                                flg_priority_in          => v_consult_req_hist.flg_priority,
                                flg_contact_type_in      => v_consult_req_hist.flg_contact_type,
                                instructions_in          => v_consult_req_hist.instructions,
                                id_room_in               => v_consult_req_hist.id_room,
                                flg_request_type_in      => v_consult_req_hist.flg_request_type,
                                flg_req_resp_in          => v_consult_req_hist.flg_req_resp,
                                request_reason_in        => v_consult_req_hist.request_reason,
                                id_language_in           => v_consult_req_hist.id_language,
                                flg_recurrence_in        => v_consult_req_hist.flg_recurrence,
                                frequency_in             => v_consult_req_hist.frequency,
                                dt_rec_begin_in          => v_consult_req_hist.dt_rec_begin,
                                dt_rec_end_in            => v_consult_req_hist.dt_rec_end,
                                nr_events_in             => v_consult_req_hist.nr_events,
                                week_day_in              => v_consult_req_hist.week_day,
                                week_nr_in               => v_consult_req_hist.week_nr,
                                month_day_in             => v_consult_req_hist.month_day,
                                month_nr_in              => v_consult_req_hist.month_nr,
                                id_soft_reg_by_in        => v_consult_req_hist.id_soft_reg_by,
                                rows_out                 => l_rowids_hist);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ_HIST',
                                      i_rowids     => l_rowids_hist,
                                      o_error      => o_error);
    
        IF NOT pk_events.get_fe_approval_professionals(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_consult_req    => i_consult_req,
                                                       i_hist           => pk_alert_constant.g_no,
                                                       o_id_prof_list   => l_id_prof_list,
                                                       o_name_prof_list => l_name_prof_list,
                                                       o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_events.insert_prof_approval_hist_nc(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_consult_req_hist => l_id_consult_req_hist,
                                                      i_prof_approval    => l_id_prof_list,
                                                      o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_events.get_fe_request_professionals(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_consult_req    => i_consult_req,
                                                      i_hist           => pk_alert_constant.g_no,
                                                      o_id_prof_list   => l_id_prof_list,
                                                      o_name_prof_list => l_name_prof_list,
                                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_events.insert_request_prof_hist_nc(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_consult_req_hist => l_id_consult_req_hist,
                                                     i_prof_list        => l_id_prof_list,
                                                     o_error            => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END send_cr_to_history;

    /********************************************************************************************
    * insert consult req no commit
    *
    * @param      i_lang       language identifier              
    * @param   i_prof                 
    * @param     i_patient            
    * @param     i_episode            
    * @param     i_epis_type   
    * @param     i_request_prof              
    * @param     i_inst_req_to        
    * @param     i_sch_event          
    * @param     i_dep_clin_serv      
    * @param     i_complaint          
    * @param     i_dt_begin_event     
    * @param     i_dt_end_event       
    * @param     i_priority           
    * @param     i_contact_type       
    * @param     i_notes              
    * @param     i_instructions       
    * @param     i_room               
    * @param     i_request_type       
    * @param     i_request_responsable
    * @param     i_request_reason     
    * @param     i_prof_approval      
    * @param     i_language           
    * @param     i_recurrence         
    * @param     i_status             
    * @param     i_frequency          
    * @param     i_dt_rec_begin       
    * @param     i_dt_rec_end         
    * @param     i_nr_events          
    * @param     i_week_day           
    * @param     i_week_nr            
    * @param     i_month_day          
    * @param     i_month_nr           
    * @param     id_task_dependency   
    * @param     i_flg_origin_module  
    * @param     i_episode_to_exec    
    * @param     o_consult_req        return cursor
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION insert_consult_req_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN consult_req.dt_begin_event%TYPE,
        i_dt_end_event        IN consult_req.dt_end_event%TYPE,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN consult_req.dt_rec_begin%TYPE,
        i_dt_rec_end          IN consult_req.dt_rec_end%TYPE,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        id_task_dependency    IN tde_task_dependency.id_task_dependency%TYPE DEFAULT NULL,
        i_flg_origin_module   IN VARCHAR2 DEFAULT NULL,
        i_episode_to_exec     IN consult_req.id_episode_to_exec%TYPE DEFAULT NULL,
        o_consult_req         OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'INSERT_CONSULT_REQ_NC';
    
        l_next           consult_req.id_consult_req%TYPE := ts_consult_req.next_key;
        l_instit_requsts consult_req.id_instit_requests%TYPE;
        l_inst_requested consult_req.id_inst_requested%TYPE;
    
        l_rows_out      table_varchar := table_varchar();
        l_flg_status_in consult_req.flg_status%TYPE;
    
        l_need_approval_param VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_need_approval_prof  VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
        --Indicação se é uma consulta subsquente ou de especialidade
        l_sub_spec VARCHAR2(1 CHAR);
    
        l_epis_dcs        dep_clin_serv.id_dep_clin_serv%TYPE;
        l_sch_event_occur sch_event.flg_occurrence%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error          := 'GET INSTITUTION';
        l_instit_requsts := nvl(i_prof.institution, i_prof.institution);
        l_inst_requested := nvl(i_inst_req_to, i_prof.institution);
    
        IF i_episode IS NULL
        THEN
            BEGIN
                SELECT ei.id_dep_clin_serv
                  INTO l_epis_dcs
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    l_epis_dcs := NULL;
            END;
        END IF;
    
        BEGIN
            SELECT se.flg_occurrence
              INTO l_sch_event_occur
              FROM sch_event se
             WHERE se.id_sch_event = i_sch_event;
        EXCEPTION
            WHEN OTHERS THEN
                l_sch_event_occur := NULL;
        END;
    
        IF l_epis_dcs = i_dep_clin_serv
           AND l_sch_event_occur = pk_consult_req.g_flg_type_subsequent
        THEN
            l_sub_spec := g_flg_type_subsequent;
        ELSE
            l_sub_spec := g_flg_type_speciality;
        END IF;
    
        g_error := 'PK_EVENTS.CHECK_REQUIRES_APPROVAL';
        IF NOT pk_events.check_requires_approval(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_event_type    => pk_events.get_event_type_by_epis_type(i_epis_type),
                                                 o_need_approval => l_need_approval_param,
                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        FOR i IN 1 .. i_prof_approval.count
        LOOP
            IF i_prof_approval(i) = i_prof.id
            THEN
                l_need_approval_prof := pk_alert_constant.g_no;
                EXIT;
            END IF;
        END LOOP;
    
        IF l_need_approval_param = pk_alert_constant.g_yes
           AND l_need_approval_prof = pk_alert_constant.g_yes
        THEN
            l_flg_status_in := pk_consult_req.g_consult_req_stat_req;
        ELSE
            l_flg_status_in := pk_consult_req.g_consult_req_stat_reply;
        END IF;
    
        ts_consult_req.ins(id_consult_req_in      => l_next,
                           dt_consult_req_tstz_in => g_sysdate_tstz,
                           --id_clinical_service_in => i_clinical_service,
                           id_patient_in         => i_patient,
                           id_instit_requests_in => l_instit_requsts,
                           id_inst_requested_in  => l_inst_requested,
                           id_episode_in         => i_episode,
                           --dt_scheduled_tstz_in   => i_dt_scheduled,
                           notes_in            => i_notes,
                           id_dep_clin_serv_in => i_dep_clin_serv,
                           id_prof_req_in      => i_prof.id,
                           id_soft_reg_by_in   => i_prof.software,
                           flg_status_in       => l_flg_status_in,
                           --  flg_type_date_in       => i_flg_type_date,
                           id_complaint_in     => i_complaint,
                           reason_for_visit_in => i_reason_for_visit,
                           flg_type_in         => l_sub_spec,
                           id_sch_event_in     => i_sch_event,
                           dt_begin_event_in   => i_dt_begin_event,
                           dt_end_event_in     => i_dt_end_event,
                           flg_priority_in     => i_priority,
                           flg_contact_type_in => i_contact_type,
                           instructions_in     => i_instructions,
                           id_room_in          => i_room,
                           flg_request_type_in => i_request_type,
                           flg_req_resp_in     => i_request_responsable,
                           request_reason_in   => i_request_reason,
                           
                           id_epis_type_in        => i_epis_type,
                           dt_last_update_in      => g_sysdate_tstz,
                           id_prof_last_update_in => i_prof.id,
                           id_inst_last_update_in => i_prof.institution,
                           
                           id_language_in            => i_language,
                           flg_recurrence_in         => i_recurrence,
                           frequency_in              => i_frequency,
                           dt_rec_begin_in           => i_dt_rec_begin,
                           dt_rec_end_in             => i_dt_rec_end,
                           nr_events_in              => i_nr_events,
                           week_day_in               => i_week_day,
                           week_nr_in                => i_week_nr,
                           month_day_in              => i_month_day,
                           month_nr_in               => i_month_nr,
                           id_task_dependency_in     => id_task_dependency,
                           flg_freq_origin_module_in => i_flg_origin_module,
                           id_episode_to_exec_in     => i_episode_to_exec,
                           rows_out                  => l_rows_out);
    
        o_consult_req := l_next;
    
        g_error := 't_data_gov_mnt.process_insert ts_consult_req';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        o_consult_req := l_next;
    
        g_error := 'INSERT_PROF_APPROVAL_NC';
        IF NOT pk_events.insert_prof_approval_nc(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_consult_req   => l_next,
                                                 i_prof_approval => i_prof_approval,
                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'INSERT_REQUEST_PROF_NC';
        IF NOT pk_events.insert_request_prof_nc(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_consult_req => l_next,
                                                i_prof_list   => i_request_prof,
                                                o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
        
            RETURN FALSE;
    END insert_consult_req_nc;

    /********************************************************************************************
    * update consult req no commit
    *
    * @param     i_consult_req
    * @param     i_lang       language identifier             
    * @param     i_prof                 
    * @param     i_patient            
    * @param     i_episode            
    * @param     i_epis_type 
    * @param     i_request_prof                
    * @param     i_inst_req_to        
    * @param     i_sch_event          
    * @param     i_dep_clin_serv      
    * @param     i_complaint          
    * @param     i_dt_begin_event     
    * @param     i_dt_end_event       
    * @param     i_priority           
    * @param     i_contact_type       
    * @param     i_notes              
    * @param     i_instructions       
    * @param     i_room               
    * @param     i_request_type       
    * @param     i_request_responsable
    * @param     i_request_reason     
    * @param     i_prof_approval        
    * @param     i_language           
    * @param     i_recurrence         
    * @param     i_status             
    * @param     i_frequency          
    * @param     i_dt_rec_begin       
    * @param     i_dt_rec_end         
    * @param     i_nr_events          
    * @param     i_week_day           
    * @param     i_week_nr            
    * @param     i_month_day          
    * @param     i_month_nr           
    * @param     id_task_dependency   
    * @param     i_flg_origin_module  
    * @param     i_episode_to_exec    
    * @param     o_consult_req        return cursor
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION update_consult_req_nc
    (
        i_consult_req         IN consult_req.id_consult_req%TYPE,
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN consult_req.dt_begin_event%TYPE,
        i_dt_end_event        IN consult_req.dt_end_event%TYPE,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN consult_req.dt_rec_begin%TYPE,
        i_dt_rec_end          IN consult_req.dt_rec_end%TYPE,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'UPDATE_CONSULT_REC_NC';
    
        l_instit_requsts consult_req.id_instit_requests%TYPE;
        l_inst_requested consult_req.id_inst_requested%TYPE;
    
        l_rows          table_varchar;
        l_flg_status_in consult_req.flg_status%TYPE;
    
        l_need_approval_param VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_need_approval_prof  VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error          := 'GET INSTITUTION';
        l_instit_requsts := nvl(i_prof.institution, i_prof.institution);
        l_inst_requested := nvl(i_inst_req_to, i_prof.institution);
    
        g_error := 'PK_EVENTS.CHECK_REQUIRES_APPROVAL';
        IF NOT pk_events.check_requires_approval(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_event_type    => pk_events.get_event_type_by_epis_type(i_epis_type),
                                                 o_need_approval => l_need_approval_param,
                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        FOR i IN 1 .. i_prof_approval.count
        LOOP
            IF i_prof_approval(i) = i_prof.id
            THEN
                l_need_approval_prof := pk_alert_constant.g_no;
                EXIT;
            END IF;
        END LOOP;
    
        IF l_need_approval_param = pk_alert_constant.g_yes
           AND l_need_approval_prof = pk_alert_constant.g_yes
        THEN
            l_flg_status_in := pk_consult_req.g_consult_req_stat_req;
        ELSE
            l_flg_status_in := pk_consult_req.g_consult_req_stat_reply;
        END IF;
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'TS_CONSULT_REQ.UPD';
        ts_consult_req.upd(id_consult_req_in => i_consult_req,
                           --dt_consult_req_tstz_in => g_sysdate_tstz,
                           --id_clinical_service_in => i_clinical_service,
                           id_patient_in         => i_patient,
                           id_instit_requests_in => l_instit_requsts,
                           id_inst_requested_in  => l_inst_requested,
                           id_episode_in         => i_episode,
                           --dt_scheduled_tstz_in   => i_dt_scheduled,
                           notes_in              => i_notes,
                           notes_nin             => FALSE,
                           id_dep_clin_serv_in   => i_dep_clin_serv,
                           id_prof_req_in        => i_prof.id,
                           id_prof_requested_in  => NULL,
                           id_prof_requested_nin => FALSE,
                           id_soft_reg_by_in     => i_prof.software,
                           flg_status_in         => l_flg_status_in,
                           --  flg_type_date_in       => i_flg_type_date,
                           id_complaint_in      => i_complaint,
                           id_complaint_nin     => FALSE,
                           reason_for_visit_in  => i_reason_for_visit,
                           reason_for_visit_nin => FALSE,
                           --  flg_type_in            => l_flg_type,
                           id_sch_event_in      => i_sch_event,
                           dt_begin_event_in    => i_dt_begin_event,
                           dt_begin_event_nin   => FALSE,
                           dt_end_event_in      => i_dt_end_event,
                           dt_end_event_nin     => FALSE,
                           flg_priority_in      => i_priority,
                           flg_priority_nin     => FALSE,
                           flg_contact_type_in  => i_contact_type,
                           flg_contact_type_nin => FALSE,
                           instructions_in      => i_instructions,
                           instructions_nin     => FALSE,
                           id_room_in           => i_room,
                           id_room_nin          => FALSE,
                           flg_request_type_in  => i_request_type,
                           flg_request_type_nin => FALSE,
                           flg_req_resp_in      => i_request_responsable,
                           flg_req_resp_nin     => FALSE,
                           request_reason_in    => i_request_reason,
                           request_reason_nin   => FALSE,
                           
                           id_epis_type_in        => i_epis_type,
                           dt_last_update_in      => g_sysdate_tstz,
                           id_prof_last_update_in => i_prof.id,
                           id_inst_last_update_in => i_prof.institution,
                           
                           id_language_in     => i_language,
                           id_language_nin    => FALSE,
                           flg_recurrence_in  => i_recurrence,
                           flg_recurrence_nin => FALSE,
                           frequency_in       => i_frequency,
                           frequency_nin      => FALSE,
                           dt_rec_begin_in    => i_dt_rec_begin,
                           dt_rec_begin_nin   => FALSE,
                           dt_rec_end_in      => i_dt_rec_end,
                           dt_rec_end_nin     => FALSE,
                           nr_events_in       => i_nr_events,
                           nr_events_nin      => FALSE,
                           week_day_in        => i_week_day,
                           week_day_nin       => FALSE,
                           week_nr_in         => i_week_nr,
                           week_nr_nin        => FALSE,
                           month_day_in       => i_month_day,
                           month_day_nin      => FALSE,
                           month_nr_in        => i_month_nr,
                           month_nr_nin       => FALSE,
                           rows_out           => l_rows);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        IF NOT pk_events.update_prof_approval_nc(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_consult_req   => i_consult_req,
                                                 i_prof_approval => i_prof_approval,
                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF NOT pk_events.update_request_prof_nc(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_consult_req => i_consult_req,
                                                i_prof_list   => i_request_prof,
                                                o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_consult_req_nc;

    /********************************************************************************************
    * cancel future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      patient identifier
    * @param      i_cancel_reason      cancel reason
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/24
    **********************************************************************************************/
    FUNCTION cancel_future_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_cancel_reason IN consult_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN consult_req.notes_cancel%TYPE,
        i_commit        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'CANCEL_FUTURE_EVENTS';
    BEGIN
    
        g_error := 'CALL cancel_future_events_nc';
        IF NOT cancel_future_events_nc(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_consult_req   => i_consult_req,
                                       i_cancel_reason => i_cancel_reason,
                                       i_cancel_notes  => i_cancel_notes,
                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            IF i_commit = pk_alert_constant.g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
        
            RETURN FALSE;
    END cancel_future_events;
    /********************************************************************************************
    * cancel future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      patient identifier
    * @param      i_cancel_reason      cancel reason
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/24
    **********************************************************************************************/
    FUNCTION cancel_future_events_nc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_cancel_reason IN consult_req.id_cancel_reason%TYPE,
        i_cancel_notes  IN consult_req.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'cancel_future_events_NC';
        l_rowids    table_varchar;
    BEGIN
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'UPDATE CONSULT REQ';
        ts_consult_req.upd(id_consult_req_in      => i_consult_req,
                           dt_last_update_in      => current_timestamp,
                           id_prof_last_update_in => i_prof.id,
                           id_inst_last_update_in => i_prof.institution,
                           id_cancel_reason_in    => i_cancel_reason,
                           notes_cancel_in        => i_cancel_notes,
                           notes_cancel_nin       => FALSE,
                           flg_status_in          => g_consult_req_stat_cancel, --'C',
                           id_prof_cancel_in      => i_prof.id, -- PST: ALERT-115186
                           dt_cancel_tstz_in      => current_timestamp, -- PST: ALERT-115186
                           rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_future_events_nc;

    /********************************************************************************************
    * Approves a future event request
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_consult_req       future events identifier
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/02
    **********************************************************************************************/
    FUNCTION set_fe_approved
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SET_FE_APPROVED';
    
        l_fe_status consult_req.flg_status%TYPE;
    
        l_rowids table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CHECK FE CURRENT STATUS';
        SELECT cr.flg_status
          INTO l_fe_status
          FROM consult_req cr
         WHERE cr.id_consult_req = i_consult_req;
    
        IF l_fe_status <> pk_events.g_status_requested
        THEN
            RAISE g_exception;
        END IF;
    
        --IF r_exist.id_prof_auth IS NOT NULL
        --THEN
        --   RAISE g_exception_msg_1;
        --END IF;
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL UPDATE_FUTURE_EVENTS';
        ts_consult_req.upd(id_consult_req_in      => i_consult_req,
                           flg_status_in          => pk_consult_req.g_consult_req_stat_apr,
                           dt_last_update_in      => g_sysdate_tstz,
                           id_prof_last_update_in => i_prof.id,
                           id_inst_last_update_in => i_prof.institution,
                           rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_fe_approved;

    /********************************************************************************************
    * Rejects a future event request
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_consult_req       future events identifier
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    *
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/02
    **********************************************************************************************/
    FUNCTION set_fe_rejected
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SET_FE_REJECTED';
    
        l_fe_status consult_req.flg_status%TYPE;
    
        l_rowids table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CHECK FE CURRENT STATUS';
    
        SELECT cr.flg_status
          INTO l_fe_status
          FROM consult_req cr
         WHERE cr.id_consult_req = i_consult_req;
    
        IF l_fe_status <> pk_events.g_status_requested
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL UPDATE_FUTURE_EVENTS';
        ts_consult_req.upd(id_consult_req_in      => i_consult_req,
                           flg_status_in          => pk_events.g_status_pending,
                           dt_last_update_in      => g_sysdate_tstz,
                           id_prof_last_update_in => i_prof.id,
                           id_inst_last_update_in => i_prof.institution,
                           rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_fe_rejected;

    /********************************************************************************************
    * SEND TO HOLDING LIST
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req        event identifier
    * 
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION send_cr_to_holding_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'SEND_CR_TO_HOLDING_LIST';
        l_rowids    table_varchar;
    BEGIN
        FOR i IN 1 .. i_consult_req.count
        LOOP
            g_error := 'SEND TO HISTORY';
            IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_consult_req => i_consult_req(i),
                                                     o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'UPDATE CONSULT REQ';
            ts_consult_req.upd(id_consult_req_in      => i_consult_req(i),
                               dt_last_update_in      => current_timestamp,
                               id_prof_last_update_in => i_prof.id,
                               id_inst_last_update_in => i_prof.institution,
                               flg_status_in          => 'H',
                               rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'CONSULT_REQ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END LOOP;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END send_cr_to_holding_list;

    /**
    * Get Future Events task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_consult_req         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_description
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_consult_req IN consult_req.id_consult_req%TYPE,
        i_desc_type      IN VARCHAR2
    ) RETURN CLOB IS
        l_ret           CLOB;
        l_date_sep      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T073');
        l_msg_suggested sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T065');
        l_msg_scheduled sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T066');
        CURSOR c_desc IS
        -- Description of the event, type of appointment, Type of visit, Date, Status
            SELECT desc_event || ', ' || type_app || ', ' || type_visit ||
                   decode(req_date, NULL, NULL, ', ' || req_date) || decode(status, NULL, NULL, ', ' || status) descr
              FROM (SELECT pk_events.get_event_type_title(i_lang,
                                                          pk_events.get_event_type_by_epis_type(nvl(nvl(cr.id_epis_type,
                                                                                                        pk_events.get_epis_type_consult_req(cr.id_consult_req)),
                                                                                                    pk_alert_constant.g_epis_type_outpatient))) desc_event,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) type_app,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) type_visit,
                           nvl(pk_date_utils.dt_chr(i_lang,
                                                    pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                  cr.id_instit_requests,
                                                                                                  NULL),
                                                                                     cr.dt_scheduled_tstz),
                                                    i_prof),
                               nvl2(cr.dt_end_event,
                                    pk_date_utils.dt_chr(i_lang,
                                                         pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                       cr.id_instit_requests,
                                                                                                       NULL),
                                                                                          cr.dt_begin_event),
                                                         i_prof) || pk_events.g_space || l_date_sep || pk_events.g_space ||
                                    pk_date_utils.dt_chr(i_lang,
                                                         pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                       cr.id_instit_requests,
                                                                                                       NULL),
                                                                                          cr.dt_end_event),
                                                         i_prof),
                                    pk_date_utils.dt_chr(i_lang,
                                                         pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                       cr.id_instit_requests,
                                                                                                       NULL),
                                                                                          cr.dt_begin_event),
                                                         i_prof))) req_date,
                           CASE
                                WHEN cr.flg_status IN ('W', 'PC', 'PCR', 'H', 'R', 'F', 'P', 'A') THEN
                                 substr(l_msg_suggested, 2, length(l_msg_suggested) - 2)
                                WHEN cr.flg_status IN ('EA', 'T', 'V', 'S', 'M') THEN
                                 substr(l_msg_scheduled, 2, length(l_msg_scheduled) - 2)
                                ELSE
                                 NULL
                            END status
                      FROM consult_req cr
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = cr.id_dep_clin_serv
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN sch_event se
                        ON (se.id_sch_event = cr.id_sch_event)
                     WHERE cr.id_consult_req = i_id_consult_req);
    
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_ret;
        CLOSE c_desc;
    
        RETURN l_ret;
    END get_description;

    FUNCTION undo_cancel_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SEND TO HISTORY';
        IF NOT pk_consult_req.send_cr_to_history(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_consult_req => i_consult_req,
                                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ts_consult_req.upd(id_consult_req_in  => i_consult_req,
                           id_prof_cancel_in  => NULL,
                           id_prof_cancel_nin => FALSE,
                           dt_cancel_tstz_in  => NULL,
                           dt_cancel_tstz_nin => FALSE,
                           notes_cancel_in    => NULL,
                           notes_cancel_nin   => FALSE,
                           flg_status_in      => g_sched_pend,
                           rows_out           => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CONSULT_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'UNDO_CANCEL_CONSULT_REQ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END undo_cancel_consult_req;

    FUNCTION inactivate_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'CONSULT_INACTIVATE');
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_consult_req  table_number;
        l_final_status table_varchar;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_monitorization) sent in i_ids_exclude        
        CURSOR c_consult_req(ids_exclude IN table_number) IS
            WITH t1 AS
             (SELECT /*+ materialize*/
               a.id_consult_req,
               a.id_episode,
               a.flg_status,
               a.id_inst_requested,
               coalesce(a.dt_scheduled_tstz, a.dt_begin_event, a.dt_consult_req_tstz) dt_begin_or_req
                FROM consult_req a
               WHERE a.flg_status IN ('PC', 'PCR', 'P', 'R', 'W', 'H'))
            SELECT t2.id_consult_req, t2.field_04
              FROM (SELECT t.id_consult_req, t.dt_begin_or_req, cfg.field_02, cfg.field_03, cfg.field_04
                      FROM t1 t
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            *
                             FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = t.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = t.id_consult_req
                     WHERE t.id_inst_requested = i_inst
                       AND t_ids.column_value IS NULL) t2
             WHERE pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                    i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => t2.dt_begin_or_req,
                                                                                               i_amount    => t2.field_02,
                                                                                               i_unit      => t2.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
               AND rownum <= l_max_rows
            UNION ALL
            SELECT cr.id_consult_req, cfg.field_04
              FROM consult_req cr
              LEFT JOIN schedule s
                ON cr.id_schedule = s.id_schedule
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     *
                      FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = cr.flg_status
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = cr.id_consult_req
             WHERE cr.id_episode IS NULL
             AND cr.id_inst_requested = i_inst
             AND pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                  i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => coalesce(cr.dt_begin_event,
                                                                                                                     cr.dt_consult_req_tstz),
                                                                                             i_amount    => cfg.field_02,
                                                                                             i_unit      => cfg.field_03))) <=
             pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
             AND rownum <= l_max_rows
             AND t_ids.column_value IS NULL;
    
    BEGIN
    
        o_has_error := FALSE;
    
        OPEN c_consult_req(i_ids_exclude);
        FETCH c_consult_req BULK COLLECT
            INTO l_consult_req, l_final_status;
        CLOSE c_consult_req;
    
        IF l_consult_req.count > 0
        THEN
            FOR i IN 1 .. l_consult_req.count
            LOOP
                IF l_final_status(i) = pk_consult_req.g_consult_req_stat_cancel
                THEN
                
                    SAVEPOINT init_cancel;
                
                    IF NOT pk_consult_req.cancel_future_events(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_consult_req   => l_consult_req(i),
                                                               i_cancel_reason => l_cancel_id,
                                                               i_cancel_notes  => NULL,
                                                               i_commit        => pk_alert_constant.g_no,
                                                               o_error         => l_error)
                    THEN
                    
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_consult_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_consult_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        l_error.err_desc := 'ERROR CALLING PK_CONSULT_REQ.CANCEL_FUTURE_EVENTS FOR RECORD ' ||
                                            l_consult_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          l_error.err_desc,
                                                          'ALERT',
                                                          'PK_CONSULT_REQ',
                                                          'INACTIVATE_CONSULT_REQ',
                                                          o_error);
                    
                        --The array for the ids (id_consult_req) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_consult_req(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_consult_req has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_consult_req) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_consult_req.inactivate_consult_req(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_inst        => i_inst,
                                                             i_ids_exclude => i_ids_exclude,
                                                             o_has_error   => o_has_error,
                                                             o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              'ALERT',
                                              'PK_CONSULT_REQ',
                                              'INACTIVATE_CONSULT_REQ',
                                              l_error);
            RETURN FALSE;
    END inactivate_consult_req;

BEGIN
    g_consult_req_stat_req   := 'R';
    g_consult_req_stat_read  := 'F';
    g_consult_req_stat_reply := 'P';
    --G_CONSULT_REQ_STAT_REP_READ := 'A';
    g_consult_req_stat_cancel   := 'C';
    g_consult_req_hold_list     := 'H';
    g_consult_req_stat_auth     := 'T';
    g_consult_req_stat_apr      := 'V';
    g_consult_req_stat_proc     := 'S';
    g_consult_req_stat_sched    := 'M';
    g_consult_req_stat_rejected := 'N';
    g_cons_req_prof_read        := 'R';
    g_cons_req_prof_accept      := 'A';
    g_cons_req_prof_deny        := 'D';
    g_accept                    := 'ACCEPT';
    g_flg_subs_img              := 'M';
    g_flg_first_img             := 'D';
    g_sched                     := 'S';
    g_not_sched                 := 'N';
    g_flg_subs                  := 'S';
    g_flg_first                 := 'P';
    g_flg_doctor                := 'D';
    g_sched_canc                := 'C';
    g_sched_pend                := 'P';
    g_prof_active               := 'A';

    g_cat_type_tech := 'T';
    g_cat_type_phys := 'F';

    g_epis_canc    := 'C';
    g_dcst_consult := 'C';

    g_selected        := 'S';
    g_flg_available   := 'Y';
    g_flg_type_date_h := 'H';
    g_flg_type_date_a := 'A';
    g_flg_type_date_m := 'M';

    g_yes := 'Y';
    g_no  := 'N';

    g_active                     := 'A';
    g_sch_event_id_followup      := 2;
    g_sch_event_id_followup_spec := 2;

    g_sch_event_id_followup_nurse := 12;
    g_package_name                := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
