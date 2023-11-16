CREATE OR REPLACE TYPE t_rec_desc_scales IS OBJECT
(
    desc_class VARCHAR2(4000),
    signature  VARCHAR2(4000)
);

CREATE OR REPLACE TYPE t_coll_desc_scales IS TABLE OF t_rec_desc_scales;
