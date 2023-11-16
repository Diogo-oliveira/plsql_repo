CREATE OR REPLACE FUNCTION "MED_TBL_COMP_STRUCT" (i_comp_struct t_component_struct) return t_tbl_component_struct
aggregate using aggr_med_component2;
