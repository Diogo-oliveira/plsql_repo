CREATE OR REPLACE TYPE t_obj_context_record force AS OBJECT
(
-- Author  : ARIEL.MACHADO
-- Created : 1/31/2014 9:09:09 AM
-- Purpose : Object type to represent information about the scope/context in which the record was created

-- Attributes
    id_institution NUMBER(24),
    id_software    NUMBER(24),
    id_patient     NUMBER(24),
    id_visit       NUMBER(24),
    id_episode     NUMBER(24),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_context_record(SELF IN OUT NOCOPY t_obj_context_record) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_id_episode IN NUMBER
    ) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF       IN OUT NOCOPY t_obj_context_record,
        i_id_visit IN NUMBER
    ) RETURN SELF AS RESULT,

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_id_patient IN NUMBER
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    MEMBER PROCEDURE init_by_scope
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ),

    MEMBER FUNCTION to_json RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_context_record AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_context_record(SELF IN OUT NOCOPY t_obj_context_record) RETURN SELF AS RESULT IS
    BEGIN
        self.id_institution := NULL;
        self.id_software    := NULL;
        self.id_patient     := NULL;
        self.id_visit       := NULL;
        self.id_episode     := NULL;
    
        RETURN;
    END t_obj_context_record;

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_id_episode IN NUMBER
    ) RETURN SELF AS RESULT IS
        l_error t_error_out;
    BEGIN
        self.init_by_scope(i_scope => i_id_episode, i_scope_type => pk_alert_constant.g_scope_type_episode);
        RETURN;
    END t_obj_context_record;

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF       IN OUT NOCOPY t_obj_context_record,
        i_id_visit IN NUMBER
    ) RETURN SELF AS RESULT IS
        l_error t_error_out;
    BEGIN
        self.init_by_scope(i_scope => i_id_visit, i_scope_type => pk_alert_constant.g_scope_type_visit);
        RETURN;
    END t_obj_context_record;

    CONSTRUCTOR FUNCTION t_obj_context_record
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_id_patient IN NUMBER
    ) RETURN SELF AS RESULT IS
        l_error t_error_out;
    BEGIN
        self.init_by_scope(i_scope => i_id_patient, i_scope_type => pk_alert_constant.g_scope_type_patient);
        RETURN;
    END t_obj_context_record;

    -- Member procedures and functions
    MEMBER PROCEDURE init_by_scope
    (
        SELF         IN OUT NOCOPY t_obj_context_record,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) IS
    BEGIN
        CASE i_scope_type
            WHEN pk_alert_constant.g_scope_type_patient THEN
                self.id_patient     := i_scope;
                self.id_institution := NULL;
                self.id_software    := NULL;
                self.id_visit       := NULL;
                self.id_episode     := NULL;
            
            WHEN pk_alert_constant.g_scope_type_visit THEN
                self.id_visit := i_scope;
                SELECT v.id_institution, v.id_patient, v.id_visit
                  INTO self.id_institution, self.id_patient, self.id_visit
                  FROM visit v
                 WHERE v.id_visit = i_scope;
            
                self.id_episode  := NULL;
                self.id_software := NULL;
            
            WHEN pk_alert_constant.g_scope_type_episode THEN
                SELECT v.id_institution,
                       v.id_patient,
                       v.id_visit,
                       e.id_episode,
                       pk_episode.get_soft_by_epis_type(i_epis_type   => e.id_epis_type,
                                                        i_institution => v.id_institution) id_software
                  INTO self.id_institution, self.id_patient, self.id_visit, self.id_episode, self.id_software
                  FROM episode e
                 INNER JOIN visit v
                    ON e.id_visit = v.id_visit
                 WHERE e.id_episode = i_scope;
            
            ELSE
                pk_alert_exceptions.raise_error(error_code_in => 'e_invalid_scope_type',
                                                text_in       => 'The i_scope_type parameter has an unexpected value for scope type');
        END CASE;
    
    END init_by_scope;

    MEMBER FUNCTION to_json RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json.put('ID_INSTITUTION', self.id_institution);
        l_json.put('ID_SOFTWARE', self.id_software);
        l_json.put('ID_PATIENT', self.id_patient);
        l_json.put('ID_VISIT', self.id_visit);
        l_json.put('ID_EPISODE', self.id_episode);
    
        RETURN l_json;
    END to_json;
END;
/
