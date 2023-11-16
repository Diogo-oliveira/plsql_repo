CREATE OR REPLACE TYPE t_rec_comm_order_req_det FORCE AS OBJECT
(
    id_comm_order_req NUMBER(24),
    id_section         NUMBER(24),
    header_1           VARCHAR2(1000 CHAR),
    header_2           VARCHAR2(1000 CHAR),
    field_code         VARCHAR2(50 CHAR),
    field_name         VARCHAR2(1000 CHAR),
    field_value        CLOB,
    field_style        VARCHAR2(50 CHAR),
    signature          VARCHAR2(1000 CHAR),
    rank               NUMBER(24),
    field_rank         NUMBER(24),
    style_rank         NUMBER(24),
    dt_detail          TIMESTAMP(6)
        WITH LOCAL TIME ZONE,   

    CONSTRUCTOR FUNCTION t_rec_comm_order_req_det RETURN SELF AS RESULT,
    MEMBER FUNCTION to_string RETURN VARCHAR2
)
/

CREATE OR REPLACE TYPE BODY t_rec_comm_order_req_det IS
    CONSTRUCTOR FUNCTION t_rec_comm_order_req_det RETURN SELF AS RESULT IS
    BEGIN

        self.id_comm_order_req := NULL;
        self.id_section        := NULL;
        self.header_1          := NULL;
        self.header_2          := NULL;
        self.field_code        := NULL;
        self.field_name        := NULL;
        self.field_value       := NULL;
        self.field_style       := NULL;
        self.signature         := NULL;
        self.rank              := NULL;
        self.field_rank        := NULL;
        self.style_rank        := NULL;
        self.dt_detail         := NULL;

        RETURN;
    END;

    MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
        RETURN 'id_comm_order_req=' || self.id_comm_order_req || ' id_section=' || self.id_section || ' header_1=' || self.header_1 || ' header_2=' || self.header_2 || ' field_code=' || self.field_code || ' field_name=' || self.field_name || ' field_value=' || self.field_value || ' field_style=' || self.field_style || ' signature=' || self.signature || ' rank=' || self.rank || ' field_rank=' || self.field_rank || ' style_rank=' || self.style_rank || ' dt_detail=' || self.dt_detail;
    END to_string;
END;
/