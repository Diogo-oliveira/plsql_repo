/*-- Last Change Revision: $Rev: 2028950 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:55 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_bo IS

    -- This package provides the logic for ALERT Scheduler backoffice.
    -- @author  Telmo Castro
    -- @version 2.4.3
    -- @date    22-04-2008

    /*
    * returns the total number of events for a given sch type kind.
    * Can be used in a select clause.
    *
    * @param i_flg_dep_type sch type kind
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * DBImprovements - sch_event_type demise
    * @author  Telmo Castro 
    * @date     09-10-2008
    * @version  2.4.3.x
    */
    FUNCTION get_sch_type_events_count(i_flg_dep_type IN sch_event.dep_type%TYPE) RETURN NUMBER;

    /*
    * returns the total number of events linked to a given dcs.
    * Can be used in a select clause.
    *
    * @param i_id_dep_clin_serv  dcs id
    * @param i_id_sch_type       sch type id
    * @param i_flg_dep_type      dep type 
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * CORRECTED
    * added parameter i_flg_dep_type in order to properly query sch_department
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     08-07-2008
    */
    FUNCTION get_dcs_events_count
    (
        i_id_dep_clin_serv IN sch_event_dcs.id_dep_clin_serv%TYPE,
        i_id_sch_type      IN sch_department.id_department%TYPE,
        i_flg_dep_type     IN sch_department.flg_dep_type%TYPE
    ) RETURN NUMBER;

    /*
    * returns the total number of dcs in a sch type, in a institution
    * Can be used in a select clause.
    *
    * @param i_institution inst. id
    * @param i_sch_type  sch type id
    *
    * return number
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * CORRECTED
    * added parameter i_flg_dep_type in order to properly query sch_department
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     08-07-2008
    */
    FUNCTION get_dep_dcs_count
    (
        i_institution  IN department.id_institution%TYPE,
        i_id_sch_type  IN sch_department.id_department%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE
    ) RETURN NUMBER;

    /*
    * get list with candidate departments to become scheduling types.
    * There is a column which tells if department is already a sch. type.
    * Used in Agendamentos disponiveis.
    *
    * @param i_lang     Language identifier
    * @param i_prof     professional
    * @param o_depts    department list
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     22-04-2008
    */
    FUNCTION get_departments
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_inst IN department.id_institution%TYPE,
        o_depts   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * get list of Available scheduling types to be coupled with the given department.
    * There is a column indicating if the sch. type is already coupled (determined from table sch_department)
    * Used in Agendamentos disponiveis.
    *
    * @param i_lang     Language identifier
    * @param i_id_dept  department id
    * @param o_dep_types department list
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     04-07-2008
    */
    FUNCTION get_dep_types
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dept   IN department.id_institution%TYPE,
        o_dep_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * saves list of departments to sch. types table (sch_department)
    * Both cases are dealt with: those which are set and those which are unset.
    *
    * @param i_lang     Language identifier
    * @param i_prof     professional
    * @param i_ids      list of (id_department, flg_dep_type)
    * @param i_values   A=set  I=unset
    * @param o_error    Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     22-04-2008
    *
    * UPDATED
    * alteracoes para o remake do deepnav Tipos de agendamento disponiveis
    *
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    04-07-2008
    */
    FUNCTION set_sch_types
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_ids    IN table_table_varchar,
        i_values IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns scheduling types list for given institution
    * Used in Configuracao dos tipos de agendamento and Permissions
    *
    * @param i_lang       Language identifier
    * @param i_prof       professional
    * @param i_id_inst    institution id
    * @param o_sch_types  sch. types list
    * @param o_error      Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * added Total line to the beggining so that this function can be reused in Permissions
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     07-05-2008   
    */
    FUNCTION get_sch_types
    (
        i_lang      IN language.id_language%TYPE,
        i_id_inst   IN department.id_institution%TYPE,
        o_sch_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns scheduling sub types list for given institution and given sch. type.
    * Also returns designation of that subtype.
    * Included is a column with the event count for such sch_type
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang         Language identifier
    * @param i_id_inst      institution id
    * @param i_id_sch_type  sch type id
    * @param i_flg_dep_type dep type 
    * @param o_sch_types    sch. sub types list
    * @param o_subtype      subtype designation
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * incluido novo parametro i_flg_dep_type para filtrar correctamente a sch_department
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    07-07-2008
    */
    FUNCTION get_sch_subtypes
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst      IN department.id_institution%TYPE,
        i_id_sch_type  IN department.id_department%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE,
        o_sch_stypes   OUT pk_types.cursor_type,
        o_subtype      OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list of events for a given sch. subtype.
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang         Language identifier
    * @param i_id_inst      institution id
    * @param i_id_sch_Type  sch_type id
    * @param i_id_sch_stype sch subtype id
    * @param i_flg_dep_type dep type
    * @param o_sch_events   sch. sub types list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     23-04-2008
    *
    * UPDATED
    * incluido novo parametro i_flg_dep_type para filtrar correctamente a sch_department
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    07-07-2008
    */
    FUNCTION get_sch_subtype_events
    (
        i_lang         IN language.id_language%TYPE,
        i_id_inst      IN department.id_institution%TYPE,
        i_id_sch_type  IN department.id_department%TYPE,
        i_id_sch_stype IN sch_event_dcs.id_dep_clin_serv%TYPE,
        i_flg_dep_type IN sch_department.flg_dep_type%TYPE,
        o_sch_events   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * saves associations dcs - event to the database, table sch_event_dcs
    * Used in Configuracao dos tipos de agendamento
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_data         table with attribute pairs id_sch_event | id_dep_clin_serv 
    * @param i_values       table with values (Y, N)
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     24-04-2008
    *
    * UPDATED 
    * agora aceita pares null | id_dep_clin_serv. Nesse caso e' preciso encontrar todos os eventos desse
    * dep_clin_serv e settar em todos o valor respectivo em i_values
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     07-05-2008
    */
    FUNCTION set_sch_events_dcs
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_ids    IN table_table_number,
        i_values IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list of options for permission's right panel initial option
    * Used in Permissions
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param o_prof         output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    */
    FUNCTION get_sch_selection
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list scheduling types available to ALL members of input list of professionals.
    * Used in Permissions. The output is the intersection of sch types available to all professionals
    * in i_profs. That is, if a single profissional does not have access to a sch type, that type
    * is not part of the output
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_profs        list of professionals Ids 
    * @param i_inst         institutuion id. Common to all i_profs members
    * @param o_schtypes     output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    */
    FUNCTION get_prof_sch_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_profs    IN table_number,
        i_inst     IN NUMBER,
        o_schtypes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list of scheduling subtypes available to ALL members of input list of professionals.
    * Used in Permissions. The output is the intersection of all sch sub types belonging to 
    * sch types in i_schtypes and available to all professionals in i_profs. 
    * That is, if a single professional does not have access to a subtype, it does not 
    * leave the house
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_profid       list of professionals Ids
    * @param i_sch_type     sch type
    * @param i_dep_type     corresponding dep type
    * @param i_inst         institution id
    * @param o_subtypes     output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     05-05-2008
    *
    * UPDATED
    * change of behavior. From now on this accepts only one prof and one schtype. The possibility to 
    * throw several pairs was not being used, so, for the sake of simplicity this was removed. Another
    * reason to do this is the introduction of a new parameter, i_flg_dep_type, in order to 
    * properly query the sch_department table. 
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    09-07-2008
    */
    FUNCTION get_prof_sch_subtypes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_profid   IN sch_permission.id_professional%TYPE,
        i_sch_type IN sch_department.id_department%TYPE,
        i_dep_type IN sch_department.flg_dep_type%TYPE,
        i_inst     IN NUMBER,
        o_subtypes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list of events available for the given list of subtypes (dcs)
    * Used in Permissions. The output is the intersection of all events belonging to 
    * each subtype. 
    * That is, an event must be assigned to all subtypes in i_subtypes to be part of 
    * the output.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_subtypes     list of sub types
    * @param o_events       output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     06-05-2008
    */
    FUNCTION get_prof_events
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subtypes IN table_number,
        o_events   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * return list of professional available for given event.
    * If the event is targeted to professionals, a list of professionals is returned.
    * If the event is targeted to dep_clin_serv, a single line saying No designated 
    * professional is returned.
    * Used in Permissions. 
    * target_dep_clin_serv ready.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_subtypes     list of sub types
    * @param o_events       output list
    * @param o_error        Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     13-05-2008
    */
    FUNCTION get_event_profs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_subtype IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_event   IN sch_event.id_sch_event%TYPE,
        o_profs   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets a professional's permission to access a given professional's schedule.
    *
    * @param    i_lang                 Language identifier.
    * @param    i_prof                 Professional.
    * @param    i_id_dep_clin_serv     Department-Clinical service identifier.
    * @param    i_id_sch_event         Event identifier.
    * @param    i_id_prof              Professsional identifier (target professional).
    * @param    o_error                Error message if something goes wrong
    *
    * @author  Nuno Guerreiro
    * @version alpha
    * @since   2007/05/15
    *
    * IMPORTED FROM PK_SCHEDULE
    * @author  Telmo Castro
    * @version 2.4.3
    * @date    09-05-2008
    */
    FUNCTION get_permission
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_prof          IN professional.id_professional%TYPE DEFAULT NULL,
        o_permission       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns decomposition of this combinations
    * i_to_profs | i_on_profs | i_schtypes | i_subtypes | i_events
    *    Y       |    Y 
    *    Y       |    Y       |    Y
    *    Y       |    Y       |    Y       |     Y
    *    Y       |    Y       |    Y       |     Y      |    Y
    * 
    * into a cursor_type with this columns
    *   id_prof | id_prof_agenda ou id_dep_clin_serv | id_event | flg_permission
    * 
    * Used in Permissions to breakdown all user choices into all possible 
    * combinations to be shown in summary screen before saving.
    * All parameters of type table_xxx must have equal total members, because
    * pairing is done through collection index.
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_inst         institution id
    * @param i_to_profs     list of professional ids that are being given permissions
    * @param i_on_profs     list of professional ids whose agendas are being granted/revoked permission
    * @param i_schtypes     list of pairs sch_type + dep_type
    * @param i_subtypes     list of sch subtypes 
    * @param i_events       list of events
    * @param o_perms        output list
    * @param o_error        Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     12-05-2008
    */
    FUNCTION get_permissions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN sch_permission.id_institution%TYPE,
        i_to_profs     IN table_number,
        i_on_profs     IN table_number,
        i_schtypes     IN table_table_varchar, -- table_number,
        i_subtypes     IN table_number,
        i_events       IN table_number,
        o_perms        OUT pk_types.cursor_type,
        o_msg_max_rows OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_test(o_rs OUT pk_types.cursor_type) RETURN BOOLEAN;

    /*
    * returns all possible permissions given to i_to_profs upon i_on_profs.
    * This is a cartesian product: i_to_profs x i_on_profs.
    * Used in Permissions to decompose selections of the kind 
    * i_to_prof - i_on_prof
    *
    * @param i_lang         Language identifier
    * @param i_prof         professional. Used to set up the audit fields
    * @param i_inst         institution id
    * @param i_to_profs     professionals being configured
    * @param i_on_profs     professionals being granted access
    * @param o_perm         output
    * @param o_error        Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     09-05-2008
    */
    FUNCTION get_perms_from_zero
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_permission.id_institution%TYPE,
        i_to_profs IN table_number,
        i_on_profs IN table_number,
        o_perms    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * permissions master set function. It accepts multiple permissions, in which all columns are
    * separated in nested tables. So all this tables must have equal length, even if all or some of
    * its values are null.
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id, common to all permissions being set
    * @param i_to_profs       list of professional ids that are being given permissions
    * @param i_on_profs       list of professional ids whose agendas are being granted/revoked permission
    * @param i_on_subtypes    list of sub types
    * @param i_events         list of events 
    * @param i_perms          list of access level being set
    * @param o_error          Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     14-05-2008
    *
    * UPDATED
    * alteracao para equiparar i_schtypes(null) a i_schtypes(table_varchar(null, null))
    * @author   Telmo Castro
    * @version  2.4.3.2
    * @date     22-09-2008
    */
    FUNCTION set_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN sch_permission.id_institution%TYPE,
        i_to_profs    IN table_number,
        i_on_profs    IN table_number,
        i_on_subtypes IN table_number,
        i_events      IN table_number,
        i_perms       IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * obter string <profilename> para ser usado no get_details
    * foi necessario tornar publico para nao dar o PLS-00231.
    * To be used inside a SELECT statement.
    *
    * @param i_lang         language id
    * @param i_id_prof      id do profissional
    * @param i_id_inst      id instituticao
    * @param i_msg          mensagem a devolver quando i_id_prof e' nulo (caso das permissoes prof1-dcs)
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     20-05-2008
    */
    FUNCTION get_profile
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN sch_permission.id_prof_agenda%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        i_msg     IN sys_config.value%TYPE
    ) RETURN VARCHAR2;

    /*
    * To be used inside a SELECT statement.
    *
    * @param i_id_prof      id do profissional
    * @param i_id_inst      id instituticao
    * @param i_msg          mensagem a devolver quando i_id_prof e' nulo (caso das permissoes prof1-dcs)
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     20-05-2008
    */
    FUNCTION get_inline_events
    (
        i_lang           IN language.id_language%TYPE,
        i_id_inst        IN sch_permission.id_institution%TYPE,
        i_id_prof        IN sch_permission.id_professional%TYPE,
        i_id_prof_agenda IN sch_permission.id_prof_agenda%TYPE,
        i_id_dcs         IN sch_permission.id_dep_clin_serv%TYPE,
        i_flg_perm       IN sch_permission.flg_permission%TYPE
    ) RETURN VARCHAR2;

    /*
    * details of permissions assigned to professionals in i_to_profs.
    *
    * @param i_lang           Language identifier
    * @param i_prof           professional. Used to set up the audit fields
    * @param i_inst           institution id, common to all permissions being set
    * @param i_to_profs       list of professionals to fetch details
    * @param o_perm           output list
    * @param o_error          Error message (if an error occurred)
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.4.3
    * @date     16-05-2008
    
    * UPDATED
    * faltava uma coluna com o perfil do to professional.
    * @author  Telmo castro
    * @date    17-06-2008
    * @version 2.4.3
    */
    FUNCTION get_details
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_inst     IN institution.id_institution%TYPE,
        i_to_profs IN table_number,
        o_perms    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION calc_vac_dur
    (
        i_id_prof     IN professional.id_professional%TYPE,
        vac_dt_begin  IN sch_consult_vacancy.dt_begin_tstz%TYPE,
        vac_dt_end    IN sch_consult_vacancy.dt_end_tstz%TYPE,
        unav_dt_begin IN sch_absence.dt_begin_tstz%TYPE,
        unav_dt_end   IN sch_absence.dt_end_tstz%TYPE
    ) RETURN NUMBER;

    FUNCTION has_unavs(i_day IN PLS_INTEGER) RETURN VARCHAR2;

    FUNCTION get_month_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_date     OUT VARCHAR2,
        o_data     OUT pk_types.cursor_type,
        o_depnames OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_day_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_date     OUT VARCHAR2,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_vacancy_data
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_vac IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_data   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_services
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_sch_type IN sch_dep_type.dep_type%TYPE DEFAULT NULL,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_bo_sch_types
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_dep   IN sch_consult_vacancy.id_prof%TYPE,
        i_sch_type IN sch_dep_type.dep_type%TYPE DEFAULT NULL,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_id_dep   IN sch_department.id_department%TYPE,
        i_sch_type IN sch_department.flg_dep_type%TYPE,
        i_id_event IN sch_event.id_sch_event%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_events
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN professional.id_professional%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_dep   IN sch_department.id_department%TYPE,
        i_sch_type IN sch_department.flg_dep_type%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacancy
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_vac       IN sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        i_id_inst      IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof      IN sch_consult_vacancy.id_prof%TYPE,
        i_maxvacs      IN sch_consult_vacancy.max_vacancies%TYPE,
        i_id_dcs       IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_event     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_room      IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin     IN VARCHAR2,
        i_dt_end       IN VARCHAR2,
        i_id_exam      IN schedule_exam.id_exam%TYPE DEFAULT NULL,
        i_flg_urg      IN sch_consult_vac_oris.flg_urgency%TYPE DEFAULT NULL,
        i_flg_status   IN sch_consult_vacancy.flg_status%TYPE DEFAULT 'A',
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        o_id_vac       OUT sch_consult_vacancy.id_sch_consult_vacancy%TYPE,
        o_flg_show2    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vacancies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_inst      IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof      IN sch_consult_vacancy.id_prof%TYPE,
        i_maxvacs      IN sch_consult_vacancy.max_vacancies%TYPE,
        i_id_dcs       IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_event     IN sch_consult_vacancy.id_sch_event%TYPE,
        i_id_room      IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin     IN VARCHAR2,
        i_dt_end       IN VARCHAR2,
        i_id_exam      IN schedule_exam.id_exam%TYPE,
        i_flg_urg      IN sch_consult_vac_oris.flg_urgency%TYPE,
        i_flg_status   IN sch_consult_vacancy.flg_status%TYPE,
        i_id_phys_area IN sch_consult_vac_mfr.id_physiatry_area%TYPE DEFAULT NULL,
        i_flg_timeunit IN VARCHAR2 DEFAULT NULL,
        i_flg_end_by   IN VARCHAR2 DEFAULT NULL,
        i_nr_events    IN NUMBER DEFAULT NULL,
        i_repeat_every IN NUMBER DEFAULT NULL,
        i_weekday      IN NUMBER DEFAULT NULL,
        i_day_of_month IN NUMBER DEFAULT NULL,
        i_week         IN NUMBER DEFAULT NULL,
        i_month        IN NUMBER DEFAULT NULL,
        i_rep_dt_begin IN VARCHAR2,
        i_rep_dt_end   IN VARCHAR2,
        o_flg_show2    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_vacancies
    (
        i_lang    IN language.id_language%TYPE,
        i_id_vacs IN table_number,
        o_count   OUT NUMBER,
        o_flag    OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_count    OUT NUMBER,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_inst  IN sch_consult_vacancy.id_institution%TYPE,
        i_id_prof  IN sch_consult_vacancy.id_prof%TYPE,
        i_id_dcs   IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room  IN sch_consult_vacancy.id_room%TYPE,
        i_dt_begin IN VARCHAR2,
        o_count    OUT NUMBER,
        o_flag     OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_unav
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_unav  IN sch_absence.id_sch_absence%TYPE,
        o_unav  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_unav
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_prof    IN professional.id_professional%TYPE,
        i_unav       IN sch_absence.id_sch_absence%TYPE,
        i_start_date VARCHAR2,
        i_end_date   VARCHAR2,
        i_start_hour VARCHAR2,
        i_end_hour   VARCHAR2,
        i_desc       IN sch_absence.desc_absence%TYPE,
        o_id_unav    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_unav
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_unav  IN table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --para o cancel unav
    FUNCTION get_blocked_vacancies
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_unavs IN table_number,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    -- para o set unav
    FUNCTION get_unblocked_vacancies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_prof    IN sch_absence.id_professional%TYPE,
        i_id_inst    IN sch_absence.id_institution%TYPE,
        i_dt_begin   IN VARCHAR2,
        i_dt_end     IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_num_scheds OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_dcs_config
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_dcs  IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_inst IN department.id_institution%TYPE,
        o_config  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_unav_dt_begin(i_dia PLS_INTEGER
                               --        i_tab t_table_unavs
                               ) RETURN sch_absence.dt_begin_tstz%TYPE;

    FUNCTION get_unav_dt_end(i_dia PLS_INTEGER
                             --        i_tab t_table_unavs
                             ) RETURN sch_absence.dt_end_tstz%TYPE;

    /** @headcom
    * Public Function. Copy paste after slot
    *
    * @param      I_LANG                     Language identification
    * @param      i_prof                     Professional identification
    * @param      i_slot                     Unavailability identification
    * @param      o_id_scv                     Unavailability identification
    * @param      o_id_scve                     Unavailability identification
    * @param      o_id_scvos                     Unavailability identification
    * @param      o_flg_show                     Unavailability identification
    * @param      o_msg                     Unavailability identification
    * @param      o_msg_title                     Unavailability identification
    * @param      o_button                     Unavailability identification
    * @param      o_error                    Error
    *
    * @return     boolean
    * @author     Susana Silva
    * @version    2.5.0.5
    * @since      2008/07/28
    */
    FUNCTION copy_paste_after
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_slot      IN NUMBER,
        o_id_scv    OUT NUMBER,
        o_id_scve   OUT NUMBER,
        o_id_scvos  OUT NUMBER,
        o_flg_show2 OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * ALERT-34830. Group cancellation
    * 
    * @param i_lang           Language identifier
    * @param i_prof           professional login. 
    * @param i_id_prof        target prof id (optional)
    * @param i_dt_begin       start date
    * @param i_dt_begin       end date
    * @param i_id_dcs         target clinical service
    * @param i_id_room        target room id (optional)
    * @param i_sch_event      schedule events
    * @param o_data           data output
    * @param o_error          Error data
    *
    * @return True if successful, false otherwise.
    *
    * @author   Susana Silva
    * @version  2.5.0.6
    * @date     27-08-2009
    */

    FUNCTION get_events_cancelled
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_prof   IN sch_consult_vacancy.id_prof%TYPE,
        i_dt_begin  IN VARCHAR2,
        i_dt_end    IN VARCHAR2,
        i_id_dcs    IN sch_consult_vacancy.id_dep_clin_serv%TYPE,
        i_id_room   IN sch_consult_vacancy.id_room%TYPE,
        i_sch_event IN sch_consult_vacancy.id_sch_event%TYPE,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns scheduling types list for given institution. This function originated from get_sch_types.
    * Because get_sch_types was used in 2 diferent places.
    * Used in alert backoffice -> scheduler -> permissions (option = by scheduling type)
    *
    * @param i_lang       Language identifier
    * @param i_prof       professional data
    * @param i_id_inst    institution id
    * @param o_sch_types  sch. types list
    * @param o_error      Error message (if an error occurred).
    *
    * @return True if successful, false otherwise.
    *
    * @author   Telmo Castro
    * @version  2.6
    * @date     09-04-2010
    */
    FUNCTION get_sch_types_by_type
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_inst   IN department.id_institution%TYPE,
        o_sch_types OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    ------------------------------- GLOBALS -----------------------------------
    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_package_owner VARCHAR2(30);

    /* Message stack for storing multiple warning/error messages. */
    g_msg_stack table_varchar;

    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    /* Active */
    g_status_active CONSTANT VARCHAR2(1) := 'A';
    /* Inactive */
    g_status_inactive CONSTANT VARCHAR2(1) := 'I';

    /*blocked*/
    g_status_blocked CONSTANT VARCHAR2(1) := 'B';

    /* Search values for sys_config */
    g_search_default_duration CONSTANT VARCHAR2(20) := 'SCH_DEFAULT_DURATION';
    g_num_max_rows            CONSTANT VARCHAR2(30) := 'SCH_BO_PERMISSIONS_MAX_ROWS';

    /* sys_messages */
    g_msg_todoseventos       CONSTANT VARCHAR2(8) := 'SCH_T201';
    g_msg_todosschtypes      CONSTANT VARCHAR2(8) := 'SCH_T206';
    g_msg_todossubtypes      CONSTANT VARCHAR2(8) := 'SCH_T207';
    g_msg_todoseventos2      CONSTANT VARCHAR2(8) := 'SCH_T208';
    g_msg_noaccess           CONSTANT VARCHAR2(8) := 'SCH_T218';
    g_msg_viewonly           CONSTANT VARCHAR2(8) := 'SCH_T219';
    g_msg_viewandsched       CONSTANT VARCHAR2(8) := 'SCH_T220';
    g_msg_todosprofs         CONSTANT VARCHAR2(8) := 'SCH_T224';
    g_msg_no_desig_prof      CONSTANT VARCHAR2(8) := 'SCH_T225';
    g_msg_no_desig_prof_grid CONSTANT VARCHAR2(8) := 'SCH_T233';
    g_msg_no_desif_prof_det  CONSTANT VARCHAR2(8) := 'SCH_T234';
    g_msg_no_access          CONSTANT VARCHAR2(8) := 'SCH_T268';
    g_msg_unavailability     CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T513';

    g_msg_popupheadertitle CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T504';
    g_msg_vac_overlap_1    CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T565';
    g_msg_vac_overlap_2    CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T566';
    g_msg_vac_overlap_3    CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T506';

    g_msg_used_vac_2 CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T508';
    g_msg_used_vac_3 CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T509';

    g_msg_desta       CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T554';
    g_msg_destas      CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T555';
    g_msg_vaga        CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T538';
    g_msg_vagas       CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T539';
    g_msg_sessao      CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T540';
    g_msg_sessoes     CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T541';
    g_msg_esta        CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T542';
    g_msg_estas       CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T543';
    g_msg_tem         CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T556';
    g_msg_marcacao    CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T544';
    g_msg_marcacoes   CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T545';
    g_msg_editar_canc CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T568';
    g_msg_cancele     CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T569';
    g_msg_a           CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T546';
    g_msg_as          CONSTANT VARCHAR2(20) := 'ADMINISTRATOR_T547';
    g_msg_max_rows    CONSTANT VARCHAR2(20) := 'SCH_T850';

    -- weekdays 
    g_msg_seg CONSTANT VARCHAR2(8) := 'SCH_T314';
    g_msg_ter CONSTANT VARCHAR2(8) := 'SCH_T315';
    g_msg_qua CONSTANT VARCHAR2(8) := 'SCH_T316';
    g_msg_qui CONSTANT VARCHAR2(8) := 'SCH_T317';
    g_msg_sex CONSTANT VARCHAR2(8) := 'SCH_T318';
    g_msg_sab CONSTANT VARCHAR2(8) := 'SCH_T319';
    g_msg_dom CONSTANT VARCHAR2(8) := 'SCH_T320';

    g_unav_icon CONSTANT VARCHAR2(15) := 'BlockedIcon';

    /* messages for list of options in permissions middle panel */
    g_perm_by_profs    CONSTANT VARCHAR2(20) := 'SCH_PERM_BY_PROF';
    g_perm_by_schtypes CONSTANT VARCHAR2(20) := 'SCH_PERM_BY_SCHTYPE';

    g_perm_by_list CONSTANT table_varchar := table_varchar(g_perm_by_profs, g_perm_by_schtypes);

    -- sys_config keys
    g_cfg_exclude_phys_app_type CONSTANT sys_config.id_sys_config%TYPE := 'SCH_BO_EXCLUDE_PERMISSIONS_FOR_PHYS_APPS';

    -- used in function get_month_vacancies
    TYPE t_unav IS RECORD(
        dt_begin sch_absence.dt_begin_tstz%TYPE,
        dt_end   sch_absence.dt_end_tstz%TYPE);

    TYPE t_table_unavs IS TABLE OF t_unav INDEX BY PLS_INTEGER;

    table_unavs t_table_unavs;

    -- hour sign
    g_msg_hour_indicator CONSTANT VARCHAR2(30) := 'HOURS_SIGN';

    /*sys_domains*/
    g_dom_flg_status      CONSTANT VARCHAR2(40) := 'SCH_CONSULT_VACANCY.FLG_STATUS';
    g_dom_flg_img_blocked CONSTANT VARCHAR2(40) := 'SCH_EVENT.FLG_IMG_BLOCKED';

    g_flg_type_sch_absence   VARCHAR2(1) := 'O';
    g_flg_status_sch_absence VARCHAR2(1) := 'A';

    -- events
    g_surg_sch_event NUMBER := 14;
    g_inp_sch_event  NUMBER := 17;

    -- exceptions
    my_exception EXCEPTION;

END pk_schedule_bo;
/
