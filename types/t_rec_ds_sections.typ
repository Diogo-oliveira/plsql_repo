-- CHANGED BY: sergio.dias
-- CHANGE DATE: 04/12/2013 17:22
-- CHANGE REASON: [ALERT-271307]
DROP TYPE t_table_ds_sections;

CREATE OR REPLACE TYPE t_rec_ds_sections FORCE AS OBJECT
(
    id_ds_cmpt_mkt_rel     NUMBER(24),
    id_ds_component_parent NUMBER(24),
    id_ds_component        NUMBER(24),
    component_desc         VARCHAR2(1000 CHAR),
    internal_name          VARCHAR2(200 CHAR),
    flg_component_type     VARCHAR2(1 CHAR),
    flg_data_type          VARCHAR2(2 CHAR),
    slg_internal_name      VARCHAR2(200 CHAR),
    addit_info_xml_value   CLOB,
    rank                   NUMBER(24),
    max_len                NUMBER(24),
    min_value              NUMBER(24),
    max_value              NUMBER(24),
    gender                 VARCHAR2(1 CHAR),
    age_min_value          NUMBER(5,2),
    age_min_unit_measure   NUMBER(24),
    age_max_value          NUMBER(5,2),
    age_max_unit_measure   NUMBER(24),
    component_values       t_table_ds_items_values,
    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER,
        gender                 VARCHAR2,
        age_min_value          NUMBER,
        age_min_unit_measure   NUMBER,
        age_max_value          NUMBER,
        age_max_unit_measure   NUMBER,
        component_values       t_table_ds_items_values
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER,
        component_values       t_table_ds_items_values
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER
    ) RETURN SELF AS RESULT
) INSTANTIABLE
NOT FINAL;
/

CREATE OR REPLACE TYPE BODY t_rec_ds_sections AS
    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER,
        gender                 VARCHAR2,
        age_min_value          NUMBER,
        age_min_unit_measure   NUMBER,
        age_max_value          NUMBER,
        age_max_unit_measure   NUMBER,
        component_values       t_table_ds_items_values
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_ds_cmpt_mkt_rel     := id_ds_cmpt_mkt_rel;
        self.id_ds_component_parent := id_ds_component_parent;
        self.id_ds_component        := id_ds_component;
        self.component_desc         := component_desc;
        self.internal_name          := internal_name;
        self.flg_component_type     := flg_component_type;
        self.flg_data_type          := flg_data_type;
        self.slg_internal_name      := slg_internal_name;
        self.addit_info_xml_value   := addit_info_xml_value;
        self.rank                   := rank;
        self.max_len                := max_len;
        self.min_value              := min_value;
        self.max_value              := max_value;
        self.gender                 := gender;
        self.age_min_value          := age_min_value;
        self.age_min_unit_measure   := age_min_unit_measure;
        self.age_max_value          := age_max_value;
        self.age_max_unit_measure   := age_max_unit_measure;

        IF component_values IS NOT NULL
        THEN
            self.component_values := component_values;
        ELSE
            self.component_values := NEW t_table_ds_items_values();
        END IF;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER,
        component_values       t_table_ds_items_values
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_ds_cmpt_mkt_rel     := id_ds_cmpt_mkt_rel;
        self.id_ds_component_parent := id_ds_component_parent;
        self.id_ds_component        := id_ds_component;
        self.component_desc         := component_desc;
        self.internal_name          := internal_name;
        self.flg_component_type     := flg_component_type;
        self.flg_data_type          := flg_data_type;
        self.slg_internal_name      := slg_internal_name;
        self.addit_info_xml_value   := addit_info_xml_value;
        self.rank                   := rank;
        self.max_len                := max_len;
        self.min_value              := min_value;
        self.max_value              := max_value;

        IF component_values IS NOT NULL
        THEN
            self.component_values := component_values;
        ELSE
            self.component_values := NEW t_table_ds_items_values();
        END IF;
    
        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_ds_sections
    (
        SELF                   IN OUT NOCOPY t_rec_ds_sections,
        id_ds_cmpt_mkt_rel     NUMBER,
        id_ds_component_parent NUMBER,
        id_ds_component        NUMBER,
        component_desc         VARCHAR2,
        internal_name          VARCHAR2,
        flg_component_type     VARCHAR2,
        flg_data_type          VARCHAR2,
        slg_internal_name      VARCHAR2,
        addit_info_xml_value   CLOB,
        rank                   NUMBER,
        max_len                NUMBER,
        min_value              NUMBER,
        max_value              NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_ds_cmpt_mkt_rel     := id_ds_cmpt_mkt_rel;
        self.id_ds_component_parent := id_ds_component_parent;
        self.id_ds_component        := id_ds_component;
        self.component_desc         := component_desc;
        self.internal_name          := internal_name;
        self.flg_component_type     := flg_component_type;
        self.flg_data_type          := flg_data_type;
        self.slg_internal_name      := slg_internal_name;
        self.addit_info_xml_value   := addit_info_xml_value;
        self.rank                   := rank;
        self.max_len                := max_len;
        self.min_value              := min_value;
        self.max_value              := max_value;
        self.component_values       := NEW t_table_ds_items_values();
    
        RETURN;
    END;
END;
/

CREATE OR REPLACE TYPE t_table_ds_sections IS TABLE OF t_rec_ds_sections;
-- CHANGE END: sergio.dias