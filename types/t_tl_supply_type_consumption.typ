drop type t_tbl_supply_type_consumption;

CREATE OR REPLACE TYPE t_tl_supply_type_consumption AS OBJECT
(
    val      VARCHAR2(30),
    desc_val VARCHAR2(800),
    flg_selected varchar2(1)
);
/