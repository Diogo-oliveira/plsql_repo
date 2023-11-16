-- Ao alterar este TYPE é necessário avisar o grupo do P1 / Referral.

CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(6),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE
)
;
/
-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 15-01-2009
-- CHANGE REASON: ALERT-9198
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30)
)
;
/
-- CHANGE END

-- CHANGED BY: José Castro
-- CHANGE DATE: 23-04-2009
-- CHANGE REASON: ALERT-696
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6)
);
/
-- CHANGE END: José Castro

-- CHANGED BY: José Castro
-- CHANGE DATE: 23-04-2009
-- CHANGE REASON: ALERT-29031
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
		id_analysis_req_det         NUMBER(24)
);
/
-- CHANGE END: José Castro

-- CHANGED BY: José Castro
-- CHANGE DATE: 23-04-2009
-- CHANGE REASON: ALERT-29031
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000)  
);
/
-- CHANGE END: José Castro

-- CHANGED BY: José Castro
-- CHANGE DATE: 15-06-2009
-- CHANGE REASON: ALERT-32128
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1)
);
/
-- CHANGE END: José Castro


-- CHANGED BY: José Castro
-- CHANGE DATE: 18-06-2009
-- CHANGE REASON: ALERT-696
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1),
    result_comments             VARCHAR2(4000)
);
/
-- CHANGE END: José Castro

-- CHANGED BY: Carlos Nogueira
-- CHANGE DATE: 29-09-2009
-- CHANGE REASON: ALERT-47125
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1),
    result_comments             VARCHAR2(4000),
    id_result                   VARCHAR2(4000)
);
/
-- CHANGE END: Carlos Nogueira

-- CHANGED BY: José Castro
-- CHANGE DATE: 15-10-2009
-- CHANGE REASON: ALERT-49104
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1),
    result_comments             VARCHAR2(4000),
    id_result                   VARCHAR2(4000),
    dt_ins_result_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE
);
/
-- CHANGE END: José Castro

-- CHANGED BY: José Castro
-- CHANGE DATE: 27-01-2010
-- CHANGE REASON: ALERT-69852
CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    date_analysis_result_par    VARCHAR2(4000),
    hour_analysis_result_par    VARCHAR2(4000),
    desc_analysis_result        VARCHAR2(4000),
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  VARCHAR2(4000),
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1),
    result_comments             VARCHAR2(4000),
    id_result                   VARCHAR2(4000),
    dt_ins_result_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE
);
/
-- CHANGE END: José Castro
