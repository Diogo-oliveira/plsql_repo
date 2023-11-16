/*-- Last Change Revision: $Rev: 2028663 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_proc AS

    TYPE rec_arrive IS RECORD(
        id_transportation      transportation.id_transportation%TYPE,
        dt_transportation_tstz transportation.dt_transportation_tstz%TYPE,
        id_professional        transportation.id_professional%TYPE,
        id_transp_entity       transportation.id_transp_entity%TYPE,
        transp_entity          pk_translation.t_desc_translation,
        flg_time               transportation.flg_time%TYPE,
        notes                  transportation.notes%TYPE,
        id_external_cause      visit.id_external_cause%TYPE,
        external_cause_desc    pk_translation.t_desc_translation,
        id_origin              visit.id_origin%TYPE,
        origin_desc            pk_translation.t_desc_translation,
        companion              epis_info.companion%TYPE,
        flg_show_detail        VARCHAR2(1 CHAR),
        flg_letter             epis_triage.flg_letter%TYPE,
        desc_letter            sys_domain.desc_val%TYPE,
        triage_origin_desc     epis_triage.desc_origin%TYPE,
        emergency_contact      epis_triage.emergency_contact%TYPE);

    TYPE cursor_arrive IS REF CURSOR RETURN rec_arrive;

    TYPE table_arrive IS TABLE OF rec_arrive;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_arrive);

    /**********************************************************************************************
    * Retornar os dados para o cabeçalho da aplicação
    *
    * @param i_lang                   the id language
    * @param i_id_pat                 patient id
    * @param i_id_episode             episode id
    * @param i_prof                   professional, software and institution ids
    * @param o_name                   patient name
    * @param o_gender                 patient gender
    * @param o_age                    patient age
    * @param o_health_plan            subsistema de saúde do utente. Se houver + do q 1, considera-se o q tiver FLG_DEFAULT = 'S'
    * @param o_compl_pain             Quaica completa
    * @param o_info_adic              Informação adicional (descrição da categoria + data da última alteração +nome do profissional)
    * @param o_cat_prof               professional category
    * @param o_cat_nurse              nurse category
    * @param o_compl_diag             Diagnosis
    * @param o_prof_name              professional name
    * @param o_nurse_name             nurse name
    * @param o_prof_spec              professional speciality
    * @param o_nurse_spec             nurse speciality
    * @param o_acuity                 acuity
    * @param o_color_text             color text
    * @param o_desc_acuity            acuity description
    * @param o_title_episode          number of episodes title
    * @param o_episode                number of episodes
    * @param o_title_clin_rec         clin record title
    * @param o_clin_rec               clin record number of the patient
    * @param o_title_location         name of the location where the patient's at title
    * @param o_location               name of the location where the patient's at
    * @param o_title_time_room        title for length of stay
    * @param o_time_room              length of stay of the patient in it's current room
    * @param o_title_admit            title for the admission time field
    * @param o_admit                  date/hour of patient admission in th service
    * @param o_title_total_time       title of the episode duration
    * @param o_total_time             episode duration
    * @param o_pat_photo              patient photo
    * @param o_prof_photo             professional photo
    * @param o_habit                  nº of habit
    * @param o_allergy                nº of allergy
    * @param o_prev_epis              nº of previous episode
    * @param o_relev_disease          nº of relevant disease
    * @param o_blood_type             tipo sanguíneo
    * @param o_relev_note             relevant notes
    * @param o_application            application area
    * @param o_info
    * @param o_nkda                   indicação de "Sem alergias a fármacos"
    * @param o_origin                 Indicação se o episódio advem de um Centro de Saúde
    * @param o_has_adv_directives     Flag that tells if the patient has any advanced directives
    * @param o_adv_directive_sh       Advanced directives shortcut
    * @param o_title_adv_directive    Advanced directives title
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/02
    **********************************************************************************************/
    FUNCTION get_epis_header
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_age         OUT VARCHAR2,
        o_health_plan OUT VARCHAR2,
        o_dbo         OUT VARCHAR2,
        o_compl_pain  OUT VARCHAR2,
        o_info_adic   OUT VARCHAR2,
        o_cat_prof    OUT VARCHAR2,
        o_cat_nurse   OUT VARCHAR2,
        o_compl_diag  OUT VARCHAR2,
        o_prof_name   OUT VARCHAR2,
        o_nurse_name  OUT VARCHAR2,
        o_prof_spec   OUT VARCHAR2,
        o_nurse_spec  OUT VARCHAR2,
        o_acuity      OUT VARCHAR2,
        o_color_text  OUT VARCHAR2,
        o_desc_acuity OUT VARCHAR2,
        --
        o_title_episode    OUT VARCHAR2,
        o_episode          OUT VARCHAR2,
        o_title_clin_rec   OUT VARCHAR2,
        o_clin_rec         OUT VARCHAR2,
        o_title_location   OUT VARCHAR2,
        o_location         OUT VARCHAR2,
        o_title_time_room  OUT VARCHAR2,
        o_time_room        OUT VARCHAR2,
        o_title_admit      OUT VARCHAR2,
        o_admit            OUT VARCHAR2,
        o_title_total_time OUT VARCHAR2,
        o_total_time       OUT VARCHAR2,
        --
        o_pat_photo           OUT VARCHAR2,
        o_prof_photo          OUT VARCHAR2,
        o_habit               OUT VARCHAR2,
        o_allergy             OUT VARCHAR2,
        o_prev_epis           OUT VARCHAR2,
        o_relev_disease       OUT VARCHAR2,
        o_blood_type          OUT VARCHAR2,
        o_relev_note          OUT VARCHAR2,
        o_application         OUT VARCHAR2,
        o_info                OUT VARCHAR2,
        o_nkda                OUT VARCHAR2,
        o_origin              OUT VARCHAR2,
        o_has_adv_directives  OUT VARCHAR2,
        o_adv_directive_sh    OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_title_adv_directive OUT VARCHAR2,
        o_icon_fast_track     OUT VARCHAR2,
        o_desc_fast_track     OUT VARCHAR2,
        o_flg_status          OUT episode.flg_status%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados
    * @param o_flg_disch_pend         flag que determina se a alta pendente aparece ou nao na grelha
                                               N- aparece tranportes Y- pararece a alta pendente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/05
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_disch_pend  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pat_criteria_active_clin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_patcriteriaactiveclin;
    --
    /**********************************************************************************************
    * Contagem de pacientes por sala e por sexo
    *
    * @param i_prof                   professional, software and institution ids
    * @param i_gender                 gender
    * @param i_room                   room id
    *
    * @return                         value
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_patient_count
    (
        i_prof   IN profissional,
        i_gender IN patient.gender%TYPE,
        i_room   IN room.id_room%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Contagem dos profissionais por sala
    *
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    * @param i_type_prof              Types of professionals
    *
    * @return                         value
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/05/31
    **********************************************************************************************/
    FUNCTION get_professional_count
    (
        i_prof      IN profissional,
        i_room      IN room.id_room%TYPE,
        i_type_prof IN VARCHAR2
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    *  Obter a descrição da categoria do profissional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_prof                professional id
    * @param o_cat                    category description
    * @param o_flg_type               type of category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2006/06/07
    **********************************************************************************************/
    FUNCTION get_category_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_prof  IN professional.id_professional%TYPE,
        o_cat      OUT VARCHAR2,
        o_flg_type OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Registar para um dado episódio o detalhe do transporte de chegada
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param i_dt_transportation      Data do transporte
    * @param i_id_transp_entity       Transporte entidade
    * @param i_flg_time               E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes                  notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/06/20
    **********************************************************************************************/
    FUNCTION create_transportation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar o detalhe do último transporte de chegada registado para um episódio clinico
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param o_transp                 cursor with all information of last transport
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/06/20
    **********************************************************************************************/
    FUNCTION get_transportation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_transp  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar as cores / detalhe, disponiveis para o cabeçalho conforme o tipo de triagem : Manchester ou Triage Nurse
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_head_col               cursor with all cabeçalho das cores, bem como toda a informação a elas associadas
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/06/22
    **********************************************************************************************/
    FUNCTION get_chart_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_room     IN room.id_room%TYPE,
        o_head_col OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Contagem de pacientes para cada côr
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_type               Tipo de listagem: M - My Patients; A - All Patients; R - Por sala
    * @param i_color                  color id
    * @param i_room                   room id
    * @param o_pat                    patient id
    * @param o_color                  color detail
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/06/23
    **********************************************************************************************/
    FUNCTION get_chart_pat_color
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_color    IN triage_color.id_triage_color%TYPE,
        i_room     IN room.id_room%TYPE,
        o_pat      OUT NUMBER,
        o_color    OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os episódios inactivos e pendentes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_epis_inact             array with inactive episodes
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados
    * @param o_flg_show
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/10/06
    **********************************************************************************************/
    FUNCTION get_epis_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_epis_inactive
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN CLOB,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_episinactive;
    --
    /**********************************************************************************************
    * Listar todos os episódios inactivos e pendentes para um determinado paciente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_epis_inact             cursor with episódios inactivos de um paciente
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Emilia Taborda
    * @version                        1.0
    * @since                          2006/08/10
    * @notes                          Os episódios onde se podem registar notas pós-alta são:os que têm origem no software (I_PROF.SOFTWARE)
                                                                                             ou que têm como EPISODE.ID_EPISODE_ORIGIN
                                                                                             um episódio originado no software (I_PROF_.SOFTWARE).
                                      Nem todas as categorias de profissionais podem fazer reaberturas.
                                      Essa validação é feita posteriormente.
                                      Não considerar altas canceladas.
    **********************************************************************************************/
    FUNCTION get_epis_pat_inactive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter todos os diagnósticos finais de um episódio inactivo
    *
    * @param i_lang                 the id language
    * @param i_episode              episode id
    *
    * @return                       diagnosis description
    *
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        2006/12/20
    **********************************************************************************************/
    FUNCTION get_epis_inact_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Listar todos os meus episódios INACTIVOS nas últimas 24 horas (Episódios de Urgência e de internamento)
    *
    * @param i_lang                 the id language
    * @param i_prof                 professional, software and institution ids
    * @param i_type_inactive        Tipo de pesquisa de inactivos: MI24 - Meus doentes nas últimas 24 horas
                                                                   I24 -  doentes nas últimas 24 horas
    * @param i_prof_cat_type        professional category
    * @param o_epis_inact           cursor with all episode inactiv
    * @param o_error                Error message
    *
    * @return                       TRUE if sucess, FALSE otherwise
    *
    * @author                       Emília Taborda
    * @version                      1.0
    * @since                        2007/01/22
    **********************************************************************************************/
    FUNCTION get_epis_inactive_24
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_inactive IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_epis_inact    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter todas as queixas de um episódio
    *
    * @param i_lang             language id
    * @param i_prof             professional, software and institution ids
    * @param i_episode          episode id
    *
    * @return                   description
    *
    * @author                   Emília Taborda
    * @version                  1.0
    * @since                    2007/01/19
    *
    * @author                   José Silva
    * @version                  2.5.1.2
    * @since                    2010/10/27
    **********************************************************************************************/
    FUNCTION get_epis_anamnesis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB;
    --
    /**********************************************************************************************
    * Obter todas os diagnósticos de saída (finais) de um episódio (concatenação)
    *
    * @param i_episode          episode id
    * @param i_institution      institution id
    * @param i_software         software id
    *
    * @return                   description
    *
    * @author                   Emília Taborda
    * @version                  1.0
    * @since                    2007/01/23
    **********************************************************************************************/
    FUNCTION get_epis_diag_concat
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2;
    --
    /**********************************************************************************************
    * Registar a informação de chegada do episódio
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Luis Gaspar
    * @version                  1.0
    * @since                    2007/02/21
    **********************************************************************************************/
    FUNCTION set_arrive
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * DATABASE INTERNAL FUNCION. Register the data about the arrival of the patient.
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param i_internal_type     Called from (A) Arrived by (T) Triage
    * @param i_sysdate           Current date
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   José Brito (using SET_ARRIVE by Luís Gaspar)
    * @version                  2.6.0
    * @since                    2009/12/07
    **********************************************************************************************/
    FUNCTION set_arrive_internal
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        i_internal_type         IN VARCHAR2, -- (A) Arrived by (T) Triage
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_id_transportation     OUT transportation.id_transportation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Show history of all records added in "Arrived by".
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_epis                Episode ID
    * @param o_detail                 "Arrived by" history
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        1.0
    * @since                          2009/05/29
    **********************************************************************************************/
    FUNCTION get_arrived_by_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar o detalhe da informação de chegada do episódio.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_epis                episode id
    * @param o_arrive                 cursor with toda a informação associada à chegada do episódio
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007/02/22
    **********************************************************************************************/
    FUNCTION get_arrive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE,
        o_arrive  OUT cursor_arrive,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * listar todos os episódios inactivos de urgência ou com origem na urgência (obs)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_epis_inact             array with inactive episodes admin
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados
    * @param o_flg_show
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007/02/23
    **********************************************************************************************/
    FUNCTION get_epis_inactive_admin
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_inact      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os episódios INACTIVOS para um determinado paciente que pertencem ao tipo de episódio associado ao software que realiza o pedido
      ou têm origem num episódio com tipo de episódio associado ao software que realiza o pedido
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_epis_inact             cursor with episodes inactives
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007-02-22
    * @notes                          Os episódios que podem ter notas pós-alta são: os que têm origem no software (I_PROF.SOFTWARE)
                                                                                     ou que têm como EPISODE.ID_EPISODE_ORIGIN um episódio originado
                                                                                     no software (I_PROF_.SOFTWARE).
                                      Nem todas as categorias de profissionais podem fazer reaberturas.Essa validação é feita posteriormente.
                                      Não considerar altas canceladas.
    **********************************************************************************************/
    FUNCTION get_epis_pat_inactive_admin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_epis_inact OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar todos os meus episódios INACTIVOS nas últimas 24 horas para um determinado paciente
      que pertencem ao tipo de episódio associado ao software que realiza o pedido
      ou têm origem num episódio com tipo de episódio associado ao software que realiza o pedido
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_type_inactive          Tipo de pesquisa de inactivos:MI24 - Meus doentes nas últimas 24 horas
                                                                    I24 -  doentes nas últimas 24 horas
    * @param i_prof_cat_type          professional categoty
    * @param o_epis_inact             cursor with episodes inactives
    * @param o_error                  Error message
    *
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2007/02/23
    **********************************************************************************************/
    FUNCTION get_epis_inactive_24_admin
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_inactive IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_epis_inact    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal administrativo
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category
    * @param o_flg_show
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_pat                    cursor with active patient
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados
    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luis Gaspar
    * @version                        1.0
    * @since                          2006/02/26
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_admin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_pat_criteria_active_admin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_patcriteriaactiveadmin;
    --

    /**********************************************************************************************
    * Search for on-call physicians.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_id_sys_btn_crit        Search criteria ID's
    * @param i_crit_val               Search criteria values
    * @param o_flg_show               Show message: (Y) yes (N) no
    * @param o_msg                    Message
    * @param o_msg_title              Message title
    * @param o_button                 Button type
    * @param o_list                   Cursor with search results
    * @param o_mess_no_result         Message to show when search doesn't return results
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito [Based on GET_PAT_CRITERIA_ACTIVE_ADMIN]
    * @version                        1.0
    * @since                          2009/03/31
    **********************************************************************************************/
    FUNCTION get_on_call_physician_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_on_call_physician_criteria
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2
    ) RETURN t_coll_oncallphysiciancriteria;

    /**********************************************************************************************
    * Retornar episódios fechados de um doente
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_pat                    patient id
    * @param i_institution            institution id
    * @param i_software               software id
    *
    * @return                         value
    *
    * @author                         Emília Taborda
    * @version                        1.0
    * @since                          2007/05/03
    **********************************************************************************************/
    FUNCTION get_prev_episode
    (
        i_lang        IN language.id_language%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Contagem de pacientes por sala e por idade
    *
    * @param i_prof             professional, software and institution ids
    * @param i_adult_child      A - Adulto; C - Criança
    * @param i_room             room id
    *
    * @return                   value
    *
    * @author                   Teresa Coutinho
    * @version                  1.0
    * @since                    2007/06/06
    **********************************************************************************************/
    FUNCTION get_adult_child_count
    (
        i_prof        IN profissional,
        i_adult_child IN VARCHAR2,
        i_room        IN room.id_room%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Returns search results for cancelled episodes.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        search criteria ID's
    * @param i_crit_val               search criteria values
    * @param i_dt                     date to search
    * @param o_msg
    * @param o_msg_title
    * @param o_button
    * @param o_epis_cancel            array with cancelled episodes
    * @param o_mess_no_result         message to show when there's no results
    * @param o_flg_show
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucessfull, FALSE otherwise
    *
    * @author                         José Brito [based on GET_PAT_CRITERIA_ACTIVE_ADMIN by Luís Gaspar]
    * @version                        1.0
    * @since                          2008/04/22
    **********************************************************************************************/
    FUNCTION get_epis_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_epis_cancelled
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2,
        i_hint  IN VARCHAR2
    ) RETURN t_coll_episcancelled;
    --
    /********************************************************************************************
    * Checks if the professional can access the reopen functionality
    *
    * @param i_lang                  language id
    * @param i_prof                  professional, software and institution ids
    * @param i_episode               episode id
    * @param i_epis_software         episode software
    *
    * @return                        flg_reopen: Y - can access reopen popup ; N - can't access reopen popup
    *
    * @author                        José Silva
    * @version                       1.0
    * @since                         24-04-2008
    ********************************************************************************************/
    FUNCTION check_flg_reopen
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_epis_software IN epis_type_soft_inst.id_software%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Changes the episode id_dep_clin_serv 
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_episode               episode id
    * @param i_dep_clin_serv         id_dep_clin_serv
    *
    * @return                        TRUE/ FALSE
    *
    * @author                        Elisabete Bugalho
    * @version                       1.0    
    * @since                        11-10-2012
    ********************************************************************************************/
    FUNCTION set_epis_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Calculates length of stay of the patient
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_id_episode            episode id
    * @param i_dt_begin              Optional begin date (used in lenght of stay in a room)
    * @param i_dt_end                Optional end date (used in lenght of stay in a room)
    * @param i_flg_sort              Optional flag that decides what is returned. Y - numeric value for sorting; N (default) - string value for display in grids
    *
    * @return                        TRUE/ FALSE
    *
    * @author                        Sergio Dias
    * @version                       2.6.3.7.1
    * @since                         11-10-2012
    ********************************************************************************************/
    FUNCTION get_los_duration
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN movement.dt_end_tstz%TYPE DEFAULT NULL,
        i_dt_end     IN episode.dt_end_tstz%TYPE DEFAULT NULL,
        i_flg_sort   IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Calculates string to sort grids (LOS and patient age)
    *
    * @param i_lang                  language id   
    * @param i_prof                  professional, software and institution ids 
    * @param i_type                  Type of call: A - patient age call, L - LOS call
    * @param i_id_episode            Episode id
    *
    * @return                        concattenated string
    *
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         19-9-2014
    ********************************************************************************************/
    FUNCTION get_formatted_string_for_sort
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_type    IN VARCHAR2,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_los_duration_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_dt_begin   IN movement.dt_end_tstz%TYPE DEFAULT NULL,
        i_dt_end     IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /**
      Globais
    **/
    g_no_results   BOOLEAN;
    g_overlimit    BOOLEAN;
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_date_mask CONSTANT VARCHAR2(16) := 'YYYYMMDDHH24MISS';
    g_exception EXCEPTION;
    --
    g_yes        CONSTANT VARCHAR2(1) := 'Y';
    g_no         CONSTANT VARCHAR2(1) := 'N';
    g_cancelled  CONSTANT VARCHAR2(1) := 'C';
    g_flg_active CONSTANT VARCHAR2(1) := 'A';
    --
    g_prof_active             CONSTANT prof_institution.flg_state%TYPE := 'A';
    g_category_avail          CONSTANT category.flg_available%TYPE := 'Y';
    g_prof_cat_doctor         CONSTANT category.flg_type%TYPE := 'D';
    g_prof_cat_administrative CONSTANT category.flg_type%TYPE := 'A';
    g_prof_cat_manchester     CONSTANT category.flg_type%TYPE := 'M';
    g_prof_cat_nurse          CONSTANT category.flg_type%TYPE := 'N';
    g_cat_prof                CONSTANT category.flg_prof%TYPE := 'Y';
    g_flg_available           CONSTANT identification_notes.flg_available%TYPE := 'Y';
    --
    g_soft_care   CONSTANT software.code_software%TYPE := 3;
    g_soft_edis   CONSTANT software.code_software%TYPE := 8;
    g_soft_inp    CONSTANT software.code_software%TYPE := 11;
    g_soft_ubu    CONSTANT software.code_software%TYPE := 29;
    g_soft_triage CONSTANT software.code_software%TYPE := 35;
    g_soft_pharm  CONSTANT software.code_software%TYPE := 20;
    --
    g_epis_type_edis CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_inp  CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_epis_type_ubu  CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_epis_type_urg  CONSTANT epis_type.id_epis_type%TYPE := 2;
    --
    g_profile_edis_anciliary CONSTANT profile_template.id_profile_template%TYPE := 402;
    --
    g_no_triage            CONSTANT VARCHAR2(200) := '0x787864';
    g_no_triage_color_text CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_no_color_rank        CONSTANT triage_color.rank%TYPE := 999;
    g_no_triage_color_id   CONSTANT triage_color.id_triage_color%TYPE := 9;
    g_color_available      CONSTANT triage_color.flg_available%TYPE := 'Y';
    g_tr_color_flg_show    CONSTANT triage_color.flg_show%TYPE := 'Y';
    g_id_no_triage         CONSTANT triage_color.id_triage_color%TYPE := 9;
    g_id_no_triage_nurse   CONSTANT triage_color.id_triage_color%TYPE := 14;
    --
    g_inactive_24  CONSTANT VARCHAR2(12) := 'I24';
    g_inactive_m24 CONSTANT VARCHAR2(12) := 'MI24';
    --
    g_default_hplan_n  CONSTANT pat_health_plan.flg_default%TYPE := 'N';
    g_default_hplan_y  CONSTANT pat_health_plan.flg_default%TYPE := 'Y';
    g_hplan_active     CONSTANT pat_health_plan.flg_status%TYPE := 'A';
    g_hplan_inactive   CONSTANT pat_health_plan.flg_status%TYPE := 'I';
    g_patient_active   CONSTANT patient.flg_status%TYPE := 'A';
    g_pat_blood_active CONSTANT pat_blood_group.flg_status%TYPE := 'A';

    g_pat_hist_diag_type_med CONSTANT pat_history_diagnosis.flg_type%TYPE := 'M';

    g_episode_flg_type_def  CONSTANT episode.flg_type%TYPE := 'D';
    g_episode_flg_type_temp CONSTANT episode.flg_type%TYPE := 'T';
    g_epis_active           CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_inactive         CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending          CONSTANT episode.flg_status%TYPE := 'P';
    --
    g_epis_anam_type_complaint CONSTANT epis_anamnesis.flg_type%TYPE := 'C';
    g_epis_anam_def            CONSTANT epis_anamnesis.flg_temp%TYPE := 'D';
    g_epis_anam_temp           CONSTANT epis_anamnesis.flg_temp%TYPE := 'T';
    g_epis_anam_status_active  CONSTANT epis_anamnesis.flg_status%TYPE := 'A';

    g_epis_complaint_active CONSTANT epis_complaint.flg_status%TYPE := 'A';

    g_epis_diag_type_definitive CONSTANT epis_diagnosis.flg_type%TYPE := 'D';
    g_epis_diag_type_probable   CONSTANT epis_diagnosis.flg_type%TYPE := 'P';

    g_epis_diag_act       CONSTANT epis_diagnosis.flg_status%TYPE := 'A';
    g_epis_diag_base      CONSTANT epis_diagnosis.flg_status%TYPE := 'B';
    g_epis_diag_confirmed CONSTANT epis_diagnosis.flg_status%TYPE := 'F';
    g_epis_diag_despiste  CONSTANT epis_diagnosis.flg_status%TYPE := 'D';

    g_epis_diag_final_type_primary CONSTANT epis_diagnosis.flg_final_type%TYPE := 'P';
    g_epis_diag_final_type_sec     CONSTANT epis_diagnosis.flg_final_type%TYPE := 'S';
    --
    g_discharge_flg_status_active CONSTANT discharge.flg_status%TYPE := 'A';
    g_discharge_flg_status_pend   CONSTANT discharge.flg_status%TYPE := 'P';
    g_discharge_flg_status_reopen CONSTANT discharge.flg_status%TYPE := 'R';
    --
    g_discharge_disch_type_triage CONSTANT discharge.flg_type_disch%TYPE := 'T';
    --
    g_movem_term CONSTANT movement.flg_status%TYPE := 'F';
    --
    g_flg_type_cons CONSTANT VARCHAR2(20) := 'CONS';

    g_task_analysis CONSTANT VARCHAR2(1) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1) := 'H';
    --
    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';

    g_icon_ft          CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer CONSTANT VARCHAR2(1) := 'T';
    g_desc_header      CONSTANT VARCHAR2(1) := 'H';
    g_desc_grid        CONSTANT VARCHAR2(1) := 'G';
    g_ft_color         CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white  CONSTANT VARCHAR2(200) := '0x787864';
    g_ubu_color        CONSTANT triage_color.color%TYPE := '0xE78284';
    g_ft_status        CONSTANT VARCHAR2(1) := 'A';
    --
    g_inst_type_h CONSTANT institution.flg_type%TYPE := 'H';
    --
    g_domain_nurse_act CONSTANT sys_domain.code_domain%TYPE := 'NURSE_ACTIVITY_REQ.FLG_STATUS';
    --
    g_transfer_inst_transp CONSTANT transfer_institution.flg_status%TYPE := 'T';
    --
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';

    g_flg_type_appointment_type CONSTANT doc_area_inst_soft.flg_type%TYPE := 'A';
    g_flg_type_specialty        CONSTANT doc_template_context.flg_type%TYPE := 'S';

    g_sort_type_los CONSTANT doc_template_context.flg_type%TYPE := 'L';
    g_sort_type_age CONSTANT doc_template_context.flg_type%TYPE := 'A';
END pk_edis_proc;
/
