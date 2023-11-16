CREATE OR REPLACE TYPE t_obj_nnn_epis_diag_eval UNDER t_obj_temporal_record
(
-- Author  : ARIEL.MACHADO
-- Created : 1/30/2014 16:28:08 AM
-- Purpose : NANDA, NIC, NOC development: Object type to represent an Evaluation of a NANDA nursing diagnoses

-- Attributes
    id_nnn_epis_diag_eval       NUMBER(24),
    id_nnn_epis_diagnosis       NUMBER(24),
    context_record              t_obj_context_record,
    prof_info                   t_obj_prof_info,
    lst_related_factor          t_coll_obj_nan_related_factor,
    lst_risk_factor             t_coll_obj_nan_risk_factor,
    lst_defining_characteristic t_coll_obj_nan_def_chars,
    cancel_info                 t_obj_cancel_info,
    status                      t_obj_status,
    dt_evaluation               TIMESTAMP WITH LOCAL TIME ZONE,
    notes                       CLOB,

-- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_diag_eval
    (
        SELF                          IN OUT NOCOPY t_obj_nnn_epis_diag_eval,
        i_id_nnn_epis_diag_eval       IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_diagnosis       IN NUMBER DEFAULT NULL,
        i_context_record              IN t_obj_context_record DEFAULT NULL,
        i_prof_info                   IN t_obj_prof_info DEFAULT NULL,
        i_lst_related_factor          IN t_coll_obj_nan_related_factor DEFAULT NULL,
        i_lst_risk_factor             IN t_coll_obj_nan_risk_factor DEFAULT NULL,
        i_lst_defining_characteristic IN t_coll_obj_nan_def_chars DEFAULT NULL,
        i_cancel_info                 IN t_obj_cancel_info DEFAULT NULL,
        i_status                      IN t_obj_status DEFAULT NULL,
        i_dt_evaluation               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_notes                       IN CLOB DEFAULT NULL,
        i_bitemporal_data             IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes      IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT,

-- Member functions and procedures
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t
)
;
/
CREATE OR REPLACE TYPE BODY t_obj_nnn_epis_diag_eval AS

    -- Default constructor
    CONSTRUCTOR FUNCTION t_obj_nnn_epis_diag_eval
    (
        SELF                          IN OUT NOCOPY t_obj_nnn_epis_diag_eval,
        i_id_nnn_epis_diag_eval       IN NUMBER DEFAULT NULL,
        i_id_nnn_epis_diagnosis       IN NUMBER DEFAULT NULL,
        i_context_record              IN t_obj_context_record DEFAULT NULL,
        i_prof_info                   IN t_obj_prof_info DEFAULT NULL,
        i_lst_related_factor          IN t_coll_obj_nan_related_factor DEFAULT NULL,
        i_lst_risk_factor             IN t_coll_obj_nan_risk_factor DEFAULT NULL,
        i_lst_defining_characteristic IN t_coll_obj_nan_def_chars DEFAULT NULL,
        i_cancel_info                 IN t_obj_cancel_info DEFAULT NULL,
        i_status                      IN t_obj_status DEFAULT NULL,
        i_dt_evaluation               IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_notes                       IN CLOB DEFAULT NULL,
        i_bitemporal_data             IN t_obj_bitemporal_data DEFAULT NULL,
        i_has_historical_changes      IN VARCHAR2 DEFAULT 'N'
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_nnn_epis_diag_eval       := i_id_nnn_epis_diag_eval;
        self.id_nnn_epis_diagnosis       := i_id_nnn_epis_diagnosis;
        self.context_record              := i_context_record;
        self.prof_info                   := i_prof_info;
        self.lst_related_factor          := i_lst_related_factor;
        self.lst_risk_factor             := i_lst_risk_factor;
        self.lst_defining_characteristic := i_lst_defining_characteristic;
        self.cancel_info                 := i_cancel_info;
        self.status                      := i_status;
        self.dt_evaluation               := i_dt_evaluation;
        self.notes                       := i_notes;
        self.bitemporal_data             := i_bitemporal_data;
        self.has_historical_changes      := i_has_historical_changes;
    
        RETURN;
    END t_obj_nnn_epis_diag_eval;

    -- Member functions and procedures
    OVERRIDING MEMBER FUNCTION to_json
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN json_object_t IS
        l_json     json_object_t;
        l_json_lst json_array_t;
    BEGIN
        l_json := (SELF AS t_obj_temporal_record).to_json(i_lang => i_lang, i_prof => i_prof);
    
        l_json.put('ID_NNN_EPIS_DIAG_EVAL', self.id_nnn_epis_diag_eval);
        l_json.put('ID_NNN_EPIS_DIAGNOSIS', self.id_nnn_epis_diagnosis);
    
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
    
        IF self.lst_related_factor IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_related_factor.count()
            LOOP
                l_json_lst.append(self.lst_related_factor(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_RELATED_FACTOR', l_json_lst);
    
        IF self.lst_risk_factor IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_risk_factor.count()
            LOOP
                l_json_lst.append(self.lst_risk_factor(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_RISK_FACTOR', l_json_lst);
    
        IF self.lst_defining_characteristic IS NOT empty
        THEN
            FOR i IN 1 .. self.lst_defining_characteristic.count()
            LOOP
                l_json_lst.append(self.lst_defining_characteristic(i).to_json());
            END LOOP;
        END IF;
        l_json.put('LST_DEFINING_CHARACTERISTIC', l_json_lst);
    
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
        l_json.put('NOTES', json_object_t.parse(self.notes));
    
        RETURN l_json;
    END to_json;
END;
/
