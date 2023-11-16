-- Record with all the data related with an icnp intervention needed to make a request
CREATE OR REPLACE TYPE t_rec_icnp_interv_act_st_cplan IS OBJECT
(
    id_interv            NUMBER(24), -- icnp_cplan_stand_compo.id_composition%TYPE
    desc_interv          VARCHAR2(1000 CHAR),
    id_rel_diag          NUMBER(24), -- icnp_cplan_stand_compo.id_composition_parent%TYPE,
    desc_instr           VARCHAR2(1000 CHAR),
    execution            VARCHAR2(1 CHAR), -- icnp_cplan_stand_compo.flg_time%TYPE,
    desc_execution       VARCHAR2(1000 CHAR),
    dt_begin             VARCHAR2(4000), -- sys_message.desc_message%TYPE,
    id_order_recurr_plan NUMBER(24), -- icnp_cplan_stand_compo.id_order_recurr_plan%TYPE,
    flg_prn              VARCHAR2(1), -- icnp_cplan_stand_compo.flg_prn%TYPE,
    desc_prn             VARCHAR2(800), -- sys_domain.desc_val%type
    prn_notes            CLOB -- icnp_cplan_stand_compo.prn_notes%TYPE
)
;
/
