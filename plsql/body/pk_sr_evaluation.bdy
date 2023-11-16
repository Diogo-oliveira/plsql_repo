/*-- Last Change Revision: $Rev: 2027730 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_evaluation AS

    /********************************************************************************************
    * Obtem a descrição de um item da avaliação
    *
    * @param i_lang        Id do idioma
    * @param i_patient     ID do paciente
    * @param i_prof        Id do profissional, instituição e software
    * @param i_sql_cursor  SQL a executar para obter a descrição do item de acolhimento
    * @param i_label       Label a mostrar para a descrição do item de acolhimento
    *
    * @return              Descrição de um item da avaliação
    *
    * @author              Rui Batista
    * @since               2006/09/15
       ********************************************************************************************/

    FUNCTION get_eval_item_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_sql_cursor IN VARCHAR2,
        i_label      IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_sql VARCHAR2(4000);
        --l_patient patient.id_patient%TYPE;
        l_cursor pk_types.cursor_type;
        l_count  NUMBER;
        l_desc   VARCHAR2(4000);
        l_temp   VARCHAR2(2000);
    
    BEGIN
    
        g_error := 'SCAN SUBS VARIABLES';
        pk_alertlog.log_debug(g_error);
        l_sql := i_sql_cursor;
    
        --Substitui as variáveis existentes no código
        SELECT REPLACE(l_sql, '&I_LANG', i_lang)
          INTO l_sql
          FROM dual;
        SELECT REPLACE(l_sql, '&G_CANCEL', '''' || g_cancel || '''')
          INTO l_sql
          FROM dual;
        SELECT REPLACE(l_sql, '&G_FINISH', '''' || g_finish || '''')
          INTO l_sql
          FROM dual;
        SELECT REPLACE(l_sql, '&I_PATIENT', i_patient)
          INTO l_sql
          FROM dual;
    
        --Abre cursor e constroi a descrição do item do acolhimento
        l_count := 0;
        g_error := 'open l_cursor';
        pk_alertlog.log_debug(g_error);
        OPEN l_cursor FOR l_sql;
        LOOP
            FETCH l_cursor
                INTO l_temp;
            EXIT WHEN l_cursor%NOTFOUND;
        
            IF l_count = 0
            THEN
                l_desc := l_temp;
            ELSE
                l_desc := l_desc || ', ' || l_temp;
            END IF;
            l_count := l_count + 1;
        END LOOP;
        CLOSE l_cursor;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_sql || ': ' || SQLERRM;
    END;

    /********************************************************************************************
    * Obtem a lista de tipos de avaliações
    *
    * @param i_lang          Id do idioma
    * @param i_prof          Id do profissional, instituição e software
    * @param i_prof_cat_type Categoria do profissional (N-Enfermeiro, D-Médico)
    * @param i_surg_period   ID do periodo operatório. Valores possíveis:
    *                            1- Pré-operatório
    *                            2- Intra-operatório
    *                            3- Pós-operatório
    *
    * @param o_list          Lista dos tipos de avaliações
    * @param o_error         Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/28
       ********************************************************************************************/

    FUNCTION get_eval_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem a lista de tipos de avaliações
        g_error := 'GET EVAT TYPE CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT pk_translation.get_translation(i_lang, code_sr_eval_type) label,
                   nvl(id_doc_area, 0) data,
                   NULL icon,
                   nvl(id_doc_area, 0) id_doc_area
              FROM sr_eval_type
             WHERE id_surg_period = i_surg_period
               AND id_institution IN (i_prof.institution, 0)
               AND id_software = i_prof.software
               AND flg_available = g_available
               AND nvl(flg_access, g_access_all) IN (g_access_all, i_prof_cat_type)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EVAL_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de tipos de registos
    *
    * @param i_lang           Id do idioma
    * @param i_prof           Id do profissional, instituição e software
    * @param i_prof_cat_type  Categoria do profissional (N-Nurse; D-Doctor, A-Auxiliar)
    * @param i_surg_period    ID do periodo operatório. Valores possíveis:
    *                               1- Pré-operatório
    *                               2- Intra-operatório
    *                               3- Pós-operatório
    *                               4- Registos que não sejam avaliações
    * @param i_type           Tipo de registos. Valores possíveis: 
    *                               N- Avaliações de enfermagem
    *                               D- Registos do cirurgião e anestesista
    *
    * @param o_list           Lista dos tipos de registos
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE/FALSE
    *
    * @author                 Rui Batista
    * @since                  2006/11/02
       ********************************************************************************************/

    FUNCTION get_reg_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        i_type          IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem a lista de tipos de avaliações
        g_error := 'GET TYPE CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT pk_translation.get_translation(i_lang, code_sr_eval_type) label,
                   id_doc_area data,
                   NULL icon,
                   nvl(id_doc_area, 0) id_doc_area,
                   rank
              FROM sr_eval_type
             WHERE id_surg_period = i_surg_period
               AND val = i_type
               AND id_institution IN (i_prof.institution, 0)
               AND id_software = i_prof.software
               AND flg_available = g_available
               AND nvl(flg_access, g_access_all) IN (g_access_all, i_prof_cat_type)
            UNION --                                PARA TRAZER AS AVALIAÇÕES REPETIDAS. RETIRAR DEPOIS DE REFORMULAR A TABELA
            SELECT pk_translation.get_translation(i_lang, code_sr_eval_type) label,
                   id_doc_area data,
                   NULL icon,
                   nvl(id_doc_area, 0) id_doc_area,
                   rank
              FROM sr_eval_type
             WHERE id_sr_eval_type IN (6, 7)
               AND i_type = 'N'
               AND id_institution IN (i_prof.institution, 0)
               AND id_software = i_prof.software
               AND flg_available = g_available
               AND nvl(flg_access, g_access_all) IN (g_access_all, i_prof_cat_type)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REG_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Verifica se é possível realizar avaliaçoes para um dado periodo operatório, baseando-se no estado 
    *  do paciente para determinar qual o estado operatório em que este se encontra.
    *            A regra é:
    *              - Se periodo operatorio paciente < I_SURG_PERIOD
    *                .Mensagem de erro e não pode ser feita a avaliação.
    *              - Se periodo operatorio paciente = I_SURG_PERIOD
    *                .Não mostra mensagem
    *              - Se periodo operatorio paciente > I_SURG_PERIOD                  
    *                . Mostra mensagem de aviso com possibilidade do profissional continuar.
    *                
    *            EXCEPÇÕES:
    *              - Se o periodo do operatorio do paciente for 1 (Pré-operatório) e I_SURG_PERIOD=2 e a avaliação for correspondente ao Acolhimento no Bloco,
    *                deixa continuar, dado que para o paciente passar para o estado de Admitido no bloco é necessário realizar esta avaliação.     
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_episode     Id do episódio  
    * @param i_surg_period ID do periodo operatório. Valores possíveis:
    *                         1- Pré-operatório
    *                         2- Intra-operatório
    *                         3- Pós-operatório
    * @param i_doc_area    ID da avaliação que o profissional está a tentar criar.
    *
    * @param o_flg_show    Indica se existe uma mensagem para mostrar ao utilizador. Valores possíveis:
                                Y - Mostrar a mensagem
                                N - Não mostrar a mensagem
    * @param o_msg_result  Mensagem a apresentar
    * @param o_title       Título da mensagem
    * @param o_button      Botões a apresentar. Combinação dos possíveis valores:
                                N - Botão de não confirmação
                                C - Botão de confirmação/lido
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Campos
    * @since               2006/11/09
       ********************************************************************************************/

    FUNCTION check_pat_status_period
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_surg_period IN sr_surg_period.id_surg_period%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_result  OUT VARCHAR2,
        o_title       OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_pat_status IS
            SELECT sps.flg_pat_status, nvl(ssp.id_sr_surg_period, g_no_period)
              FROM sr_pat_status sps, sr_pat_status_period ssp
             WHERE sps.id_episode = i_episode
               AND ssp.flg_pat_status(+) = sps.flg_pat_status
             ORDER BY sps.dt_status_tstz DESC;
    
        l_curr_pat_status sr_pat_status.flg_pat_status%TYPE;
        l_curr_period     sr_pat_status_period.id_sr_surg_period%TYPE;
        l_check_flg       VARCHAR2(1);
    BEGIN
        o_flg_show := 'N';
    
        g_error := 'OPEN C_GET_PAT_STATUS';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_pat_status;
        FETCH c_get_pat_status
            INTO l_curr_pat_status, l_curr_period;
        g_found := c_get_pat_status%FOUND;
        CLOSE c_get_pat_status;
    
        -- @todo Verificar se é mesmo necessário
        IF NOT g_found
        THEN
            l_curr_period := g_default_period; -- Pré-operatório
        END IF;
    
        -- Verifica se o período definido pelo utilizador é diferente do período actual em que se encontra o doente.
        g_error := 'CHECK PERIOD';
        pk_alertlog.log_debug(g_error);
        IF (i_surg_period <> l_curr_period)
        THEN
            o_flg_show := 'Y';
            o_title    := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014'); -- Aviso
        
            -- Verifica se o periodo indicado pelo utilizador é anterior ou posterior ao período em que o doente se encontra.
            IF (l_curr_period < i_surg_period AND l_curr_period != 0)
            THEN
                -- EXCEPÇÃO: Se a avaliação for a de Acolhimento no Bloco e l_curr_period=1 e I_SURG_PERIOD=2, deixa avançar
                IF i_doc_area = g_receive_doc_area
                   AND l_curr_period = 1
                   AND i_surg_period = 2
                THEN
                    o_flg_show := 'N';
                    o_title    := 'N';
                ELSE
                    o_button := 'C';
                    g_error  := 'GET MSG_RESULT';
                    pk_alertlog.log_debug(g_error);
                    SELECT decode(l_curr_period,
                                  1,
                                  pk_message.get_message(i_lang, 'SURGERY_ROOM_M016'), -- O paciente ainda não se encontra no bloco
                                  2,
                                  pk_message.get_message(i_lang, 'SURGERY_ROOM_M017') -- O paciente ainda se encontra em cirurgia
                                  )
                      INTO o_msg_result
                      FROM dual;
                END IF;
            ELSE
                o_button := 'NC';
                g_error  := 'GET MSG_RESULT';
                pk_alertlog.log_debug(g_error);
                SELECT decode(l_curr_period,
                              2,
                              pk_message.get_message(i_lang, 'SURGERY_ROOM_M018'), -- O paciente já se encontra em cirurgia. Deseja continuar?
                              3,
                              pk_message.get_message(i_lang, 'SURGERY_ROOM_M019'), -- O paciente já terminou a cirurgia. Deseja continuar?
                              0,
                              pk_message.get_message(i_lang, 'SURGERY_ROOM_M030')) -- A cirúrgia está cancelada
                  INTO o_msg_result
                  FROM dual;
            END IF;
        END IF;
    
        -- Se a área é o Acolhimento no bloco e o periodo actual é pré ou intra operatório
        IF i_doc_area = g_receive_doc_area
           AND (l_curr_period = 1 OR l_curr_period = 2)
           AND o_msg_result IS NULL
        THEN
            --testa se tem POS e se está POS aprovado e não expirado
            l_check_flg := pk_sr_pos.check_pos_status(i_lang, i_prof, i_episode);
        
            IF l_check_flg = pk_alert_constant.g_yes
            THEN
                o_flg_show   := 'Y';
                o_title      := pk_message.get_message(i_lang, 'SURGERY_ROOM_M032');
                o_button     := 'NC';
                g_error      := 'GET MSG_RESULT';
                o_msg_result := pk_message.get_message(i_lang, 'SURGERY_ROOM_M031');
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REG_TYPE_LIST',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Valida se existe alguma regra para a avaliação (mensagem a mostrar caso se verifiquem algumas respostas)
    *  e caso a regra se verifique devolve a mensagem a apresentar.
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_episode     ID do episódio
    * @param i_doc_area    ID da área
    *
    * @param o_flg_show    Indica se deve ser apresentada mensagem (Y/N)
    * @param o_msg_title   Título da mensagem
    * @param o_msg_text    Texto da mensagem
    * @param o_button      Botões a apresentar. Combinação de: C - Confirmar/Lido, N - Não confirmar, R - Lido
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Campos
    * @since               2006/11/17
       ********************************************************************************************/

    FUNCTION check_eval_rule
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_doc IS
            SELECT id_epis_documentation
              FROM epis_documentation
             WHERE id_doc_area = i_doc_area
               AND id_episode = i_episode
             ORDER BY dt_creation_tstz DESC;
    
        l_id_epis_doc  epis_documentation.id_epis_documentation%TYPE;
        l_count        NUMBER;
        l_code_message sys_domain.desc_val%TYPE;
    BEGIN
        -- Get the ID for the last information on the EPIS_DOCUMENTATION table
        g_error := 'OPEN C_EPIS_DOC';
        pk_alertlog.log_debug(g_error);
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_id_epis_doc;
        g_found := c_epis_doc%FOUND;
        CLOSE c_epis_doc;
    
        IF NOT g_found
        THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EVAL_RULE',
                                              o_error);
            RETURN FALSE;
        
        END IF;
    
        -- Count the number of answers on the evaluation that match the answers associated with the rule
        SELECT COUNT(1)
          INTO l_count
          FROM epis_documentation_det
         WHERE id_epis_documentation = l_id_epis_doc
           AND id_doc_element_crit IN (SELECT id_doc_element_crit
                                         FROM sr_eval_rule
                                        WHERE id_doc_area = i_doc_area);
    
        IF l_count > 0
        THEN
            -- The rule is verified and a message will be shown to the user
            -- 
            -- Get the code for the message from the SYS_DOMAIN table.
        
            SELECT desc_val
              INTO l_code_message
              FROM sys_domain
             WHERE code_domain = 'SR_EVAL_RULE.CODE_MESSAGE'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND val = i_doc_area
               AND flg_available = 'Y'
               AND id_language = i_lang;
        
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
            o_msg_text  := pk_message.get_message(i_lang, l_code_message);
            o_button    := 'R';
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EVAL_RULE',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de tipos de registos/avaliações a serem mostrados nas opções de cração
    *  de um novo registo/avaliação através de uma página sumário
    *
    * @param i_lang           Id do idioma
    * @param i_prof           Id do profissional, instituição e software
    * @param i_prof_cat_type  Categoria do profissional (N-Nurse; D-Doctor, A-Auxiliar)
    * @param i_surg_period    ID do periodo operatório. Valores possíveis:
    *                              1- Pré-operatório
    *                              2- Intra-operatório
    *                              3- Pós-operatório
    *                              4- Registos que não sejam avaliações
    * @param i_type           Tipo de registos. Valores possíveis: E- Avaliações,  R- Registos
    *
    * @param o_list           Lista dos tipos de registos
    * @param o_error          Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/11/30
       ********************************************************************************************/

    FUNCTION get_summ_page_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        i_type          IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem a lista de tipos de avaliações
        g_error := 'GET TYPE CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT pk_translation.get_translation(i_lang, code_sr_eval_summ) label,
                   id_doc_area data,
                   screen_name,
                   rank,
                   nvl((SELECT id_surg_period
                         FROM sr_eval_summ sr2
                        WHERE --sr2.flg_type = sr.flg_type AND 
                        sr2.id_doc_area = sr.id_doc_area
                    AND sr2.id_surg_period != 4),
                       i_surg_period) id_surg_period
              FROM sr_eval_summ sr
             WHERE sr.id_surg_period = nvl(i_surg_period, 1)
               AND sr.flg_type = i_type
               AND sr.id_institution IN (i_prof.institution, 0)
               AND sr.id_software IN (i_prof.software, 0)
               AND nvl(sr.flg_access, g_access_all) IN (g_access_all, i_prof_cat_type)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMM_PAGE_TYPE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get number of records registered in given operative period
    *
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    * @param    i_surg_period    ID of surgical period. Possible values:
    *                              1- Pre-operative
    *                              2- Intra-operative
    *                              3- Pós-operativbe
    *                              4- Requests that are not assessments
    * @param    i_type           Records type. POssible values: E- Assessment, R- Records
    *
    * @return              Count of records
    *
    * @author              Anna Kurowska
    * @since               2016/10/26
       ********************************************************************************************/
    FUNCTION get_eval_register_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope_type  IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_surg_period IN sr_surg_period.id_surg_period%TYPE,
        i_type        IN sr_eval_summ.flg_type%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_EVAL_REGISTER_COUNT';
        l_episodes  table_number := table_number();
        l_count     NUMBER(24);
    BEGIN
    
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(DISTINCT ed.id_doc_area)
          INTO l_count
          FROM epis_documentation ed
          JOIN doc_area da
            ON da.id_doc_area = ed.id_doc_area
          JOIN sr_eval_summ sres
            ON sres.id_doc_area = da.id_doc_area
          JOIN sr_surg_period srsp
            ON srsp.id_surg_period = sres.id_surg_period
          JOIN institution i
            ON i.id_institution = sres.id_institution
          JOIN software s
            ON s.id_software = sres.id_software
         WHERE ed.id_episode_context IN (SELECT *
                                           FROM TABLE(l_episodes))
           AND ed.flg_status = g_active
           AND srsp.id_surg_period = i_surg_period
           AND sres.id_institution IN (i_prof.institution, 0)
           AND sres.id_software IN (i_prof.software, 0)
           AND sres.flg_type = i_type; --ID_EVALUATION
    
        RETURN l_count;
    END get_eval_register_count;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sr_evaluation;
/
