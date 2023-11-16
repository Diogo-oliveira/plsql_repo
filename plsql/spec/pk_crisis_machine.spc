/*-- Last Change Revision: $Rev: 2028586 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_crisis_machine IS

    /** 
    * Generate all xml files needed for Flash
    *
    * @param      i_lang             language
    * @param      i_crisis_machine   crisis machine
    * @param      o_file_names       table of XML file names
    * @param      o_xml_values       table of XML text
    * @param      o_crypt            indicates if you need to crypt the file
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/07/31
    */

    FUNCTION generate_xml_files_cur
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_generate_all   IN BOOLEAN DEFAULT TRUE,
        o_cursor         OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Creates the crontab file and replaces current crontab with new file
    *
    * @param      i_lang             language
    * @param      o_result           resultado 1-OK; 0-ERRO
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/08/07
    */

    PROCEDURE set_crontab
    (
        o_xml   OUT CLOB,
        o_error OUT VARCHAR2
    );

    /** 
    * Returns last episode from a patient
    *
    * @param      i_patient          id_patient
    * @param      i_institution      id_institution    
    *
    * @return     number
    * @author     Álvaro Vasconcelos
    * @version    0.1
    * @since      2010/03/30
    */
    FUNCTION get_last_episode
    (
        i_patient       IN patient.id_patient%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_software      IN software.id_software%TYPE DEFAULT NULL,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL
    ) RETURN episode.id_episode%TYPE;

    /** 
    * returns a list of episodes and patients for generation
    *
    * @param      i_lang             language
    * @param      i_crisis_machine   crisis machine
    * @param      o_list             list with format (ID_EPISODE,ID_PATIENT, ID_INSTITUTION, ID_SOFTWARE, PATH_CRISIS_MACHINE, PWD_ENC_CRI_MACHINE, ID_LANGUAGE)
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/07/25
    */

    FUNCTION get_episode_and_patient
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Updates list of transfered episodes. Updates the date columns
    * one report at a time
    *
    * @param      i_lang             language
    * @param      i_epis             episode
    * @param      i_pat              patient
    * @param      i_date_finish      date_finish
    * @param      i_report_cm        name of the pdf file
    * @param      i_CRISIS_MACHINE   crisis_machine
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/08/20
    */

    FUNCTION set_crisis_epis
    (
        i_lang            IN language.id_language%TYPE,
        i_crisis_epis               IN crisis_epis.id_crisis_epis%TYPE,
        i_epis            IN crisis_epis.id_episode%TYPE,
        i_pat             IN crisis_epis.id_patient%TYPE,
        i_date_finish     IN TIMESTAMP WITH TIME ZONE,
        i_cm_report_name  IN crisis_epis.cm_report_name%TYPE,
        i_crisis_machine  IN crisis_machine.id_crisis_machine%TYPE,
        i_schedule        IN crisis_epis.id_schedule%TYPE,
        i_id_report       IN crisis_epis.id_report%TYPE,
        i_flg_report_type IN crisis_epis.flg_report_type%TYPE,
        i_software        IN crisis_epis.id_software%TYPE,
        i_crisis_log      IN crisis_log.id_crisis_log%TYPE,
        i_episode_type              IN crisis_epis.episode_type%TYPE,
        i_cm_report_path            IN crisis_epis.cm_report_path%TYPE,
        i_flg_show_demographic_data IN crisis_epis.flg_show_demographic_data%TYPE,
        i_flg_status                IN crisis_epis.flg_status%TYPE,
        i_token                     IN crisis_epis.token%TYPE,
        o_error           OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Updates RSYNC LOGs
    *
    * @param      i_lang             language
    * @param      i_crisis_machine   crisis machine
    * @param      i_rsync_file       Dados do RSYNC
    * @param      i_result           Resultado da cópia
    * @param      i_date_expected    Data prevista de RSYNC
    * @param      i_date_transf      Data real de RSYNC
    * @param      i_cm_adress        Crisis machine adress (there should be unique adress per clone)
    * @param      o_error            error
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/08/08
    */

    FUNCTION set_rsync
    (
        i_lang              IN language.id_language%TYPE,
        i_crisis_log        IN crisis_log.id_crisis_log%TYPE,
        i_crisis_machine    IN crisis_log.id_crisis_machine%TYPE,
        i_rsync_file        IN crisis_log.log_command%TYPE,
        i_result            IN crisis_log.flg_status%TYPE,
        i_rep_generated     IN crisis_log.reports_generated%TYPE,
        i_rep_not_generated IN crisis_log.reports_not_generated%TYPE,
        i_dt_upd_start      IN TIMESTAMP WITH TIME ZONE,
        i_dt_rep_cleanup    IN TIMESTAMP WITH TIME ZONE,
        i_dt_xml_gen        IN TIMESTAMP WITH TIME ZONE,
        i_dt_sta_upd        IN TIMESTAMP WITH TIME ZONE,
        i_dt_rep_upd        IN TIMESTAMP WITH TIME ZONE,
        i_dt_upd_end        IN TIMESTAMP WITH TIME ZONE,
        i_cm_adress         IN crisis_log.crisis_machine_address%TYPE DEFAULT NULL,
        o_error             OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Auxilliary function for JAVA to get Crisis Machine details
    *
    * @param      i_crisis_machine        crisis machine to get details
    * @param      o_details               crisis machine details
    * @param      o_cm_log                crisis machine logid by address (multiple records when clone)
    * @param      o_error                 erro
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/09/11
    */

    FUNCTION get_crisis_machine_details
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_details        OUT pk_types.cursor_type,
        o_cm_log         OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Get institution for crisis machine
    *
    * @param      i_crisis_machine        crisis machine 
    *
    * @return     number (id_institution)
    * @author     RS
    * @version    0.1
    * @since      2007/09/11
    */

    FUNCTION get_crisis_inst(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE) RETURN NUMBER;

    /** 
    * Delete OLD Episodes and Logs
    *
    * @param      i_lang                  language
    * @param      i_crisis_machine        máquina de crise
    * @param      o_error                 erro
    *
    * @return     boolean
    * @author     RS
    * @version    0.1
    * @since      2007/12/05
    */

    FUNCTION delete_episodes_and_logs
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Gets File Sync Setup
    *
    * @param      i_lang                  language
    * @param      o_cm_setup              cursor with crisis machine setup
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Nuno Ferreira
    * @version    0.1
    * @since      2009/08/17
    */

    FUNCTION get_file_sync_setup
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_cm_setup       OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Deletes old files from the file system
    *
    * @param      i_lang                  language
    * @param      i_crisis_machine        crisis machine id
    * @param      o_epis2delete           cursor
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Rui Spratley
    * @version    2.6.0.3
    * @since      2010/06/04
    */
    FUNCTION delete_old_files
    (
        i_lang           IN language.id_language%TYPE,
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_epis2delete    OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Gets reports list for a specific institution/software
    *
    * @param      i_lang                  Language
    * @param      i_prof                  Profissional
    * @param      i_rep_profile_template  Rep_profile_template ID
    * @param      i_flg_area_report       rep_profile_template_det.flg_area_report
    * @param      o_reports               cursor with reports list
    * @param      o_error                 error
    *
    * @return     boolean
    *
    * @author     Gustavo Serrano
    * @since      2011/05/27
    * @version    2.6.1.2
    */
    FUNCTION get_reports_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN professional.id_professional%TYPE,
        i_inst                 IN institution.id_institution%TYPE,
        i_soft                 IN software.id_software%TYPE,
        i_rep_profile_template IN table_number,
        i_flg_area_report      IN rep_profile_template_det.flg_area_report%TYPE,
        o_reports              OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION convert_tbl_to_cursor
    (
        i_lang                IN language.id_language%TYPE,
        i_flg_report_type_tbl IN table_varchar,
        i_report_name_tbl     IN table_varchar,
        i_report_id_tbl       IN table_varchar,
        i_report_desc_tbl     IN table_varchar
    ) RETURN pk_types.cursor_type;

    FUNCTION get_admission_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_triage_end_date
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_silhouette
    (
        i_lang       IN language.id_language%TYPE,
        i_silhouette IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_epis_type_by_inst_soft
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN NUMBER;

    PROCEDURE disable_flg_upd_ui(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE);

    PROCEDURE set_crisis_log
    (
        i_crisis_log     IN VARCHAR2,
        i_crisis_machine IN NUMBER,
        i_log            IN VARCHAR2
    );

    FUNCTION get_crisis_machine_clone(i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE) RETURN table_varchar;

    /** 
    * get lock for a specific control name
    *
    * @param      i_control_name          control name
    * @param      i_server_name           server name    
    * @param      i_minimum_interval      minimum interval in minutes between last execution to get lock
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */
    FUNCTION control_get_lock
    (
        i_control_name     IN crisis_control.control_name%TYPE,
        i_server_name      IN crisis_control.server_name%TYPE,
        i_minimum_interval IN NUMBER,
        o_error            OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * release lock for a specific control name
    *
    * @param      i_control_name          control name 
    * @param      o_error                 error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */
    FUNCTION control_release_lock
    (
        i_control_name IN crisis_control.control_name%TYPE,
        o_error        OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * Update status of crisis_epis records which are in error 
    * or in_progress too much time
    *
    * @param      i_lang             language
    * @param      i_crisis_machine   crisis machine
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION update_status
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * get next crisis_epis to process and change flg_status to "in process"
    *
    * @param      i_crisis_machine   crisis machine
    * @param      i_date             date
    * @param      i_token            varchar    
    * @param      o_next_id          next id_crisis_epis to process
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_next_crisis_epis
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        i_date           IN TIMESTAMP WITH TIME ZONE,
        i_token          IN crisis_epis.token%TYPE,
        o_next_id        OUT crisis_epis.id_crisis_epis%TYPE,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * returns a crisis_epis record
    *
    * @param      i_id_crisis_epis   id_crisis_epis
    * @param      o_crisis_epis      crisis_epis_record
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_crisis_epis
    (
        i_id_crisis_epis IN crisis_epis.id_crisis_epis%TYPE,
        o_crisis_epis    OUT pk_types.cursor_type,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * returns a list of crisis_epis records which have reports
    *
    * @param      i_id_crisis_machine   id_crisis_machine
    * @param      o_crisis_epis         crisis_epis_record
    * @param      o_error               error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_reports_to_update
    (
        i_id_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_crisis_epis       OUT pk_types.cursor_type,
        o_error             OUT VARCHAR2
    ) RETURN BOOLEAN;

    /** 
    * returns the number of crisis_epis with status=waiting for a id_crisis_machine
    *
    * @param      i_crisis_machine   crisis machine  
    * @param      o_count          
    * @param      o_error            error
    *
    * @return     boolean
    * @author     Gilberto Rocha
    * @version    2.8.0.1
    * @since      2019/11/29
    */

    FUNCTION get_waiting_count
    (
        i_crisis_machine IN crisis_machine.id_crisis_machine%TYPE,
        o_count          OUT NUMBER,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN;

END pk_crisis_machine;
/
