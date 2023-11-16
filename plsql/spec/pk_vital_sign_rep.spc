/*-- Last Change Revision: $Rev: 2029044 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_vital_sign_rep AS

    --
    -- PUBLIC CONSTANTS
    -- 
    g_error VARCHAR2(4000);
    g_exception EXCEPTION;
    --
    -- PUBLIC FUNCTIONS
    -- 

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_n_records              Number of collumns of registries
    * @param      o_n_vs                      Number of registries
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS
    ***********************************************************************************************************/
    FUNCTION get_vs_n_records
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_view     IN vs_soft_inst.flg_view%TYPE,
        i_patient      IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit        IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_n_records OUT PLS_INTEGER,
        o_n_vs         OUT PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_patient                   Patient id
    * @param      i_visit                     Visit id
    * @param      o_vs_grid                   Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/24
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_vs_short_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_patient  IN vital_signs_ea.id_patient%TYPE DEFAULT NULL,
        i_visit    IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        o_vs_grid  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the vital sign information registered for one episode VISIT
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    * @param      o_val_vs                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_all
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_val_vs     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns the number of vital sign registered for one patient and number of moments of vital sign registration
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_flg_view                  Vital signs view:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param      i_flg_screen                Screen type
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_interval                  Interval to filter
    * @param      i_dt_begin                  Date begin of the interval (Last X records, Last X my records)
    * @param      i_dt_end                    Date end of the interval (Last X records, Last X my records)   
    * @param      o_time                      Returns time collumns
    * @param      o_sign_v                    Returns information about each vital sign registry
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Luís Maia
    * @version    2.5.1.9
    * @since      2011/11/25
    *
    * @dependencies    REPORTS; UX
    ***********************************************************************************************************/
    FUNCTION get_epis_vs_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_interval   IN VARCHAR2,
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:
    *                                                     S- Resumo;
    *                                                     H - Saída de turno;
    *                                                     V1 - Grelha completa;
    *                                                     V2 - Grelha reduzida;
    *                                                     V3 - Biometria;
    *                                                     T - Triagem;
    * @param o_notes_vs         Lista das notas dos sinais vitais do episódio
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/25
    ********************************************************************************************/
    FUNCTION get_epis_vs_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_notes_vs OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns all cancelled vital sign reads in a visit
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital sign read ID
    * @param        o_vsr_history            History Info
    * @param        o_error                  Error
    *
    * @author                                Luís Maia
    * @version                               2.6.1.0.1
    * @since                                 30-Nov-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_cancelled_vital_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        o_vsr_cancelled OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_episode             Vital Sign read ID
    * @param        o_vsr_history            History information
    * @param        o_error                  List of changed columns 
    *
    * @author                                Luís Maia
    * @version                               2.6.1.0.1
    * @since                                 30-Nov-2011
    *
    * @dependencies                          REPORTS
    ************************************************************************************************************/
    FUNCTION get_visit_vital_sign_read_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        o_vsr_history OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * get the patient last BMI values
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Luís Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************
    * This function returns the vital sign detail for the edit screen
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      Professional id, institution and software
    * @param      i_id_vital_sign_read       vital_sign_read identifier
    * @param       o_cursor             out cursor
    * @param       o_error             error message 
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013/09/27
    *
    * @dependencies     UX
    ***********************************************************************************************************/
    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_cursor             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obter todos os SVs activos registados num episódio.Se há + do q 1 leitura do mesmo SV, retorna o + recente.
      Retorna tb os nomes e IDs dos SVs q ñ têm leitura neste episódio
    *
    * @param i_lang             Id do idioma
    * @param i_episode          episode id
    * @param i_prof             professional, software, institution ids
    * @param i_flg_view         Posição dos sinais vitais:S- Resumo;
                                                          H - Saída de turno;
                                                          V1 - Grelha completa;
                                                          V2 - Grelha reduzida;
                                                          V3 - Biometria;
                                                          T - Triagem;
    * @param o_sign_v           Detalhe dos Sinais vitais na triagem
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/06/29
    * @notes                    Para além de apresentar os sinais vitais activos(+ recentes) do episódio,
                                também serão listados os sinais vitais que não existam no episódio mas
                                que deverão ser visualizados tendo em conta o parâmetro I_FLG_VIEW.
    ********************************************************************************************/
    FUNCTION get_epis_vs_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_start_date IN VARCHAR2 DEFAULT NULL,
        i_end_date   IN VARCHAR2 DEFAULT NULL,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
END pk_vital_sign_rep;
/
