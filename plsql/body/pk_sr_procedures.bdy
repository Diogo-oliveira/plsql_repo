/*-- Last Change Revision: $Rev: 2027741 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:09 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_procedures AS

    /********************************************************************************************
    * Actualiza o detalhe da visita pós-operatória
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_subcat           Sub-categoria do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/15
    ********************************************************************************************/
    FUNCTION get_prof_subcat
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_subcat OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem sub-categoria do profissional que efectuou o login na aplicação
        g_error := 'GET PROF SUBCATEG';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT flg_type
              INTO o_subcat
              FROM prof_cat pc, category_sub c
             WHERE pc.id_professional = i_prof.id
               AND c.id_category_sub = pc.id_category_sub;
        EXCEPTION
            WHEN no_data_found THEN
                o_subcat := g_cat_type_doctor;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_SUBCAT',
                                              o_error);
            RETURN FALSE;
        
    END get_prof_subcat;

    /********************************************************************************************
    * Obtem a descrição de um item do acolhimento
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sql_cursor       SQL a executar para obter a descrição do item de acolhimento
    * @param i_label            Label a mostrar para a descrição do item de acolhimento
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/08/18
    ********************************************************************************************/
    FUNCTION get_receive_item_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_sql_cursor IN VARCHAR2,
        i_label      IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_sql     VARCHAR2(4000);
        l_patient patient.id_patient%TYPE;
        l_cursor  pk_types.cursor_type;
        l_count   NUMBER;
        l_desc    VARCHAR2(4000);
        l_temp    VARCHAR2(200);
    
    BEGIN
    
        g_error := 'SCAN SUBS VARIABLES';
        pk_alertlog.log_debug(g_error);
        l_sql := i_sql_cursor;
    
        --Obtem dados a passar ao SQL
        --ID do Paciente
        BEGIN
            -- <DENORM_EPISODE_JOSE_BRITO>
            SELECT e.id_patient
              INTO l_patient
              FROM episode e --, visit v
             WHERE e.id_episode = i_episode;
            --AND v.id_visit = e.id_visit;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_patient := NULL;
        END;
    
        --Substitui as variáveis existentes no código
        SELECT REPLACE(l_sql, '&I_LANG', i_lang)
          INTO l_sql
          FROM dual;
        SELECT REPLACE(l_sql, '&G_CANCEL', '''' || g_canceled || '''')
          INTO l_sql
          FROM dual;
        SELECT REPLACE(l_sql, '&I_PATIENT', l_patient)
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
    
        l_desc := to_char(l_count) || ' ' || i_label || ': ' || l_desc;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_receive_item_desc;

    /********************************************************************************************
    * Obtém a última informação, caso exista, na tabela SR_RECEIVE para um dado episódio. Caso não 
    *   exista a informação, as variáveis de saída terão os valores default.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * 
    * @param o_status           Indica o estado de admissão. (Y- Admitido para cirurgia; N- Não admitido para cirurgia). Default=N
    * @param o_manual           Indica se a última informação é decorrente de intervenção manual ou automática. (Y-Manual; N-Automática). Default=N
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_sr_receive
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_status  OUT VARCHAR2,
        o_manual  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_sr_receive IS
            SELECT flg_status, flg_manual
              FROM sr_receive
             WHERE id_episode = i_episode
             ORDER BY dt_receive_tstz DESC;
    
        r_sr_receive c_sr_receive%ROWTYPE;
    
    BEGIN
        g_error  := 'SET OUTPUT INITIAL VALUES';
        o_status := 'N';
        o_manual := 'N';
    
        -- Obtém o último registo para este episódio na SR_RECEIVE, caso exista.
        g_error := 'GET C_SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        OPEN c_sr_receive;
        FETCH c_sr_receive
            INTO r_sr_receive;
        g_found := c_sr_receive%FOUND;
        CLOSE c_sr_receive;
    
        IF g_found
        THEN
            o_status := r_sr_receive.flg_status;
            o_manual := r_sr_receive.flg_manual;
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
                                              'GET_SR_RECEIVE',
                                              o_error);
            RETURN FALSE;
        
    END get_sr_receive;

    /********************************************************************************************
    * Obtém o estado de admissão no bloco para o episódio, baseado nas respostas às perguntas mandatórias.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_doc_template     Template id
    * @param o_status           Indica o estado de admissão. (Y- Admitido para cirurgia; N- Não admitido para cirurgia)
    * @param o_flg_show         Indicates if should be presented a Warning message to the user. (Y- Yes; N- No)
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION check_receive_status
    (
        i_lang         IN language.id_language%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        o_status       OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_epis_doc     epis_documentation.id_epis_documentation%TYPE;
        l_id_doc          documentation.id_documentation%TYPE;
        l_id_doc_template epis_documentation.id_doc_template%TYPE;
        l_admit_status    VARCHAR2(1char);
        l_episode_exists  VARCHAR2(1char) := pk_alert_constant.g_yes;
    
        CURSOR c_epis_doc IS
            SELECT id_epis_documentation, id_doc_template
              FROM epis_documentation
             WHERE id_doc_area = g_receive_doc_area
               AND id_episode = i_episode
               AND flg_status = g_active
             ORDER BY epis_documentation.dt_creation_tstz DESC;
    
        CURSOR c_mandatory_documentation
        (
            i_id_epis_doc  IN epis_documentation.id_epis_documentation%TYPE,
            i_doc_template IN epis_documentation.id_doc_template%TYPE
        ) IS
            SELECT de.id_documentation
              FROM doc_element de
             INNER JOIN doc_element_crit DEC
                ON dec.id_doc_element = de.id_doc_element
               AND dec.flg_mandatory = pk_alert_constant.g_yes
             INNER JOIN documentation d
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_area = g_receive_doc_area
               AND dtad.id_doc_template = i_doc_template
               AND d.flg_available = pk_alert_constant.g_yes
               AND de.flg_available = pk_alert_constant.g_yes
            MINUS
            SELECT edd.id_documentation
              FROM epis_documentation_det edd
             INNER JOIN doc_element_crit DEC
                ON dec.id_doc_element_crit = edd.id_doc_element_crit
               AND dec.flg_mandatory = pk_alert_constant.g_yes
             WHERE edd.id_epis_documentation = i_id_epis_doc;
    
        CURSOR c_mandatory_fields(i_doc_template IN epis_documentation.id_doc_template%TYPE) IS
            SELECT de.id_documentation
              FROM doc_element de
             INNER JOIN doc_element_crit DEC
                ON dec.id_doc_element = de.id_doc_element
               AND dec.flg_mandatory = pk_alert_constant.g_yes
             INNER JOIN documentation d
                ON d.id_documentation = de.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             WHERE dtad.id_doc_area = g_receive_doc_area
               AND dtad.id_doc_template = i_doc_template
               AND d.flg_available = pk_alert_constant.g_yes
               AND de.flg_available = pk_alert_constant.g_yes;
    
    BEGIN
        -- Verifica se existe alguma avaliação e caso exista, obtém o identificador da última.
        g_error := 'GET C_EPIS_DOC';
        pk_alertlog.log_debug(g_error);
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_id_epis_doc, l_id_doc_template;
        g_found := c_epis_doc%FOUND;
        CLOSE c_epis_doc;
        IF NOT g_found
        THEN
            l_admit_status    := pk_alert_constant.g_no;
            l_episode_exists  := pk_alert_constant.g_no;
            l_id_epis_doc     := NULL;
            l_id_doc_template := i_doc_template;
        END IF;
    
        IF l_episode_exists = pk_alert_constant.g_no
        THEN
            g_error := 'GET C_MANDATORY_FIELDS';
            pk_alertlog.log_debug(g_error);
            OPEN c_mandatory_fields(l_id_doc_template);
            FETCH c_mandatory_fields
                INTO l_id_doc;
            g_found := c_mandatory_fields%FOUND;
            CLOSE c_mandatory_fields;
        
            g_error := 'CHECK G_FOUND';
            pk_alertlog.log_debug(g_error);
        
            -- 
            l_admit_status := pk_alert_constant.g_no;
            IF g_found
            THEN
                o_flg_show := pk_alert_constant.g_yes;
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        
        ELSE
            -- Abre o cursor com as perguntas obrigatórias que ainda não tenham uma resposta que satisfaça a obrigatoriedade.
            g_error := 'GET C_MANDATORY_DOCUMENTATION';
            pk_alertlog.log_debug(g_error);
            OPEN c_mandatory_documentation(l_id_epis_doc, l_id_doc_template);
            FETCH c_mandatory_documentation
                INTO l_id_doc;
            g_found := c_mandatory_documentation%FOUND;
            CLOSE c_mandatory_documentation;
        
            g_error := 'CHECK G_FOUND';
            pk_alertlog.log_debug(g_error);
            -- Se algum registo foi encontrado significa que o paciente não pode ser admitido.
            IF g_found
            THEN
                l_admit_status := pk_alert_constant.g_no;
            ELSE
                l_admit_status := pk_alert_constant.g_yes;
            END IF;
        
            --
            g_error := 'GET IF MESSAGE SHOULD BE PRESENT TO USER';
            pk_alertlog.log_debug(g_error);
            IF l_admit_status = pk_alert_constant.g_yes
            THEN
                o_flg_show := pk_alert_constant.g_no;
            ELSE
                o_flg_show := pk_alert_constant.g_yes;
            END IF;
        END IF;
        --
        o_status := l_admit_status;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_RECEIVE_STATUS',
                                              o_error);
            RETURN FALSE;
    END check_receive_status;

    /********************************************************************************************
    * Cria uma nova entrada na SR_RECEIVE referente a uma alteração no estado de admissão para cirurgia
    *   do episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_status           Indica o novo estado a criar. (Y- Admitido; N- Não admitido)
    * @param i_manual           Indica se o registo a criar é decorrente de uma intervenção manual por um profissional ou
    *                              através de uma validação automática (Y- Manual; N-Automático)
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION insert_sr_receive
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_status         IN VARCHAR2,
        i_manual         IN VARCHAR2,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_pat_status IS
            SELECT flg_pat_status
              FROM sr_pat_status
             WHERE id_episode = i_episode;
    
        l_pat_status     sr_pat_status.flg_pat_status%TYPE;
        l_aux            VARCHAR2(1024);
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INSERT SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        IF (i_manual = pk_alert_constant.g_no)
        THEN
            INSERT INTO sr_receive
                (id_sr_receive, id_episode, flg_status, flg_manual, id_prof, dt_receive_tstz)
            VALUES
                (seq_sr_receive.nextval, i_episode, i_status, i_manual, NULL, g_sysdate_tstz);
        ELSE
            INSERT INTO sr_receive
                (id_sr_receive, id_episode, flg_status, flg_manual, id_prof, dt_receive_tstz)
            VALUES
                (seq_sr_receive.nextval, i_episode, i_status, i_manual, i_prof.id, g_sysdate_tstz);
        END IF;
    
        -- If status=Y, need to check if patient status should be changed to 'Admitted'. Patient status is changed to 'Admitted' only
        -- if actual patient status is prior to 'Admitted' in the workflow.
        OPEN c_pat_status;
        FETCH c_pat_status
            INTO l_pat_status;
        CLOSE c_pat_status;
    
        IF nvl(l_pat_status, g_pat_status_a) IN (g_pat_status_a, g_pat_status_w, g_pat_status_l, g_pat_status_t)
        THEN
            -- Updates Patient status to V-Admitted
            g_error := 'SET PAT STATUS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_episode        => i_episode,
                                                  i_flg_status_new => g_pat_status_v,
                                                  i_flg_status_old => l_pat_status,
                                                  i_test           => 'N',
                                                  i_transaction_id => l_transaction_id,
                                                  o_flg_show       => l_aux,
                                                  o_msg_title      => l_aux,
                                                  o_msg_text       => l_aux,
                                                  o_button         => l_aux,
                                                  o_error          => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'INSERT_SR_RECEIVE',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_RECEIVE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'INSERT_SR_RECEIVE',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END insert_sr_receive;

    /********************************************************************************************
    * Obtém o estado de admissão no bloco para o episódio, indicando se o mesmo é obtido de forma automática 
    *  (verificação das respostas às perguntas obrigatórias) ou manual (alterado por um profissional).
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_transaction_id   Transaction ID
    * @param o_status           Indica o estado de admissão. (Y- Admitido para cirurgia; N- Não admitido para cirurgia)
    * @param o_manual           Indica se o estado obtido é obtido a partir de uma alteração manual por um profissional. 
    *                              (Y- Manual; N- Automático)
    * @param o_title            Título a mostrar no ecrã (Ex: 'Admitido para cirurgia')
    * @param o_status_labels    Cursor com as labels correspondentes a cada valor de status.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_receive_status
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_status         OUT VARCHAR2,
        o_manual         OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_status_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_status         sr_receive.flg_status%TYPE;
        l_flg_show       VARCHAR2(1char);
        l_manual         sr_receive.flg_manual%TYPE;
        l_aut_status     sr_receive.flg_status%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, NULL);
    
        g_error := 'SET OUTPUT INITIAL VALUES';
        pk_alertlog.log_debug(g_error);
        o_status := 'N';
        o_manual := 'N';
    
        -- Obtém a label para o título
        SELECT pk_message.get_message(i_lang, 'SR_LABEL_T041')
          INTO o_title
          FROM dual;
    
        g_error := 'open o_status_labels cursor';
        pk_alertlog.log_debug(g_error);
        -- Obtém os cursores com os labels para os valores de status
        OPEN o_status_labels FOR
            SELECT 'Y' status, pk_message.get_message(i_lang, 'SR_LABEL_T343') desc_status
              FROM dual
            UNION
            SELECT 'N' status, pk_message.get_message(i_lang, 'SR_LABEL_T344') desc_status
              FROM dual;
    
        -- Obtém o último registo para este episódio na SR_RECEIVE, caso exista.
        g_error := 'GET_SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_procedures.get_sr_receive(i_lang    => i_lang,
                                               i_episode => i_episode,
                                               o_status  => l_status,
                                               o_manual  => l_manual,
                                               o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Caso existam registos e o último registo seja manual e STATUS=Y (alterado por um profissional), não faz a validação se as perguntas obrigatórias já foram respondidas.
        g_error := 'CHECK C_SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        IF l_manual = pk_alert_constant.g_yes
           AND l_status = pk_alert_constant.g_yes
        THEN
            o_status := l_status;
            o_manual := l_manual;
            RETURN TRUE;
        END IF;
    
        -- Faz a validação se as perguntas obrigatórias já foram respondidas e o paciente pode ser admitido.
        g_error := 'CALL CHECK_RECEIVE_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT check_receive_status(i_lang         => i_lang,
                                    i_episode      => i_episode,
                                    i_doc_template => NULL,
                                    o_status       => l_aut_status,
                                    o_flg_show     => l_flg_show,
                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Caso o último registo na SR_RECEIVE seja automático com STATUS=Y e o resultado da função CHECK_RECEIVE_STATUS for N, deve
        -- adicionar uma nova linha à SR_RECEIVE.      
        IF l_manual = pk_alert_constant.g_no
           AND l_status = pk_alert_constant.g_yes
           AND l_aut_status = pk_alert_constant.g_no
        THEN
            g_error := 'CREATE_SR_RECEIVE';
            pk_alertlog.log_debug(g_error);
            IF NOT insert_sr_receive(i_lang           => i_lang,
                                     i_episode        => i_episode,
                                     i_status         => l_aut_status,
                                     i_manual         => pk_alert_constant.g_no,
                                     i_prof           => NULL,
                                     i_transaction_id => l_transaction_id,
                                     o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        o_status := l_aut_status;
        o_manual := pk_alert_constant.g_no;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, NULL);
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
                                              'GET_RECEIVE_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_status_labels);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, NULL);
            RETURN FALSE;
    END get_receive_status;

    /********************************************************************************************
    * USED BY UX!
    * Obtém o estado de admissão no bloco para o episódio, indicando se o mesmo é obtido de forma automática 
    *  (verificação das respostas às perguntas obrigatórias) ou manual (alterado por um profissional).
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * 
    * @param o_status           Indica o estado de admissão. (Y- Admitido para cirurgia; N- Não admitido para cirurgia)
    * @param o_manual           Indica se o estado obtido é obtido a partir de uma alteração manual por um profissional. 
    *                              (Y- Manual; N- Automático)
    * @param o_title            Título a mostrar no ecrã (Ex: 'Admitido para cirurgia')
    * @param o_status_labels    Cursor com as labels correspondentes a cada valor de status.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_receive_status
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_status        OUT VARCHAR2,
        o_manual        OUT VARCHAR2,
        o_title         OUT VARCHAR2,
        o_status_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_ext_exception EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, NULL);
    
        g_error := 'call get_receive_status for id_episode : ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_receive_status(i_lang           => i_lang,
                                  i_episode        => i_episode,
                                  i_transaction_id => l_transaction_id,
                                  o_status         => o_status,
                                  o_manual         => o_manual,
                                  o_title          => o_title,
                                  o_status_labels  => o_status_labels,
                                  o_error          => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
        pk_alertlog.log_debug(g_error);
        pk_schedule_api_upstream.do_commit(l_transaction_id, NULL);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, NULL);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_status_labels);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RECEIVE_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_status_labels);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, NULL);
            RETURN FALSE;
    END get_receive_status;

    /********************************************************************************************
    * Para um episódio obtém as perguntas obrigatórias para as quais ainda não foi dada uma resposta.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param o_unver_items      Cursor com as perguntas que ainda não foram respondidas
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_unverif_items
    (
        i_lang         IN language.id_language%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        o_unver_items  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_doc IS
            SELECT id_epis_documentation
              FROM epis_documentation
             WHERE id_doc_area = g_receive_doc_area
               AND id_episode = i_episode
             ORDER BY dt_creation_tstz DESC;
    
        l_id_epis_doc epis_documentation.id_epis_documentation%TYPE;
    BEGIN
        g_error := 'OPEN C_EPIS_DOC';
        pk_alertlog.log_debug(g_error);
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_id_epis_doc;
        g_found := c_epis_doc%FOUND;
        CLOSE c_epis_doc;
    
        IF g_found
        THEN
            g_error := 'GET UNVER_ITEMS';
            pk_alertlog.log_debug(g_error);
            OPEN o_unver_items FOR
                SELECT pk_translation.get_translation(i_lang, dc_par.code_doc_component) title,
                       pk_translation.get_translation(i_lang, dc.code_doc_component) item
                  FROM (SELECT DISTINCT de.id_documentation
                          FROM doc_element de
                         INNER JOIN doc_element_crit DEC
                            ON dec.id_doc_element = de.id_doc_element
                           AND dec.flg_mandatory = pk_alert_constant.g_yes
                         INNER JOIN documentation d
                            ON d.id_documentation = de.id_documentation
                         INNER JOIN doc_template_area_doc dtad
                            ON d.id_documentation = dtad.id_documentation
                         WHERE dtad.id_doc_area = g_receive_doc_area
                           AND dtad.id_doc_template = i_doc_template
                           AND d.flg_available = pk_alert_constant.g_available
                           AND d.id_documentation NOT IN
                               (SELECT edd.id_documentation
                                  FROM epis_documentation_det edd
                                 INNER JOIN doc_element_crit DEC
                                    ON dec.id_doc_element = edd.id_doc_element
                                   AND dec.flg_mandatory = pk_alert_constant.g_yes
                                 WHERE edd.id_epis_documentation = l_id_epis_doc) -- Identificador da última avaliação na EPIS_DOCUMENTATION
                           AND de.flg_available = pk_alert_constant.g_available) doc
                 INNER JOIN documentation d
                    ON d.id_documentation = doc.id_documentation
                 INNER JOIN doc_template_area_doc dtad
                    ON dtad.id_documentation = d.id_documentation
                 INNER JOIN doc_component dc
                    ON dc.id_doc_component = d.id_doc_component
                  LEFT JOIN (SELECT d.id_documentation, dc.code_doc_component
                               FROM documentation d
                              INNER JOIN doc_component dc
                                 ON dc.id_doc_component = d.id_doc_component
                              INNER JOIN doc_template_area_doc dtad
                                 ON dtad.id_documentation = d.id_documentation
                              WHERE dtad.id_doc_template = i_doc_template
                                AND dtad.id_doc_area = g_receive_doc_area
                                AND d.flg_available = pk_alert_constant.g_available) dc_par
                    ON dc_par.id_documentation = d.id_documentation_parent
                 WHERE dtad.id_doc_area = g_receive_doc_area
                   AND dtad.id_doc_template = i_doc_template
                 ORDER BY dtad.rank;
        ELSE
            g_error := 'GET UNVER_ITEMS';
            pk_alertlog.log_debug(g_error);
            OPEN o_unver_items FOR
                SELECT pk_translation.get_translation(i_lang, t.code_doc_component) item
                  FROM (SELECT DISTINCT d.id_documentation, dc.code_doc_component, dtad.rank
                          FROM documentation d
                         INNER JOIN doc_template_area_doc dtad
                            ON d.id_documentation = dtad.id_documentation
                         INNER JOIN doc_element de
                            ON de.id_documentation = d.id_documentation
                           AND de.flg_available = pk_alert_constant.g_available
                         INNER JOIN doc_element_crit DEC
                            ON dec.id_doc_element = de.id_doc_element
                           AND dec.flg_mandatory = pk_alert_constant.g_yes
                         INNER JOIN doc_component dc
                            ON dc.id_doc_component = d.id_doc_component
                         WHERE dtad.id_doc_area = g_receive_doc_area
                           AND d.flg_available = pk_alert_constant.g_available
                           AND dtad.id_doc_template = i_doc_template) t
                 ORDER BY t.rank;
        
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
                                              'GET_UNVERIF_RECV_ITEMS',
                                              o_error);
            pk_types.open_my_cursor(o_unver_items);
            RETURN FALSE;
        
    END get_unverif_items;

    /********************************************************************************************
    * Verifica se todas as checklist do master estão com estado Verificado. Se sim, altera também
    *   o estado do master para verificado
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_status           Indica o novo estado a criar. (Y- Admitido; N- Não admitido)
    * @param i_prof             ID do profissional, instituição e software
    * @param i_doc_template     Template id
    * @param i_test             Indica se deve ser feita a validação
    * @param o_flg_show         Y - existe msg para mostrar; N - não existe   
    * @param o_unverif_items    Cursor com os items não verificados
    * @param o_title            Título da mensagem
    * @param o_msg_text         Texto a apresentar no ecrã caso a lista de items não verificados não contenha elementos.
    * @param o_button           Botões a mostrar: N - não, R - lido, C - confirmado 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION set_sr_receive
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_status        IN VARCHAR2,
        i_prof          IN profissional,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_unverif_items OUT pk_types.cursor_type,
        o_title         OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_status         sr_receive.flg_status%TYPE;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        o_flg_show := 'N';
        o_button   := 'NC';
        -- Abre o cursor de saída, dado que em algumas situações ele não é preenchido.
        pk_types.open_my_cursor(o_unverif_items);
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CHECK TEST';
        pk_alertlog.log_debug(g_error);
        -- Apenas faz o teste se indicado pelo parametro de entrada e o create for para STATUS=Y
        IF i_test = pk_alert_constant.g_yes
           AND i_status = pk_alert_constant.g_yes
        THEN
            IF NOT check_receive_status(i_lang         => i_lang,
                                        i_episode      => i_episode,
                                        i_doc_template => i_doc_template,
                                        o_status       => l_status,
                                        o_flg_show     => o_flg_show,
                                        o_error        => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF o_flg_show = pk_alert_constant.g_yes
            THEN
                g_error := 'GET_UNVERIF_ITEMS';
                pk_alertlog.log_debug(g_error);
                IF NOT get_unverif_items(i_lang         => i_lang,
                                         i_episode      => i_episode,
                                         i_doc_template => i_doc_template,
                                         o_unver_items  => o_unverif_items,
                                         o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                o_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
                --
                RETURN TRUE;
            END IF;
        
        END IF;
    
        g_error := 'INSERT SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        IF NOT insert_sr_receive(i_lang           => i_lang,
                                 i_episode        => i_episode,
                                 i_status         => i_status,
                                 i_manual         => pk_alert_constant.g_yes,
                                 i_prof           => i_prof,
                                 i_transaction_id => l_transaction_id,
                                 o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'SET_SR_RECEIVE',
                                              o_error);
        
            pk_types.open_my_cursor(o_unverif_items);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_sr_receive;

    /********************************************************************************************
    * Função a ser chamada quando há uma actualização na avaliação de acolhimento para o bloco. Esta função 
    *   vai validar se o estado de admissão é automático e caso seja, valida se as perguntas obrigatórias 
    *   já foram respondidas e caso tenham sido, adiciona uma nova entrada à SR_RECEIVE.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_status           Indica o novo estado a criar. (Y- Admitido; N- Não admitido)
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_status           Estado da admissão (Y-Admitido; N-Não admitido)
    * @param o_manual           Indica se o estado de admissão é decorrente de intervenção manual ou 
    *                            validação automática. (Y-Manual; N-Automática)
    * @param o_unverif_items    Cursor com os items não verificados
    * @param o_title            Titulo da janela a apresentar caso O_UNVERIF_ITEMS tenha elementos
    * @param o_button           Botões a apresentar caso O_UNVERIF_ITEMS tenha elementos.  
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION update_receive
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_doc_template   IN doc_template.id_doc_template%TYPE,
        i_transaction_id IN VARCHAR2,
        o_status         OUT sr_receive.flg_status%TYPE,
        o_manual         OUT sr_receive.flg_manual%TYPE,
        o_unverif_items  OUT pk_types.cursor_type,
        o_title          OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_status         sr_receive.flg_status%TYPE;
        l_flg_show       VARCHAR2(1char);
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        o_button := 'NC';
        o_title  := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
    
        -- Valida se existem items por verificar.
        g_error := 'GET_UNVERIF_ITEMS';
        pk_alertlog.log_debug(g_error);
        IF NOT get_unverif_items(i_lang, i_episode, i_doc_template, o_unverif_items, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Obtém última informação da SR_RECEIVE para o episódio
        g_error := 'GET_SR_RECEIVE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_sr_receive(i_lang    => i_lang,
                              i_episode => i_episode,
                              o_status  => o_status,
                              o_manual  => o_manual,
                              o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF o_status = pk_alert_constant.g_yes
           AND o_manual = pk_alert_constant.g_yes
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'CHECK RECEIVE STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT check_receive_status(i_lang         => i_lang,
                                    i_episode      => i_episode,
                                    i_doc_template => i_doc_template,
                                    o_status       => l_status,
                                    o_flg_show     => l_flg_show,
                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CHECK STATUS';
        pk_alertlog.log_debug(g_error);
        IF o_status <> l_status
        THEN
            g_error := 'CREATE_SR_RECEIVE';
            pk_alertlog.log_debug(g_error);
            IF NOT insert_sr_receive(i_lang           => i_lang,
                                     i_episode        => i_episode,
                                     i_status         => l_status,
                                     i_manual         => pk_alert_constant.g_no,
                                     i_prof           => i_prof,
                                     i_transaction_id => l_transaction_id,
                                     o_error          => o_error)
            THEN
                RETURN FALSE;
            END IF;
            o_status := l_status;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'UPDATE_RECEIVE',
                                              o_error);
            pk_types.open_my_cursor(o_unverif_items);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END update_receive;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_sr_procedures;
/
