CREATE OR REPLACE TYPE t_obj_nnn_epis_activity UNDER t_obj_temporal_record
(
-- Author  : ARIEL.MACHADO
-- Created : 2/28/2014 3:28:13 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent a NIC Activity

-- Attributes
    id_nnn_epis_activity   NUMBER(24),
    id_nic_activity        NUMBER(24),
    id_nic_othr_actv_vrsn  NUMBER(24),
    context_record         t_obj_context_record,
    prof_info              t_obj_prof_info,
    cancel_info            t_obj_cancel_info,
    status                 t_obj_status,
    id_episode_origin      NUMBER(24),
    id_episode_destination NUMBER(24),
    flg_prn                VARCHAR2(1 CHAR),
    notes_prn              CLOB,
    flg_time               VARCHAR2(1 CHAR),
    flg_priority           VARCHAR2(1 CHAR),
    id_order_recurr_plan   NUMBER(24),
    desc_instructions      VARCHAR2(1000 CHAR),
    flg_doc_type           VARCHAR2(1 CHAR),
    doc_parameter          NUMBER(24),

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity
    (
        SELF                     IN OUT NOCOPY t_obj_nnn_epis_activity,
        i_id_nnn_epis_activity   IN NUMBER DEFAULT NULL,
        i_id_nic_activity        IN NUMBER DEFAULT NULL,
        i_id_nic_othr_actv_vrsn  IN NUMBER DEFAULT NULL,
        i_context_record         IN t_obj_context_record DEFAULT NULL,
        i_prof_info              IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info            IN t_obj_cancel_info DEFAULT NULL,
        i_status                 IN t_obj_status DEFAULT NULL,
        i_id_episode_origin      IN NUMBER DEFAULT NULL,
        i_id_episode_destination IN NUMBER DEFAULT NULL,
        i_flg_prn                IN VARCHAR2 DEFAULT NULL,
        i_notes_prn              IN CLOB DEFAULT NULL,
        i_flg_time               IN VARCHAR2 DEFAULT NULL,
        i_flg_priority           IN VARCHAR2 DEFAULT NULL,
        i_id_order_recurr_plan   IN NUMBER DEFAULT NULL,
        i_desc_instructions      IN VARCHAR2 DEFAULT NULL,
        i_flg_doc_type           IN VARCHAR2 DEFAULT NULL,
        i_doc_parameter          IN NUMBER DEFAULT NULL,
        i_bitemporal_data        IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes IN VARCHAR2 DEFAULT 'N'
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
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_activity AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_activity
    (
        SELF                     IN OUT NOCOPY t_obj_nnn_epis_activity,
        i_id_nnn_epis_activity   IN NUMBER DEFAULT NULL,
        i_id_nic_activity        IN NUMBER DEFAULT NULL,
        i_id_nic_othr_actv_vrsn  IN NUMBER DEFAULT NULL,
        i_context_record         IN t_obj_context_record DEFAULT NULL,
        i_prof_info              IN t_obj_prof_info DEFAULT NULL,
        i_cancel_info            IN t_obj_cancel_info DEFAULT NULL,
        i_status                 IN t_obj_status DEFAULT NULL,
        i_id_episode_origin      IN NUMBER DEFAULT NULL,
        i_id_episode_destination IN NUMBER DEFAULT NULL,
        i_flg_prn                IN VARCHAR2 DEFAULT NULL,
        i_notes_prn              IN CLOB DEFAULT NULL,
        i_flg_time               IN VARCHAR2 DEFAULT NULL,
        i_flg_priority           IN VARCHAR2 DEFAULT NULL,
        i_id_order_recurr_plan   IN NUMBER DEFAULT NULL,
        i_desc_instructions      IN VARCHAR2 DEFAULT NULL,
        i_flg_doc_type           IN VARCHAR2 DEFAULT NULL,
        i_doc_parameter          IN NUMBER DEFAULT NULL,
        i_bitemporal_data        IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nnn_epis_activity   := i_id_nnn_epis_activity;
        self.id_nic_activity        := i_id_nic_activity;
        self.id_nic_othr_actv_vrsn  := i_id_nic_othr_actv_vrsn;
        self.context_record         := i_context_record;
        self.prof_info              := i_prof_info;
        self.cancel_info            := i_cancel_info;
        self.status                 := i_status;
        self.id_episode_origin      := i_id_episode_origin;
        self.id_episode_destination := i_id_episode_destination;
        self.flg_prn                := i_flg_prn;
        self.notes_prn              := i_notes_prn;
        self.flg_time               := i_flg_time;
        self.flg_priority           := i_flg_priority;
        self.id_order_recurr_plan   := i_id_order_recurr_plan;
        self.desc_instructions      := i_desc_instructions;
        self.flg_doc_type           := i_flg_doc_type;
        self.doc_parameter          := i_doc_parameter;
        self.bitemporal_data        := i_bitemporal_data;
        self.has_historical_changes := i_has_historical_changes;
    
        RETURN;
    END t_obj_nnn_epis_activity;

    -- Member procedures and functions
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json := (SELF AS t_obj_temporal_record).to_json(i_lang => i_lang, i_prof => i_prof);
    
        l_json.put('ID_NNN_EPIS_ACTIVITY', self.id_nnn_epis_activity);
        l_json.put('ID_NIC_ACTIVITY', self.id_nic_activity);
        l_json.put('ID_NIC_OTHR_ACTV_VRSN', self.id_nic_othr_actv_vrsn);
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
        l_json.put('ID_EPISODE_ORIGIN', self.id_episode_origin);
        l_json.put('ID_EPISODE_DESTINATION', self.id_episode_destination);
        l_json.put('FLG_PRN', self.flg_prn);
        l_json.put('NOTES_PRN', json_object_t.parse(self.notes_prn));
        l_json.put('FLG_TIME', self.flg_time);
        l_json.put('FLG_PRIORITY', self.flg_priority);
        l_json.put('ID_ORDER_RECURR_PLAN', self.id_order_recurr_plan);
        l_json.put('DESC_INSTRUCTIONS', self.desc_instructions);
        l_json.put('FLG_DOC_TYPE', self.flg_time);
        l_json.put('DOC_PARAMETER', self.flg_time);
    
        RETURN l_json;
    END to_json;
END;
/
