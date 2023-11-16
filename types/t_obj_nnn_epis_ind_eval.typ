CREATE OR REPLACE TYPE t_obj_nnn_epis_ind_eval UNDER t_obj_temporal_record
(
-- Author  : ARIEL.MACHADO
-- Created : 2/5/2014 3:30:01 PM
-- Purpose : NANDA, NIC, NOC development: Object type to represent an Evaluation of a NOC Indicator

-- Attributes
    id_nnn_epis_ind_eval  NUMBER(24),
    id_nnn_epis_indicator NUMBER(24),
    context_record        t_obj_context_record,
    prof_info             t_obj_prof_info,
    target_value          t_obj_likert_scale_level,
    indicator_value       t_obj_likert_scale_level,
    cancel_info           t_obj_cancel_info,
    status                t_obj_status,
    dt_evaluation         TIMESTAMP WITH LOCAL TIME ZONE,
    dt_plan               TIMESTAMP WITH LOCAL TIME ZONE,
    notes                 CLOB,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_ind_eval
    (
        SELF                     IN OUT NOCOPY t_obj_nnn_epis_ind_eval,
        i_id_nnn_epis_ind_eval   IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_indicator  IN NUMBER DEFAULT NULL,
        i_context_record         IN t_obj_context_record DEFAULT NULL,
        i_prof_info              IN t_obj_prof_info DEFAULT NULL,
        i_target_value           IN t_obj_likert_scale_level DEFAULT NULL,
        i_indicator_value        IN t_obj_likert_scale_level DEFAULT NULL,
        i_cancel_info            IN t_obj_cancel_info DEFAULT NULL,
        i_status                 IN t_obj_status DEFAULT NULL,
        i_dt_evaluation          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_plan                IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_notes                  IN CLOB DEFAULT NULL,
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
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_ind_eval AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_ind_eval
    (
        SELF                     IN OUT NOCOPY t_obj_nnn_epis_ind_eval,
        i_id_nnn_epis_ind_eval   IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_indicator  IN NUMBER DEFAULT NULL,
        i_context_record         IN t_obj_context_record DEFAULT NULL,
        i_prof_info              IN t_obj_prof_info DEFAULT NULL,
        i_target_value           IN t_obj_likert_scale_level DEFAULT NULL,
        i_indicator_value        IN t_obj_likert_scale_level DEFAULT NULL,
        i_cancel_info            IN t_obj_cancel_info DEFAULT NULL,
        i_status                 IN t_obj_status DEFAULT NULL,
        i_dt_evaluation          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_plan                IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_notes                  IN CLOB DEFAULT NULL,
        i_bitemporal_data        IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nnn_epis_ind_eval   := i_id_nnn_epis_ind_eval;
        self.id_nnn_epis_indicator  := i_id_nnn_epis_indicator;
        self.context_record         := i_context_record;
        self.prof_info              := i_prof_info;
        self.target_value           := i_target_value;
        self.indicator_value        := i_indicator_value;
        self.cancel_info            := i_cancel_info;
        self.status                 := i_status;
        self.dt_evaluation          := i_dt_evaluation;
        self.dt_plan                := i_dt_plan;
        self.notes                  := i_notes;
        self.bitemporal_data        := i_bitemporal_data;
        self.has_historical_changes := i_has_historical_changes;
    
        RETURN;
    END t_obj_nnn_epis_ind_eval;

    -- Member procedures and functions
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json json_object_t;
    BEGIN
        l_json := (SELF AS t_obj_temporal_record).to_json(i_lang => i_lang, i_prof => i_prof);
    
        l_json.put('ID_NNN_EPIS_IND_EVAL', self.id_nnn_epis_ind_eval);
        l_json.put('ID_NNN_EPIS_INDICATOR', self.id_nnn_epis_indicator);
    
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
    
        IF self.target_value IS NOT NULL
        THEN
            l_json.put('TARGET_VALUE', self.target_value.to_json());
        ELSE
            l_json.put('TARGET_VALUE', json_object_t());
        END IF;
    
        IF self.indicator_value IS NOT NULL
        THEN
            l_json.put('INDICATOR_VALUE', self.indicator_value.to_json());
        ELSE
            l_json.put('INDICATOR_VALUE', json_object_t());
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
    
        l_json.put('DT_EVALUATION',
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_evaluation, i_prof => i_prof));
        l_json.put('DT_PLAN', pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => self.dt_plan, i_prof => i_prof));
    
        l_json.put('NOTES', json_object_t.parse(self.notes));
    
        RETURN l_json;
    END to_json;
END;
/
