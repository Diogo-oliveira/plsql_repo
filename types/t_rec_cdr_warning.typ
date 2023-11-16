CREATE OR REPLACE TYPE t_rec_cdr_warning force AS OBJECT
(
-- data structure for the cds popup
    section_1_id            NUMBER(24), -- section 1 identifier
    desc_concept            VARCHAR2(1000 CHAR), -- section 1 description
    section_2_id            NUMBER(24), -- section 2 identifier
    desc_element            VARCHAR2(1000 CHAR), -- section 2 description
    icon_cdr_concept        VARCHAR2(200 CHAR), -- section 2 icon
    section_3_id            NUMBER(24), -- section 3 identifier
    id_cdr_action           NUMBER(24), -- rule action identifier
    id_cdr_answer           NUMBER(24), -- answer identifier
    notes_answer            CLOB, -- answer notes
    flg_req_notes           VARCHAR2(1 CHAR), -- are notes required for this answer? Y/N
    show_line_flg           VARCHAR2(1 CHAR), -- is this the last row of each section 3? Y/N
    id_cdr_event            NUMBER(24), -- event identifier
    type_desc               VARCHAR2(1000 CHAR), -- rule type description
    type_icon               VARCHAR2(200 CHAR), -- rule type icon
    type_icon_color         VARCHAR2(200 CHAR), -- rule type icon color
    type_message            VARCHAR2(32000 CHAR), -- rule message description
    severity_desc           VARCHAR2(1000 CHAR), -- rule severity description
    severity_color          VARCHAR2(200 CHAR), -- rule severity color
    severity_text_style     VARCHAR2(1 CHAR), -- rule severity text style
    triggered_by_desc       CLOB, -- rule "triggered by" description
    triggered_by_color      VARCHAR2(200 CHAR),
    section_4_last_item_flg VARCHAR2(1 CHAR), -- is this the last row of each section 4? Y/N
    rank                    NUMBER(6), -- warning general ranking
    id_links                NUMBER(24),
    id_cdr_definition       NUMBER(24),
    id_cdr_doc_instance     NUMBER(24),
    CONSTRUCTOR FUNCTION t_rec_cdr_warning RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_cdr_warning IS

    CONSTRUCTOR FUNCTION t_rec_cdr_warning RETURN SELF AS RESULT IS
    BEGIN
        self.section_1_id            := NULL;
        self.desc_concept            := NULL;
        self.section_2_id            := NULL;
        self.desc_element            := NULL;
        self.icon_cdr_concept        := NULL;
        self.section_3_id            := NULL;
        self.id_cdr_action           := NULL;
        self.id_cdr_answer           := NULL;
        self.notes_answer            := NULL;
        self.flg_req_notes           := NULL;
        self.show_line_flg           := NULL;
        self.id_cdr_event            := NULL;
        self.type_desc               := NULL;
        self.type_icon               := NULL;
        self.type_icon_color         := NULL;
        self.type_message            := NULL;
        self.severity_desc           := NULL;
        self.severity_color          := NULL;
        self.severity_text_style     := NULL;
        self.triggered_by_desc       := NULL;
        self.triggered_by_color      := NULL;
        self.severity_color          := NULL;
        self.section_4_last_item_flg := NULL;
        self.rank                    := NULL;
        self.id_links                := NULL;
        self.id_cdr_definition       := NULL;
        self.id_cdr_doc_instance     := NULL;
        RETURN;
    END;

END;
/
