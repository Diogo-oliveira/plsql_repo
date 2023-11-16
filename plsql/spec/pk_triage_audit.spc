/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_triage_audit IS

    -- Author  : JOAO.EIRAS
    -- Created : 18-04-2007 11:55:35
    -- Purpose : Package para a auditoria da triagem

    TYPE t_quest_answer IS RECORD(
        question  pk_translation.t_desc_translation,
        answer    audit_quest_answer.answer%TYPE,
        t_comment audit_req_comment.t_comment%TYPE);
    TYPE tbl_quest_answer IS TABLE OF t_quest_answer;

    /**
    * Retorna todos os períodos auditados
    * 
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param o_periods (cursor) periodos auditados
    *        Colunas do cursor:
    *         - month mês
    *         - yes ano
    *         - period data com mês e anos indicados
    * @param o_error (string) mensagem de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_audited_periods
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        o_periods OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna os profissionais que podem fazer auditorias na instituição
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param o_auditors (cursor) com os auditores
    *        Colunas do cursor:
    *         - id_professional
    *         - name nome do profissional
    * @param o_min_profs (inteiro) número mínimo de auditores para realizar a auditoria
    * @param o_max_profs (inteiro) número máximo de auditores para realizar a auditoria
    * @param o_require_self (string) indica que o profissional que requisita a auditoria
    *        deve ser incluido automaticamente na listagem de auditores, e não removível
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_all_auditors
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_auditors     OUT pk_types.cursor_type,
        o_min_profs    OUT INTEGER,
        o_max_profs    OUT INTEGER,
        o_require_self OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Verifica se se pode realizar uma auditoria no intervalo de tempo especificado.
    * Valida o intervalo de tempo, verifica se há episódios por profissional suficientes
    * para se proceder à auditoria, verifica sobreposições com outras auditorias, verifica
    * se faltam auditar períodos, e outros
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_dt_begin (date)  data de início de intervalo
    * @param i_dt_end (date) data de fim de intervalo
    * @oaram i_auditors Array com ids de auditores (estes não podem ser auditados)
    * @param o_period período de auditoria (mês e ano)
    * @param o_flg_show (string) variavel booleana (Y,N) que indica se há uma mensagem a mostrar ao utilizador, 
    * @param o_msg_title (string) titulo da mensage a mostrar ao utilizador
    * @param o_msg (string) texto da mensagem a mostrar ao utilizador
    * @param o_button (string) flags que indicam os botões a mostrar ao utilizador com a imagem
    * @param o_error (string) mensagem de erro
    * @return (booleano) true (booleano) em caso de sucesso, false em caso de erro
    */
    FUNCTION check_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_auditors IN table_number,
        
        o_period OUT VARCHAR2,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna um cursor com a informação necessária para preencher a grelha das auditorias
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_period (date) periodo do qual se quer visualizar as auditorias.
    *        Este parametro é opcional. Passar a NULL caso não seja necessário
    * @param o_all_audits (cursor) com dados das auditorias para preencher a grelha
    *        Colunas do cursor:
    *         - id_audit_req id da auditoria
    *         - desc_audit_type nome da auditoria
    *         - dt_req data de requisição
    *         - dt_open data de abertura
    *         - dt_close data de fecho
    *         - dt_status data a apresentar na grelha, dependendo do estado
    *         - flg_status estado do auditoria
    *         - desc_status descrição do estado do auditoria
    *         - period periodo auditado
    *         - profs_names nomes dos auditores
    *         - has_cancel_notes indica se a auditoria tem notas de cancelamento, caso seja cancelada
    *         - rank inteiro para ordenação
    *         - avail_butt_ok indica se o botão de OK fica activo
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_all_audit_reqs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_period IN VARCHAR2,
        
        o_all_audits OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_can_create_audit_req
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN;
    /**
    * Criar requisição de auditoria
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_type (inteiro )tipo de auditoria que se pretende criar
    * @param i_dt_begin (date) data de inicio do intervalo a auditar
    * @param i_dt_end (date) data de fim do intervalo a auditar
    * @param i_auditors (array de inteiros) table_number com ids de auditores
    * @param o_audit_req (inteiro) id da nova requisição
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro. Atenção: falha pode também significar parametros invalidos
    */
    FUNCTION create_audit_req
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        -- i_audit_type IN audit_type.id_audit_type%TYPE,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_auditors  IN table_number,
        o_audit_req OUT audit_req.id_audit_req%TYPE,
        
        --o_flg_show  OUT VARCHAR2,
        --o_msg_title OUT VARCHAR2,
        --o_msg  OUT VARCHAR2,
        --o_button    OUT VARCHAR2,
        
        o_error OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**
    * Indica se as perguntas de um profissional foram todas respondidas e se pode proceder à retrospectiva
    * Não valida permissões do utilizador !
    * Apenas valida pela quantidade de dados preenchidos na auditoria indicada.
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof (inteiro) id da auditoria de profissional que se pretende analisar
    * @param i_professional (inteiro) id do profissional auditado do qual se quer verificar se se pode efectuar a retrospeciva
    * @param o_flg_show (string) variavel que indica se há mensagem a mostrar ao utilizador
    * @param o_msg_title (string) título da mensagem
    * @param o_msg_test (string) texto da mensagem a apresentar
    * @param o_button (string) flag com os tipos de botões a disponibilizar
    * @param o_result (string) variável com booleano 'N' ou 'Y' que indica, respectivamente, se a validação falhou, ou teve sucesso
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro. Atenção: falha pode também significar parametros invalidos
    */
    FUNCTION check_can_do_prof_retrosp
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Indica se uma auditoria pode ser fechada.
    * Não valida permissões do utilizador !
    * Apenas valida pela quantidade de dados preenchidos
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req (inteiro) id da auditoria que se pretende analisar
    * @param o_flg_show (string) variavel que indica se há mensagem a mostrar ao utilizador
    * @param o_msg_title (string) título da mensagem
    * @param o_msg (string) texto da mensagem a apresentar
    * @param o_button (string) flag com os tipos de botões a disponibilizar
    * @param o_result (string) variável com booleano 'N' ou 'Y' que indica, respectivamente, se a validação falhou, ou teve sucesso
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro. Atenção: falha pode também significar parametros invalidos
    */
    FUNCTION check_can_close_audit_req
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_result OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna o título e mensagem a apresentar no dialogo de confirmação de (re)abertura de auditoria
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req (inteiro) id da auditoria
    * @param o_msg_title (string) título da mensagem
    * @param o_msg (string) texto da mensagem a apresentar
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_open_audit_title
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Mudar estado de auditoria
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req (inteiro )id da auditoria
    * @param i_flg_status (string) novo estado. Todos os estados são validados,
    *        assim como as permissões do utilizador. Valores possíveis:
    *          - R - requisitada: resulta sempre em erro, pois uma auditoria fica requisitada quando é criada e nunca mais
    *          - A - aberta
    *          - F - fechada
    *          - C - cancelada
    *          - I - interrompida
    * @param i_notes_cancel (string) notas em caso de cancelamento
    * @param o_flg_show (string) variavel que indica se há mensagem a mostrar ao utilizador
    * @param o_msg_title (string) título da mensagem
    * @param o_msg_test (string) texto da mensagem a apresentar
    * @param o_button (string) flag com os tipos de botões a disponibilizar
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION set_audit_req_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_audit_req    IN audit_req.id_audit_req%TYPE,
        i_flg_status   IN audit_req.flg_status%TYPE,
        i_notes_cancel IN audit_req.notes_cancel%TYPE,
        
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Grava se o profissional tomou conhecimento ou não do resultado da auditoria em causa
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param (inteiro) id da auditoria ao profissional
    * @param (string) booleano Y/N que indica se o profissional tomou ou não conhecimento da auditoria
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION set_prof_saw_result
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        i_answer         IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna os icons para as respostas booleanas, e respectivos valores das respostas
    * 
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param o_icons (cursor) cursor com colunas
       - desc_val texto da respostas, tipo sim/não
       - val valor da respsotas, tipo Y/N
       - rank inteiro para ordenação
       - img_name nome do icon associado
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_criteria_icons
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_icons OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Lista os profissionais a ser auditados, na grelha de profissionais de uma auditoria
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req (inteiro) id da requisição de auditoria
    * @param o_profs (cursor) com linhas da grelha
    *        Colunas do cursor:
    *         - id_audit_req_prof id da auditoria do profissional
    *         - name nome do profissional
    *         - num_audited número de episódios que já foram auditados
    *         - num_to_audit número de episódios que faltam auditar
    *         - num_pri_ok número de prioridades correctas
    *         - num_pri_ans número de respostas à pergunta sobre as prioridades
    *         - perc_pri_ok percentagem de prioridades correctas
    *         - flg_saw_result indica se o profissional tomou conhecimento dos resultados da auditoria
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_list_audited_profs
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_audit_req IN audit_req.id_audit_req%TYPE,
        
        o_profs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_audited_prof_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof_epis.id_audit_req_prof%TYPE,
        
        o_det   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retorna a lista de questões a responder por retrospectiva de um profissional
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof (inteiro) id da auditoria de profissional
    * @param o_quests (cursor) lista de questões e respostas
    *        Colunas do cursor:
    *         - id_audit_criteria id da pergunta
    *         - desc_audit_criteria texto da pergunta
    *         - flg_ans_type tipo de resposta: B - booleana, Q - número
    *         - flg_ans_criteria critério que esta pergunta avalia. Ver comentário da coluna audit_criteria.flg_ans_criteria
    *         - answer_bool valor da resposta caso seja uma resposta booleana
    *         - answer_qnt_yes valor da resposta SIM caso seja a resposta seja um número
    *         - answer_qnt_no valor da resposta NÃO caso seja a resposta seja um número
    *         - answer_qnt_total número total de respostas à pergutna em causa (que corresponde ao número de episódios)
    *         - editable indica se a resposta a esta pergutna é introduzida pelo utilizador. Caso contrário é calculada automaticamente
    *         - has_notes indica que esta pergunta tem comentários gravados anteriormente
    * @param o_comments (cursor) comentários inseridos sobre esta auditoria de profissional
    *        Colunas do cursor:
    *         - t_comment text do comentário
    *         - dt_saved data de gravação
    *         - flg_status C - cancelado, N - normal
    *         - prof_name nome do profissional que fez este registo
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_list_quests_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        --o_flg_show  OUT VARCHAR2,
        --o_msg_title OUT VARCHAR2,
        --o_msg  OUT VARCHAR2,
        --o_button    OUT VARCHAR2,
        
        o_quests      OUT pk_types.cursor_type,
        o_comments    OUT pk_types.cursor_type,
        o_has_history OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Devolve as notas de uma pergunta sobre uma retrospectiva de um profissional
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof (inteiro) id da auditoria do profissional
    * @param i_audit_criteria (inteiro) id da pergunta
    * @param o_notes (cursor) com as notas
    *        Colunas do cursor:
    *         - t_comment text do comentário
    *         - dt_saved data de gravação
    *         - flg_status C - cancelado, N - normal
    *         - prof_name nome do profissional que fez este registo
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_quest_answer_prof_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        i_audit_criteria IN audit_criteria.id_audit_criteria%TYPE,
        
        o_notes OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Salva respostas a perguntas, sobre a retrospectiva de um profissional
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof (inteiro) id da auditoria do profissional
    * @param i_ids_criterias (array de inteiros) table_number com ids das questões
    * @param i_answers (array de strings) table_varchar com respostas, na mesma ordem dos ids guardados em i_ids_criterias
    * @param i_notes (array de strings) table_varchar com notas por pergunta
    * @param i_comment (string) comentário final sobre o episódio
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION set_quest_answer_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        i_ids_criterias IN table_number,
        i_answers       IN table_varchar,
        i_notes         IN table_varchar,
        i_comment       IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Lista os episódios de um profissional a ser auditados
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof (inteiro) id da auditoria do profissional
    * @param o_epis (cursor) com linhas da grelha
    *        Colunas do cursor:
    *         - id_audit_req_prof_epis is da auditoria do episódio
    *         - id_episode id do episódio
    *         - id_visit id da visita
    *         - id_patient id do paciente
    *         - pat_name nome do paciente
    *         - bi número de bi do paciente
    *         - id_ext_epis número de episódio externo
    *         - audit_ok indica se a auditoria a este episódio está compelta (todas as pergunta respondidas)
    *         - desc_audit_state texto a apresentar sobre o estado a auditoria deste episódio, que poderá ser "por auditar" ou "auditado"
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_list_audited_epis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_audit_req_prof IN audit_req_prof.id_audit_req_prof%TYPE,
        
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_audited_epis_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_det   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Lista as perguntas por episódio, já com as respostas previamente preenchidas, e comentários associado
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof_epis (inteiro) id da auditoria do episódio
    * @param o_quests (cursor) com as perguntas e respostas existentes
    *        Colunas do cursor:
    *         - id_audit_criteria id da pergunta
    *         - desc_audit_criteria texto da pergunta
    *         - flg_ans_type tipo de resposta: B - booleana, Q - número
    *         - flg_ans_criteria critério que esta pergunta avalia. Ver comentário da coluna audit_criteria.flg_ans_criteria
    *         - answer texto/valor da resposta
    *         - editable indica se a resposta a esta pergunta é introduzida pelo utilizador. Caso contrário é calculada automaticamente
    *         - has_notes indica que esta pergunta tem comentários gravados anteriormente
    * @param o_comments (cursor) com comentários sobre esta auditoria de episódio
    *        Colunas do cursor:
    *         - t_comment text do comentário
    *         - dt_saved data de gravação
    *         - flg_status C - cancelado, N - normal
    *         - prof_name nome do profissional que fez este registo
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_list_quests_epis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_quests      OUT pk_types.cursor_type,
        o_comments    OUT pk_types.cursor_type,
        o_has_history OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Devolve as notas de uma pergunta sobre um episódio
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof_epis (inteiro) id da auditoria do episódio
    * @param i_audit_criteria (inteiro) id da pergunta
    * @param o_notes (cursor) com os comentários sobre a pergunta em causa
    *        Colunas do cursor:
    *         - t_comment text do comentário
    *         - dt_saved data de gravação
    *         - flg_status C - cancelado, N - normal
    *         - prof_name nome do profissional que fez este registo
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_quest_answer_epis_notes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        i_audit_criteria      IN audit_criteria.id_audit_criteria%TYPE,
        
        o_notes OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Salva respostas a perguntas, sobre um episódio de um triador
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req_prof_epis (inteiro) id da auditoria do episódio
    * @param i_ids_criterias (array de inteiros) table_number com ids das questões
    * @param i_answers (array de strings) table_varchar com respostas, na mesma ordem dos ids guardados em i_ids_criterias
    * @param i_notes (array de strings) table_varchar com notas por pergunta
    * @param i_comment (string) comentário final sobre o episódio
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION set_quest_answer_epis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_audit_req_prof_epis IN audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        i_ids_criterias IN table_number,
        i_answers       IN table_varchar,
        i_notes         IN table_varchar,
        i_comment       IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Função que retorna dados para preencher o cabeçalho
    *
    * @param i_lang (inteiro) id da lingua das mensagens
    * @param i_prof (objecto) dados do utilizador
    * @param i_audit_req (inteiro) id da auditoria
    * @param i_audit_req_prof (inteiro) id da auditoria do profissional
    * @param i_audit_req_prof_epis (inteiro) id da auditoria do episódio
    *
    * @param o_prof_photo (string) url para a fotografia do utilizador
    * @param o_prof_name (string) nome do utilizador
    * @param o_prof_nick_name (string) nome do utilizador
    * @param o_prof_spec (string) especialidade do utilizador
    * @param o_prof_inst (string) instituição do utilizador
    * @param o_prof_inst_abbr (string) abreviação da instituição do utilizador
    *
    * @param o_audit_type (string) título do tipo de auditoria
    * @param o_title_period (string) título "Período"
    * @param o_period (string) perído da auditoria, em data formatada
    *
    * @param o_adt_prof_name (string) nome do profissional auditado
    * @param o_adt_prof_photo (string) url da fotografia do profissional auditado
    * @param o_adt_prof_gender (string) sexo
    * @param o_adt_prof_age (string) idade do profissional
    *
    * @param o_title_pat_name (string) título "Nome" do paciente
    * @param o_pat_name (string) nome do paciente
    *
    * @param o_title_epis_anamnesis (string) titulo "Diagnostico" ou "Queixa" conforme aplicável
    * @param o_epis_anamnesis (string) diagnostico ou queixa do paciente
    *
    * @param o_title_id_epis_ext_sys (string) título "Episódio" do paciente
    * @param o_id_epis_ext_sys (string) número de episódio externo do paciente
    *
    * @param o_error (string) variavel com mensagen de erro
    * @return (booleano) true em caso de sucesso, false em caso de erro
    */
    FUNCTION get_header
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        
        i_audit_req           audit_req.id_audit_req%TYPE,
        i_audit_req_prof      audit_req_prof.id_audit_req_prof%TYPE,
        i_audit_req_prof_epis audit_req_prof_epis.id_audit_req_prof_epis%TYPE,
        
        o_prof_photo     OUT VARCHAR2,
        o_prof_name      OUT VARCHAR2,
        o_prof_nick_name OUT VARCHAR2,
        o_prof_spec      OUT VARCHAR2,
        o_prof_inst      OUT VARCHAR2,
        o_prof_inst_abbr OUT VARCHAR2,
        
        o_audit_type        OUT VARCHAR2,
        o_title_period      OUT VARCHAR2,
        o_title_desc_period OUT VARCHAR2,
        o_period_begin      OUT VARCHAR2,
        o_period_end        OUT VARCHAR2,
        
        o_adt_prof_name   OUT VARCHAR2,
        o_adt_prof_photo  OUT VARCHAR2,
        o_adt_prof_gender OUT patient.gender%TYPE,
        o_adt_prof_age    OUT NUMBER,
        
        o_title_pat_name OUT VARCHAR2,
        o_pat_name       OUT VARCHAR2,
        
        o_title_epis_anamnesis OUT VARCHAR2,
        o_epis_anamnesis       OUT VARCHAR2,
        
        o_title_id_epis_ext_sys OUT VARCHAR2,
        o_id_epis_ext_sys       OUT VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --Função para o Rui Pereira.
    FUNCTION test_complex_cursor
    (
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Checks if exists any audit open    
    *
    * @param      i_lang           language   
    * @param      i_prof           professional
    *
    * @return     'Y' can create, 'N' cannot create
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/07/23
    ***********************************************************************************************************/

    FUNCTION check_can_create
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /******************************************************************************
    * Returns the IDs of the reports that depend on ID_AUDIT_REQ, 
    * ID_AUDIT_REQ_PROF_EPIS and ID_AUDIT_REQ_PROF.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_reports         Report IDs that depend on ID_AUDIT_REQ
    * @param o_reports_audit   Report IDs that depend on ID_AUDIT_REQ_PROF
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2008-11-25
    *
    ******************************************************************************/
    FUNCTION get_audit_reports
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_reports       OUT pk_types.cursor_type,
        o_reports_audit OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
      Globais / Constantes
    **/
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_exception EXCEPTION;

    g_owner        VARCHAR2(200);
    g_package_name VARCHAR2(200);

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';
    g_date_mask VARCHAR2(16) := 'YYYYMMDDHH24MISS';

    g_prof_flg_active CONSTANT professional.flg_state%TYPE := 'A';

    g_epis_stat_active   CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_stat_inactive CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_stat_cancel   CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_stat_pend     CONSTANT episode.flg_status%TYPE := 'P';

    g_adt_req_open  CONSTANT audit_req.flg_status%TYPE := 'A';
    g_adt_req_req   CONSTANT audit_req.flg_status%TYPE := 'R';
    g_adt_req_close CONSTANT audit_req.flg_status%TYPE := 'F';
    g_adt_req_intr  CONSTANT audit_req.flg_status%TYPE := 'I';
    g_adt_req_canc  CONSTANT audit_req.flg_status%TYPE := 'C';

    g_adt_req_prf_rel_auditor CONSTANT audit_req_prof.flg_rel_type%TYPE := 'A';
    g_adt_req_prf_rel_audited CONSTANT audit_req_prof.flg_rel_type%TYPE := 'D';

    g_adt_quest_for_epis CONSTANT audit_criteria.flg_for%TYPE := 'E';
    g_adt_quest_for_prof CONSTANT audit_criteria.flg_for%TYPE := 'P';
    g_adt_quest_for_adt  CONSTANT audit_criteria.flg_for%TYPE := 'A';

    g_adt_quest_tp_bool CONSTANT audit_criteria.flg_ans_type%TYPE := 'B';
    g_adt_quest_tp_txt  CONSTANT audit_criteria.flg_ans_type%TYPE := 'B';
    g_adt_quest_tp_qnt  CONSTANT audit_criteria.flg_ans_type%TYPE := 'Q';

    g_adt_req_cmt_flg_norm CONSTANT audit_req_comment.flg_status%TYPE := 'N';
    g_adt_req_cmt_flg_canc CONSTANT audit_req_comment.flg_status%TYPE := 'C';

    g_adt_qt_crit_flx      CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'F'; --fluxogramas
    g_adt_qt_crit_dsc      CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'D'; --discriminadores
    g_adt_qt_crit_pri      CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'P'; --prioridades
    g_adt_qt_crit_pain     CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'R'; --Regua da dor
    g_adt_qt_crit_repain   CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'O'; --Reavaliação da dor
    g_adt_qt_crit_doc_read CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'L'; --documentação legível
    g_adt_qt_crit_rtr      CONSTANT audit_criteria.flg_ans_criteria%TYPE := 'T'; --retriagem

    g_adt_qt_for_epis CONSTANT audit_criteria.flg_for%TYPE := 'E';
    g_adt_qt_for_prof CONSTANT audit_criteria.flg_for%TYPE := 'P';
    g_adt_qt_for_adt  CONSTANT audit_criteria.flg_for%TYPE := 'A';

    g_soft_edis CONSTANT software.id_software%TYPE := 8;

END pk_triage_audit;
/
