/*-- Last Change Revision: $Rev: 2028533 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_bird_eye_view AS
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas da urgência
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_emergency_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas de private practice
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         paulo teixeira
    * @version                        1.0 
    * @since                          2010/10/14
    **********************************************************************************************/
    FUNCTION get_private_practice_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter o departamento por defeito para a instituição ou o departmento onde está a especialidade preferencial do profissional
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_depart                 cursor with department default
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_dep_floor_default
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_depart OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todos os departamentos da instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_department             cursor with all departments 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_view_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todos os andares da instituição 
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_floors                 cursor with all floors
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/19
    **********************************************************************************************/
    FUNCTION get_beyes_view_floors
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_floors OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de os departamentos e salas de um andar
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_inst            floor institution id
    * @param i_department             department id
    * @param o_floors_dep             cursor with all floors department
    * @param o_rooms                  cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          
    **********************************************************************************************/
    FUNCTION get_beyes_floors_dep_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_floors_inst IN floors_institution.id_floors_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_floors_dep  OUT pk_types.cursor_type,
        o_rooms       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todas as salas de um dado departamento para a instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id   
    * @param o_val_x                  cursor with all value x
    * @param o_val_y                  cursor with all value y   
    * @param o_room                   cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_dep_room
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        o_val_x      OUT table_varchar,
        o_val_y      OUT table_varchar,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem dos departamentos de um andar
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors                 floor id
    * @param i_department             department id
    * @param o_val_x                  cursor with all value x
    * @param o_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_floors_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors     IN floors_institution.id_floors_institution%TYPE,
        i_department IN department.id_department%TYPE,
        o_val_x      OUT table_varchar,
        o_val_y      OUT table_varchar,
        o_floors_dep OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Check if the given department has BIRDS EYE VIEW SUPPORT
    *   
    * @param i_flg_type_dpt           department type
    * @param i_type_list              list of supported departments
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2007/12/26
    **********************************************************************************************/
    FUNCTION check_dpt_type
    (
        i_flg_type_dpt IN department.flg_type%TYPE,
        i_type_list    IN table_varchar
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Registar as posições dos andares para cada departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id
    * @param i_val_x                  cursor with all value x
    * @param i_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION set_beyes_floors_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        i_val_x      IN table_number,
        i_val_y      IN table_number,
        o_floors_dep OUT floors_department.id_floors_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Registar as posições dos andares para cada departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id
    * @param i_room                   room id       
    * @param i_val_x                  cursor with all value x
    * @param i_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_room                   cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION set_beyes_room_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        i_room       IN room.id_room%TYPE,
        i_val_x      IN table_number,
        i_val_y      IN table_number,
        o_floors_dep OUT floors_department.id_floors_department%TYPE,
        o_room       OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter o nome da instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_institution            institution id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/21
    **********************************************************************************************/
    FUNCTION get_beyes_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_institution OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Contagem de pacientes por sala
    *   
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/04
    **********************************************************************************************/
    FUNCTION get_patient_count
    (
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
    ) RETURN NUMBER;
    --
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do bloco operatório
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Batista
    * @version                        1.0 
    * @since                          2006/10/31
    **********************************************************************************************/
    FUNCTION get_sr_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do internamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floor                  floor id    
    * @param o_pat                    cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         
    * @version                        1.0 
    * @since                          
    **********************************************************************************************/
    FUNCTION get_inp_pat
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_floor IN NUMBER,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do bloco operatório
    *   
    * @param i_lang                   the id language
    * @param i_id_room                room id                   
    * @param i_prof                   professional, software and institution ids
    * @param o_surgery                cursor with surgery rooms
    * @param o_patient                cursor with all patient
    * @param o_professionals          cursor with all professionals   
    * @param o_materials              cursor with all materials of room   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Campos
    * @version                        1.0 
    * @since                          2006/11/08
    **********************************************************************************************/
    FUNCTION get_sr_room_info
    (
        i_lang          IN language.id_language%TYPE,
        i_id_room       IN room.id_room%TYPE,
        i_prof          IN profissional,
        o_surgery       OUT pk_types.cursor_type,
        o_patient       OUT pk_types.cursor_type,
        o_professionals OUT pk_types.cursor_type,
        o_materials     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Eliminar as posições para uma determinada sala
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id   
    * @param o_room                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/11/08
    **********************************************************************************************/
    FUNCTION delete_room_dep_pos
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_room  OUT room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Eliminar as posições de um determinado departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             professional department id    
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/02
    **********************************************************************************************/
    FUNCTION delete_floors_dep_pos
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_dep_position.id_floors_department%TYPE,
        o_floors_dep OUT floors_dep_position.id_floors_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Registar o departamento por defeito
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_inst            floor institution id    
    * @param i_department             department id
    * @param o_floors_inst            cursor with all floors institution
    * @param o_department             cursor with all departments   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/06
    **********************************************************************************************/
    FUNCTION set_default_department
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_floors_inst IN floors_institution.id_floors_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_floors_inst OUT floors_institution.id_floors_institution%TYPE,
        o_department  OUT department.id_department%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error VARCHAR2(4000);
    g_exception EXCEPTION;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_ret          BOOLEAN;
    g_flg_max      room_dep_position.flg_max%TYPE;

    g_floors_avail floors_department.flg_available%TYPE;
    g_epis_type    epis_type.id_epis_type%TYPE;
    g_sr_epis_type CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_epis_active episode.flg_status%TYPE;
    g_flg_default floors_department.flg_dep_default%TYPE;
    g_flg_pref      CONSTANT VARCHAR2(1) := 'Y';
    g_status_cancel CONSTANT VARCHAR2(1) := 'C';
    g_flg_schedule  CONSTANT VARCHAR2(1) := 'Y';
    g_dep_default VARCHAR2(50);

    g_status_active CONSTANT VARCHAR2(1) := 'A';
    g_yes           VARCHAR2(1);
    g_no            VARCHAR2(1);
    g_flg_available VARCHAR2(1);

    g_software_inp  software.id_software%TYPE;
    g_software_edis software.id_software%TYPE;

    g_flg_ehr_normal CONSTANT VARCHAR2(1) := 'N';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_bird_eye_view;
/
