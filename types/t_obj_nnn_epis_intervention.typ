CREATE OR REPLACE TYPE t_obj_nnn_epis_intervention UNDER t_obj_temporal_record
(
-- Author  : ARIEL.MACHADO
-- Created : 2/28/2014 3:54:11 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent a NIC intervention in a patient's care plan

-- Attributes
    id_nnn_epis_intervention NUMBER(24),
    id_nic_intervention      NUMBER(24),
    context_record           t_obj_context_record,
    prof_info                t_obj_prof_info,
    cancel_info              t_obj_cancel_info,
    status                   t_obj_status,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_intervention
    (
        SELF                       IN OUT NOCOPY t_obj_nnn_epis_intervention,
        i_id_nnn_epis_intervention IN NUMBER DEFAULT NULL,
        i_id_nic_intervention      IN NUMBER DEFAULT NULL,
        i_context_record           IN t_obj_context_record DEFAULT NULL,
        i_prof_info                IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info              IN t_obj_cancel_info DEFAULT NULL,
        i_status                   IN t_obj_status DEFAULT NULL,
        i_bitemporal_data          IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes   IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
FINAL;
/
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_intervention AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_intervention
    (
        SELF                       IN OUT NOCOPY t_obj_nnn_epis_intervention,
        i_id_nnn_epis_intervention IN NUMBER DEFAULT NULL,
        i_id_nic_intervention      IN NUMBER DEFAULT NULL,
        i_context_record           IN t_obj_context_record DEFAULT NULL,
        i_prof_info                IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info              IN t_obj_cancel_info DEFAULT NULL,
        i_status                   IN t_obj_status DEFAULT NULL,
        i_bitemporal_data          IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes   IN VARCHAR2 DEFAULT 'N'
        
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nnn_epis_intervention := i_id_nnn_epis_intervention;
        self.id_nic_intervention      := i_id_nic_intervention;
        self.context_record           := i_context_record;
        self.prof_info                := i_prof_info;
        self.cancel_info              := i_cancel_info;
        self.status                   := i_status;
        self.bitemporal_data          := i_bitemporal_data;
        self.has_historical_changes   := i_has_historical_changes;
    
        RETURN;
    END t_obj_nnn_epis_intervention;

    -- Member procedures and functions
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json := (SELF AS t_obj_temporal_record).to_json(i_lang => i_lang, i_prof => i_prof);
    
        l_json.put('ID_NNN_EPIS_INTERVENTION', self.id_nnn_epis_intervention);
        l_json.put('ID_NIC_INTERVENTION', self.id_nic_intervention);
        IF self.context_record IS NOT NULL
        THEN
            l_json.put('CONTEXT_RECORD', self.context_record.to_json());
        ELSE
            l_json.put('CONTEXT_RECORD', json_object_t());
        END IF;
    
        IF self.prof_info IS NOT NULL
        THEN
            l_json.put('PROF_INFO', self.prof_info.to_json());
        ELSE
            l_json.put('PROF_INFO', json_object_t());
        END IF;
    
        IF self.cancel_info IS NOT NULL
        THEN
            l_json.put('CANCEL_INFO', self.cancel_info.to_json());
        ELSE
            l_json.put('CANCEL_INFO', json_object_t());
        END IF;
    
        IF self.status IS NOT NULL
        THEN
            l_json.put('STATUS', self.status.to_json());
        ELSE
            l_json.put('STATUS', json_object_t());
        END IF;
    
        RETURN l_json;
    END to_json;
END;
/
