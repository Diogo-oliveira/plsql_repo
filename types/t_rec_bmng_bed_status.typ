-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 2009-07-31
-- CHANGE REASON: ALERT-38599
CREATE OR REPLACE TYPE t_rec_bmng_bed_status AS OBJECT
(
    id_bed                    NUMBER(24),
    id_bmng_action            NUMBER(24),
    icon_bed_status           VARCHAR2(200),
    icon_bed_cleaning_status  VARCHAR2(200),
    desc_bed_status           VARCHAR2(200),
    desc_cleaning_status      VARCHAR2(200),
    availability              NUMBER(24),
    desc_availability         VARCHAR2(200),
    flg_conflict              VARCHAR2(1),
    flg_bed_sts_toflash       VARCHAR2(1),
    flg_bed_clean_sts_toflash VARCHAR2(1)
)
/
-- CHANGE END: Alexandre Santos